@IsTest
public class CustomerCommunicationHandlerTest {
    @TestSetup public static void setupData() {
        Test.startTest();
        Utility__c eversource = new Utility__c(
            Name = 'Eversource',
            Number_of_Decimal_Places__c = 2
        );

        Utility__c nationalGrid = new Utility__c(
            Name = 'National Grid',
            Number_of_Decimal_Places__c = 2
        );

        insert new List<Utility__c>{
            eversource, nationalGrid
        };

        Utility_NMC_Tariff__c everbillNMC = new Utility_NMC_Tariff__c(Name = 'Eversource SEMA Class 2',
            Utility__c = 'Eversource',
            Class__c = 'Class 2',
            Value_of_Net_Metering_Credit__c = 0.1848,
            Current_Billing_Rate__c = true);

        Utility_NMC_Tariff__c eversizeNMC = new Utility_NMC_Tariff__c(Name = 'Eversource SEMA Class 2',
            Utility__c = 'Eversource',
            Class__c = 'Class 2',
            Value_of_Net_Metering_Credit__c = 0.1848,
            Sizing_Rate__c = true);

        insert new List<Utility_NMC_Tariff__c>{
            everbillNMC, eversizeNMC
        };

        Load_U__c everLZU = new Load_U__c(Name = '02633',
            LZ__c = 'SEMA',
            Town__c = 'Medfield');
        insert everLZU;

        ZipCode_Utility_Junction__c junction = new ZipCode_Utility_Junction__c(
            Load_Zone_Utility__c = everLZU.Id,
            Utility__c = eversource.Id
        );
        insert junction;

        TestFactory.insertBWAddress();
        TestFactory.setCSBillSettings();

        Entity__c entity1 = new Entity__c(Name = 'Oxford Barrett St. P1');
        insert entity1;

        Shared_Solar_System__c sss1 =
            new Shared_Solar_System__c(Name = 'SSS1',
                Service_Territory__c = 'SEMA',
                Service_Territories__c = 'SEMA',
                Open__c = true,
                Reserved_Capacity_kW_DC__c = '0',
                Capacity_Committed_kW_DC__c = 0,
                Total_System_Size_kWh_DC__c = 1445.86,
                Total_System_Size_kW_AC__c = 996,
                Utility__c = eversource.Id,
                Credit_Score_Requirement__c = 200,
                Assignment_Order__c = '1',
                Utility_NMC_Tariff__c = eversizeNMC.Id,
                Expected_Yield_kWh_kW__c = 1300,
                Assemblage_Count__c = 1,
                BWC_Project_Entity_Manual__c = entity1.Id,
                Maximum_Subscription_Capacity_kWDC__c = 25,
                Billing_Method__c = 'NMC');
        insert sss1;

        Shared_Solar_System__c sss2 =
            new Shared_Solar_System__c(Name = 'SSS2',
                Service_Territory__c = 'SEMA',
                Service_Territories__c = 'SEMA',
                Open__c = true,
                Reserved_Capacity_kW_DC__c = '0',
                Capacity_Committed_kW_DC__c = 0,
                Total_System_Size_kWh_DC__c = 1225.86,
                Total_System_Size_kW_AC__c = 800,
                Utility__c = eversource.Id,
                Credit_Score_Requirement__c = 200,
                Assignment_Order__c = '1',
                Utility_NMC_Tariff__c = eversizeNMC.Id,
                Expected_Yield_kWh_kW__c = 1300,
                Assemblage_Count__c = 1,
                BWC_Project_Entity_Manual__c = entity1.Id,
                Maximum_Subscription_Capacity_kWDC__c = 25,
                Billing_Method__c = 'NMC');
        insert sss2;


        Shared_Solar_System__c sss3 =
            new Shared_Solar_System__c(Name = 'SSS3',
                Service_Territory__c = 'SEMA',
                Service_Territories__c = 'SEMA',
                Open__c = true,
                Reserved_Capacity_kW_DC__c = '0',
                Capacity_Committed_kW_DC__c = 0,
                Total_System_Size_kWh_DC__c = 1111.86,
                Total_System_Size_kW_AC__c = 940,
                Utility__c = eversource.Id,
                Credit_Score_Requirement__c = 200,
                Assignment_Order__c = '1',
                Utility_NMC_Tariff__c = eversizeNMC.Id,
                Expected_Yield_kWh_kW__c = 1300,
                Assemblage_Count__c = 1,
                BWC_Project_Entity_Manual__c = entity1.Id,
                Maximum_Subscription_Capacity_kWDC__c = 25,
                Billing_Method__c = 'NMC');
        insert sss3;

        Account accountParent1 = new Account(Name = 'Par Account 1', Client_Brand_Key__c = 'BluewaveLogo');
        Account accountParent2 = new Account(Name = 'Par Account 2', Client_Brand_Key__c = 'AmpRed');
        Account accountParent3 = new Account(Name = 'Par Account 3', Client_Brand_Key__c = 'BluewaveLogo');
        insert new List<Account>{
            accountParent1, accountParent2, accountParent3
        };

        Contact contactA = new Contact(FirstName = 'Contact A',
            LastName = 'Last',
            Account = accountParent1,
            Email = 'jpentaleriA@bluewavesolar.com');
        Contact contactB = new Contact(FirstName = 'Contact B',
            LastName = 'Last',
            Account = accountParent2,
            Email = 'jpentaleriB@bluewavesolar.com');
        Contact contactC = new Contact(FirstName = 'Contact C',
            LastName = 'Last',
            Account = accountParent3,
            Email = 'jpentaleriC@bluewavesolar.com');

        insert new List<Contact>{
            contactA, contactB, contactC
        };

        Id propertyAccountRT = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Property').getRecordTypeId();
        Account propAcct1 = new Account(Name = 'Prop Account 1',
            Parent_Account__c = accountParent1.Id,
            Send_Bills_Contact__c = contactA.Id,
            RecordTypeId = propertyAccountRT,
            Client_Brand_Key__c = 'BluewaveLogo');
        Account propAcct2 = new Account(Name = 'Prop Account 2',
            Parent_Account__c = accountParent2.Id,
            Send_Bills_Contact__c = contactB.Id,
            RecordTypeId = propertyAccountRT,
            Client_Brand_Key__c = 'AmpRed');
        Account propAcct3 = new Account(Name = 'Prop Account 3',
            Parent_Account__c = accountParent3.Id,
            Send_Bills_Contact__c = contactC.Id,
            RecordTypeId = propertyAccountRT,
            Client_Brand_Key__c = 'BluewaveLogo');

        insert new List<Account>{
            propAcct1, propAcct2, propAcct3
        };

        Utility_Account_Log__c ualog1 = new Utility_Account_Log__c(
            Name = '0000234',
            Account__c = propAcct1.Id,
            Annual_Cost_of_Electricity__c = 10000,
            Name_on_Account__c = 'Name one');

        Utility_Account_Log__c ualog2 = new Utility_Account_Log__c(
            Name = '0000236',
            Account__c = propAcct2.Id,
            Annual_Cost_of_Electricity__c = 10000,
            Name_on_Account__c = 'Name two');

        Utility_Account_Log__c ualog3 = new Utility_Account_Log__c(
            Name = '0000238',
            Account__c = propAcct3.Id,
            Annual_Cost_of_Electricity__c = 10000,
            Name_on_Account__c = 'Name three');

        insert new List<Utility_Account_Log__c>{
            ualog1, ualog2, ualog3
        };

        Product2 normalCSProduct = new Product2(Name = 'BlueWave Community Solar',
            Family = 'Community Solar',
            Product_Type__c = 'Community Solar',
            State__c = 'MA',
            ProductCode = 'CS - BlueWave - 10%',
            IsActive = true,
            Lender_of_Record__c = 'BlueWave',
            NMC_Discount__c = 10,
            Annual_kWh_Maximum__c = 100000000,
            NM_Rate_Floor__c = 0,

            Days_In_Bill_Period__c = 20,
            Customer_Subscription_Type__c = 'Electricity Cost ($)',

            Monthly_Late_Fee__c = 1,
            Cancellation_Paragraph_Two__c = 'Your cancellation will take up to 6 months',
            Cancellation_Paragraph_Three__c = 'There is a termination fee');

        Product2 publicCSProduct = new Product2(Name = 'BlueWave Public Offtake CS',
            Family = 'Community Solar',
            Product_Type__c = 'Community Solar',
            State__c = 'MA',
            ProductCode = 'CS - Bluewave - Public CS - 20%',
            IsActive = true,
            Lender_of_Record__c = 'BlueWave',
            NMC_Discount__c = 20,
            Annual_kWh_Maximum__c = 63000,
            Customer_Subscription_Type__c = 'Electricity Cost ($)',
            NM_Rate_Floor__c = 0.09,
            Days_in_Bill_Period__c = 20,
            Monthly_Late_Fee__c = 0.8333,
            Cancellation_Paragraph_Two__c = 'Your cancellation is immediate');
        insert new List<Product2>{
            normalCSProduct, publicCSProduct
        };

        Opportunity opportunityone =
            new Opportunity(Name = 'Jordan Jordan 0000234',
                AccountId = propAcct1.Id,
                Shared_Solar_System__c = sss1.Id,
                StageName = 'Complete',
                Product__c = normalCSProduct.Id,
                NMC_Tariff__c = everbillNMC.Id,
                Product_Line__c = 'Community Solar',
                CloseDate = System.today());

        Opportunity opportunitytwo =
            new Opportunity(Name = 'Jordan Jordan 0000236',
                AccountId = propAcct2.Id,
                Shared_Solar_System__c = sss2.Id,
                StageName = 'Complete',
                Product__c = normalCSProduct.Id,
                NMC_Tariff__c = everbillNMC.Id,
                Product_Line__c = 'Community Solar',
                CloseDate = System.today());

        Opportunity opportunitythree =
            new Opportunity(Name = 'Jordan Jordan 0000238',
                AccountId = propAcct3.Id,
                Shared_Solar_System__c = sss3.Id,
                StageName = 'Complete',
                Product__c = normalCSProduct.Id,
                NMC_Tariff__c = everbillNMC.Id,
                Product_Line__c = 'Community Solar',
                CloseDate = System.today());
        insert new List<Opportunity>{
            opportunityone, opportunitytwo, opportunitythree
        };

        Utility_Account_Subscription__c uasOne =
            new Utility_Account_Subscription__c(Name = '0000234',
                Utility_Account_Log__c = ualog1.Id,
                Opportunity__c = opportunityone.Id,
                Sizing_Method__c = everbillNMC.Id,
                Next_Schedule_Z_Status__c = 'Active Subscription',

                Calculated_Annual_Cost_of_Electricity__c = 4000);


        Utility_Account_Subscription__c uasTwo =
            new Utility_Account_Subscription__c(Name = '0000236',
                Utility_Account_Log__c = ualog2.Id,
                Opportunity__c = opportunitytwo.Id,
                Sizing_Method__c = everbillNMC.Id,
                Next_Schedule_Z_Status__c = 'Active Subscription',

                Calculated_Annual_Cost_of_Electricity__c = 8000);

        Utility_Account_Subscription__c uasThree =
            new Utility_Account_Subscription__c(Name = '0000238',
                Utility_Account_Log__c = ualog3.Id,
                Opportunity__c = opportunitythree.Id,
                Sizing_Method__c = everbillNMC.Id,
                Next_Schedule_Z_Status__c = 'Active Subscription',

                Calculated_Annual_Cost_of_Electricity__c = 300);


        insert new List<Utility_Account_Subscription__c>{
            uasOne, uasTwo, uasThree
        };

        Utility_Account_Subscription__c uas01 = [
            SELECT Id, Subscription_Comment_c__c, Subscription_Type__c, Opportunity__c
            FROM Utility_Account_Subscription__c
            WHERE Id = :uasOne.Id
        ];

        SubscriptionManagementService.UASWrapper uasw1 = new SubscriptionManagementService.UASWrapper(uas01, 4000, 4000);

        Utility_Account_Subscription__c uas02 = [
            SELECT Id, Subscription_Comment_c__c, Subscription_Type__c, Opportunity__c
            FROM Utility_Account_Subscription__c
            WHERE Id = :uasTwo.Id
        ];

        SubscriptionManagementService.UASWrapper uasw2 = new SubscriptionManagementService.UASWrapper(uas01, 8000, 8000);

        Utility_Account_Subscription__c uas03 = [
            SELECT Id, Subscription_Comment_c__c, Subscription_Type__c, Opportunity__c
            FROM Utility_Account_Subscription__c
            WHERE Id = :uasThree.Id
        ];

        SubscriptionManagementService.UASWrapper uasw3 = new SubscriptionManagementService.UASWrapper(uas01, 300, 300);

        List<SubscriptionManagementService.UASWrapper> listUASW = new List<SubscriptionManagementService.UASWrapper> {
            uasw1, uasw2, uasw3
        };

        new SubscriptionManagementService().insertSubscriptionOrdersWithWrapper(listUASW);

        Schedule_Z__c scheduleZ1 = new Schedule_Z__c(
            Name = '18-0515 Oxford Barrett St. P1',
            Shared_Solar_System__c = sss1.Id,
            Date_Enacted_by_Utility__c = Date.newInstance(2018, 1, 1),
            Status__c = 'Billing'
        );

        Schedule_Z__c scheduleZ2 = new Schedule_Z__c(
            Name = '18-0515 Oxford Barrett St. P2',
            Shared_Solar_System__c = sss2.Id,
            Date_Enacted_by_Utility__c = Date.newInstance(2018, 1, 1),
            Status__c = 'Billing'
        );

        Schedule_Z__c scheduleZ3 = new Schedule_Z__c(
            Name = '18-0515 Oxford Barrett St. P3',
            Shared_Solar_System__c = sss3.Id,
            Date_Enacted_by_Utility__c = Date.newInstance(2018, 1, 1),
            Status__c = 'Billing'
        );

        insert new List<Schedule_Z__c>{
            scheduleZ1, scheduleZ2, scheduleZ3
        };
        Test.stopTest();
    }

