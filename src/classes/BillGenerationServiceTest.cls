// JP 1/19/20 : Once we've transitioned fully over to billing off transfers and only creating UASBs, delete this
// everything is covered by TransferSheetBillingTest

@isTest
public class BillGenerationServiceTest {
    @TestSetup
    public static void testSetup() {
        TestBillCreationForCancelledCustomers.testSetupBillRecords();
        setCollectionsWindow(90);
        CustomerCommunicationHandlerTest.setDaysPastDue(System.today().addDays(-30),3);
    }

    public static void generateBills(List<Id> billPeriodIdList) {

        List<Bill_Period__c> billPeriods = [
            SELECT Id, Shared_Solar_System__c, Bill_Date__c
            FROM Bill_Period__c
            WHERE Id IN :billPeriodIdList
        ];
        BillGenerationAsyncService ee = new BillGenerationAsyncService(billPeriods);
        ee.executeBatchJob();
    }

    public static List<Transfer__c> insertSecondMonthProduction() {
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

        Bill_Period__c bpB1 = new Bill_Period__c(
            Name = 'sssB - November 2016',
            Shared_Solar_System__c = sssList[0].Id,
            Bill_Date__c = oneMonthInFuture
        );

        Bill_Period__c bpA1 = new Bill_Period__c(
            Name = 'sssA - November 2016',
            Shared_Solar_System__c = sssList[1].Id,
            Bill_Date__c = oneMonthInFuture
        );

        insert new List<Bill_Period__c>{bpB1, bpA1};

        Production__c prodB1 = new Production__c(
            Name = 'sssB September Production',
            Shared_Solar_System__c = sssList[0].Id,
            Start_Date__c = oneMonthAgo,
            End_Date__c = todaysDate,
            Production_kWh__c = 73072.00,
            Credits_Generated__c = 12033.73
        );

        Production__c prodA1 = new Production__c(
            Name = 'sssA September Production',
            Shared_Solar_System__c = sssList[1].Id,
            Start_Date__c = oneMonthAgo,
            End_Date__c = todaysDate,
            Production_kWh__c = 73072.00,
            Credits_Generated__c = 12033.73
        );

        insert new List<Production__c>{prodB1, prodA1};

        Transfer__c transferB1 = new Transfer__c(
            Name = 'Main Transfer - sssB September',
            Bill_Period__c = bpB1.Id,
            Date_of_Transfer__c = oneMonthAgo,
            Shared_Solar_System__c = sssList[0].Id,
            Transfer_Type__c = 'Main',
            Allocation_Schedule__c = schZOne.Id,
            Attempted_kWh_Transfer__c = 73072.00,
            Attempted_Transfer__c =  12033.73,
            Transfer_Amount__c =  12033.73,
            Default_Credit_Value__c = 0.1848
        );


        Transfer__c transferA1 = new Transfer__c(
            Name = 'Main Transfer - sssA September',
            Bill_Period__c = bpA1.Id,
            Date_of_Transfer__c = oneMonthAgo,
            Shared_Solar_System__c = sssList[1].Id,
            Transfer_Type__c = 'Main',
            Allocation_Schedule__c = schZTwo.Id,
            Attempted_kWh_Transfer__c = 73072.00,
            Attempted_Transfer__c =  12033.73,
            Transfer_Amount__c =  12033.73,
            Default_Credit_Value__c = 0.1848
        );

        insert new List<Transfer__c>{transferB1, transferA1};


        return new List<Transfer__c>{transferA1, transferB1};
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

        List<Transfer__c> transfers = insertSecondMonthProduction();
        for (Transfer__c transfer : transfers) {
            secondScheduleZIds.add(transfer.Allocation_Schedule__c);
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
        List<Transfer__c> transfers = insertSecondMonthProduction();
        for (Transfer__c transfer : transfers){
            scheduleZIds.add(transfer.Allocation_Schedule__c);
        }

        List<Schedule_Z_Subscription__c> szsList = ScheduleZSubscriptionSelector.getListForBilling(scheduleZIds);

        Set<Id> uasIdsAlreadyBilling = new Set<Id>();
        for (Schedule_Z_Subscription__c szs : szsList) {
            uasIdsAlreadyBilling.add(szs.Utility_Account_Subscription__c);
        }
        Date maxPastDueDate = Date.today().addDays(-90);
        List<Schedule_Z_Subscription__c> overdue = ScheduleZSubscriptionSelector.getOverdueSZSubscriptions(
            1,
            maxPastDueDate,
            uasIdsAlreadyBilling
        );
        System.assertEquals(4,uasIdsAlreadyBilling.size());
        System.assertEquals(2,overdue.size());
    }

    @isTest
    public static void testAsyncJob() {
        List<UASB__c> beforeUASBs = queryForBills();

        Test.startTest();
            List<Transfer__c> transfers = insertSecondMonthProduction();
            generateBills(new List<Id>{transfers[0].Bill_Period__c, transfers[1].Bill_Period__c});
        Test.stopTest();

        List<UASB__c> afterUASBs = queryForBills();

        System.assertEquals(8,beforeUASBs.size());
        System.assertEquals(14,afterUASBs.size());
    }
}