/**
 * Created by SarahRenfro on 11/11/2019.
 */
@IsTest
private class BillPeriodServiceTest {

    @TestSetup
    public static void setupData() {
        // Insert Utility record
        Utility__c ngrid = new Utility__c(
            Name = 'National Grid',
            Number_of_Decimal_Places__c = 2
        );
        insert ngrid;

        // Insert Shared Solar Systems
        Shared_Solar_System__c sss1 = new Shared_Solar_System__c(
            Name = 'Oxford Barrett St. P1',
            Service_Territory__c = 'SEMA',
            Service_Territories__c = 'SEMA',
            Open__c = true,
            Billing_Method__c = 'NMC',
            Reserved_Capacity_kW_DC__c = '10',
            Capacity_Committed_kW_DC__c = 0,
            Total_System_Size_kWh_DC__c = 1445.86,
            Total_System_Size_kW_AC__c = 1000,
            Utility__c = ngrid.Id,
            Credit_Score_Requirement__c = 300,
            Assignment_Order__c = '1',
            Expected_Yield_kWh_kW__c = 1300,
            Assemblage_Count__c = 1,
            Maximum_Subscription_Capacity_kWDC__c = 25
        );
        Shared_Solar_System__c sss2 = new Shared_Solar_System__c(
            Name = 'Oxford Barrett St. P2',
            Service_Territory__c = 'SEMA',
            Service_Territories__c = 'SEMA',
            Open__c = true,
            Billing_Method__c = 'NMC',
            Reserved_Capacity_kW_DC__c = '10',
            Capacity_Committed_kW_DC__c = 0,
            Total_System_Size_kWh_DC__c = 1445.86,
            Total_System_Size_kW_AC__c = 1000,
            Utility__c = ngrid.Id,
            Credit_Score_Requirement__c = 300,
            Assignment_Order__c = '1',
            Expected_Yield_kWh_kW__c = 1300,
            Assemblage_Count__c = 1,
            Maximum_Subscription_Capacity_kWDC__c = 25,
            UCB__c = true
        );
        insert new List<Shared_Solar_System__c>{sss1, sss2};

        // Insert Allocation Schedule
        Schedule_Z__c scheduleZ1 = new Schedule_Z__c(
            Name = '18-0515 Oxford Barrett St. P1',
            Shared_Solar_System__c = sss1.Id,
            Date_Enacted_by_Utility__c = Date.newInstance(2018,1,1),
            Status__c = 'Billing'
        );
        insert scheduleZ1;

        // Insert production records
        Production__c prod1 = new Production__c(
            Name = 'SSS 1 Production - May 2019',
            Shared_Solar_System__c = sss1.Id,
            Production_kWh__c = 20000,
            Credits_Generated__c = 10000,
            Start_Date__c = Date.newInstance(2019, 5, 1),
            End_Date__c = Date.newInstance(2019, 5, 29)
        );
        Production__c prod2 = new Production__c(
            Name = 'SSS 1 Production - May 2020',
            Shared_Solar_System__c = sss1.Id,
            Production_kWh__c = 20000,
            Credits_Generated__c = 10000,
            Start_Date__c = Date.newInstance(2020, 5, 1),
            End_Date__c = Date.newInstance(2020, 5, 29)
        );
       insert new List<Production__c>{prod1, prod2};

        // May Transfer has Date of Transfer in June - to be placed on July Bill Period
        Transfer__c onTime1 = new Transfer__c(
            Name = 'Main May Transfer',
            Transfer_Type__c = 'Main',
            Allocation_Schedule__c = scheduleZ1.Id,
            Shared_Solar_System__c = sss1.Id,
            Attempted_Transfer__c = 10000,
            Attempted_kWh_Transfer__c = 20000,
            Transfer_Amount__c = 10000,
            Date_of_Transfer__c = Date.newInstance(2019, 6, 4),
            Bills_Generated__c = false
        );
        Transfer__c onTime2 = new Transfer__c(
            Name = 'Main June Transfer',
            Transfer_Type__c = 'Main',
            Allocation_Schedule__c = scheduleZ1.Id,
            Shared_Solar_System__c = sss1.Id,
            Attempted_Transfer__c = 8000,
            Attempted_kWh_Transfer__c = 15000,
            Transfer_Amount__c = 8000,
            Date_of_Transfer__c = Date.newInstance(2019, 7, 4)
        );
        Transfer__c onTime3 = new Transfer__c(
            Name = 'Main July Transfer',
            Transfer_Type__c = 'Main',
            Allocation_Schedule__c = scheduleZ1.Id,
            Shared_Solar_System__c = sss1.Id,
            Attempted_Transfer__c = 4980,
            Attempted_kWh_Transfer__c = 9000,
            Transfer_Amount__c = 4980,
            Date_of_Transfer__c = Date.newInstance(2019, 8, 4)
        );
        insert new List<Transfer__c> {onTime1, onTime2, onTime3};
    }