    public static void setDaysPastDue(Date overdueDate, Integer numberOfAccounts) {
        List<Account> accounts = [
            SELECT Id,
                Max_Overdue_Due_Date_Zuora__c,
                Total_Outstanding_Balance_Zuora__c,
                Max_Overdue_Due_Date__c,
                Total_Outstanding_Balance__c
            FROM Account
            WHERE Parent_Account__c != NULL
            ORDER BY Account.Name
        ];
        Integer count = 0;
        for (Account acct : accounts) {
            if (count < numberOfAccounts) {
                acct.Max_Overdue_Due_Date_Zuora__c = overdueDate;
                acct.Total_Outstanding_Balance_Zuora__c = 12.00;
                count += 1;
            } else {
                acct.Max_Overdue_Due_Date_Zuora__c = System.today().addDays(15);
                acct.Total_Outstanding_Balance_Zuora__c = 100;
            }
        }
        update accounts;
    }

    @IsTest
    public static void testThreeDayWarning() {
        setDaysPastDue(System.today().addDays(3), 2);

        Test.startTest();
        CustomerCommunicationHandler m = new CustomerCommunicationHandler();
        Database.executeBatch(m, 10);
        Test.stopTest();

        System.assertEquals(MessagingService.emailsSent.size(), 2);
    }

