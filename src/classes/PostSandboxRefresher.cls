/*
  Author: Peter Yao

  Description: 1. Changes emails in Leads and Contacts so we don't accidentally email them
                  Courtesy of http://www.soliantconsulting.com/blog/2016/03/salesforce-sandboxpostcopy-interface
               2. Deletes the Recurring Billing scheduled job

  Tested By: PostSandboxRefresherTest
               
 */
global class PostSandboxRefresher implements SandboxPostCopy {
    global static Date csDataDate = Date.newInstance(2000,1,1);
    global void runApexClass(SandboxContext context) {
        disableEmails();
        deleteScheduledJob('Recurring Billing');
        updateLetterStreamToTestConfig();
        updateDocusignToDemoConfig();
        switchChargentToTestMode();
        setupBWTestPartner();
        setupDataForReportTest();
        System.enqueueJob(new PostSandboxRefresher.CSRecordLoader(new PostSandboxRefresher.CSDataSetting(24)));
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

        partner.Default_Sales_Rep__c = salesRepExec.Id;
        System_Properties__c sysProp = System_Properties__c.getAll().values()[0];
        sysProp.Default_CS_Partner__c = partner.Id;
        update partner;
        update sysProp;

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
        global CSDataSetting csDataSetting;
        global CSRecordLoader(CSDataSetting csDataSetting) {
            this.csDataSetting = csDataSetting;
        }

        global void execute(QueueableContext context) {
            Utility_NMC_Tariff__c everbillNMC = new Utility_NMC_Tariff__c(
                Name = 'Eversource SEMA Class 2',
                Utility__c = 'Eversource',
                Class__c = 'Class 2',
                Value_of_Net_Metering_Credit__c = 0.1848,
                Current_Billing_Rate__c = true,
                CreatedDate = csDataDate
            );

            Utility_NMC_Tariff__c ngridbillNMC = new Utility_NMC_Tariff__c(
                Name = 'National Grid WCMA Class 2 Billing Rate',
                Utility__c = 'National Grid',
                Class__c = 'Class 2',
                Value_of_Net_Metering_Credit__c = 0.1848,
                Current_Billing_Rate__c = true,
                CreatedDate = csDataDate
            );

            Utility_NMC_Tariff__c ngridsizeNMC = new Utility_NMC_Tariff__c(
                Name = 'National Grid WCMA Class 2 Sizing Rate',
                Utility__c = 'National Grid',
                Class__c = 'Class 2',
                Value_of_Net_Metering_Credit__c = 0.1848,
                Sizing_Rate__c = true,
                CreatedDate = csDataDate
            );

            CS_Bill_Setting__c csBillSetting = new CS_Bill_Setting__c(
                Default_Bill_Message_for_Autopay__c = '<b>Go paperless today!</b><br>If you haven’t already, sign up for ' +
                    'paperless billing! Contact our customer support team using the contact info at the bottom of your ' +
                    'bill. Thank you for doing your part to protect the planet and create a better future for your community.',
                Default_Bill_Message_for_Non_Autopay__c = '<b>Payment Instructions</b><br>Please note our payment address ' +
                    'and payee name in the Payment Details section of your bill. You now only need to send us a single ' +
                    'check made payable to:<br><br>BCS Customer Management<br>111 Huntington Ave., Suite 650,<br>Boston, MA 02199',
                CreatedDate = csDataDate
            );
            insert csBillSetting;


            insert new List<Utility_NMC_Tariff__c>{
                everbillNMC, ngridsizeNMC, ngridbillNMC
            };

            if (!Test.isRunningTest()) {
                System.enqueueJob(new PostSandboxRefresher.SolarSystemHelper(csDataSetting));
            }
        }
    }

    global class SolarSystemHelper implements Queueable {
        global CSDataSetting csDataSetting;
        global SolarSystemHelper(CSDataSetting csDataSetting) {
            this.csDataSetting = csDataSetting;
        }

        global void execute(QueueableContext context) {
            Product2 normalCSProduct = new Product2(
                Name = 'BlueWave SMART',
                Family = 'Community Solar',
                Product_Type__c = 'Community Solar',
                Program__c = 'SMART - Community Solar',
                Customer_Subscription_Type__c = 'kWh',
                State__c = 'MA',
                ProductCode = 'CS - BlueWave - 10%',
                IsActive = true,
                Lender_of_Record__c = 'BlueWave',
                NMC_Discount__c = 10,
                Annual_kWh_Maximum__c = 100000000,
                NM_Rate_Floor__c = 0,
                Credit_Minimum__c = '200',
                Monthly_Late_Fee__c = 1,
                Cancellation_Paragraph_Two__c = '<br>Per Massachusetts utility and state regulations, project capacity ' +
                    'allocation forms can only be filed up to two times per year; therefore, it may take up to six ' +
                    'months for your subscription to stop receiving solar credits. During this time, you will remain ' +
                    'responsible for paying for all solar credits transferred to your account. Once the utility removes ' +
                    'your subscription, we will notify you via email.</br>'
            );

            Product2 normalSRECProduct = new Product2(
                Name = 'BlueWave SREC',
                Family = 'Community Solar',
                Product_Type__c = 'Community Solar',
                Program__c = 'SREC - Community Solar',
                Customer_Subscription_Type__c = 'Electricity Cost ($)',
                State__c = 'MA',
                ProductCode = 'CS - BlueWave - 10%',
                IsActive = true,
                Lender_of_Record__c = 'BlueWave',
                NMC_Discount__c = 10,
                Annual_kWh_Maximum__c = 100000000,
                NM_Rate_Floor__c = 0,
                Credit_Minimum__c = '200',
                Monthly_Late_Fee__c = 1,
                Cancellation_Paragraph_Two__c = '<br>Per Massachusetts utility and state regulations, project capacity ' +
                    'allocation forms can only be filed up to two times per year; therefore, it may take up to six ' +
                    'months for your subscription to stop receiving solar credits. During this time, you will remain ' +
                    'responsible for paying for all solar credits transferred to your account. Once the utility removes ' +
                    'your subscription, we will notify you via email.</br>',
                Cancellation_Paragraph_Three__c = '<i><br>Please note, per the terms of your contract, you may be charged ' +
                    'an early termination fee to cancel your community solar subscription, unless you provide a replacement ' +
                    'customer. Please refer to your contract for more details.</br></i>'
            );

            insert new List<Product2>{
                normalCSProduct,
                normalSRECProduct
            };


            Utility_NMC_Tariff__c eversizeNMC = [SELECT Id FROM Utility_NMC_Tariff__c WHERE Name = 'Eversource SEMA Class 2' LIMIT 1];
            Utility_NMC_Tariff__c nationalGridNMC = [SELECT Id FROM Utility_NMC_Tariff__c WHERE Name = 'National Grid WCMA Class 2 Billing Rate' LIMIT 1];
            Account clientAccount = new Account(Name = 'Test Client', CreatedDate = csDataDate);
            insert clientAccount;

            Contact clientContact = new Contact(
                AccountId = clientAccount.Id,
                FirstName = 'Test',
                LastName = 'Client',
                CreatedDate = csDataDate
            );
            insert clientContact;

            Entity__c entity1 = new Entity__c(Name = 'Project A Oak Road', CreatedDate = csDataDate);
            insert entity1;

            Entity__c entity2 = new Entity__c(Name = 'Project B Main St', CreatedDate = csDataDate);
            insert entity2;

            Utility__c eversource = new Utility__c(Name = 'Eversource', Number_of_Decimal_Places__c = 2, CreatedDate = csDataDate);
            insert eversource;
            Utility__c nationalGrid = new Utility__c(Name = 'National Grid', Number_of_Decimal_Places__c = 2, CreatedDate = csDataDate);
            insert nationalGrid;

            insertTariffsForProduct(normalCSProduct.Id, eversource.Id, nationalGrid.Id);

            Load_U__c everLZU = new Load_U__c(Name = '02633',
                Load_Zone__c = 'SEMA Eversource',
                LZ__c = 'SEMA',
                Town__c = 'Medfield',
                CreatedDate = csDataDate
            );

            Load_U__c ngridLZU = new Load_U__c(Name = '01570',
                Load_Zone__c = 'WCMA National Grid',
                LZ__c = 'WCMA',
                Town__c = 'Westtown',
                CreatedDate = csDataDate
            );

            insert new List<Load_U__c>{
                everLZU, ngridLZU
            };

            ZipCode_Utility_Junction__c junction = new ZipCode_Utility_Junction__c(
                Load_Zone_Utility__c = everLZU.Id,
                Utility__c = eversource.Id,
                CreatedDate = csDataDate
            );
            ZipCode_Utility_Junction__c junctionTwo = new ZipCode_Utility_Junction__c(
                Load_Zone_Utility__c = ngridLZU.Id,
                Utility__c = nationalGrid.Id,
                CreatedDate = csDataDate
            );
            insert new List<ZipCode_Utility_Junction__c>{junction, junctionTwo};

            Shared_Solar_System__c sss1 = getSolarSystem('Project A Oak Road', '1', clientAccount, eversizeNMC, normalCSProduct, entity1, eversource);
            Shared_Solar_System__c sss2 = getSolarSystem('Project B Main St', '2', clientAccount, eversizeNMC, normalCSProduct, entity2, eversource);
            Shared_Solar_System__c sss3 = getSolarSystem('Project C Second St', '3', clientAccount, eversizeNMC, normalSRECProduct, entity2, eversource);
            Shared_Solar_System__c sss4 = getSolarSystem('Project D Dee St', '4', clientAccount, nationalGridNMC, normalSRECProduct, entity2, nationalGrid);
            Shared_Solar_System__c sss5 = getSolarSystem('Project E Dog St', '5', clientAccount, nationalGridNMC, normalCSProduct, entity2, nationalGrid);

            insert new List<Shared_Solar_System__c>{
                sss1, sss2, sss3, sss4, sss5
            };

            if (!Test.isRunningTest()) {
                System.enqueueJob(new PostSandboxRefresher.GatewayHelper(csDataSetting));
            }
        }

        public void insertTariffsForProduct(Id productId, Id eversourceId, Id nationalGridId) {
            Utility_NMC_Tariff__c eversourceG1 =  new Utility_NMC_Tariff__c(
                Value_of_Net_Metering_Credit__c = .70578,
                Name = 'Eversource G1',
                Utility_Relationship__c = eversourceId,
                Customer_Type__c = 'Non-Residential',
                Maximum_kWh__c = 10000,
                Date__c = Date.today(),
                CreatedDate = csDataDate
            );
            Utility_NMC_Tariff__c eversourceG2 =  new Utility_NMC_Tariff__c(
                Value_of_Net_Metering_Credit__c = .70578,
                Name = 'Eversource G2',
                Utility_Relationship__c = eversourceId,
                Customer_Type__c = 'Non-Residential',
                Minimum_kWh__c = 10000,
                Date__c = Date.today(),
                CreatedDate = csDataDate
            );
            Utility_NMC_Tariff__c eversourceR1 =  new Utility_NMC_Tariff__c(
                Value_of_Net_Metering_Credit__c = .70578,
                Name = 'Eversource R1',
                Utility_Relationship__c = eversourceId,
                Customer_Type__c = 'Residential',
                Date__c = Date.today(),
                CreatedDate = csDataDate
            );
            Utility_NMC_Tariff__c nationalGridG1 =  new Utility_NMC_Tariff__c(
                Value_of_Net_Metering_Credit__c = .70578,
                Name = 'National Grid G1',
                Utility_Relationship__c = nationalGridId,
                Customer_Type__c = 'Non-Residential',
                Maximum_kWh__c = 10000,
                Date__c = Date.today(),
                CreatedDate = csDataDate
            );
            Utility_NMC_Tariff__c nationalGridG2 =  new Utility_NMC_Tariff__c(
                Value_of_Net_Metering_Credit__c = .70578,
                Name = 'National Grid G2',
                Utility_Relationship__c = nationalGridId,
                Customer_Type__c = 'Non-Residential',
                Minimum_kWh__c = 10000,
                Date__c = Date.today(),
                CreatedDate = csDataDate
            );
            Utility_NMC_Tariff__c nationalGridR1 =  new Utility_NMC_Tariff__c(
                Value_of_Net_Metering_Credit__c = .70578,
                Name = 'National Grid R1',
                Utility_Relationship__c = nationalGridId,
                Customer_Type__c = 'Residential',
                Date__c = Date.today(),
                CreatedDate = csDataDate
            );

            insert new List<Utility_NMC_Tariff__c>{
                eversourceG1, eversourceG2, eversourceR1, nationalGridG1, nationalGridG2, nationalGridR1
            };

            Product_Tariff__c smartER1 = new Product_Tariff__c(
                Product__c = productId,
                Utility_NMC_Tariff__c = eversourceR1.Id,
                Size_Ratio__c = 1.5,
                CreatedDate = csDataDate
            );
            Product_Tariff__c smartEG1 = new Product_Tariff__c(
                Product__c = productId,
                Utility_NMC_Tariff__c = eversourceG1.Id,
                Size_Ratio__c = 1.4,
                CreatedDate = csDataDate
            );
            Product_Tariff__c smartEG2 = new Product_Tariff__c(
                Product__c = productId,
                Utility_NMC_Tariff__c = eversourceG2.Id,
                Size_Ratio__c = 1.3,
                CreatedDate = csDataDate
            );
            Product_Tariff__c smartNGR1 = new Product_Tariff__c(
                Product__c = productId,
                Utility_NMC_Tariff__c = nationalGridR1.Id,
                Size_Ratio__c = 1.35,
                CreatedDate = csDataDate
            );
            Product_Tariff__c smartNGG1 = new Product_Tariff__c(
                Product__c = productId,
                Utility_NMC_Tariff__c = nationalGridG1.Id,
                Size_Ratio__c = 1.45,
                CreatedDate = csDataDate
            );
            Product_Tariff__c smartNGG2 = new Product_Tariff__c(
                Product__c = productId,
                Utility_NMC_Tariff__c = nationalGridG2.Id,
                Size_Ratio__c = 1.55,
                CreatedDate = csDataDate
            );

            insert new List<Product_Tariff__c>{
                smartER1, smartEG1, smartEG2, smartNGR1, smartNGG1, smartNGG2
            };
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
                    Utility__c = utility.Id,
                    CreatedDate = csDataDate
                );
            return sss;
        }
    }

    global class GatewayHelper implements Queueable {
        global CSDataSetting csDataSetting;
        global GatewayHelper(CSDataSetting csDataSetting) {
            this.csDataSetting = csDataSetting;
        }

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
                    ChargentBase__Default_Payment_Method_for_PC__c = 'Credit Card',
                    ChargentBase__Default_Payment_Method_for_PR__c = 'Credit Card',
                    Shared_Solar_System__c = sssList[0].Id,
                    Entity__c = sssList[0].BWC_Project_Entity_Manual__r.Id,
                    ChargentBase__Available_Payment_Methods__c = 'Credit Card;eCheck',
                    ChargentBase__Active__c = true,
                    CreatedDate = csDataDate
                );
            insert chGateway;

            ChargentBase__Gateway__c chGateway2 =
                new ChargentBase__Gateway__c(Name = 'Chargent Gateway B',
                    ChargentBase__Test_Mode__c = true,
                    RecordTypeId = authorizeRT.Id,
                    ChargentBase__Merchant_ID__c = '2EBsLaEw64D',
                    ChargentBase__Security_Key__c = '9QcB6Meb59K5x8WG',
                    ChargentBase__Default_Payment_Method_for_PC__c = 'eCheck',
                    ChargentBase__Default_Payment_Method_for_PR__c = 'eCheck',
                    Shared_Solar_System__c = sssList[1].Id,
                    Entity__c = sssList[1].BWC_Project_Entity_Manual__r.Id,
                    ChargentBase__Available_Payment_Methods__c = 'Credit Card;eCheck',
                    ChargentBase__Active__c = true,
                    CreatedDate = csDataDate
                );
            insert chGateway2;

            Entity__c defaultEntity = new Entity__c(
                Name = 'BWC Holdings, LLC',
                Gateway__c = chGateway.Id,
                CreatedDate = csDataDate
            );

            insert defaultEntity;

            Entity__c entity1 = [SELECT Id FROM Entity__c WHERE Name = 'Project A Oak Road' LIMIT 1];
            entity1.Gateway__c = chGateway.Id;
            Entity__c entity2 = [SELECT Id FROM Entity__c WHERE Name = 'Project B Main St' LIMIT 1];
            entity2.Gateway__c = chGateway2.Id;
            update new List<Entity__c>{entity1, entity2};

            if (!Test.isRunningTest()) {
                System.enqueueJob(new PostSandboxRefresher.FirstAccountHelper(csDataSetting));
            }
        }
    }

    global class FirstAccountHelper implements Queueable {
        global CSDataSetting csDataSetting;
        global FirstAccountHelper(CSDataSetting csDataSetting) {
            this.csDataSetting = csDataSetting;
        }

        global void execute(QueueableContext context) {
            Util.disableAllTriggers();
            // Can't do more than 12 because the Update SSS On Opportunity Complete PB fails with
            // "DUPLICATE_VALUE: Maximum number of duplicate updates in one batch (12 allowed)"
            Integer batchNumber = csDataSetting.numberOfAccountBatches;
            List<PostSandboxRefresher.Name> names = new List<PostSandboxRefresher.Name>();
            names.add(new Name('Ashley', 'Smith', batchNumber));
            names.add(new Name('Steven', 'Ward', batchNumber));
            names.add(new Name('Marie', 'Mitchell', batchNumber));
            names.add(new Name('Justin', 'Jenkins', batchNumber));
            names.add(new Name('Russell', 'Butler', batchNumber));
            names.add(new Name('Cobie', 'Croft', batchNumber));
            names.add(new Name('Ridwan', 'Conner', batchNumber));
            names.add(new Name('Margaux', 'Maldonado', batchNumber));
            names.add(new Name('Conor', 'Schmitt', batchNumber));
            names.add(new Name('Akbar', 'Boyce', batchNumber));
            names.add(new Name('Viaan', 'Faulkner', batchNumber));
            names.add(new Name('Ritchie', 'Ho', batchNumber));
            createSubscriptions(0, names);
            if (!Test.isRunningTest()) {
                System.enqueueJob(new PostSandboxRefresher.SecondAccountHelper(csDataSetting));
            }
        }

    }

    global class SecondAccountHelper implements Queueable {
        global CSDataSetting csDataSetting;
        global SecondAccountHelper(CSDataSetting csDataSetting) {
            this.csDataSetting = csDataSetting;
        }

        global void execute(QueueableContext context) {
            Integer batchNumber = csDataSetting.numberOfAccountBatches;
            List<PostSandboxRefresher.Name> names = new List<PostSandboxRefresher.Name>();
            names.add(new Name('Joshua', 'Phillips', batchNumber));
            names.add(new Name('Donna', 'Simmons', batchNumber));
            names.add(new Name('Keith', 'Morgan', batchNumber));
            names.add(new Name('Mark', 'Allen', batchNumber));
            names.add(new Name('Albert', 'Price', batchNumber));
            names.add(new Name('Naveed', 'Ventura', batchNumber));
            names.add(new Name('Woody', 'Walsh', batchNumber));
            names.add(new Name('Nafisa', 'Wong', batchNumber));
            names.add(new Name('Ritik', 'Mann', batchNumber));
            names.add(new Name('Clement', 'Aguirre', batchNumber));
            names.add(new Name('Mollie', 'Hassan', batchNumber));
            names.add(new Name('Harrison', 'Harris', batchNumber));
            createSubscriptions(1, names);

            if (!Test.isRunningTest()) {
                if (batchNumber > 1) {
                    csDataSetting.numberOfAccountBatches--;
                    System.enqueueJob(new PostSandboxRefresher.FirstAccountHelper(csDataSetting));
                } else {
                    Util.enableAllTriggers();
                    System.enqueueJob(new PostSandboxRefresher.ProductionUpdateHelper(csDataSetting));
                }
            }
        }
    }

    global class ProductionUpdateHelper implements Queueable {
        global CSDataSetting csDataSetting;
        global ProductionUpdateHelper(CSDataSetting csDataSetting) {
            this.csDataSetting = csDataSetting;
        }

        global void execute(QueueableContext context) {
            List<Shared_Solar_System__c> sssList = [
                SELECT Id, Name, BWC_Project_Entity_Manual__r.Id, Product__r.Id
                FROM Shared_Solar_System__c
                WHERE BWC_Project_Entity_Manual__r.Id != NULL
                ORDER BY Name DESC
            ];

            Date today = Date.today();
            Date threeMonthsAgo = today.addMonths(-3);
            Date twoMonthsAgo = today.addMonths(-2);
            Date oneMonthAgo = today.addMonths(-1);

            Schedule_Z__c scheduleZ1 = new Schedule_Z__c(
                Name = '2016 - sssA',
                Shared_Solar_System__c = sssList[0].Id,
                Status__c = 'Billing',
                Date_Enacted_by_Utility__c = Date.today()-90,
                CreatedDate = csDataDate
            );
            insert scheduleZ1;

            Schedule_Z__c scheduleZ2 = new Schedule_Z__c(
                Name = '2016 - sssB',
                Shared_Solar_System__c = sssList[1].Id,
                Status__c = 'Billing',
                Date_Enacted_by_Utility__c = Date.today()-90,
                CreatedDate = csDataDate
            );
            insert scheduleZ2;

            Energy_Usage_Update__c productionupdateA1 = new Energy_Usage_Update__c (
                Name = 'sssA - August 2016',
                Shared_Solar_System__c = sssList[0].Id,
                Production__c = 81869.00,
                Due_Date__c = threeMonthsAgo,
                Billing_Period_End_Date__c = twoMonthsAgo,
                Total_System_NMCs__c = 13483.66,
                Date__c = threeMonthsAgo,
                Schedule_Z__c =  scheduleZ1.Id,
                CreatedDate = csDataDate
            );

            insert productionupdateA1;

            Energy_Usage_Update__c prodUpdateBB = new Energy_Usage_Update__c (
                Name = 'sssB - August 2016',
                Shared_Solar_System__c = sssList[1].Id,
                Production__c = 367918.00,
                Due_Date__c = threeMonthsAgo,
                Billing_Period_End_Date__c = twoMonthsAgo,
                Total_System_NMCs__c = 40983.43,
                Date__c = threeMonthsAgo,
                Schedule_Z__c =  scheduleZ2.Id,
                CreatedDate = csDataDate
            );

            insert prodUpdateBB;

            List<Energy_Usage_Update__c> trigProdUp;
            trigProdUp = ProductionUpdateSelector.getAllProductionUpdatesById(new List<Id>{productionupdateA1.Id, prodUpdateBB.Id});
            EnergyUsageUpdateTriggerHandler ee = new EnergyUsageUpdateTriggerHandler(trigProdUp);
            // We want to skip running in a batch, so that we can set the Account Bills to published before starting
            // the next round of bills (so that the bill number is updated appropriately)
            ee.createBills(ScheduleZSubscriptionSelector.getListForBilling(ee.scheduleZs));
            ee.finish(null);
            setBillsToPublished();

            if (!Test.isRunningTest()) {
                System.enqueueJob(new PostSandboxRefresher.ProductionUpdateHelper2(csDataSetting));
            }
        }
    }

    global class ProductionUpdateHelper2 implements Queueable {
        global CSDataSetting csDataSetting;
        global ProductionUpdateHelper2(CSDataSetting csDataSetting) {
            this.csDataSetting = csDataSetting;
        }

        global void execute(QueueableContext context) {
            List<Shared_Solar_System__c> sssList = [
                SELECT Id, Name, BWC_Project_Entity_Manual__r.Id, Product__r.Id
                FROM Shared_Solar_System__c
                WHERE BWC_Project_Entity_Manual__r.Id != NULL
                ORDER BY Name DESC
            ];

            Date today = Date.today();
            Date threeMonthsAgo = today.addMonths(-3);
            Date twoMonthsAgo = today.addMonths(-2);
            Date oneMonthAgo = today.addMonths(-1);

            Schedule_Z__c scheduleZ1 = [SELECT Id FROM Schedule_Z__c WHERE Name = '2016 - sssA'];
            Schedule_Z__c scheduleZ2 = [SELECT Id FROM Schedule_Z__c WHERE Name = '2016 - sssB'];

            Energy_Usage_Update__c productionupdateB2 = new Energy_Usage_Update__c (
                Name = 'sssA - September 2016',
                Shared_Solar_System__c = sssList[0].Id,
                Production__c = 73072.00,
                Due_Date__c = twoMonthsAgo,
                Billing_Period_End_Date__c = oneMonthAgo,
                Total_System_NMCs__c = 12033.73,
                Date__c = twoMonthsAgo,
                Schedule_Z__c =  scheduleZ1.Id,
                CreatedDate = csDataDate
            );

            insert productionupdateB2;

            Energy_Usage_Update__c prodUpdateCC = new Energy_Usage_Update__c (
                Name = 'sssB - September 2016',
                Shared_Solar_System__c = sssList[1].Id,
                Production__c = 81869.00,
                Due_Date__c = twoMonthsAgo,
                Billing_Period_End_Date__c = oneMonthAgo,
                Total_System_NMCs__c = 13483.66,
                Date__c = twoMonthsAgo,
                Schedule_Z__c =  scheduleZ2.Id,
                CreatedDate = csDataDate
            );

            insert prodUpdateCC;

            List<Energy_Usage_Update__c> trigProdUp;
            trigProdUp = ProductionUpdateSelector.getAllProductionUpdatesById(new List<Id>{productionupdateB2.Id, prodUpdateCC.Id});
            EnergyUsageUpdateTriggerHandler ee = new EnergyUsageUpdateTriggerHandler(trigProdUp);
            ee.createBills(ScheduleZSubscriptionSelector.getListForBilling(ee.scheduleZs));
            ee.finish(null);
            setBillsToPublished();

            if (!Test.isRunningTest()) {
                System.enqueueJob(new PostSandboxRefresher.ProductionUpdateHelper3(csDataSetting));
            }
        }
    }

    global class ProductionUpdateHelper3 implements Queueable {
        global CSDataSetting csDataSetting;
        global ProductionUpdateHelper3(CSDataSetting csDataSetting) {
            this.csDataSetting = csDataSetting;
        }

        global void execute(QueueableContext context) {
            List<Shared_Solar_System__c> sssList = [
                SELECT Id, Name, BWC_Project_Entity_Manual__r.Id, Product__r.Id
                FROM Shared_Solar_System__c
                WHERE BWC_Project_Entity_Manual__r.Id != NULL
                ORDER BY Name DESC
            ];

            Date today = Date.today();
            Date threeMonthsAgo = today.addMonths(-3);
            Date twoMonthsAgo = today.addMonths(-2);
            Date oneMonthAgo = today.addMonths(-1);

            Schedule_Z__c scheduleZ1 = [SELECT Id FROM Schedule_Z__c WHERE Name = '2016 - sssA'];
            Schedule_Z__c scheduleZ2 = [SELECT Id FROM Schedule_Z__c WHERE Name = '2016 - sssB'];

            Energy_Usage_Update__c productionupdateB3 = new Energy_Usage_Update__c (
                Name = 'sssA - October 2016',
                Shared_Solar_System__c = sssList[0].Id,
                Production__c = 327001.00,
                Due_Date__c = oneMonthAgo,
                Billing_Period_End_Date__c = today,
                Total_System_NMCs__c = 36424.44,
                Date__c = oneMonthAgo,
                Schedule_Z__c =  scheduleZ1.Id,
                CreatedDate = csDataDate
            );

            insert productionupdateB3;

            Energy_Usage_Update__c prodUpdateDD = new Energy_Usage_Update__c (
                Name = 'sssB - October 2016',
                Shared_Solar_System__c = sssList[1].Id,
                Production__c = 73072.00,
                Due_Date__c = oneMonthAgo,
                Billing_Period_End_Date__c = today,
                Total_System_NMCs__c = 12033.73,
                Date__c = oneMonthAgo,
                Schedule_Z__c =  scheduleZ2.Id,
                CreatedDate = csDataDate
            );

            insert prodUpdateDD;

            List<Energy_Usage_Update__c> trigProdUp;
            trigProdUp = ProductionUpdateSelector.getAllProductionUpdatesById(new List<Id>{productionupdateB3.Id, prodUpdateDD.Id});
            EnergyUsageUpdateTriggerHandler ee = new EnergyUsageUpdateTriggerHandler(trigProdUp);
            ee.createBills(ScheduleZSubscriptionSelector.getListForBilling(ee.scheduleZs));
            ee.finish(null);
            setBillsToPublished();

            if (!Test.isRunningTest()) {
                System.enqueueJob(new PostSandboxRefresher.PaymentHelper(csDataSetting));
            }
        }
    }

    global class PaymentHelper implements Queueable {
        global CSDataSetting csDataSetting;
        global PaymentHelper(CSDataSetting csDataSetting) {
            this.csDataSetting = csDataSetting;
        }

        global void execute(QueueableContext context) {
            ChargentBase__Gateway__c gatewayOne = [
                SELECT Id, Entity__r.Id
                FROM ChargentBase__Gateway__c
                WHERE Name = 'Chargent Gateway'
                LIMIT 1
            ];

            List<Account_Bill__c> accountbilllist = [
                SELECT Id, Name, Carry_Over_Balance__c, Bill_Number__c, Property_Account_ID__c, (
                    SELECT Id, Shared_Solar_System__r.BWC_Project_Entity_Manual__c FROM System_Bills__r LIMIT 1
                )
                FROM Account_Bill__c
                WHERE Total_Due__c > 0
                ORDER BY Date__c DESC
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
                        ChargentOrders__Card_Last_4__c = '1111',
                        Entity__c = accountbill.System_Bills__r[0].Shared_Solar_System__r.BWC_Project_Entity_Manual__c,
                        CreatedDate = csDataDate
                    );
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
                        Activity_Type__c = 'Payment',
                        CreatedDate = csDataDate);
                insert transA;
                transA.Distributed_Among_System_Bills__c = true;
                update transA;
            }
        }
    }

    global class CSDataSetting {
        public Integer numberOfAccountBatches;
        public CSDataSetting(Integer numberOfAccounts) {
            this.numberOfAccountBatches = (Integer) Math.rint(numberOfAccounts/24);
        }
    }

    public class Name {
        public String firstName;
        public String lastName;
        public Name(String firstName, String lastName, Integer batchNumber) {
            this.firstName = firstName;
            this.lastName = lastName + (batchNumber>1?' ' + batchNumber:'');
        }
        public String getFullName() {
            return firstName + ' ' + lastName;
        }
    }

    // gets random number between min and max inclusive
    private static Integer getRandom(Integer min, Integer max) {
        Double d = Math.random(); // between 0 and 1
        d = d * (max - min + 1); // scale between 0 and (max-min)
        d = d + min; // shift up to min
        return (Integer) Math.floor(d);
    }

    // Helper methods used when loading CS records
    private static Contact getContact(String firstName1, String lastName1, Account accountParent1, User owner) {
        Contact contact1 = new Contact(
            FirstName = firstName1,
            LastName = lastName1,
            AccountId = accountParent1.Id,
            OwnerId = owner.Id,
            CreatedDate = csDataDate
        );
        return contact1;
    }

    private static Account getPropertyAccount(String accountName1, Account accountParent1, Contact contact1) {
        Account propAccount1 = new Account(
            Name = accountName1,
            Parent_Account__c = accountParent1.Id,
            Send_Bills_Contact__c = contact1.Id,
            RecordTypeId = '012j00000010HeQ',
            BillingStreet = '1 Main',
            BillingCity = 'Boston',
            BillingPostalCode = '12312',
            BillingState = 'Massachusetts',
            CreatedDate = csDataDate
        );
        return propAccount1;
    }

    private static Utility_Account_Log__c getUtilityAccountLog(String name, Decimal cost, Account propAccount1,
        String accountName1) {
        Utility_Account_Log__c ualog1 = new Utility_Account_Log__c(
            Name = name,
            Account__c = propAccount1.Id,
            Annual_Cost_of_Electricity__c = cost,
            Name_on_Account__c = accountName1,
            CreatedDate = csDataDate
        );
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
            RecordTypeId = '012j00000010HPE',
            Product_Line__c = 'Community Solar',
            CreatedDate = csDataDate
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
            Customer_Subscription_KW_DC_STATIC__c = subscription,
            CreatedDate = csDataDate
        );
        return uas1;
    }

    private static void createSubscriptions(Integer sssIndex, List<PostSandboxRefresher.Name> names) {
        List<Shared_Solar_System__c> sssList = [
            SELECT Id, Name, BWC_Project_Entity_Manual__r.Id, Product__r.Id
            FROM Shared_Solar_System__c
            ORDER BY Name DESC
        ];
        User api = [SELECT Id FROM User WHERE Name = 'API' LIMIT 1];

        List<Account> parentAccounts = new List<Account>();
        for (Integer i = 0; i < names.size(); i++) {
            parentAccounts.add(new Account(
                Name = names[i].getFullName(),
                RecordTypeId = '012j00000010Ha3',
                OwnerId = api.Id,
                CreatedDate = csDataDate
            ));
        }
        insert parentAccounts;

        List<Contact> contacts = new List<Contact>();
        for (Integer i = 0; i < names.size(); i++) {
            contacts.add(getContact(names[i].firstName, names[i].lastName, parentAccounts[i], api));
        }
        insert contacts;

        List<Account> propertyAccounts = new List<Account>();
        for (Integer i = 0; i < names.size(); i++) {
            propertyAccounts.add(getPropertyAccount(names[i].getFullName(), parentAccounts[i], contacts[i]));
        }
        insert propertyAccounts;

        List<Utility_Account_Log__c> uals = new List<Utility_Account_Log__c>();
        for (Integer i = 0; i < names.size(); i++) {
            if (i == 0) {
                uals.add(getUtilityAccountLog('0000234', 10000, propertyAccounts[i], names[i].getFullName()));
                uals.add(getUtilityAccountLog('0000235', 10000, propertyAccounts[i], names[i].getFullName()));
            } else {
                uals.add(getUtilityAccountLog('0000234' + i, 10000, propertyAccounts[i], names[i].getFullName()));
            }
        }
        insert uals;

        List<Opportunity> opportunities = new List<Opportunity>();
        for (Integer i = 0; i < names.size(); i++) {
            if (i == names.size() - 1) {
                opportunities.add(getOpportunity(names[i].getFullName(), propertyAccounts[i], sssList[sssIndex]));
                opportunities.add(getOpportunity(names[i].getFullName(), propertyAccounts[i], sssList[sssIndex==0?1:0]));
            } else {
                opportunities.add(getOpportunity(names[i].getFullName(), propertyAccounts[i], sssList[sssIndex]));
            }
        }
        insert opportunities;

        List<Utility_Account_Subscription__c> subscriptions = new List<Utility_Account_Subscription__c>();
        for (Integer i = 0; i < names.size(); i++) {
            if (i == names.size() - 1) {
                subscriptions.add(getUtilityAccountSubscription('000234' + i, getRandom(10, 20), uals[i], opportunities[i]));
                subscriptions.add(getUtilityAccountSubscription('000234' + i, getRandom(10, 20), uals[i+1], opportunities[i+1]));
            } else {
                subscriptions.add(getUtilityAccountSubscription('000234' + i, getRandom(10, 20), uals[i], opportunities[i]));
            }
        }
        insert subscriptions;
    }

    public static void setBillsToPublished() {
        List <Account_Bill__c> listAccountBills = [
            SELECT Id, Published__c
            FROM Account_Bill__c
            WHERE Published__c = FALSE
        ];
        for (Account_Bill__c acctBill : listAccountBills) {
            acctBill.Published__c = true;
        }
        update listAccountBills;
    }

    public static void deleteCSRecords() {
        Organization o = [SELECT IsSandbox FROM Organization LIMIT 1];

        if (o.IsSandbox || Test.isRunningTest()) {
            Util.disableAllTriggers();
            delete [SELECT Id FROM CS_Bill_Setting__c];
            delete [SELECT Id FROM ChargentOrders__Transaction__c];
            delete [SELECT Id FROM ChargentOrders__ChargentOrder__c];
            delete [SELECT Id FROM Utility_Account_Bill__c];
            delete [SELECT Id FROM Account_Bill__c];
            delete [SELECT Id FROM System_Bill__c];
            delete [SELECT Id FROM UASB__c];
            delete [SELECT Id FROM Energy_Usage_Update__c];
            delete [SELECT Id FROM Schedule_Z__c];
            delete [SELECT Id FROM Schedule_Z_Subscription__c];
            delete [SELECT Id FROM Utility_Account_Subscription__c];
            delete [SELECT Id FROM Utility_Account_Log__c];
            delete [SELECT Id FROM Opportunity];
            delete [SELECT Id FROM Case];
            delete [SELECT Id FROM Contact];
            delete [SELECT Id FROM Account];
            delete [SELECT Id FROM ChargentBase__Gateway__c];
            delete [SELECT Id FROM Shared_Solar_System__c];
            delete [SELECT Id FROM Utility__c];
            delete [SELECT Id FROM Entity__c];
            delete [SELECT Id FROM Utility_NMC_Tariff__c];
            delete [SELECT Id FROM Load_U__c];
            delete [SELECT Id FROM Product2 WHERE ProductCode = 'CS - BlueWave - 10%'];
            Util.enableAllTriggers();
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