    @IsTest
    static void testVerifyProductions() {
        Shared_Solar_System__c sss = [SELECT Id FROM Shared_Solar_System__c WHERE UCB__c = FALSE LIMIT 1];

        Bill_Period__c bp = new Bill_Period__c(
            Name = 'sssA - July Bill Period 2019',
            Shared_Solar_System__c = sss.Id,
            Bill_Date__c = Date.newInstance(2019, 7, 15)
        );
        insert bp;

        bp.Bill_Status__c = 'Production Uploaded';
        update bp;

        List<Production__c> productionList = [SELECT Id, Verification_Status__c FROM Production__c ORDER BY Start_Date__c ASC];
        System.assertEquals('Pending Verification', productionList[0].Verification_Status__c, 'Invalid verification status');
        System.assertEquals('Pending Verification', productionList[1].Verification_Status__c,'Invalid verification status');

        bp.Bill_Status__c = 'Production QCed';
        update bp;

        productionList = [SELECT Id, Verification_Status__c, Start_Date__c FROM Production__c ORDER BY Start_Date__c ASC];
        System.assertEquals('Verified', productionList[0].Verification_Status__c, 'Invalid verification status');
        System.assertEquals('Pending Verification', productionList[1].Verification_Status__c, 'Invalid verification status');
    }

    @IsTest
    static void testBillPeriodInsert() {
        Shared_Solar_System__c sss = [SELECT Id FROM Shared_Solar_System__c WHERE UCB__c = FALSE LIMIT 1];

        // July Bill Period will grab May Transfer
        Bill_Period__c bp1 = new Bill_Period__c(
            Name = 'sssA - July Bill Period 2016',
            Shared_Solar_System__c = sss.Id,
            Bill_Date__c = Date.newInstance(2019, 7, 15)
        );
        insert bp1;

        List<Transfer__c> mayTransfers = [SELECT Id, Bill_Period__c FROM Transfer__c WHERE Bill_Period__c = :bp1.Id];
        System.assertEquals(1, mayTransfers.size(), 'Incorrect number of transfer records');

        //September Bill Period will grab June & July Transfer (2 months of production)
        Bill_Period__c bp2 = new Bill_Period__c(
            Name = 'sssA - September Bill Period 2016',
            Shared_Solar_System__c = sss.Id,
            Bill_Date__c = Date.newInstance(2019, 9, 15)
        );
        insert bp2;

        List<Transfer__c> multiTransfers = [SELECT Id, Bill_Period__c FROM Transfer__c WHERE Bill_Period__c = :bp2.Id];
        System.assertEquals(2, multiTransfers.size(), 'Incorrect number of transfer records');
    }


    @IsTest
    static void testBillPeriodStatusUpdates() {
        Shared_Solar_System__c sss = [SELECT Id FROM Shared_Solar_System__c WHERE UCB__c = FALSE LIMIT 1];

        Test.startTest();
        Bill_Period__c bp1 = new Bill_Period__c(
            Name = 'sssA - July Bill Period 2016',
            Shared_Solar_System__c = sss.Id,
            Bill_Date__c = Date.newInstance(2019, 7, 15)
        );
        Bill_Period__c bp2 = new Bill_Period__c(
            Name = 'sssA - August Bill Period 2016',
            Shared_Solar_System__c = sss.Id,
            Bill_Date__c = Date.newInstance(2019, 8, 15)
        );
        Bill_Period__c bp3 = new Bill_Period__c(
            Name = 'sssA - September Bill Period 2016',
            Shared_Solar_System__c = sss.Id,
            Bill_Date__c = Date.newInstance(2019, 9, 15)
        );
        Bill_Period__c bp4 = new Bill_Period__c(
            Name = 'sssA - October Bill Period 2016',
            Shared_Solar_System__c = sss.Id,
            Bill_Date__c = Date.newInstance(2019, 10, 15)
        );
        List<Bill_Period__c> bpList = new List<Bill_Period__c> {bp1, bp2, bp3, bp4};
        insert bpList;

        bp1.Bill_Status__c = 'Production Uploaded';
        bp2.Bill_Status__c = 'Production QCed';
        bp3.Bill_Status__c = 'Generated';
        bp4.Bill_Status__c = 'Credit Transfers QCed';
        update bpList;
        Test.stopTest();

        List<Bill_Period__c> bpStatuses = [
            SELECT Id, Bill_Status__c, Date_Host_Bill_Uploaded__c, Date_Host_Account_Bill_QCed__c,
                Date_Credit_Transfers_QCed__c, Date_Generated__c
            FROM Bill_Period__c
            ORDER BY Bill_Date__c ASC
        ];
        System.assertEquals(Date.today(), bpStatuses[0].Date_Host_Bill_Uploaded__c, 'Invalid date, should be TODAY');
        System.assertEquals(Date.today(), bpStatuses[1].Date_Host_Account_Bill_QCed__c, 'Invalid date, should be TODAY');
        System.assertEquals(Date.today(), bpStatuses[2].Date_Generated__c, 'Invalid date, should be TODAY');
        System.assertEquals(Date.today(), bpStatuses[3].Date_Credit_Transfers_QCed__c, 'Invalid date, should be TODAY');
    }

