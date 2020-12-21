/**
 * Created by SarahRenfro on 12/15/2020.
 */

@IsTest

private class InvocableDateEnactedALSUpdateTestclass {
    @TestSetup
    static void testSetup() {
        SubscriptionManagementServiceTest.setupData();
    }

    /****************
    * UNIT TESTS
    *****************/

    @IsTest
    static void testFindRetiredUASes() {
        useMocks();
        InvocableDateEnactedALSUpdate invocableService = new InvocableDateEnactedALSUpdate();
        List<Utility_Account_Subscription__c> checkUASes = invocableService.findRetiredUASes(getReplacedScheduleZ().Id, Date.newInstance(2020, 01, 08), Date.newInstance(2020, 01, 12) );

        System.assertEquals(2, checkUASes.size(), 'Only the UASes with a matching Date Removed From Project get updated.');
        System.assertEquals(Date.newInstance(2020, 01, 12), checkUASes[0].Date_Removed_from_Project__c, 'UAS updated with new Date Removed From Utility from ALS');
        System.assertEquals(Date.newInstance(2020, 01, 12), checkUASes[1].Date_Removed_from_Project__c, 'UAS updated with new Date Removed From Utility from ALS');

    }

    @IsTest
    static void testFindRetiredOpportunities() {
        useMocks();
        InvocableDateEnactedALSUpdate invocableService = new InvocableDateEnactedALSUpdate();
        List<Opportunity> checkOpps = invocableService.findRetiredOpportunities();

        System.assertEquals(1, checkOpps.size(), 'Only update Opportunities where the UAS change in Date Removed From Project resulted in new max Date Removed From Project');
        System.assertEquals(Date.newInstance(2020, 01, 12), checkOpps[0].Date_Removed_from_Project__c, 'Opp is updated with Date Removed From Project from UAS');
    }

    @IsTest
    static void testFindRetiredAccounts() {
        useMocks();
        InvocableDateEnactedALSUpdate invocableService = new InvocableDateEnactedALSUpdate();
        List<Account> checkAccounts = invocableService.findRetiredAccounts();


        System.assertEquals(1, checkAccounts.size(), 'Only update Accounts where the Opp change in Date Removed From Project resulted in a new max Date Removed From Project');
        System.assertEquals(Date.newInstance(2020, 01, 12), checkAccounts[0].Date_Removed_from_Project__c, 'Account is updated with Date Removed from Project from Opp');
    }

    /**
     * SYSTEM TEST
    */

