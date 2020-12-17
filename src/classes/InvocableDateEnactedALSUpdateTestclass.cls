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

    public static Schedule_Z__c getReplacedScheduleZ() {
        Date retiredDate = Date.newInstance(2020,01,08);
        Schedule_Z__c scheduleZ = new Schedule_Z__c(
            Id = 'a3z0a000000pJnEAAU',
            Date_Schedule_Z_Retired_by_Utility__c = retiredDate,
            Shared_Solar_System__c = 'a1J0a000008l0FdEAI'
        );
        return scheduleZ;
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
            String retiredDate = '2020-01-08';
            // 2 UASes with a Date Removed From Project from an ALS
            // 1 UAS with a Date Removed From Project from a finalled UAL
            String szs = '[{"attributes" : {"type" : "Schedule_Z_Subscription__c","url" : "/services/data/v47.0/sobjects/Schedule_Z_Subscription__c/a540a000000UxtGAAA"},' +
                '"Id" : "a540a000000UxtGAAA",' +
                '"Name" : "szsA",' +
                '"Utility_Account_Subscription__c": "a1d0a000001npymAAA" ,' +
                    '"Utility_Account_Subscription__r": {"attributes" : {"type" : "Utility_Account_Subscription__c","url" : "/services/data/v47.0/sobjects/Utility_Account_Subscription__c/a1d0a000001npymAAA"},' +
                    '"Id" : "a1d0a000001npymAAA",' +
                    '"Date_Removed_from_Project__c" : "'+ retiredDate + '"' +
                    '},' +
                '"Schedule_Z__c": "a3z0a000000pJnEAAU",' +
                    '"Schedule_Z__r": {"attributes": {"type" : "Schedule_Z__c","url" : "/services/data/v47.0/sobjects/Schedule_Z__c/a3z0a000000pJnEAAU"}, ' +
                    '"Id": "a3z0a000000pJnEAAU",' +
                    '"Date_Schedule_Z_Retired_by_Utility__c": "'+ retiredDate + '"' +
                    '}'+
                '},' +
                '{"attributes" : {"type" : "Schedule_Z_Subscription__c","url" : "/services/data/v47.0/sobjects/Schedule_Z_Subscription__c/a540a000000UxtGBBB"},' +
                '"Id" : "a540a000000UxtGBBB",' +
                '"Name" : "szsB",' +
                '"Utility_Account_Subscription__c": "a1d0a000001npymBBB" ,' +
                    '"Utility_Account_Subscription__r": {"attributes" : {"type" : "Utility_Account_Subscription__c","url" : "/services/data/v47.0/sobjects/Utility_Account_Subscription__c/a1d0a000001npymBBB"},' +
                    '"Id" : "a1d0a000001npymBBB",' +
                    '"Date_Removed_from_Project__c" : "' + retiredDate + '"' +
                    '},' +
                '"Schedule_Z__c": "a3z0a000000pJnEAAU",' +
                    '"Schedule_Z__r": {"attributes": {"type" : "Schedule_Z__c","url" : "/services/data/v47.0/sobjects/Schedule_Z__c/a3z0a000000pJnEAAU"}, ' +
                    '"Id": "a3z0a000000pJnEAAU",' +
                    '"Date_Schedule_Z_Retired_by_Utility__c": "' + retiredDate + '"' +
                    '}' +
                '},' +
                '{"attributes" : {"type" : "Schedule_Z_Subscription__c","url" : "/services/data/v47.0/sobjects/Schedule_Z_Subscription__c/a540a000000UxtGCCC"},' +
                '"Id" : "a540a000000UxtGCCC",' +
                '"Name" : "szsC",' +
                '"Utility_Account_Subscription__c": "a1d0a000001npymCCC" ,' +
                    '"Utility_Account_Subscription__r": {"attributes" : {"type" : "Utility_Account_Subscription__c","url" : "/services/data/v47.0/sobjects/Utility_Account_Subscription__c/a1d0a000001npymCCC"},' +
                    '"Id" : "a1d0a000001npymCCC",' +
                    '"Date_Removed_from_Project__c" : "2019-11-01"' +
                    '},' +
                '"Schedule_Z__c": "a3z0a000000pJnEAAU",' +
                    '"Schedule_Z__r": {"attributes": {"type" : "Schedule_Z__c","url" : "/services/data/v47.0/sobjects/Schedule_Z__c/a3z0a000000pJnEAAU"}, ' +
                    '"Id": "a3z0a000000pJnEAAU",' +
                    '"Date_Schedule_Z_Retired_by_Utility__c": "' + retiredDate + '"' +
                    '}' +
                '}]';

            switch on methodCall.stubbedMethodName {
                when 'getRetiredALSSFromALS' {
                    return (List<Schedule_Z_Subscription__c>) JSON.deserialize(szs, List<Schedule_Z_Subscription__c>.class);
                }
            }
            return null;
        }
    }

    public class MockOpportunitiesSelector extends MockProvider {
        public MockOpportunitiesSelector() {
        }
        public override Object handleMethodCall(MethodCall methodCall) {
            String retiredDate = '2020-01-08';
            String newRetiredDate = '2020-01-12';
            String opps = '[{"attributes" : {"type" : "Opportunity","url" : "/services/data/v47.0/sobjects/Opportunity/006e000000MJSVoAAP"},' +
                '"AccountId":"001j0000011mR6LAAU",' +
                '"Id" : "006e000000MJSVoAAA",' +
                '"Name" : "oppA",' +
                '"Date_Removed_From_Project__c": "2020-04-02",' +
                '"Shared_Solar_System__c": "a1J0a000008l0FdEAI",' +
                '"Utility_Account_Subscriptions__r": {' +
                '    "totalSize": 2,' +
                '       "done": true,' +
                '       "records": ' +
                '           [' +
                '               {' +
                '                   "attributes": {' +
                '                       "type": "Utility_Account_Subscription__c",' +
                '                       "url": "/services/data/v48.0/sobjects/Utility_Account_Subscription__c/a1d0a000001npymAAA"' +
                '                   },' +
                '                   "Opportunity__c": "006e000000MJSVoAAA",' +
                '                   "Id": "a1d0a000001npymAAA",' +
                '                   "Date_Removed_From_Project__c": "' + newRetiredDate + '"' +
                '               },' +
                '               {' +
                '                   "attributes": {' +
                '                       "type": "Utility_Account_Subscription__c",' +
                '                       "url": "/services/data/v48.0/sobjects/Utility_Account_Subscription__c/a1d0a000001npymBBB"' +
                '                   },' +
                '                   "Opportunity__c": "006e000000MJSVoAAA",' +
                '                   "Id": "a1d0a000001npymBBB",' +
                '                   "Date_Removed_From_Project__c": "2020-04-02"' +
                '               }' +
                '           ]' +
                '   }' +
                '}, '  +
                '{"attributes" : {"type" : "Opportunity","url" : "/services/data/v47.0/sobjects/Opportunity/006e000000MJSVoBBB"},' +
                '"AccountId":"001j0000011mR6LBBB",' +
                '"Id" : "006e000000MJSVoBBB",' +
                '"Name" : "oppB",' +
                '"Date_Removed_From_Project__c": "' + retiredDate + '",' +
                '"Shared_Solar_System__c": "a1J0a000008l0FdEAI",' +
                '"Utility_Account_Subscriptions__r": {' +
                '    "totalSize": 1,' +
                '       "done": true,' +
                '       "records": ' +
                '           [' +
                '               {' +
                '                   "attributes": {' +
                '                       "type": "Utility_Account_Subscription__c",' +
                '                       "url": "/services/data/v48.0/sobjects/Utility_Account_Subscription__c/a1d0a000001npymCCC"' +
                '                   },' +
                '                   "Opportunity__c": "006e000000MJSVoBBB",' +
                '                   "Id": "a1d0a000001npymCCC",' +
                '                   "Date_Removed_From_Project__c": "' + newRetiredDate + '"' +
                '               }' +
                '           ]' +
                '   }' +
                '}]';

            switch on methodCall.stubbedMethodName {
                when 'selectRetiredOpportunities' {
                    return (List<Opportunity>) JSON.deserialize(opps, List<Opportunity>.class);
                }
            }


            return null;
        }
    }

    public class MockAccountSelector extends MockProvider {
        public MockAccountSelector() {
        }
        public override Object handleMethodCall(MethodCall methodCall) {
            String retiredDate = '2020-01-08';
            String newRetiredDate = '2020-01-12';
            String accts = '[{"attributes" : {"type" : "Account","url" : "/services/data/v47.0/sobjects/Account/001e000001Zo2EMAAA"},' +
                '"Id" : "001e000001Zo2EMAAA",' +
                '"Name" : "Account A",' +
                '"Date_Removed_From_Project__c": "2020-04-02",' +
                '"Opportunities": {' +
                '    "totalSize": 2,' +
                '       "done": true,' +
                '       "records": ' +
                '           [' +
                '               {' +
                '                   "attributes": {' +
                '                       "type": "Opportunity",' +
                '                       "url": "/services/data/v48.0/sobjects/Opportunity/006e000000MJSVoAAA"' +
                '                   },' +
                '                   "Id": "006e000000MJSVoAAA",' +
                '                   "Date_Removed_From_Project__c": "' + newRetiredDate + '"' +
                '               },' +
                '               {' +
                '                   "attributes": {' +
                '                       "type": "Opportunity",' +
                '                       "url": "/services/data/v48.0/sobjects/Opportunity/006e000000MJSVoBBB"' +
                '                   },' +
                '                   "Id": "006e000000MJSVoAAA",' +
                '                   "Date_Removed_From_Project__c": "2020-04-02"' +
                '               }' +
                '           ]' +
                '   }' +
                '},' +
                '{"attributes" : {"type" : "Account","url" : "/services/data/v47.0/sobjects/Account/001e000001Zo2EMBBB"},' +
                '"Id" : "001e000001Zo2EMBBB",' +
                '"Name" : "Account B",' +
                '"Date_Removed_From_Project__c": "' + retiredDate + '",' +
                '"Opportunities": {' +
                '    "totalSize": 1,' +
                '       "done": true,' +
                '       "records": ' +
                '           [' +
                '               {' +
                '                   "attributes": {' +
                '                       "type": "Opportunity",' +
                '                       "url": "/services/data/v48.0/sobjects/Opportunity/006e000000MJSVoCCC"' +
                '                   },' +
                '                   "Id": "006e000000MJSVoCCC",' +
                '                   "Date_Removed_From_Project__c": "' + newRetiredDate + '"' +
                '               }' +
                '           ]' +
                '   }' +
                '}]';


            switch on methodCall.stubbedMethodName {
                when 'getRetiredAccounts' {
                    return (List<Account>) JSON.deserialize(accts, List<Account>.class);
                }
            }
            return null;
        }
    }
}