    @IsTest
    static void testMarkBillPeriodsAsBillRunComplete() {
        // Setup
        Shared_Solar_System__c nonUcbSss = [SELECT Id FROM Shared_Solar_System__c WHERE UCB__c = FALSE LIMIT 1];
        Shared_Solar_System__c ucbSss = [SELECT Id FROM Shared_Solar_System__c WHERE UCB__c = TRUE LIMIT 1];
        Date billDate = Date.newInstance(2019, 7, 15);
        Date invoiceDate = Date.newInstance(2019, 7, 20);

        Bill_Period__c bp1 = new Bill_Period__c(
            Name = 'sssA - July Bill Period 2019',
            Shared_Solar_System__c = nonUcbSss.Id,
            Bill_Status__c = 'Ready to Generate',
            Bill_Date__c = billDate
        );
        Bill_Period__c bp2 = new Bill_Period__c(
            Name = 'sssB - July Bill Period 2019',
            Shared_Solar_System__c = ucbSss.Id,
            Bill_Status__c = 'Ready to Generate',
            Bill_Date__c = billDate
        );
        Bill_Period__c bp3 = new Bill_Period__c(
            Name = 'sssA - June Bill Period 2019',
            Shared_Solar_System__c = nonUcbSss.Id,
            Bill_Status__c = 'Ready to Generate',
            Bill_Date__c = Date.newInstance(2019, 6, 15) // old bill period, shouldn't be touched
        );
        insert new List<Bill_Period__c>{bp1, bp2, bp3};

        // Run test
        Test.startTest();
        new BillPeriodService().markBillPeriodsAsBillRunComplete(invoiceDate);
        Test.stopTest();

        // Validate bill periods
        List<Bill_Period__c> billPeriods = [SELECT Id FROM Bill_Period__c WHERE Bill_Status__c = 'Bill Run Complete'];
        System.assertEquals(2, billPeriods.size(), 'Invalid number of bill periods where bill status = complete');

        // Validate SSS first bill date fields
        nonUcbSss = [SELECT First_Bill_Date__c, UCB_First_Bill_Date__c FROM Shared_Solar_System__c WHERE Id =: nonUcbSss.Id];
        ucbSss = [SELECT First_Bill_Date__c, UCB_First_Bill_Date__c FROM Shared_Solar_System__c WHERE Id =: ucbSss.Id];
        System.assertEquals(billDate, nonUcbSss.First_Bill_Date__c, 'Invalid first bill date');
        System.assertEquals(null, nonUcbSss.UCB_First_Bill_Date__c, 'UCB first bill date should be null for non UCB project');
        System.assertEquals(billDate, ucbSss.First_Bill_Date__c, 'Invalid first bill date');
        System.assertEquals(billDate, ucbSss.UCB_First_Bill_Date__c, 'Invalid UCB first bill date');
    }

    @IsTest
    static void testFirstDateProductionBilled(){
        // Setup
        Shared_Solar_System__c sss = [SELECT Id FROM Shared_Solar_System__c LIMIT 1];
        Bill_Period__c bp = new Bill_Period__c(
            Name = 'sssA - July Bill Period 2016',
            Shared_Solar_System__c = sss.Id,
            Bill_Status__c = 'Ready to Generate',
            Bill_Date__c = Date.newInstance(2019, 7, 15)
        );
        insert bp;

        // Run test
        Test.startTest();
        new BillPeriodService().markBillPeriodsAsBillRunComplete(Date.newInstance(2019, 7, 20));
        Test.stopTest();

        List<Bill_Period__c> billPeriods = [SELECT Id FROM Bill_Period__c WHERE Bill_Status__c = 'Bill Run Complete'];
        System.assertEquals(1,billPeriods.size());

        List<Production__c> productionList = [
            SELECT Id, Credits_Transferred__c, First_Date_Production_Billed__c
            FROM Production__c
            ORDER BY Start_Date__c ASC
        ];
        System.assertEquals(bp.Bill_Date__c, productionList[0].First_Date_Production_Billed__c);
        System.assertEquals(null, productionList[1].First_Date_Production_Billed__c);
    }