    @IsTest
    static void testHappyPath() {
        Shared_Solar_System__c sss = [
            SELECT Id
            FROM Shared_Solar_System__c
            LIMIT 1
        ];

        Date oldRetiredDate = Date.newInstance(2020, 01, 08);
        Date newRetiredDate = Date.newInstance(2020, 01, 12);

        Id parentAccountRT =
            Schema.SObjectType.Account.getRecordTypeInfosByName().get('Parent Account').getRecordTypeId();

        Account parentAccount = new Account(
            Name = 'Parent Account',
            RecordTypeId = parentAccountRT
        );
        insert parentAccount;

        Account propertyAccount = new Account(
            Name = 'Property Account',
            Parent_Account__c = parentAccount.Id,
            Date_Removed_from_Project__c = oldRetiredDate
        );
        insert propertyAccount;

        Opportunity opp = new Opportunity(
            Name = 'Opportunity A',
            AccountId = propertyAccount.Id,
            Date_Removed_from_Project__c = oldRetiredDate,
            Shared_Solar_System__c = sss.Id,
            StageName = 'Complete',
            CloseDate = System.today()
        );
        insert opp;

        Utility_Account_Log__c ual =
            new Utility_Account_Log__c(Name = '0000234',
                Account__c = propertyAccount.Id,
                Annual_Cost_of_Electricity__c = 10000,
                Name_on_Account__c = 'sarah testcase');
        insert ual;

        Utility_Account_Subscription__c uas =
            new Utility_Account_Subscription__c(Name = '0000234',
                Utility_Account_Log__c = ual.Id,
                Opportunity__c = opp.Id,
                Next_Schedule_Z_Status__c = 'Inactive Subscription',
                Date_Removed_from_Project__c = oldRetiredDate
            );
        insert uas;

        Schedule_Z__c enactedALS = new Schedule_Z__c(
            Name = 'Enacted ALS',
            Shared_Solar_System__c = sss.Id,
            Status__c = 'Enacted By Utility',
            Date_Enacted_by_Utility__c = oldRetiredDate
        );

        Schedule_Z__c billingALS = new Schedule_Z__c(
            Name = 'Billing ALS',
            Shared_Solar_System__c = sss.Id,
            Status__c = 'Billing',
            Date_Schedule_Z_Retired_by_Utility__c = oldRetiredDate
        );

        insert new List<Schedule_Z__c>{enactedALS, billingALS};
        List<Id> alsList = new List<Id>{enactedALS.Id, billingALS.Id};

        Schedule_Z_Subscription__c alss = new Schedule_Z_Subscription__c(
            Schedule_Z__c = billingALS.Id,
            Utility_Account_Subscription__c = uas.Id,
            Number_of_Decimal_Places__c = 4,
            Customer_Subscription_kW_DC__c = 5,
            System_Size_kW_DC__c = 100
        );
        insert alss;

        enactedALS.Date_Enacted_by_Utility__c = newRetiredDate;
        update enactedALS;

        InvocableDateEnactedALSUpdate.updateDateRemovedFromProject(new List<List<Id>>{alsList});

        Schedule_Z__c checkALS = [
            SELECT Id, Date_Schedule_Z_Retired_by_Utility__c
            FROM Schedule_Z__c
            WHERE Status__c = 'Billing'
            LIMIT 1
        ];

        System.assertEquals(newRetiredDate, checkALS.Date_Schedule_Z_Retired_by_Utility__c, 'Billing ALS should be updated with "Date Enacted By Utility" from Enacted ALS');

        Utility_Account_Subscription__c checkUAS = [
            SELECT Id, Date_Removed_from_Project__c
            FROM Utility_Account_Subscription__c
            LIMIT 1
        ];
        System.assertEquals(newRetiredDate, checkUAS.Date_Removed_from_Project__c, 'UAS should be updated with new Date Removed from Project from retired ALS');

        Opportunity checkOpp = [
            SELECT Id, Date_Removed_from_Project__c
            FROM Opportunity
            LIMIT 1
        ];
        System.assertEquals(newRetiredDate, checkOpp.Date_Removed_from_Project__c, 'Opp should be updated with new Date Removed from Project from UAS');


        Account checkAccount = [
            SELECT Id, Date_Removed_from_Project__c
            FROM Account
            WHERE Id = :propertyAccount.Id
        ];
        System.assertEquals(newRetiredDate, checkAccount.Date_Removed_from_Project__c, 'Account should be updated with new Date Removed from Project from Opportunity');
    }

    /***************************
     * MOCKS & HELPER METHODS
    ***************************/

    private static Schedule_Z__c getReplacedScheduleZ() {
        Date retiredDate = Date.newInstance(2020,01,08);
        Schedule_Z__c scheduleZ = new Schedule_Z__c(
            Id = 'a3z0a000000pJnEAAU',
            Date_Schedule_Z_Retired_by_Utility__c = retiredDate,
            Shared_Solar_System__c = 'a1J0a000008l0FdEAI'
        );
        return scheduleZ;
    }
    private static sfab_FabricatedSObject getAcct(Date acctDateRemoved, Date dateRemovedFromProject, Date otherRemovedDate) {
        sfab_FabricatedSObject fabbedAcct = new sfab_FabricatedSObject(Account.class);
        fabbedAcct.setField(Account.Date_Removed_from_Project__c, acctDateRemoved);
        List<sfab_FabricatedSObject> oppList = new List<sfab_FabricatedSObject>{
            getOpp(dateRemovedFromProject, dateRemovedFromProject, null)
        };
        if (otherRemovedDate != null) {
            oppList.add(getOpp(otherRemovedDate, otherRemovedDate, null));
        }
        fabbedAcct.setChildren('Opportunities', oppList);
        return fabbedAcct;
    }

    private static sfab_FabricatedSObject getOpp(Date oppDateRemoved, Date dateRemovedFromProject, Date otherDateRemoved) {
        sfab_FabricatedSObject fabbedOpp = new sfab_FabricatedSObject(Opportunity.class);
        fabbedOpp.setField(Opportunity.Date_Removed_from_Project__c, oppDateRemoved);
        fabbedOpp.setField(Opportunity.StageName, 'Complete');
        fabbedOpp.setField(Opportunity.CloseDate, System.today());
        //if the opp date removed = dateRemoved, only need one uas
        List<sfab_FabricatedSObject> uasList = new List<sfab_FabricatedSObject>{
            getUAS(dateRemovedFromProject)
        };
        if (otherDateRemoved != null) {
            uasList.add(getUAS(otherDateRemoved));
        }
        fabbedOpp.setChildren('Utility_Account_Subscriptions__r', uasList);
        return fabbedOpp;
    }

