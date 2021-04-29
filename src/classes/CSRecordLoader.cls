/**
     @description CSRecordLoader loads community solar records for testing. Currently, bill numbers aren't advanced
     because roll-up summaries aren't recalculated before the next bills are loaded, but updating the
     last bill number will allow total due to show in the customer portal. Occasionally the Energy Usage Update Handler
     hits UNABLE_TO_LOCK_ROW which we should investigate.
     To avoid governor limits, the methods below chain queueable methods, loading in this order:
     - Insert Load Zones and Tariffs
     - Insert a Product, Utility_NMC_Tariff, Entity, Utility, and Shared Solar Systems
     - Insert Gateways
     - Insert Parent Account, Contact, Property Account, Utility Account Log, Opportunity, and Utility Account Subscription
     - Insert Schedule Z, Bill Periods, Productions, and Transfers - then call EEUTH them to generate UASBs, System Bills, and Account Bills
     - Update Account Bills to publish them
     Tested By: PostSandboxRefresherTest
 */
@SuppressWarnings('PMD.ApexCRUDViolation')
public without sharing class CSRecordLoader extends Promise {
    @TestVisible private static Date csDataDate = Date.newInstance(2000,1,1);
    private CSDataSetting csDataSetting;

    public static void loadCSData() {
        CSDataSetting csDataSetting = new CSDataSetting(24);
        CSRecordLoader recordLoader = new CSRecordLoader(csDataSetting);
        recordLoader.then(new SolarSystemHelper(csDataSetting))
            .then(new GatewayHelper(csDataSetting))
            .then(new FirstAccountHelper(csDataSetting))
            .then(new SecondAccountHelper(csDataSetting))
            .then(new TransferHelper(csDataSetting));
        System.enqueueJob(recordLoader);
    }
    @TestVisible private CSRecordLoader(CSDataSetting csDataSetting) {
        this.csDataSetting = csDataSetting;
    }

    public override void execute() {
        Utility_NMC_Tariff__c everbillNMC = new Utility_NMC_Tariff__c(
            Name = 'Eversource SEMA Class 2',
            Utility__c = 'Eversource',
            Class__c = 'Class 2',
            Value_of_Net_Metering_Credit__c = 0.1848,
            Current_Billing_Rate__c = true,
            Size_Ratio__c = 1,
            CreatedDate = csDataDate
        );
        Utility_NMC_Tariff__c ngridbillNMC = new Utility_NMC_Tariff__c(
            Name = 'National Grid WCMA Class 2 Billing Rate',
            Utility__c = 'National Grid',
            Class__c = 'Class 2',
            Value_of_Net_Metering_Credit__c = 0.1848,
            Current_Billing_Rate__c = true,
            Size_Ratio__c = 1,
            CreatedDate = csDataDate
        );
        Utility_NMC_Tariff__c ngridsizeNMC = new Utility_NMC_Tariff__c(
            Name = 'National Grid WCMA Class 2 Sizing Rate',
            Utility__c = 'National Grid',
            Class__c = 'Class 2',
            Value_of_Net_Metering_Credit__c = 0.1848,
            Sizing_Rate__c = true,
            Size_Ratio__c = 1,
            CreatedDate = csDataDate
        );
        insert new List<Utility_NMC_Tariff__c>{
            everbillNMC, ngridsizeNMC, ngridbillNMC
        };
        List<CS_Bill_Setting__c> billSettings = [SELECT Id FROM CS_Bill_Setting__c];
        if (billSettings.isEmpty()) {
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
        }

        List<Custom_File_Upload_Share__c> fileUploadShares = [SELECT Id FROM Custom_File_Upload_Share__c];
        if (fileUploadShares.isEmpty()) {
            insert new Custom_File_Upload_Share__c(Name = 'Apply Site');
        }
    }

    @TestVisible private without sharing class SolarSystemHelper extends Promise {
        private CSDataSetting csDataSetting;
        @TestVisible private SolarSystemHelper(CSDataSetting csDataSetting) {
            this.csDataSetting = csDataSetting;
        }
        public override void execute() {
            Product2 normalCSProduct = [SELECT Id FROM Product2 WHERE ProductCode = 'CS-MA-7' LIMIT 1];
            Product2 normalSRECProduct = [SELECT Id FROM Product2 WHERE ProductCode = 'CS-MA-8' LIMIT 1];

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
            Entity__c entity1 = new Entity__c(
                Name = 'Project A Oak Road',
                CreatedDate = csDataDate,
                Client_Account__c = clientAccount.Id);
            insert entity1;
            Entity__c entity2 = new Entity__c(
                Name = 'Project B Main St',
                Client_Account__c = clientAccount.Id,
                CreatedDate = csDataDate);
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
            Shared_Solar_System__c sss5 = getSolarSystem('Project E UCB', '5', clientAccount, nationalGridNMC, normalCSProduct, entity2, nationalGrid);
            sss5.UCB__c = true;
            List<Shared_Solar_System__c> sharedSolarSystems = new List<Shared_Solar_System__c>{sss1, sss2, sss3, sss4, sss5};
            insert sharedSolarSystems;
            Default_Utility_Fee__c ucbAdminFee = new Default_Utility_Fee__c(
                Utility__c = nationalGrid.Id,
                Description__c = 'UCB Admin Fee',
                Type__c = 'UCB',
                Method_for_UCB_Utility_Admin__c = 'Calculated Credits',
                Start_Date__c = Date.today().addMonths(-1),
                End_Date__c = Date.today().addYears(1),
                Utility_Admin_Fee__c = .1
            );
            insert ucbAdminFee;
            List<Account> partners = [SELECT Id, Name, Partner__c FROM Account WHERE RecordType.Name = 'Partner Account'];
            fflib_SObjectUnitOfWork uow = new fflib_SObjectUnitOfWork(
                new List<SObjectType>{
                    Commission_Structure__c.SObjectType,
                    Partner_Shared_Solar_System_Eligibility__c.SObjectType
                }
            );
            for (Shared_Solar_System__c sss : sharedSolarSystems) {
                for (Account partner : partners) {
                    Commission_Structure__c commissionStructure = new Commission_Structure__c(
                        Name = partner.Name + ' $.06 / $.02',
                        Cents_kW_DC_Up_Front__c = .06,
                        Cents_kW_DC_First_Bill__c = 0,
                        Cents_kW_DC_First_Bill_Paid__c = .02,
                        Partner__c = partner.Partner__c,
                        Partner_Account__c = partner.Id,
                        Product__c = sss.Product__c,
                        CreatedDate = csDataDate
                    );
                    uow.registerNew(commissionStructure);
                    Partner_Shared_Solar_System_Eligibility__c eligibility =
                        new Partner_Shared_Solar_System_Eligibility__c(
                            Shared_Solar_System__c = sss.Id,
                            Account__c = partner.Id,
                            Start_Date__c = Date.newInstance(2020,1,1),
                            CreatedDate = csDataDate
                        );
                    uow.registerNew(eligibility, Partner_Shared_Solar_System_Eligibility__c.Commission_Structure__c, commissionStructure);
                }
            }
            uow.commitWork();
        }

        @TestVisible private void insertTariffsForProduct(Id productId, Id eversourceId, Id nationalGridId) {
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
                    Service_Territories__c = 'NEMA;SEMA;WCMA',
                    BWC_Project_Entity_Manual__c = entity.Id,
                    Maximum_Subscription_Capacity_kWDC__c = 25,
                    Utility__c = utility.Id,
                    Available_SMB_Underwriting_Method_Docs__c = true,
                    Available_SMB_Underwriting_Method_FICO__c = true,
                    CreatedDate = csDataDate
                );
            return sss;
        }
    }
    @TestVisible private without sharing class GatewayHelper extends Promise {
        private CSDataSetting csDataSetting;
        private GatewayHelper(CSDataSetting csDataSetting) {
            this.csDataSetting = csDataSetting;
        }
        public override void execute() {
            Entity__c defaultEntity = new Entity__c(
                Name = 'BWC Holdings, LLC',
                CreatedDate = csDataDate
            );
            insert defaultEntity;
            Entity__c entity1 = [SELECT Id FROM Entity__c WHERE Name = 'Project A Oak Road' LIMIT 1];
            Entity__c entity2 = [SELECT Id FROM Entity__c WHERE Name = 'Project B Main St' LIMIT 1];
            update new List<Entity__c>{entity1, entity2};
        }
    }
    @TestVisible private without sharing class FirstAccountHelper extends Promise {
        private CSDataSetting csDataSetting;
        @TestVisible private FirstAccountHelper(CSDataSetting csDataSetting) {
            this.csDataSetting = csDataSetting;
        }
        public override void execute() {
            // Can't do more than 12 because the Update SSS On Opportunity Complete PB fails with
            // "DUPLICATE_VALUE: Maximum number of duplicate updates in one batch (12 allowed)"
            Integer batchNumber = csDataSetting.numberOfAccountBatches;
            List<CustomerName> names = new List<CustomerName>();
            names.add(new CustomerName('Ashley', 'Smith', batchNumber));
            names.add(new CustomerName('Steven', 'Ward', batchNumber));
            names.add(new CustomerName('Marie', 'Mitchell', batchNumber));
            names.add(new CustomerName('Justin', 'Jenkins', batchNumber));
            names.add(new CustomerName('Russell', 'Butler', batchNumber));
            names.add(new CustomerName('Cobie', 'Croft', batchNumber));
            names.add(new CustomerName('Ridwan', 'Conner', batchNumber));
            names.add(new CustomerName('Margaux', 'Maldonado', batchNumber));
            names.add(new CustomerName('Conor', 'Schmitt', batchNumber));
            names.add(new CustomerName('Akbar', 'Boyce', batchNumber));
            names.add(new CustomerName('Viaan', 'Faulkner', batchNumber));
            names.add(new CustomerName('Ritchie', 'Ho', batchNumber));
            createSubscriptions(0, names);
        }
    }
    @TestVisible private without sharing class SecondAccountHelper extends Promise {
        private CSDataSetting csDataSetting;
        @TestVisible private SecondAccountHelper(CSDataSetting csDataSetting) {
            this.csDataSetting = csDataSetting;
        }
        public override void execute() {
            Integer batchNumber = csDataSetting.numberOfAccountBatches;
            List<CustomerName> names = new List<CustomerName>();
            names.add(new CustomerName('Joshua', 'Phillips', batchNumber));
            names.add(new CustomerName('Donna', 'Simmons', batchNumber));
            names.add(new CustomerName('Keith', 'Morgan', batchNumber));
            names.add(new CustomerName('Mark', 'Allen', batchNumber));
            names.add(new CustomerName('Albert', 'Price', batchNumber));
            names.add(new CustomerName('Naveed', 'Ventura', batchNumber));
            names.add(new CustomerName('Woody', 'Walsh', batchNumber));
            names.add(new CustomerName('Nafisa', 'Wong', batchNumber));
            names.add(new CustomerName('Ritik', 'Mann', batchNumber));
            names.add(new CustomerName('Clement', 'Aguirre', batchNumber));
            names.add(new CustomerName('Mollie', 'Hassan', batchNumber));
            names.add(new CustomerName('Harrison', 'Harris', batchNumber));
            createSubscriptions(1, names);
        }
    }

    @TestVisible private without sharing class TransferHelper extends Promise {
        private CSDataSetting csDataSetting;
        @TestVisible private TransferHelper(CSDataSetting csDataSetting) {
            this.csDataSetting = csDataSetting;
        }
        public override void execute() {
            try {
                innerExecute();
            } catch (Exception e) {
                Logger.logNow('TransferHelper', 'execute', e.getMessage() + '\n' + e.getStackTraceString(), Logger.ERROR);
            }
        }
        private void innerExecute() {
            List<Shared_Solar_System__c> sssList = [
                SELECT Id, Name, BWC_Project_Entity_Manual__r.Id, Product__r.Id
                FROM Shared_Solar_System__c
                WHERE BWC_Project_Entity_Manual__r.Id != NULL
                ORDER BY Name DESC
            ];
            Date today = Date.today();
            Date threeMonthsAgo = today.addMonths(-3);
            Date twoMonthsAgo = today.addMonths(-2);
            Schedule_Z__c scheduleZ1 = new Schedule_Z__c(
                Name = sssList[0].Name + ' ' + (Date.today()-90).format(),
                Shared_Solar_System__c = sssList[0].Id,
                Status__c = 'Billing',
                Date_Enacted_by_Utility__c = Date.today()-90,
                CreatedDate = csDataDate
            );
            insert scheduleZ1;
            Schedule_Z__c scheduleZ2 = new Schedule_Z__c(
                Name = sssList[1].Name + ' ' + (Date.today()-90).format(),
                Shared_Solar_System__c = sssList[1].Id,
                Status__c = 'Billing',
                Date_Enacted_by_Utility__c = Date.today()-90,
                CreatedDate = csDataDate
            );
            insert scheduleZ2;
            Bill_Period__c bpA = new Bill_Period__c(
                Name = sssList[0].Name + ' - ' + threeMonthsAgo.format(),
                Shared_Solar_System__c = sssList[0].Id,
                Bill_Date__c = threeMonthsAgo,
                CreatedDate = csDataDate
            );
            Bill_Period__c bpB = new Bill_Period__c(
                Name = sssList[1].Name + ' - ' + threeMonthsAgo.format(),
                Shared_Solar_System__c = sssList[1].Id,
                Bill_Date__c = threeMonthsAgo,
                CreatedDate = csDataDate
            );
            insert new List<Bill_Period__c>{bpB, bpA};
            Production__c prodA = new Production__c(
                Name = sssList[0].Name + ' Production ' + threeMonthsAgo.format(),
                Shared_Solar_System__c = sssList[0].Id,
                Start_Date__c = threeMonthsAgo,
                End_Date__c = twoMonthsAgo,
                Production_kWh__c = 81869,
                Credits_Generated__c = 13483.66,
                CreatedDate = csDataDate
            );
            Production__c prodB = new Production__c(
                Name = sssList[1].Name + ' Production ' + threeMonthsAgo.format(),
                Shared_Solar_System__c = sssList[1].Id,
                Start_Date__c = threeMonthsAgo,
                End_Date__c = twoMonthsAgo,
                Production_kWh__c = 367918,
                Credits_Generated__c = 40983.43,
                CreatedDate = csDataDate
            );
            insert new List<Production__c>{prodB, prodA};
            Transfer__c transferA = new Transfer__c(
                Name = sssList[0].Name + ' Main Transfer - ' + threeMonthsAgo.format(),
                Bill_Period__c = bpA.Id,
                Bill_By__c = 'UASB',
                Date_of_Transfer__c = twoMonthsAgo,
                Shared_Solar_System__c = sssList[0].Id,
                Transfer_Type__c = 'Main',
                Allocation_Schedule__c = scheduleZ1.Id,
                Attempted_kWh_Transfer__c = 81869,
                Attempted_Transfer__c = 13483.66,
                Transfer_Amount__c = 13483.66,
                Default_Credit_Value__c = 0.1848,
                CreatedDate = csDataDate
            );
            Transfer__c transferB = new Transfer__c(
                Name = sssList[1].Name + ' Main Transfer - ' + threeMonthsAgo.format(),
                Bill_Period__c = bpB.Id,
                Bill_By__c = 'UASB',
                Date_of_Transfer__c = twoMonthsAgo,
                Shared_Solar_System__c = sssList[1].Id,
                Transfer_Type__c = 'Main',
                Allocation_Schedule__c = scheduleZ2.Id,
                Attempted_kWh_Transfer__c = 367918,
                Attempted_Transfer__c = 40983.43,
                Transfer_Amount__c = 40983.43,
                Default_Credit_Value__c = 0.1848,
                CreatedDate = csDataDate
            );
            insert new List<Transfer__c>{transferB, transferA};
            TransferPartService transferPartService = new TransferPartService();
            transferPartService.createPartsFromTransfer(new List<Transfer__c>{transferA, transferB});

            generateUASBsForUCB(transferA);
            BillGenerationAsyncService ee = new BillGenerationAsyncService(new List<Bill_Period__c>{bpB});
            ee.executeBatchJob();
            if (!Test.isRunningTest()) {
                callTransferHelper2Future(JSON.serialize(csDataSetting));
            }
        }

    }
    // Because the AllocationScheduleService is queued to run, we can't also directly queue the TransferHelper2 class,
    // so we'll use a future method to queue it.
    @Future
    public static void callTransferHelper2Future(String csDataSettingJSON) {
        CSDataSetting csDataSetting = (CSDataSetting) JSON.deserialize(csDataSettingJSON, CSDataSetting.class);
        System.enqueueJob(new TransferHelper2(csDataSetting));
    }
    @TestVisible private without sharing class TransferHelper2 implements Queueable {
        private CSDataSetting csDataSetting;
        @TestVisible private TransferHelper2(CSDataSetting csDataSetting) {
            this.csDataSetting = csDataSetting;
        }
        public void execute(QueueableContext context) {
            try {
                innerExecute();
            } catch (Exception e) {
                Logger.logNow('TransferHelper2', 'execute', e.getMessage() + '\n' + e.getStackTraceString(), Logger.ERROR);
            }
        }
        private void innerExecute() {
            List<Shared_Solar_System__c> sssList = [
                SELECT Id, Name, BWC_Project_Entity_Manual__r.Id, Product__r.Id
                FROM Shared_Solar_System__c
                WHERE BWC_Project_Entity_Manual__r.Id != NULL
                ORDER BY Name DESC
            ];
            Date today = Date.today();
            Date twoMonthsAgo = today.addMonths(-2);
            Date oneMonthAgo = today.addMonths(-1);
            Schedule_Z__c scheduleZ1 = [SELECT Id FROM Schedule_Z__c WHERE Name = :(sssList[0].Name + ' ' + (Date.today()-90).format())];
            Schedule_Z__c scheduleZ2 = [SELECT Id FROM Schedule_Z__c WHERE Name = :(sssList[1].Name + ' ' + (Date.today()-90).format())];
            Bill_Period__c bpA = new Bill_Period__c(
                Name = sssList[0].Name + ' - ' + twoMonthsAgo.format(),
                Shared_Solar_System__c = sssList[0].Id,
                Bill_Date__c = twoMonthsAgo,
                CreatedDate = csDataDate
            );
            Bill_Period__c bpB = new Bill_Period__c(
                Name = sssList[1].Name + ' - ' + twoMonthsAgo.format(),
                Shared_Solar_System__c = sssList[1].Id,
                Bill_Date__c = twoMonthsAgo,
                CreatedDate = csDataDate
            );
            insert new List<Bill_Period__c>{bpB, bpA};
            Production__c prodA = new Production__c(
                Name = sssList[0].Name + ' Production ' + twoMonthsAgo.format(),
                Shared_Solar_System__c = sssList[0].Id,
                Start_Date__c = twoMonthsAgo,
                End_Date__c = oneMonthAgo,
                Production_kWh__c = 73072,
                Credits_Generated__c = 12033.73,
                CreatedDate = csDataDate
            );
            Production__c prodB = new Production__c(
                Name = sssList[1].Name + ' Production ' + twoMonthsAgo.format(),
                Shared_Solar_System__c = sssList[1].Id,
                Start_Date__c = twoMonthsAgo,
                End_Date__c = oneMonthAgo,
                Production_kWh__c = 81869,
                Credits_Generated__c = 13483.66,
                CreatedDate = csDataDate
            );
            insert new List<Production__c>{prodB, prodA};
            Transfer__c transferA = new Transfer__c(
                Name = sssList[0].Name + ' Main Transfer - ' + twoMonthsAgo.format(),
                Bill_Period__c = bpA.Id,
                Bill_By__c = 'UASB',
                Date_of_Transfer__c = oneMonthAgo,
                Shared_Solar_System__c = sssList[0].Id,
                Transfer_Type__c = 'Main',
                Allocation_Schedule__c = scheduleZ1.Id,
                Attempted_kWh_Transfer__c = 73072,
                Attempted_Transfer__c = 12033.73,
                Transfer_Amount__c = 12033.73,
                Default_Credit_Value__c = 0.1848,
                CreatedDate = csDataDate
            );
            Transfer__c transferB = new Transfer__c(
                Name = sssList[1].Name + ' Main Transfer - ' + twoMonthsAgo.format(),
                Bill_Period__c = bpB.Id,
                Bill_By__c = 'UASB',
                Date_of_Transfer__c = oneMonthAgo,
                Shared_Solar_System__c = sssList[1].Id,
                Transfer_Type__c = 'Main',
                Allocation_Schedule__c = scheduleZ2.Id,
                Attempted_kWh_Transfer__c = 81869,
                Attempted_Transfer__c = 13483.66,
                Transfer_Amount__c = 13483.66,
                Default_Credit_Value__c = 0.1848,
                CreatedDate = csDataDate
            );
            insert new List<Transfer__c>{transferB, transferA};
            TransferPartService transferPartService = new TransferPartService();
            transferPartService.createPartsFromTransfer(new List<Transfer__c>{transferA, transferB});
            generateUASBsForUCB(transferA);
            BillGenerationAsyncService ee = new BillGenerationAsyncService(new List<Bill_Period__c>{bpB});
            ee.executeBatchJob();
            if (!Test.isRunningTest()) {
                callTransferHelper3Future(JSON.serialize(csDataSetting));
            }
        }
    }
    @Future
    public static void callTransferHelper3Future(String csDataSettingJSON) {
        CSDataSetting csDataSetting = (CSDataSetting) JSON.deserialize(csDataSettingJSON, CSDataSetting.class);
        System.enqueueJob(new TransferHelper3(csDataSetting));
    }
    @TestVisible private without sharing class TransferHelper3 implements Queueable {
        private CSDataSetting csDataSetting;
        @TestVisible private TransferHelper3(CSDataSetting csDataSetting) {
            this.csDataSetting = csDataSetting;
        }
        public void execute(QueueableContext context) {
            try {
                innerExecute();
            } catch (Exception e) {
                Logger.logNow('TransferHelper3', 'execute', e.getMessage() + '\n' + e.getStackTraceString(), Logger.ERROR);
            }
        }
        private void innerExecute() {
            List<Shared_Solar_System__c> sssList = [
                SELECT Id, Name, BWC_Project_Entity_Manual__r.Id, Product__r.Id
                FROM Shared_Solar_System__c
                WHERE BWC_Project_Entity_Manual__r.Id != NULL
                ORDER BY Name DESC
            ];
            Date today = Date.today();
            Date oneMonthAgo = today.addMonths(-1);
            Schedule_Z__c scheduleZ1 = [SELECT Id FROM Schedule_Z__c WHERE Name = :(sssList[0].Name + ' ' + (Date.today()-90).format())];
            Schedule_Z__c scheduleZ2 = [SELECT Id FROM Schedule_Z__c WHERE Name = :(sssList[1].Name + ' ' + (Date.today()-90).format())];
            Bill_Period__c bpA = new Bill_Period__c(
                Name = sssList[0].Name + ' - ' + oneMonthAgo.format(),
                Shared_Solar_System__c = sssList[0].Id,
                Bill_Date__c = oneMonthAgo,
                CreatedDate = csDataDate
            );
            Bill_Period__c bpB = new Bill_Period__c(
                Name = sssList[1].Name + ' - ' + oneMonthAgo.format(),
                Shared_Solar_System__c = sssList[1].Id,
                Bill_Date__c = oneMonthAgo,
                CreatedDate = csDataDate
            );
            insert new List<Bill_Period__c>{bpB, bpA};
            Production__c prodA = new Production__c(
                Name = sssList[0].Name + ' Production ' + oneMonthAgo.format(),
                Shared_Solar_System__c = sssList[0].Id,
                Start_Date__c = oneMonthAgo,
                End_Date__c = oneMonthAgo.addMonths(1),
                Production_kWh__c = 327001,
                Credits_Generated__c = 36424.44,
                CreatedDate = csDataDate
            );

            Production__c prodB = new Production__c(
                Name = sssList[1].Name + ' Production ' + oneMonthAgo.format(),
                Shared_Solar_System__c = sssList[1].Id,
                Start_Date__c = oneMonthAgo,
                End_Date__c = oneMonthAgo.addMonths(1),
                Production_kWh__c = 81869,
                Credits_Generated__c = 12033.73,
                CreatedDate = csDataDate
            );
            insert new List<Production__c>{prodB, prodA};
            Transfer__c transferA = new Transfer__c(
                Name = sssList[0].Name + ' Main Transfer - ' + oneMonthAgo.format(),
                Bill_Period__c = bpA.Id,
                Bill_By__c = 'UASB',
                Date_of_Transfer__c = oneMonthAgo.addMonths(1),
                Shared_Solar_System__c = sssList[0].Id,
                Transfer_Type__c = 'Main',
                Allocation_Schedule__c = scheduleZ1.Id,
                Attempted_kWh_Transfer__c = 327001,
                Attempted_Transfer__c = 36424.44,
                Transfer_Amount__c = 36424.44,
                Default_Credit_Value__c = 0.1848,
                CreatedDate = csDataDate
            );
            Transfer__c transferB = new Transfer__c(
                Name = sssList[1].Name + ' Main Transfer - ' + oneMonthAgo.format(),
                Bill_Period__c = bpB.Id,
                Bill_By__c = 'UASB',
                Date_of_Transfer__c = oneMonthAgo.addMonths(1),
                Shared_Solar_System__c = sssList[1].Id,
                Transfer_Type__c = 'Main',
                Allocation_Schedule__c = scheduleZ2.Id,
                Attempted_kWh_Transfer__c = 81869,
                Attempted_Transfer__c = 12033.73,
                Transfer_Amount__c = 12033.73,
                Default_Credit_Value__c = 0.1848,
                CreatedDate = csDataDate
            );
            insert new List<Transfer__c>{transferB, transferA};
            TransferPartService transferPartService = new TransferPartService();
            transferPartService.createPartsFromTransfer(new List<Transfer__c>{transferA, transferB});
            generateUASBsForUCB(transferA);
            BillGenerationAsyncService ee = new BillGenerationAsyncService(new List<Bill_Period__c>{bpB});
            ee.executeBatchJob();
        }
    }
    @TestVisible private without sharing class CSDataSetting {
        private Integer numberOfAccountBatches;
        @TestVisible private CSDataSetting(Integer numberOfAccounts) {
            this.numberOfAccountBatches = (Integer) Math.rint(numberOfAccounts/24);
        }
    }
    @TestVisible private without sharing class CustomerName {
        private String firstName;
        private String lastName;
        @TestVisible private CustomerName(String firstName, String lastName, Integer batchNumber) {
            this.firstName = firstName;
            this.lastName = lastName + (batchNumber>1?' ' + batchNumber:'');
        }
        private String getFullName() {
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
            RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Property').getRecordTypeId(),
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
    private static Opportunity getOpportunityInQC(String accountName1, Account propAccount1, Shared_Solar_System__c sss) {
        Opportunity opportunity1 = new Opportunity(
            Name = accountName1,
            AccountId = propAccount1.Id,
            Shared_Solar_System__c = sss.Id,
            StageName = 'QC In Process',
            Customer_Group__c = 'Residential',
            Product__c = sss.Product__r.Id,
            CloseDate = System.today(),
            RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Community Solar').getRecordTypeId(),
            Product_Line__c = 'Community Solar',
            NMC_Tariff__c = sss.Utility_NMC_Tariff__c,
            CreatedDate = csDataDate
        );
        return opportunity1;
    }
    private static List<Opportunity> setOpportunityPartner(List<Opportunity> opportunities){
        List<Partner__c> partners = [
            SELECT Id
            FROM Partner__c
            LIMIT 1
        ];
        for (Opportunity opp : opportunities){
            opp.Partner_tag_lookup__c = partners[0].Id;
        }
        return opportunities;
    }
    private static void getUtilityAccountSubscription(String name, Integer subscription,
        Utility_Account_Log__c ualog1, Opportunity opportunity1, fflib_SObjectUnitOfWork uow) {
        Utility_Account_Subscription__c uas1 = new Utility_Account_Subscription__c(
            Name = name,
            Utility_Account_Log__c = ualog1.Id,
            Opportunity__c = opportunity1.Id,
            Sizing_Method__c = opportunity1.NMC_Tariff__c,
            Next_Schedule_Z_Status__c = 'Active Subscription',
            calculated_annual_cost_of_electricity__c = 1400,
            Subscribed_Annual_Cost_of_Electricity__c = 1400,
            Annual_kwh_subscription_future__c  = subscription*1300,
            Customer_Subscription_KW_DC_STATIC__c = subscription,
            CreatedDate = csDataDate
        );
        uow.registerNew(uas1);
        Subscription_Order__c so = new Subscription_Order__c(
            Type__c = 'Initial',
            New_Annual_kWh__c = subscription*1300,
            New_Annual_Cost__c = 1400,
            CreatedDate = csDataDate
        );
        uow.registerNew(so, Subscription_Order__c.Utility_Account_Subscription__c, uas1);
    }
    private static void createSubscriptions(Integer sssIndex, List<CustomerName> names) {
        List<Shared_Solar_System__c> sssList = [
            SELECT Id, Name, BWC_Project_Entity_Manual__r.Id, Product__r.Id, Utility_NMC_Tariff__c
            FROM Shared_Solar_System__c
            ORDER BY Name DESC
        ];
        List<Account> propertyAccounts = insertAccountsAndContacts(names);

        List<Utility_Account_Log__c> uals = insertUtilityAccountLogs(names, propertyAccounts);
        List<Opportunity> opportunities = insertOpportunities(names, propertyAccounts, sssList, sssIndex);
        insertSubscriptions(names, uals, opportunities);
    }
    @TestVisible
    private static List<Account> insertAccountsAndContacts(List<CustomerName> names) {
        User api = [SELECT Id FROM User WHERE Name = 'API' LIMIT 1];
        List<Account> parentAccounts = new List<Account>();
        for (Integer i = 0; i < names.size(); i++) {
            parentAccounts.add(new Account(
                Name = names[i].getFullName(),
                RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Parent Account').getRecordTypeId(),
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
        return propertyAccounts;
    }
    private static List<Utility_Account_Log__c> insertUtilityAccountLogs(List<CustomerName> names, List<Account> propertyAccounts) {
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
        return uals;
    }
    private static List<Opportunity> insertOpportunities(List<CustomerName> names, List<Account> propertyAccounts, List<Shared_Solar_System__c> sssList, Integer sssIndex) {
        List<Opportunity> opportunities = new List<Opportunity>();
        for (Integer i = 0; i < names.size(); i++) {
            if (i == 0) {
                opportunities.add(getOpportunityInQC(names[i].getFullName(), propertyAccounts[i], sssList[sssIndex]));
                opportunities.add(getOpportunityInQC(names[i].getFullName(), propertyAccounts[i], sssList[sssIndex == 0 ? 1 : 0]));
            } else {
                opportunities.add(getOpportunityInQC(names[i].getFullName(), propertyAccounts[i], sssList[sssIndex]));
            }
        }
        insert setOpportunityPartner(opportunities);
        // To generate commissions, we need to update opps to Complete (not create them as complete)
        for (Opportunity opp : opportunities) {
            opp.StageName = 'Complete';
        }
        update opportunities;
        return opportunities;
    }
    private static void insertSubscriptions(List<CustomerName> names, List<Utility_Account_Log__c> uals, List<Opportunity> opportunities) {
        fflib_SObjectUnitOfWork uow = new fflib_SObjectUnitOfWork(
            new List<SObjectType>{Utility_Account_Subscription__c.SObjectType, Subscription_Order__c.SObjectType}
        );
        for (Integer i = 0; i < names.size(); i++) {
            getUtilityAccountSubscription('000234' + i, getRandom(10, 20), uals[i], opportunities[i], uow);
        }
        uow.commitWork();
    }

    public static void generateUASBsForUCB(Transfer__c transferA) {
        Transfer__c transfer = new TransferSelector().getTransferById(transferA.Id);
        List<UASB__c> uasbs = BillGenerationService.calculateUASBsFromTransfer(
            transfer, BillGenerationService.BillType.ONTIME
        );
        List<TransferSheetService.UASBWithStatus> uasbWithStatuses = new List<TransferSheetService.UASBWithStatus>();
        for (UASB__c uasb : uasbs) {
            TransferSheetService.UASBWithStatus lineItem = new TransferSheetService.UASBWithStatus();
            lineItem.sfUASB = uasb;
            lineItem.status = 'MATCH';
            lineItem.utilUASB = new UASB__c(Credits_Allocated__c = 125.15);
            uasbWithStatuses.add(lineItem);
        }
        TransferSheetService.handleTransferSheetResolutions(JSON.serialize(uasbWithStatuses), new List<String>{
            '{"uniqueid": "missingBill", "resolution": "UseSalesforce"}'
        });
    }

    public static void deleteCSRecords() {
        if (Util.isSandboxOrTest()) {
            Util.disableAllTriggers();
            delete [SELECT Id FROM CS_Bill_Setting__c WHERE CreatedDate = :csDataDate];
            delete [SELECT Id FROM Client_Allocation_Schedule_Subscription__c];
            delete [SELECT Id FROM Bill_Adjustment__c];
            delete [SELECT Id FROM Transfer_Part__c];
            delete [SELECT Id FROM Transfer__c WHERE CreatedDate = :csDataDate];
            delete [SELECT Id FROM Commission_Structure__c WHERE CreatedDate = :csDataDate];
            delete [SELECT Id FROM Utility_Account_Bill__c WHERE CreatedDate = :csDataDate];
            delete [SELECT Id FROM Account_Bill__c WHERE CreatedDate = :csDataDate];
            delete [SELECT Id FROM System_Bill__c WHERE CreatedDate = :csDataDate];
            delete [SELECT Id FROM UASB__c WHERE CreatedDate = :csDataDate];
            delete [SELECT Id FROM Bill_Period__c WHERE CreatedDate = :csDataDate];
            delete [SELECT Id FROM Production__c WHERE CreatedDate = :csDataDate];
            delete [SELECT Id FROM Client_Utility_Account_Subscription__c];
            delete [SELECT Id FROM Schedule_Z_Subscription__c WHERE CreatedDate = :csDataDate];
            delete [SELECT Id FROM Schedule_Z__c WHERE CreatedDate = :csDataDate];
            delete [SELECT Id FROM Utility_Account_Subscription__c WHERE CreatedDate = :csDataDate];
            delete [SELECT Id FROM Utility_Account_Log__c WHERE CreatedDate = :csDataDate];
            delete [SELECT Id FROM Opportunity WHERE CreatedDate = :csDataDate];
            delete [SELECT Id FROM Case WHERE CreatedDate = :csDataDate];
            delete [SELECT Id FROM Contact WHERE CreatedDate = :csDataDate];
            delete [SELECT Id FROM Account WHERE CreatedDate = :csDataDate];
            delete [SELECT Id FROM Subscription_Order__c WHERE CreatedDate = :csDataDate];
            delete [SELECT Id FROM Shared_Solar_System_Order__c];
            delete [SELECT Id FROM Shared_Solar_System__c WHERE CreatedDate = :csDataDate];
            delete [SELECT Id FROM Utility__c WHERE CreatedDate = :csDataDate];
            delete [SELECT Id FROM Entity__c WHERE CreatedDate = :csDataDate];
            delete [SELECT Id FROM Utility_NMC_Tariff__c WHERE CreatedDate = :csDataDate];
            delete [SELECT Id FROM Load_U__c WHERE CreatedDate = :csDataDate];
            Util.enableAllTriggers();
        }
    }
}