    @IsTest
    public static void testThirtyDaysLate() {
        setDaysPastDue(System.today().addDays(-30), 1);

        Test.startTest();
        CustomerCommunicationHandler m = new CustomerCommunicationHandler();
        Database.executeBatch(m, 10);
        Test.stopTest();

        System.assertEquals(MessagingService.emailsSent.size(), 1);
    }

    @IsTest
    public static void testNinetyDaysLate() {
        setDaysPastDue(System.today().addDays(-90), 3);

        Test.startTest();
        CustomerCommunicationHandler m = new CustomerCommunicationHandler();
        Database.executeBatch(m, 10);
        Test.stopTest();

        System.assertEquals(MessagingService.emailsSent.size(), 3);
    }

    @IsTest
    public static void testCaseCreation() {
        // Thirty days late should create a case
        setDaysPastDue(System.today().addDays(-30), 3);

        Test.startTest();
        CustomerCommunicationHandler m = new CustomerCommunicationHandler();
        Database.executeBatch(m, 10);
        Test.stopTest();

        List<Case> caseList = [
            SELECT Id, Subject
            FROM Case
            WHERE Subject LIKE '%Collections Call:%'
        ];

        System.assertEquals(3, caseList.size());
    }

    @IsTest
    public static void testCaseNotCreated() {
        // Seven days late should not create a case
        setDaysPastDue(System.today().addDays(-7), 3);

        Test.startTest();
        CustomerCommunicationHandler m = new CustomerCommunicationHandler();
        Database.executeBatch(m, 10);
        Test.stopTest();

        List<Case> caseList = [
            SELECT Id, Subject
            FROM Case
            WHERE Subject LIKE '%Collections Call:%'
        ];

        System.assertEquals(0, caseList.size());
    }

    @IsTest
    public static void testFormatMoney() {
        System.assertEquals('$0.10', CustomerCommunicationHandler.formatMoney(.1), 'Return should have two decimal places if the input only has one');
        System.assertEquals('$1.00', CustomerCommunicationHandler.formatMoney(1), 'Return should have two decimal places if the input has none');
        System.assertEquals('$1.10', CustomerCommunicationHandler.formatMoney(1.10), 'Return should add a dollar sign and retain two decimals');
    }

}