    private static sfab_FabricatedSObject getUAS(Date dateRemovedFromProject) {
        sfab_FabricatedSObject fabbedUAS = new sfab_FabricatedSObject(Utility_Account_Subscription__c.class);
        fabbedUAS.setField(Utility_Account_Subscription__c.Date_Removed_from_Project__c, dateRemovedFromProject);
        return fabbedUAS;
    }
    private static sfab_FabricatedSObject getALS(Date dateRemovedFromProject) {
        sfab_FabricatedSObject fabbedALS = new sfab_FabricatedSObject(Schedule_Z__c.class);
        fabbedALS.setField(Schedule_Z__c.Date_Schedule_Z_Retired_by_Utility__c, dateRemovedFromProject);
        return fabbedALS;
    }
    private static sfab_FabricatedSObject getSZS(Date uasDateRemoved, Date alsDateRemoved) {
        sfab_FabricatedSObject fabbedSZS = new sfab_FabricatedSObject(Schedule_Z_Subscription__c.class);
        fabbedSZS.setParent('Utility_Account_Subscription__r', getUAS(uasDateRemoved));
        fabbedSZS.setParent('Schedule_Z__r', getALS(alsDateRemoved));
        return fabbedSZS;
    }

    private static void useMocks() {
        InvocableDateEnactedALSUpdate.szsSelector = (ScheduleZSubscriptionSelector) Test.createStub(ScheduleZSubscriptionSelector.class, new MockScheduleZSubscriptionSelector());
        InvocableDateEnactedALSUpdate.oppSelector = (OpportunitiesSelector) Test.createStub(OpportunitiesSelector.class, new MockOpportunitiesSelector());
        InvocableDateEnactedALSUpdate.acctSelector = (AccountsSelector) Test.createStub(AccountsSelector.class, new MockAccountSelector());
    }

    public class MockScheduleZSubscriptionSelector extends MockProvider {
        public MockScheduleZSubscriptionSelector() {
        }
        public override Object handleMethodCall(MethodCall methodCall) {
            List<Schedule_Z_Subscription__c> szsList = new List<Schedule_Z_Subscription__c>{
                (Schedule_Z_Subscription__c) getSZS(Date.newInstance(2020, 1, 8), Date.newInstance(2020, 1, 8)).toSObject(),
                (Schedule_Z_Subscription__c) getSZS(Date.newInstance(2020, 1, 8), Date.newInstance(2020, 1, 8)).toSObject(),
                (Schedule_Z_Subscription__c) getSZS(Date.newInstance(2019, 11, 1), Date.newInstance(2020, 1, 8)).toSObject()
            };
            return szsList;
        }
    }


    public class MockOpportunitiesSelector extends MockProvider {
        public MockOpportunitiesSelector() {
        }
        public override Object handleMethodCall(MethodCall methodCall) {
            Date oppRemovedDate = Date.newInstance(2020, 1, 8);
            Date uasRemovedDate = Date.newInstance(2020, 1, 12);
            Date otherRemovedDate = Date.newInstance(2020, 04, 02);

            List<Opportunity> oppList = new List<Opportunity>{
                (Opportunity) getOpp(oppRemovedDate, uasRemovedDate, null).toSObject(),
                (Opportunity) getOpp(otherRemovedDate, uasRemovedDate, otherRemovedDate).toSObject()
            };
            return oppList;
        }
    }

    public class MockAccountSelector extends MockProvider {
        public MockAccountSelector() {
        }
        public override Object handleMethodCall(MethodCall methodCall) {
            Date acctRemovedDate = Date.newInstance(2020, 1, 8);
            Date oppRemovedDate = Date.newInstance(2020, 1, 12);
            Date otherRemovedDate = Date.newInstance(2020, 04, 02);

            List<Account> acctList = new List<Account>{
                (Account) getAcct(acctRemovedDate, oppRemovedDate, null).toSObject(),
                (Account) getAcct(otherRemovedDate, oppRemovedDate, otherRemovedDate).toSObject()
            };
          return acctList;

        }
    }
}