    @IsTest
    private static void testCreateUCBCommissionsAfterBillPeriodUpdate() {
        BillPeriodService.commissionService =
            (PartnerCommissionService) Test.createStub(PartnerCommissionService.class, new MockPartnerCommissionService());

        BillPeriodService.uasbSelector =
            (UASBSelector) Test.createStub(UASBSelector.class, new MockUASBSelector(null, System.today()));
        BillPeriodService.uow = new fflib_SObjectUnitOfWork(
            new List<SObjectType>{
                Account.SObjectType,
                Commission_Payment__c.SObjectType
            },
            new FFLibHelperTest.MockDML()
        );
        Set<Id> oppIdsGettingBilled = new BillPeriodService().handleUCBTransfers(new List<Transfer__c>());
        System.assertEquals(1, oppIdsGettingBilled.size(),
            'Expected one UCB opportunity to be used to look for opps that need to a commission paid');
        List<SObject> updatedObjects = FFLibHelperTest.getRegisterDirtyListFromUnitOfWork(BillPeriodService.uow, 'Account');
        System.assertEquals(1, updatedObjects.size(),
            'Expected one account to be registered for update');
        System.assertEquals(System.today(), updatedObjects[0].get(Account.First_CS_Bill_Date__c),
            'Expected First CS Bill Date to be set to today, the Date on the UASB, since it was null');

        BillPeriodService.uasbSelector =
            (UASBSelector) Test.createStub(UASBSelector.class, new MockUASBSelector(System.today().addYears(-1), System.today()));
        BillPeriodService.uow = new fflib_SObjectUnitOfWork(
            new List<SObjectType>{
                Account.SObjectType,
                Commission_Payment__c.SObjectType
            },
            new FFLibHelperTest.MockDML()
        );
        oppIdsGettingBilled = new BillPeriodService().handleUCBTransfers(new List<Transfer__c>());
        System.assertEquals(1, oppIdsGettingBilled.size(),
            'Expected one UCB opportunity to be used to look for opps that need to a commission paid');
        updatedObjects = FFLibHelperTest.getRegisterDirtyListFromUnitOfWork(BillPeriodService.uow, 'Account');
        System.assertEquals(0, updatedObjects.size(),
            'Expected no accounts to be registered for update, since they already had a First CS Bill Date');
    }

    public class MockUASBSelector extends MockProvider {
        private Date firstCSBillDate;
        private Date uasbDate;
        public MockUASBSelector(Date firstCSBillDate, Date uasbDate) {
            this.firstCSBillDate = firstCSBillDate;
            this.uasbDate = uasbDate;
        }
        public override Object handleMethodCall(MethodCall methodCall) {
            switch on methodCall.stubbedMethodName {
                when 'getUasbsByTransfer' {
                    sfab_FabricatedSObject fabbedAccount = new sfab_FabricatedSObject(Account.class);
                    fabbedAccount.setField(Account.Id, Util.getFakeId(Account.SObjectType));
                    fabbedAccount.setField(Account.First_CS_Bill_Date__c, firstCSBillDate);

                    sfab_FabricatedSObject fabbedOpp = new sfab_FabricatedSObject(Opportunity.class);
                    fabbedOpp.setField(Opportunity.Id, Util.getFakeId(Opportunity.SObjectType));
                    fabbedOpp.setField(Opportunity.AccountId, Util.getFakeId(Account.SObjectType));
                    fabbedOpp.setParent('Account', fabbedAccount);

                    sfab_FabricatedSObject fabbedUAS = new sfab_FabricatedSObject(Utility_Account_Subscription__c.class);
                    fabbedUAS.setParent('Opportunity__r', fabbedOpp);

                    sfab_FabricatedSObject fabbedUASB = new sfab_FabricatedSObject(UASB__c.class);
                    fabbedUASB.setField(UASB__c.Date__c, uasbDate);
                    fabbedUASB.setField(UASB__c.Utility_Account_Subscription__c, Util.getFakeId(Utility_Account_Subscription__c.SObjectType));
                    fabbedUASB.setParent('Utility_Account_Subscription__r', fabbedUAS);
                    return new List<UASB__c>{(UASB__c) fabbedUASB.toSObject()};
                }
            }
            return null;
        }
    }

    // PartnerCommissionServiceTest tests the PartnerCommissionService, so we mock it out here.
    public class MockPartnerCommissionService extends MockProvider {
        public override Object handleMethodCall(MethodCall methodCall) {
            return null;
        }
    }

}