@isTest
public class BillGenerationServiceTest {
    @TestSetup
    public static void testSetup() {
        TestBillCreationForCancelledCustomers.testSetupBillRecords();
        setCollectionsWindow(90);
    }

    public static void generateBills(List<Id> prodUpdateIdList) {
        List<Energy_Usage_Update__c> trigProdUp = ProductionUpdateSelector.getAllProductionUpdatesById(prodUpdateIdList);
        BillGenerationAsyncService ee = new BillGenerationAsyncService(trigProdUp);
        ee.executeBatchJob();
    }

    public static List<Energy_Usage_Update__c> insertSecondMonthSZandPU() {
        List<Shared_Solar_System__c> sssList = [
            SELECT Id, Name, BWC_Project_Entity_Manual__r.Id, Product__r.Id
            FROM Shared_Solar_System__c
            ORDER BY Name DESC];

        Schedule_Z__c schZOne = new Schedule_Z__c(
            Name = '18-0515 Project A Oak Rd',
            Shared_Solar_System__c = sssList[0].Id,
            Status__c = 'Billing'
        );

        Schedule_Z__c schZTwo = new Schedule_Z__c(
            Name = '18-0515 Project B Main St',
            Shared_Solar_System__c = sssList[1].Id,
            Status__c = 'Billing'
        );

        insert new List<Schedule_Z__c>{schZOne, schZTwo};

        Date todaysDate = Date.today();
        Date oneMonthAgo = todaysDate.addMonths(-1);
        Date oneMonthInFuture = todaysDate.addMonths(1);

        Energy_Usage_Update__c secondProdUpdateSSS1 = new Energy_Usage_Update__c (
            Name = 'sssB - September 2016',
            Shared_Solar_System__c = sssList[0].Id,
            Production__c = 73072.00,
            Due_Date__c = oneMonthInFuture,
            Billing_Period_Start_Date__c = oneMonthAgo,
            Billing_Period_End_Date__c = todaysDate,
            Total_System_NMCs__c = 12033.73,
            Date__c = todaysDate,
            Schedule_Z__c =  schZOne.Id
        );
        insert secondProdUpdateSSS1;

        Energy_Usage_Update__c secondProdUpdateSSS2 = new Energy_Usage_Update__c (
            Name = 'sssA - September 2016',
            Shared_Solar_System__c = sssList[1].Id,
            Production__c = 73072.00,
            Due_Date__c = oneMonthInFuture,
            Billing_Period_Start_Date__c = oneMonthAgo,
            Billing_Period_End_Date__c = todaysDate,
            Total_System_NMCs__c = 12033.73,
            Date__c = todaysDate,
            Schedule_Z__c =  schZTwo.Id
        );

        insert secondProdUpdateSSS2;

        return new List<Energy_Usage_Update__c>{secondProdUpdateSSS1, secondProdUpdateSSS2};
    }

    public static List<UASB__c> queryForBills() {
        List<UASB__c> uasbList= [
            SELECT Utility_Account_Subscription__r.Name, Shared_Solar_System__c,
                Utility_Account_Subscription__r.Name_on_Account_From_Log__c,
                Utility_Account_Subscription__r.Share_of_System__c,
                Production_Update__r.Name, Credits_on_Bill_Period__c,
                Utility_Account_Subscription__r.Next_Schedule_Z_Status__c,
                Utility_Account_Subscription__r.Opportunity__r.Name,
                Net_Metering_Credits_Allocated__c, Discounted_Bill__c,
                Subscription_Production_kWh__c, System_Bill__r.Opportunity__r.Name,
                Date__c
            FROM UASB__c
            ORDER BY Utility_Account_Subscription__r.Opportunity__r.Name, CreatedDate
        ];

        return uasbList;

        /* Expected values:
            acA has 1 UAL, 1 UAS (just SSS1)
            acB has 1 UAL, 2 UAS (SSS1/SSS2)
            acC has 2 UAL, 3 UAS (SSS1/SSS2 & SSS1)
        */
    }

    public static void setCollectionsWindow(Integer daysToLookBack){
        System_Properties__c propertyAlreadyInserted = [
            SELECT Id
            FROM System_Properties__c
        ];
        delete propertyAlreadyInserted;

        System_Properties__c property = new System_Properties__c(
            Name = 'System',
            CS_Bill_Batch_Size__c = 50,
            Days_Generate_Bills_for_Cancelled__c = daysToLookBack,
            Minimum_Balance_Bills_for_Cancelled__c = 0);
        insert property;
    }

