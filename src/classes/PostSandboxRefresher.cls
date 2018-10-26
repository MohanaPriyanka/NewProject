/*
  Author: Peter Yao

  Description: 1. Changes emails in Leads and Contacts so we don't accidentally email them
                  Courtesy of http://www.soliantconsulting.com/blog/2016/03/salesforce-sandboxpostcopy-interface
               2. Deletes the Recurring Billing scheduled job

  Tested By: PostSandboxRefresherTest
               
 */
global class PostSandboxRefresher implements SandboxPostCopy {
    global void runApexClass(SandboxContext context) {

        disableEmails();
        deleteScheduledJob('Recurring Billing');
        updateLetterStreamToTestConfig();
        updateDocusignToDemoConfig();
        switchChargentToTestMode();
        setupBWTestPartner();
        setupDataForReportTest();
        System.enqueueJob(new PostSandboxRefresher.CSRecordLoader());
    }

    global static void deleteScheduledJob(String jobname) {
        List<CronTrigger> crons = [
            SELECT Id, CronJobDetail.Name, CronExpression
            FROM CronTrigger
            WHERE CronJobDetail.Name = :jobname
        ];
        for (CronTrigger ct : crons) {
            System.abortJob(ct.Id);
        }
    }

    static Map<String, Map<String, Object>> objectConditionals =
        new Map<String, Map <String, Object>>{
            'Lead' => new Map<String, Object>{
                'isConverted' => false
            }
        };

    global static void disableEmails() {
        Organization o = [SELECT IsSandbox FROM Organization LIMIT 1];

        if (o.IsSandbox || Test.isRunningTest()) {
            // Map from SObject to List of Email Fields
            Map<String, List<String>> soEmailFieldMap = findEmaiLFields();
            // Invalidate Email fields found on SObjects
            processEmailFields(soEmailFieldMap);
        } else {
            throw new Util.BWException('Don\'t disable emails in production this way');
        }
    }

    private static Map<String, List<String>> findEmaiLFields() {
        Map<String, List<String>> soEmailFieldMap = new Map<String, List<String>>();
        // Iterate over all SObjects
        for (SObjectType soType : Schema.getGlobalDescribe().values()) {
            DescribeSObjectResult soDescribe = soType.getDescribe();
            // Skip objects we cannot query or update
            if (!soDescribe.isQueryable() || !soDescribe.isUpdateable() || soDescribe.getName() == 'User') {
                continue;
            }
            String objectTypeName = soDescribe.getName();
            // Iterate over all fields found on a given SObject
            for (SObjectField soField : soDescribe.fields.getMap().values()) {
                DescribeFieldResult field = soField.getDescribe();
                // Skip non Email type fields
                if (field.getType() != Schema.DisplayType.EMAIL) {
                    continue;
                }
                // Skip emails that cannot be filtered on or updated
                if (!field.isFilterable() || !field.isUpdateable()) {
                    continue;
                }
                // Collect all Email fields found
                if (soEmailFieldMap.containsKey(objectTypeName)) {
                    soEmailFieldMap.get(objectTypeName).add(field.getName());
                } else {
                    soEmailFieldMap.put(objectTypeName,
                        new List<String>{
                            field.getName()
                        });
                }
            }
        }
        return soEmailFieldMap;
    }

    private static void processEmailFields(Map<String, List<String>> soEmailFieldMap) {
        // Iterate over the SObject to Email Fields collection
        for (String objectName : soEmailFieldMap.keySet()) {
            // Get any specified conditionals
            Map<String, Object> conditionals = new Map<String, Object>();
            if (objectConditionals.containsKey(objectName)) {
                conditionals = objectConditionals.get(objectName);
            }
            // Build a list of all fields that need to be queried
            List<String> emailFields = soEmailFieldMap.get(objectName);
            List<String> fieldList = new List<String>();
            fieldList.addAll(emailFields);
            fieldList.addAll(conditionals.keySet());
            // Generate a SOQL query to get records with non null emails
            String soql = getSOQL(objectName, fieldList);
            System.enqueueJob(new PostSandboxRefresher.RecordUpdater(soql, conditionals, emailFields));
        }
    }

    global class RecordUpdater implements Queueable {
        String soql;
        Map<String, Object> conditionals;
        List<String> emailFields;

        global RecordUpdater(String soql, Map<String, Object> conditionals, List<String> emailFields) {
            this.soql = soql;
            this.conditionals = conditionals;
            this.emailFields = emailFields;
        }

        global void execute(QueueableContext context) {
            List<SObject> records = new List<SObject>();
            // Iterate over queried SObject records
            for (SObject record : Database.query(soql)) {
                // Skip records that do not match specified conditons
                if (!checkConditions(record, conditionals)) {
                    continue;
                }
                // Iterate over Email fields found on SObject and invalidate values
                for (String field : emailFields) {
                    String email = (String) record.get(field);
                    if (String.isEmpty(email)) {
                        continue;
                    }
                    record.put(field, email.replaceAll('@', '--at--') + '@disabled.disabled');
                }
                records.add(record);
            }
            if (records.size() > 0) {
                Database.executeBatch(new GenericBatchDMLOperation(records, 'Update'));
            }
        }
    }

    private static Boolean checkConditions(SObject record, Map<String, Object> conditionals) {
        for (String field : conditionals.keySet()) {
            Object value = record.get(field);
            Object condition = conditionals.get(field);
            if (value != condition) {
                return false;
            }
        }
        return true;
    }

    global static String getSOQL(String objectTypeName, List<String> fieldList) {
        List<String> conditionals = new List<String>();
        for (String field : fieldList) {
            conditionals.add(field + ' != null');
        }
        String soql = 'SELECT {!fieldList} FROM {!objectTypeName} WHERE {!conditionals}';
        return soql
            .replace('{!fieldList}', String.join(fieldList, ','))
            .replace('{!objectTypeName}', objectTypeName)
            .replace('{!conditionals}', String.join(conditionals, ' OR '));
    }

    global static void updateLetterStreamToTestConfig() {
        Organization org = [SELECT Id, IsSandbox FROM Organization LIMIT 1];
        if (!org.isSandbox && !Test.isRunningTest()) {
            throw new Util.BWException('Dont\'t update LetterStream config in production this way');
        }

        List<LetterStream_Settings__c> letterStreamSettings = [
            SELECT Id, API_Id__c, API_Key__c
            FROM LetterStream_Settings__c
        ];

        LetterStream_Settings__c newLetterStreamSetting = new LetterStream_Settings__c();
        if (!letterStreamSettings.isEmpty()) {
            newLetterStreamSetting.Id = letterStreamSettings[0].Id;
        }
        // credentials for bluewavetestAPI (see wiki)
        newLetterStreamSetting.Name = 'Test Config';
        newLetterStreamSetting.API_Id__c = 'ft5eh41g_test';
        newLetterStreamSetting.API_Key__c = 'fhv4d7bèv9v6n7_test';
        newLetterStreamSetting.API_Endpoint__c = 'https://secure.letterstream.com/apis/';
        upsert newLetterStreamSetting;
    }
  
    global static void updateDocusignToDemoConfig() {
        Organization org = [SELECT Id, IsSandbox FROM Organization LIMIT 1];
        if (!org.IsSandbox && !Test.isRunningTest()) {
            throw new Util.BWException('Don\'t update DocuSign config in production this way');
        }

        List<dsfs__DocuSignAccountConfiguration__c> docusignConfigs = [
            SELECT Id, dsfs__OrganizationId__c, dsfs__AccountId__c, dsfs__DocuSignEnvironment__c
            FROM dsfs__DocuSignAccountConfiguration__c
        ];

        dsfs__DocuSignAccountConfiguration__c docusignConfig = new dsfs__DocuSignAccountConfiguration__c();
        if (!docusignConfigs.isEmpty()) {
            // Not an empty sandbox, update the config
            docusignConfig.Id = docusignConfigs[0].Id;
        }
        docusignConfig.dsfs__OrganizationId__c = org.Id;
        // The demo instance with pyao@bluewavesolar.com login
        docusignConfig.dsfs__AccountId__c = '2255b4dd-7d4f-425a-bcc9-d53328055381';
        docusignConfig.dsfs__DocuSignEnvironment__c = 'demo';
        upsert docusignConfig;

        List<System_Properties__c> systemProperties = System_Properties__c.getall().values();
        if (systemProperties.size() > 0) {
            systemProperties[0].DocuSign_API_Account_ID__c = '2255b4dd-7d4f-425a-bcc9-d53328055381';
            systemProperties[0].DocuSign_Customer_Care_User__c = 'pyao@bluewavesolar.com';
            systemProperties[0].DocuSign_Guest_User__c = 'pyao@bluewave-capital.com';
            systemProperties[0].DocuSign_Guest_User_Credential__c = '137Newbury';
            systemProperties[0].DocuSign_Integrator_Key__c = '2ceabed4-3a84-4220-9a76-9b1f9f0cf6ed';
            update systemProperties[0];
        }
    }

    global static void switchChargentToTestMode() {
        Organization org = [SELECT Id, IsSandbox FROM Organization LIMIT 1];
        if (!org.IsSandbox && !Test.isRunningTest()) {
            throw new Util.BWException('Don\'t switch Chargent to Test Mode!');
        }

        List<ChargentOrders__ChargentOrder__c> orders = [
            SELECT Id
            FROM ChargentOrders__ChargentOrder__c
            WHERE ChargentOrders__Card_Type__c != null
            OR ChargentOrders__Bank_Account_Type__c != null
        ];
        for (ChargentOrders__ChargentOrder__c chargentOrder : orders) {
            chargentOrder.ChargentOrders__Payment_Method__c = 'Credit Card';
            chargentOrder.ChargentOrders__Card_Type__c = 'American Express';
            chargentOrder.ChargentOrders__Card_Number__c = '370000000000002';
        }
        if (orders.size() > 0) {
            Database.executeBatch(new GenericBatchDMLOperation(orders, 'Update'));
        }

        // We'll switch all gateways to Authorize for now since they have a test gateway.
        RecordType authorizeRT = [SELECT Id FROM RecordType WHERE DeveloperName = 'Authorizenet' LIMIT 1];
        List<ChargentBase__Gateway__c> gateways = [SELECT Id, Name FROM ChargentBase__Gateway__c];
        for (ChargentBase__Gateway__c gateway : gateways) {
            gateway.Name = 'Test ' + gateway.Name;
            gateway.ChargentBase__Test_Mode__c = true;
            gateway.RecordTypeId = authorizeRT.Id;
            gateway.ChargentBase__Merchant_ID__c = '2EBsLaEw64D';
            gateway.ChargentBase__Security_Key__c = '9QcB6Meb59K5x8WG';
        }
        if (gateways.size() > 0) {
            Database.executeBatch(new GenericBatchDMLOperation(gateways, 'Update'));
        }
    }

    global static void setupBWTestPartner() {
        Loan_Data__c capitalPool = new Loan_Data__c(Name = 'Revolving Credit Line',
        Total_Capital__c = 10000000,
        Investor__c = 'The Bank',
        Pool_Type__c = 'Revolving Credit Line');
        insert capitalPool;

        Loan_Traunch__c loanTrancheMA = new Loan_Traunch__c(
            Name = 'Avidia 1',
            Tranche_Cap__c = 1000000,
            Tranche_Type__c = 'Standard',
            State__c = 'MA',
            Stage__c = 'Open',
            Loan_Data__c = capitalPool.id);
        insert loanTrancheMA;

        Loan_Traunch__c loanTranchePending = new Loan_Traunch__c(
            Name = 'Tranche Assignment Pending',
            Tranche_Type__c = 'Holding',
            Stage__c = 'Closed',
            Loan_Data__c = capitalPool.id);
        insert loanTranchePending;

        Partner__c partner = new Partner__c(Name = 'BlueWave Test Partner');
        insert partner;

        BSST__c salesRep = new BSST__c(Name = 'Joe Bob', Partner__c = partner.Id, Custom_ID__c = 'test', Email__c = 'SalesRep@bluewavesolar.com.test');
        insert salesRep;

        BSST__c salesRepExec = new BSST__c(Name = 'Mr Executive', Partner__c = partner.Id, Custom_ID__c = 'exec', Email__c = 'executive@bluewavesolar.com.test');
        insert salesRepExec;
        String states = 'AK;AL;AR;AZ;CA;CO;CT;DE;FL;GA;HI;IA;ID;IL;IN;KS;KY;LA;MA;MD;ME;MI;MN;MO;MS;MT;NC;ND;NE;NH;NJ;NM;NV;NY;OH;OK;OR;PA;RI;SC;SD;TN;TX;UT;VA;VT;WA;WI;WV;WY';

        Account partnerAccount = new Account(Name='BlueWave Test Partner',
            Partner__c = partner.Id,
            RecordTypeId = '0120a000000uhu2',
            State_Market__c = states,
            Enable_CS_Application_in_Portal__c = true,
            Community_Solar_Application_Type__c = 'CSAP');
        insert partnerAccount;

        Contact execContact = new Contact(  FirstName='Joe',
            LastName='Bob',
            AccountId = partnerAccount.Id,
            Partner_Lookup__c = partner.Id,
            RecordTypeId = '012j0000000uetM',
            Sales_Representative__c = salesRep.Id);
        insert execContact;

        Contact salesRepContact = new Contact(  FirstName='Mr',
            LastName='Executive',
            AccountId = partnerAccount.Id,
            Partner_Lookup__c = partner.Id,
            RecordTypeId = '012j0000000uetM',
            Sales_Representative__c = salesRepExec.Id);
        insert salesRepContact;
    }

    /*
     CS Record Loader loads community solar records for testing. Currently, bill numbers aren't advanced
     because roll-up summaries aren't recalculated before the next bills are loaded, but updating the
     last bill number will allow total due to show in the customer portal. Occasionally the Energy Usage Update Handler
     hits UNABLE_TO_LOCK_ROW which we should investigate.

     To avoid governor limits, the methods below chain queueable methods, loading in this order:
     - Insert Load Zones and Tariffs
     - Insert a Product, Utility_NMC_Tariff, Entity, Utility, and Shared Solar Systems
     - Insert Gateways
     - Insert Parent Account, Contact, Property Account, Utility Account Log, Opportunity, and Utility Account Subscription
     - Insert Schedule Z and Production Updates, then updating them to generate UASBs, System Bills, and Account Bills
     - Update Account Bills to publish them
     - Insert Chargent Orders to create transactions
     */
    global class CSRecordLoader implements Queueable {
        global void execute(QueueableContext context) {
            Load_U__c everLZU = new Load_U__c(Name = '02633',
                Load_Zone__c = 'SEMA Eversource',
                LZ__c = 'SEMA',
                Utility__c = 'Eversource',
                Town__c = 'Medfield');

            Load_U__c ngridLZU = new Load_U__c(Name = '01570',
                Load_Zone__c = 'WCMA National Grid',
                LZ__c = 'WCMA',
                Utility__c = 'National Grid',
                Town__c = 'Westtown');

            insert new List<Load_U__c>{
                everLZU, ngridLZU
            };

            Utility_NMC_Tariff__c everbillNMC = new Utility_NMC_Tariff__c(
                Name = 'Eversource SEMA Class 2',
                Utility__c = 'Eversource',
                Class__c = 'Class 2',
                Value_of_Net_Metering_Credit__c = 0.1848,
                Current_Billing_Rate__c = true);

            Utility_NMC_Tariff__c ngridbillNMC = new Utility_NMC_Tariff__c(
                Name = 'National Grid WCMA Class 2 Billing Rate',
                Utility__c = 'National Grid',
                Class__c = 'Class 2',
                Value_of_Net_Metering_Credit__c = 0.1848,
                Current_Billing_Rate__c = true);

            Utility_NMC_Tariff__c ngridsizeNMC = new Utility_NMC_Tariff__c(
                Name = 'National Grid WCMA Class 2 Sizing Rate',
                Utility__c = 'National Grid',
                Class__c = 'Class 2',
                Value_of_Net_Metering_Credit__c = 0.1848,
                Sizing_Rate__c = true);

            insert new List<Utility_NMC_Tariff__c>{
                everbillNMC, ngridsizeNMC, ngridbillNMC
            };

            if (!Test.isRunningTest()) {
                System.enqueueJob(new PostSandboxRefresher.SolarSystemHelper());
            }
        }
    }

    global class SolarSystemHelper implements Queueable {
        global void execute(QueueableContext context) {
            Product2 normalCSProduct = new Product2(Name = 'BlueWave SMART',
                Family = 'Community Solar',
                Product_Type__c = 'Community Solar',
                State__c = 'MA',
                ProductCode = 'CS - BlueWave - 10%',
                IsActive = true,
                Lender_of_Record__c = 'BlueWave',
                NMC_Discount__c = 10,
                Annual_kWh_Maximum__c = 100000000,
                NM_Rate_Floor__c = 0,
                Program__c = 'SREC - Community Solar',
                Credit_Minimum__c = '200',
                Monthly_Late_Fee__c = 1);

            Product2 normalSRECProduct = new Product2(Name = 'BlueWave SREC',
                Family = 'Community Solar',
                Product_Type__c = 'Community Solar',
                State__c = 'MA',
                ProductCode = 'CS - BlueWave - 10%',
                IsActive = true,
                Lender_of_Record__c = 'BlueWave',
                NMC_Discount__c = 10,
                Annual_kWh_Maximum__c = 100000000,
                NM_Rate_Floor__c = 0,
                Program__c = 'SMART - Community Solar',
                Credit_Minimum__c = '200',
                Monthly_Late_Fee__c = 1);

            insert new List<Product2>{
                normalCSProduct,
                normalSRECProduct
            };

            Utility_NMC_Tariff__c eversizeNMC = [SELECT Id FROM Utility_NMC_Tariff__c WHERE Name = 'Eversource SEMA Class 2' LIMIT 1];
            Utility_NMC_Tariff__c nationalGridNMC = [SELECT Id FROM Utility_NMC_Tariff__c WHERE Name = 'National Grid WCMA Class 2 Billing Rate' LIMIT 1];
            Account clientAccount = new Account(Name = 'Test Client');
            insert clientAccount;

            Contact clientContact = new Contact(AccountId = clientAccount.Id, FirstName = 'Test', LastName = 'Client');
            insert clientContact;

            Entity__c entity1 = new Entity__c(Name = 'Project A Oak Road');
            insert entity1;

            Entity__c entity2 = new Entity__c(Name = 'Project B Main St');
            insert entity2;

            Utility__c eversource = new Utility__c(Name = 'Eversource', Number_of_Decimal_Places__c = 2);
            insert eversource;
            Utility__c nationalGrid = new Utility__c(Name = 'National Grid', Number_of_Decimal_Places__c = 2);
            insert nationalGrid;

            Shared_Solar_System__c sss1 = getSolarSystem('Project A Oak Road', '1', clientAccount, eversizeNMC, normalCSProduct, entity1, eversource);
            Shared_Solar_System__c sss2 = getSolarSystem('Project B Main St', '2', clientAccount, eversizeNMC, normalCSProduct, entity2, eversource);
            Shared_Solar_System__c sss3 = getSolarSystem('Project C Second St', '3', clientAccount, eversizeNMC, normalSRECProduct, entity2, eversource);
            Shared_Solar_System__c sss4 = getSolarSystem('Project D Dee St', '4', clientAccount, nationalGridNMC, normalSRECProduct, entity2, nationalGrid);
            Shared_Solar_System__c sss5 = getSolarSystem('Project E Dog St', '5', clientAccount, nationalGridNMC, normalCSProduct, entity2, nationalGrid);

            insert new List<Shared_Solar_System__c>{
                sss1, sss2, sss3, sss4, sss5
            };

            if (!Test.isRunningTest()) {
                System.enqueueJob(new PostSandboxRefresher.GatewayHelper());
            }
        }

        private Shared_Solar_System__c getSolarSystem(String name, String order, Account clientAccount,
            Utility_NMC_Tariff__c nmc, Product2 product, Entity__c entity, Utility__c utility) {
            Shared_Solar_System__c sss =
                new Shared_Solar_System__c(Name = name,
                    Service_Territory__c = 'SEMA',
                    Billing_Method__c = 'NMC',
                    Open__c = true,
                    Client_Account__c = clientAccount.Id,
                    Reserved_Capacity_kW_DC__c = '0',
                    Capacity_Committed_kW_DC__c = 0,
                    Total_System_Size_kWh_DC__c = 1445.86,
                    Total_System_Size_kW_AC__c = 996,
                    System_Utility__c = utility.Name,
                    Credit_Score_Requirement__c = 200,
                    Assignment_Order__c = order,
                    Utility_NMC_Tariff__c = nmc.Id,
                    Expected_Yield_kWh_kW__c = 1300,
                    Assemblage_Count__c = 1,
                    Product__c = product.Id,
                    Sales_Partners__c = 'All;BlueWave Test Partner',
                    Service_Territories__c = 'NEMA;SEMA;WCMA',
                    BWC_Project_Entity_Manual__c = entity.Id,
                    Maximum_Subscription_Assemblage__c = 25,
                    Utility__c = utility.Id);
            return sss;
        }
    }

    global class GatewayHelper implements Queueable {
        global void execute(QueueableContext context) {
            List<Shared_Solar_System__c> sssList = [
                SELECT Id, Name, BWC_Project_Entity_Manual__r.Id
                FROM Shared_Solar_System__c
                ORDER BY Name DESC
            ];

            RecordType authorizeRT = [SELECT Id FROM RecordType WHERE DeveloperName = 'Authorizenet' LIMIT 1];
            ChargentBase__Gateway__c chGateway =
                new ChargentBase__Gateway__c(Name = 'Chargent Gateway',
                    ChargentBase__Test_Mode__c = true,
                    RecordTypeId = authorizeRT.Id,
                    ChargentBase__Merchant_ID__c = '2EBsLaEw64D',
                    ChargentBase__Security_Key__c = '9QcB6Meb59K5x8WG',
                    ChargentBase__Available_Payment_Methods__c = 'Credit Card;eCheck',
                    ChargentBase__Default_Payment_Method_for_PC__c = 'Credit Card',
                    ChargentBase__Default_Payment_Method_for_PR__c = 'Credit Card',
                    Shared_Solar_System__c = sssList[0].Id,
                    Entity__c = sssList[0].BWC_Project_Entity_Manual__r.Id,
                    ChargentBase__Available_Payment_Methods__c = 'Credit Card;eCheck',
                    ChargentBase__Active__c = true);
            insert chGateway;

            ChargentBase__Gateway__c chGateway2 =
                new ChargentBase__Gateway__c(Name = 'Chargent Gateway B',
                    ChargentBase__Test_Mode__c = true,
                    RecordTypeId = authorizeRT.Id,
                    ChargentBase__Merchant_ID__c = '2EBsLaEw64D',
                    ChargentBase__Security_Key__c = '9QcB6Meb59K5x8WG',
                    ChargentBase__Available_Payment_Methods__c = 'Credit Card;eCheck',
                    ChargentBase__Default_Payment_Method_for_PC__c = 'eCheck',
                    ChargentBase__Default_Payment_Method_for_PR__c = 'eCheck',
                    Shared_Solar_System__c = sssList[1].Id,
                    Entity__c = sssList[1].BWC_Project_Entity_Manual__r.Id,
                    ChargentBase__Available_Payment_Methods__c = 'Credit Card;eCheck',
                    ChargentBase__Active__c = true);
            insert chGateway2;

            Entity__c entity1 = [SELECT Id FROM Entity__c WHERE Name = 'Project A Oak Road' LIMIT 1];
            entity1.Gateway__c = chGateway.Id;
            Entity__c entity2 = [SELECT Id FROM Entity__c WHERE Name = 'Project B Main St' LIMIT 1];
            entity2.Gateway__c = chGateway2.Id;
            update new List<Entity__c>{entity1, entity2};

            if (!Test.isRunningTest()) {
                System.enqueueJob(new PostSandboxRefresher.FirstAccountHelper());
            }
        }
    }

    global class FirstAccountHelper implements Queueable {
        global void execute(QueueableContext context) {
            createSubscriptions(
                0,
                new List<String>{'Ashley', 'Steven', 'Marie', 'Justin', 'Russell'},
                new List<String>{'Smith', 'Ward', 'Mitchell', 'Jenkins', 'Butler'}
            );

            if (!Test.isRunningTest()) {
                System.enqueueJob(new PostSandboxRefresher.SecondAccountHelper());
            }
        }

    }

    global class SecondAccountHelper implements Queueable {
        global void execute(QueueableContext context) {
            createSubscriptions(
                1,
                new List<String>{'Joshua', 'Donna', 'Keith', 'Mark', 'Albert'},
                new List<String>{'Phillips', 'Simmons', 'Morgan', 'Allen', 'Price'}
            );

            if (!Test.isRunningTest()) {
                System.enqueueJob(new PostSandboxRefresher.ProductionUpdateHelper());
            }
        }
    }

    global class ProductionUpdateHelper implements Queueable {
        global void execute(QueueableContext context) {
            List<Shared_Solar_System__c> sssList = [SELECT Id, Name, BWC_Project_Entity_Manual__r.Id, Product__r.Id
            FROM Shared_Solar_System__c
            ORDER BY Name DESC];

            Date today = Date.today();
            Date threeMonthsAgo = today.addMonths(-3);
            Date twoMonthsAgo = today.addMonths(-2);
            Date oneMonthAgo = today.addMonths(-1);

            Schedule_Z__c scheduleZ1 = new Schedule_Z__c(
                Name = '2016 - sssA',
                Shared_Solar_System__c = sssList[0].Id,
                Status__c = 'Enacted by Utility'
            );
            insert scheduleZ1;

            Schedule_Z__c scheduleZ2 = new Schedule_Z__c(
                Name = '2016 - sssB',
                Shared_Solar_System__c = sssList[1].Id,
                Status__c = 'Enacted by Utility'
            );
            insert scheduleZ2;

            Energy_Usage_Update__c productionupdateA1 = new Energy_Usage_Update__c (
                Name = 'sssA - August 2016',
                Shared_Solar_System__c = sssList[0].Id,
                Production__c = 81869.00,
                Due_Date__c = threeMonthsAgo,
                Billing_Period_End_Date__c = twoMonthsAgo,
                Total_System_NMCs__c = 13483.66,
                Size_off_NMCs__c = true,
                Date__c = threeMonthsAgo,
                Schedule_Z__c =  scheduleZ1.Id
            );

            insert productionupdateA1;

            Energy_Usage_Update__c productionupdateB2 = new Energy_Usage_Update__c (
                Name = 'sssA - September 2016',
                Shared_Solar_System__c = sssList[0].Id,
                Production__c = 73072.00,
                Due_Date__c = twoMonthsAgo,
                Billing_Period_End_Date__c = oneMonthAgo,
                Total_System_NMCs__c = 12033.73,
                Size_off_NMCs__c = true,
                Date__c = twoMonthsAgo,
                Schedule_Z__c =  scheduleZ1.Id
            );

            insert productionupdateB2;

            Energy_Usage_Update__c productionupdateB3 = new Energy_Usage_Update__c (
                Name = 'sssA - October 2016',
                Shared_Solar_System__c = sssList[0].Id,
                Production__c = 327001.00,
                Due_Date__c = oneMonthAgo,
                Billing_Period_End_Date__c = today,
                Total_System_NMCs__c = 36424.44,
                Size_off_NMCs__c = true,
                Date__c = oneMonthAgo,
                Schedule_Z__c =  scheduleZ1.Id
            );

            insert productionupdateB3;

            Energy_Usage_Update__c prodUpdateBB = new Energy_Usage_Update__c (
                Name = 'sssB - August 2016',
                Shared_Solar_System__c = sssList[1].Id,
                Production__c = 367918.00,
                Due_Date__c = threeMonthsAgo,
                Billing_Period_End_Date__c = twoMonthsAgo,
                Total_System_NMCs__c = 40983.43,
                Size_off_NMCs__c = true,
                Date__c = threeMonthsAgo,
                Schedule_Z__c =  scheduleZ2.Id
            );

            insert prodUpdateBB;

            Energy_Usage_Update__c prodUpdateCC = new Energy_Usage_Update__c (
                Name = 'sssB - September 2016',
                Shared_Solar_System__c = sssList[1].Id,
                Production__c = 81869.00,
                Due_Date__c = twoMonthsAgo,
                Billing_Period_End_Date__c = oneMonthAgo,
                Total_System_NMCs__c = 13483.66,
                Size_off_NMCs__c = true,
                Date__c = twoMonthsAgo,
                Schedule_Z__c =  scheduleZ2.Id
            );

            insert prodUpdateCC;

            Energy_Usage_Update__c prodUpdateDD = new Energy_Usage_Update__c (
                Name = 'sssB - October 2016',
                Shared_Solar_System__c = sssList[1].Id,
                Production__c = 73072.00,
                Due_Date__c = oneMonthAgo,
                Billing_Period_End_Date__c = today,
                Total_System_NMCs__c = 12033.73,
                Size_off_NMCs__c = true,
                Date__c = oneMonthAgo,
                Schedule_Z__c =  scheduleZ2.Id
            );

            insert prodUpdateDD;

            productionupdateA1.Generate_Bills__c = true;
            productionupdateB2.Generate_Bills__c = true;
            productionupdateB3.Generate_Bills__c = true;
            prodUpdateBB.Generate_Bills__c = true;
            prodUpdateCC.Generate_Bills__c = true;
            prodUpdateDD.Generate_Bills__c = true;
            update productionupdateA1;
            update productionupdateB2;
            update productionupdateB3;
            update prodUpdateBB;
            update prodUpdateCC;
            update prodUpdateDD;

            if (!Test.isRunningTest()) {
                System.enqueueJob(new PostSandboxRefresher.AccountBillHelper());
            }
        }
    }

    global class AccountBillHelper implements Queueable {
        global void execute(QueueableContext context) {
            List <Account_Bill__c> listaccountBills = [
                SELECT Id, Published__c
                FROM Account_Bill__c
            ];

            for (Account_Bill__c acctBill : listaccountBills) {
                acctBill.Published__c = true;
            }

            update listaccountBills;

            if (!Test.isRunningTest()) {
                System.enqueueJob(new PostSandboxRefresher.PaymentHelper());
            }
        }
    }

    global class PaymentHelper implements Queueable {
        global void execute(QueueableContext context) {
            ChargentBase__Gateway__c gatewayOne = [
                SELECT Id, Entity__r.Id
                FROM ChargentBase__Gateway__c
                WHERE Name = 'Chargent Gateway'
                LIMIT 1
            ];

            List<Account_Bill__c> accountbilllist = [
                SELECT Id, Name, Carry_Over_Balance__c,
                    Bill_Number__c, Property_Account_ID__c
                FROM Account_Bill__c
                WHERE Total_Due__c > 0
                ORDER BY Bill_Number__c DESC
                LIMIT 3
            ];

            for (Account_Bill__c accountbill : accountbilllist) {
                ChargentOrders__ChargentOrder__c orderA =
                    new ChargentOrders__ChargentOrder__c(ChargentOrders__Gateway__c = gatewayOne.Id,
                        ChargentOrders__Shipping_Name__c = gatewayOne.Entity__r.Id,
                        ChargentOrders__Billing_First_Name__c = 'Jordan',
                        ChargentOrders__Billing_Last_Name__c = 'Pentaleri',
                        ChargentOrders__Billing_Address__c = '108 Ridgeland Drive',
                        ChargentOrders__Billing_Zip_Postal__c = '02467',
                        ChargentOrders__Subtotal__c = accountbill.Carry_Over_Balance__c,
                        ChargentOrders__Payment_Method__c = 'Credit Card',
                        Account_Bill__c = accountbill.Id,
                        ChargentOrders__Card_Type__c = 'Visa',
                        ChargentOrders__Card_Number__c = '411111111111',
                        ChargentOrders__Card_Expiration_Month__c = '02',
                        ChargentOrders__Card_Expiration_Year__c = '2018',
                        ChargentOrders__Card_Last_4__c = '1111');
                insert orderA;

                ChargentOrders__Transaction__c transA =
                    new ChargentOrders__Transaction__c(ChargentOrders__Order__c = orderA.Id,
                        ChargentOrders__Amount__c = accountbill.Carry_Over_Balance__c,
                        ChargentOrders__Response_Status__c ='Approved',
                        ChargentOrders__Gateway_ID__c = gatewayOne.Id,
                        ChargentOrders__Gateway__c = gatewayOne.Id,
                        Distributed_Among_System_Bills__c = false,
                        ChargentOrders__Response_Message__c = 'OK',
                        ChargentOrders__Type__c = 'Charge',
                        ChargentOrders__Payment_Method__c = 'Credit Card',
                        Activity_Type__c = 'Payment');
                insert transA;
                transA.Distributed_Among_System_Bills__c = true;
                update transA;
            }
        }
    }

    // Helper methods used when loading CS records
    private static Contact getContact(String firstName1, String lastName1, Account accountParent1, User owner) {
        Contact contact1 = new Contact(
            FirstName = firstName1,
            LastName = lastName1,
            AccountId = accountParent1.Id,
            OwnerId = owner.Id
        );
        return contact1;
    }

    private static Account getPropertyAccount(String accountName1, Account accountParent1, Contact contact1) {
        Account propAccount1 = new Account(
            Name = accountName1,
            Parent_Account__c = accountParent1.Id,
            Send_Bills_Contact__c = contact1.Id,
            RecordTypeId = '012j00000010HeQ');
        return propAccount1;
    }

    private static Utility_Account_Log__c getUtilityAccountLog(String name, Decimal cost, Account propAccount1,
        String accountName1) {
        Utility_Account_Log__c ualog1 = new Utility_Account_Log__c(
            Name = name,
            Account__c = propAccount1.Id,
            Annual_Cost_of_Electricity__c = cost,
            Name_on_Account__c = accountName1);
        return ualog1;
    }

    private static Opportunity getOpportunity(String accountName1, Account propAccount1, Shared_Solar_System__c sss) {
        Opportunity opportunity1 = new Opportunity(
            Name = accountName1,
            AccountId = propAccount1.Id,
            Shared_Solar_System__c = sss.Id,
            StageName = 'Complete',
            Customer_Group__c = 'Residential',
            Product__c = sss.Product__r.Id,
            CloseDate = System.today(),
            RecordTypeId = '012j00000010HPE'
        );
        return opportunity1;
    }

    private static Utility_Account_Subscription__c getUtilityAccountSubscription(String name, Integer subscription,
        Utility_Account_Log__c ualog1, Opportunity opportunity1) {
        Utility_Account_Subscription__c uas1 = new Utility_Account_Subscription__c(
            Name = name,
            Utility_Account_Log__c = ualog1.Id,
            Opportunity__c = opportunity1.Id,
            Next_Schedule_Z_Status__c = 'Active Subscription',
            calculated_annual_cost_of_electricity__c = 1400,
            Subscribed_Annual_Cost_of_Electricity__c = 1400,
            Customer_Subscription_KW_DC_STATIC__c = subscription
        );
        return uas1;
    }

    private static void createSubscriptions(Integer sssIndex, List<String> firstNames, List<String> lastNames) {
        List<Shared_Solar_System__c> sssList = [
            SELECT Id, Name, BWC_Project_Entity_Manual__r.Id, Product__r.Id
            FROM Shared_Solar_System__c
            ORDER BY Name DESC
        ];
        User api = [SELECT Id FROM User WHERE Name = 'API' LIMIT 1];

        String firstName1 = firstNames[0];
        String firstName2 = firstNames[1];
        String firstName3 = firstNames[2];
        String firstName4 = firstNames[3];
        String firstName5 = firstNames[4];

        String lastName1 = lastNames[0];
        String lastName2 = lastNames[1];
        String lastName3 = lastNames[2];
        String lastName4 = lastNames[3];
        String lastName5 = lastNames[4];

        String accountName1 = firstName1 + ' ' + lastName1;
        String accountName2 = firstName2 + ' ' + lastName2;
        String accountName3 = firstName3 + ' ' + lastName3;
        String accountName4 = firstName4 + ' ' + lastName4;
        String accountName5 = firstName5 + ' ' + lastName5;

        Account accountParent1 = new Account(Name = accountName1, RecordTypeId = '012j00000010Ha3', OwnerId = api.Id);
        Account accountParent2 = new Account(Name = accountName2, RecordTypeId = '012j00000010Ha3', OwnerId = api.Id);
        Account accountParent3 = new Account(Name = accountName3, RecordTypeId = '012j00000010Ha3', OwnerId = api.Id);
        Account accountParent4 = new Account(Name = accountName4, RecordTypeId = '012j00000010Ha3', OwnerId = api.Id);
        Account accountParent5 = new Account(Name = accountName5, RecordTypeId = '012j00000010Ha3', OwnerId = api.Id);

        insert new List<Account>{
            accountParent1, accountParent2, accountParent3, accountParent4, accountParent5
        };

        Contact contact1 = getContact(firstName1, lastName1, accountParent1, api);
        Contact contact2 = getContact(firstName2, lastName2, accountParent2, api);
        Contact contact3 = getContact(firstName3, lastName3, accountParent3, api);
        Contact contact4 = getContact(firstName4, lastName4, accountParent4, api);
        Contact contact5 = getContact(firstName5, lastName5, accountParent5, api);

        insert new List<Contact>{
            contact1, contact2, contact3, contact4, contact5
        };

        Account propAccount1 = getPropertyAccount(accountName1, accountParent1, contact1);
        Account propAccount2 = getPropertyAccount(accountName2, accountParent2, contact2);
        Account propAccount3 = getPropertyAccount(accountName3, accountParent3, contact3);
        Account propAccount4 = getPropertyAccount(accountName4, accountParent4, contact4);
        Account propAccount5 = getPropertyAccount(accountName5, accountParent5, contact5);

        insert new List<Account>{
            propAccount1, propAccount2, propAccount3, propAccount4, propAccount5
        };

        Utility_Account_Log__c ualog1 = getUtilityAccountLog('0000234', 10000, propAccount1, accountName1);
        Utility_Account_Log__c ualog2 = getUtilityAccountLog('0000235', 10000, propAccount2, accountName2);
        Utility_Account_Log__c ualog3 = getUtilityAccountLog('0000236', 10000, propAccount3, accountName3);
        Utility_Account_Log__c ualog4 = getUtilityAccountLog('0000237', 10000, propAccount4, accountName4);
        Utility_Account_Log__c ualog5 = getUtilityAccountLog('0000238', 10000, propAccount5, accountName5);
        Utility_Account_Log__c ualog6 = getUtilityAccountLog('0000239', 10000, propAccount5, accountName5);

        insert new List<Utility_Account_Log__c>{
            ualog1, ualog2, ualog3, ualog4, ualog5, ualog6
        };

        Opportunity opportunity1 = getOpportunity(accountName1, propAccount1, sssList[sssIndex]);
        Opportunity opportunity2 = getOpportunity(accountName2, propAccount2, sssList[sssIndex]);
        Opportunity opportunity3 = getOpportunity(accountName3, propAccount3, sssList[sssIndex]);
        Opportunity opportunity4 = getOpportunity(accountName4, propAccount4, sssList[sssIndex]);
        Opportunity opportunity5 = getOpportunity(accountName5, propAccount5, sssList[sssIndex]);
        Opportunity opportunity6 = getOpportunity(accountName5, propAccount5, sssList[sssIndex==0?1:0]);

        insert new List<Opportunity>{
            opportunity1, opportunity2, opportunity3, opportunity4, opportunity5, opportunity6
        };

        Utility_Account_Subscription__c uas1 = getUtilityAccountSubscription('000234', 25, ualog1, opportunity1);
        Utility_Account_Subscription__c uas2 = getUtilityAccountSubscription('000234', 10, ualog2, opportunity2);
        Utility_Account_Subscription__c uas3 = getUtilityAccountSubscription('000234', 20, ualog3, opportunity3);
        Utility_Account_Subscription__c uas4 = getUtilityAccountSubscription('000234', 19, ualog4, opportunity4);
        Utility_Account_Subscription__c uas5 = getUtilityAccountSubscription('000234', 17, ualog5, opportunity5);
        Utility_Account_Subscription__c uas6 = getUtilityAccountSubscription('000235', 17, ualog6, opportunity6);

        insert new List<Utility_Account_Subscription__c>{
            uas1, uas2, uas3, uas4, uas5, uas6
        };
    }

    public static void deleteCSRecords() {
        Organization o = [SELECT IsSandbox FROM Organization LIMIT 1];

        if (o.IsSandbox || Test.isRunningTest()) {
            delete [SELECT Id FROM ChargentOrders__Transaction__c];
            delete [SELECT Id FROM ChargentOrders__ChargentOrder__c];
            delete [SELECT Id FROM Account_Bill__c];
            delete [SELECT Id FROM Utility_Account_Bill__c];
            delete [SELECT Id FROM System_Bill__c];
            delete [SELECT Id FROM UASB__c];
            delete [SELECT Id FROM Energy_Usage_Update__c];
            delete [SELECT Id FROM Schedule_Z__c];
            delete [SELECT Id FROM Schedule_Z_Subscription__c];
            delete [SELECT Id FROM Utility_Account_Subscription__c];
            delete [SELECT Id FROM Utility_Account_Log__c];
            delete [SELECT Id FROM Opportunity];
            delete [SELECT Id FROM Contact];
            delete [SELECT Id FROM Account];
            delete [SELECT Id FROM ChargentBase__Gateway__c];
            delete [SELECT Id FROM Shared_Solar_System__c];
            delete [SELECT Id FROM Utility__c];
            delete [SELECT Id FROM Entity__c];
            delete [SELECT Id FROM Utility_NMC_Tariff__c];
            delete [SELECT Id FROM Load_U__c];
            delete [SELECT Id FROM Product2 WHERE ProductCode = 'CS - BlueWave - 10%'];
        }
    }

    // With Winter '19, the LightningReportsControllerTest.testSummaryReportReponse started failing.
    // It looks as if Reports.ReportManager methods in the test doesn't see the data created in the test method,
    // just the SeeAllData=true data. So we'll create that data here.
    public static void setupDataForReportTest() {
        Account clientAccount = new Account(Name = 'Client Account');
        insert clientAccount;

        Lead lead = new Lead(FirstName='Cole',
            LastName='TestLightningReports',
            Company='Cole Swain',
            Annual_Income_Currency__c = 100000,
            Parent_Account__c = clientAccount.Id);
        insert lead;
    }
}