    @isTest
    public static void testGetScheduleZSubscriptions() {
        Set<Id> firstScheduleZIds = new Set<Id>();
        Set<Id> secondScheduleZIds = new Set<Id>();
        List<Schedule_Z_Subscription__c> firstSZSList;
        List<Schedule_Z_Subscription__c> secondSZSList;
        List<Schedule_Z_Subscription__c> thirdSZSList;

        List<Schedule_Z__c> scheduleZs = [
            SELECT Id
            FROM Schedule_Z__c
        ];
        System.assertEquals(2, scheduleZs.size());
        for (Schedule_Z__c schZ : scheduleZs){
            firstScheduleZIds.add(schZ.Id);
        }

        firstSZSList = BillGenerationService.getScheduleZSubscriptionList(firstScheduleZIds);

        List<Opportunity> oppsToUpdate = new List<Opportunity>();
        List<Utility_Account_Subscription__c> uasesToDeactivate = [
            SELECT Id, Name, Opportunity__r.Id
            FROM Utility_Account_Subscription__c
            WHERE Opportunity__r.Name = 'acA A_SSS1'
            OR Opportunity__r.Name = 'acC C_SSS1'
            ORDER BY Opportunity__r.Name
            LIMIT 2
        ];
        for (Utility_Account_Subscription__c uas : uasesToDeactivate){
            uas.Next_Schedule_Z_Status__c = 'Inactive Subscription';
            Opportunity oppToUpdate = new Opportunity();
            oppToUpdate.Id = uas.Opportunity__r.Id;
            oppToUpdate.StageName = 'Cancelled';
            oppsToUpdate.add(oppToUpdate);
        }
        update uasesToDeactivate;
        update oppsToUpdate;

        setCollectionsWindow(0);

        List<Energy_Usage_Update__c> productionUpdate = insertSecondMonthSZandPU();
        for (Energy_Usage_Update__c prodUpdate : productionUpdate){
            secondScheduleZIds.add(prodUpdate.Schedule_Z__c);
        }
        secondSZSList = BillGenerationService.getScheduleZSubscriptionList(secondScheduleZIds);

        setCollectionsWindow(90);

        thirdSZSList = BillGenerationService.getScheduleZSubscriptionList(secondScheduleZIds);

        // All 6 UASes are included because none are marked as cancelled:
        System.assertEquals(6,firstSZSList.size());
        // 2 Cancelled UASes are excluded, because collections window is set to 0 days
        System.assertEquals(4,secondSZSList.size());
        // 2 Cancelled UASes are included, because the collections window is set to 90 days
        System.assertEquals(6,thirdSZSList.size());
    }

    @isTest
    public static void testGetCancelledCustomers(){
        List<Opportunity> oppsToUpdate = new List<Opportunity>();
        List<Utility_Account_Subscription__c> uasesToDeactivate = [
            SELECT Id, Name, Opportunity__r.Id
            FROM Utility_Account_Subscription__c
            WHERE Opportunity__r.Name = 'acA A_SSS1'
            OR Opportunity__r.Name = 'acC C_SSS1'
            LIMIT 2
        ];
        for (Utility_Account_Subscription__c uas : uasesToDeactivate){
            uas.Next_Schedule_Z_Status__c = 'Inactive Subscription';
            Opportunity oppToUpdate = new Opportunity();
            oppToUpdate.Id = uas.Opportunity__r.Id;
            oppToUpdate.StageName = 'Cancelled';
            oppsToUpdate.add(oppToUpdate);
        }
        update uasesToDeactivate;
        update oppsToUpdate;

        Set<Id> scheduleZIds = new Set<Id>();
        List<Energy_Usage_Update__c> productionUpdate = insertSecondMonthSZandPU();
        for (Energy_Usage_Update__c prodUpdate : productionUpdate){
            scheduleZIds.add(prodUpdate.Schedule_Z__c);
        }

        List<Schedule_Z_Subscription__c> szsList = ScheduleZSubscriptionSelector.getListForBilling(scheduleZIds);

        Set<Id> uasIdsAlreadyBilling = new Set<Id>();
        for (Schedule_Z_Subscription__c szs : szsList) {
            uasIdsAlreadyBilling.add(szs.Utility_Account_Subscription__c);
        }
        List<Schedule_Z_Subscription__c> overdue = ScheduleZSubscriptionSelector.getOverdueSZSubscriptions(System_Properties__c.getAll().values()[0], uasIdsAlreadyBilling);

        System.assertEquals(4,uasIdsAlreadyBilling.size());
        System.assertEquals(2,overdue.size());
    }

    @isTest
    public static void testAsyncJob() {
        List<UASB__c> beforeUASBs = queryForBills();

        Test.startTest();
            List<Energy_Usage_Update__c> productionUpdates = insertSecondMonthSZandPU();
            generateBills(new List<Id>{productionUpdates[0].Id, productionUpdates[1].Id});
        Test.stopTest();

        List<UASB__c> afterUASBs = queryForBills();

        System.assertEquals(8,beforeUASBs.size());
        System.assertEquals(14,afterUASBs.size());
    }
}