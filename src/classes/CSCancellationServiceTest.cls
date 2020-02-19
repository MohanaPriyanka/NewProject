/**
 * Created by Sarah Renfro on 12/6/2018.
 */

@IsTest
public with sharing class CSCancellationServiceTest {
    @TestSetup public static void testSetup() {
        CustomerCommunicationHandlerTest.setupData();
    }

    public static void createBills(Date billDate, Id sssID){
        Schedule_Z__c scheduleZ1 = new Schedule_Z__c(
            Name = '18-0515 Oxford Barrett St. P1',
            Shared_Solar_System__c = sssID,
            Status__c = 'Billing'
        );

        insert scheduleZ1;

        Bill_Period__c bpA1 = new Bill_Period__c(
            Name = 'sssA - March 2016',
            Shared_Solar_System__c = sssID,
            Bill_Date__c = billDate
        );
        insert bpA1;

        Production__c prodA1 = new Production__c(
            Name = 'sssA March Production',
            Shared_Solar_System__c = sssID,
            Start_Date__c = billDate.addMonths(-1),
            End_Date__c = billDate,
            Production_kWh__c = 160000,
            Credits_Generated__c = 36000
        );
        insert prodA1;

        Transfer__c transferA1 = new Transfer__c(
            Name = 'Main Transfer - sssA March',
            Bill_Period__c = bpA1.Id,
            Date_of_Transfer__c = billDate,
            Shared_Solar_System__c = sssID,
            Transfer_Type__c = 'Main',
            Allocation_Schedule__c = scheduleZ1.Id,
            Attempted_Transfer__c = 36000,
            Attempted_kWh_Transfer__c = 160000,
            Transfer_Amount__c = 36000,
            Default_Credit_Value__c = 0.2429
        );
        insert transferA1;

        TestBillCreationandPayment.runBillPeriod(new List<Id>{bpA1.Id});
    }

    @IsTest static void testOverdueAccounts() {
        //Set up delinquent customers
        CustomerCommunicationHandlerTest.setDaysPastDue(System.Today().addDays(-68), 10);

        Test.startTest();
        CSCancellationService.handleOverdueAccounts();
        Test.stopTest();

        List<Account> propertyAccounts = [
            SELECT Id, Cancellation_Request_Date__c, Cancellation_Comments__c, Cancellation_Reason__c
            FROM Account
            WHERE Parent_Account__c != null
        ];

        for (Account acct : propertyAccounts) {
            System.assertNotEquals(null, acct.Cancellation_Request_Date__c);
            System.assertEquals('Automated Cancellation', acct.Cancellation_Comments__c);
            System.assertEquals('Lack of Payment', acct.Cancellation_Reason__c);
        }
    }

    @IsTest static void testOverdueAnchors() {
        Util.disableTrigger('Disable_OpportunityTrigger__c');
        List<Opportunity> opps = [SELECT Id FROM Opportunity];
        for (Opportunity opp : opps) {
            opp.Customer_Group__c = 'Anchor';
        }
        update opps;
        Util.enableTrigger('Disable_OpportunityTrigger__c');

        CustomerCommunicationHandlerTest.setDaysPastDue(System.Today().addDays(-68), 10);

        Test.startTest();
        CSCancellationService.handleOverdueAccounts();
        Test.stopTest();

        List<Account> propertyAccounts = [
            SELECT Id, Cancellation_Request_Date__c, Cancellation_Comments__c, Cancellation_Reason__c
            FROM Account
            WHERE Parent_Account__c != null
        ];

        Set<Id> accountIds = new Set<Id>();
        for (Account acct : propertyAccounts) {
            System.assertEquals(null, acct.Cancellation_Request_Date__c);
            System.assertEquals(null, acct.Cancellation_Reason__c);
            accountIds.add(acct.Id);
        }

        List<Account> allAccounts = [SELECT Id, Cancellation_Request_Date__c FROM Account WHERE Id != :accountIds];
        System.assertNotEquals(0, allAccounts.size());
        for (Account a : allAccounts) {
            System.assertEquals(null, a.Cancellation_Request_Date__c);
        }
    }

    @IsTest static void testUASToInactive() {
        //Set up delinquent customers
        CustomerCommunicationHandlerTest.setDaysPastDue(System.Today().addDays(-68), 10);

        Test.startTest();
        MessagingService.onlyUseActiveTemplates = false;
        CSCancellationService.handleOverdueAccounts();
        Test.stopTest();

        List<Utility_Account_Subscription__c> uases = [
            SELECT Id, Next_Schedule_Z_Status__c, Utility_Account_Log__r.Account__r.Days_Past_Due__c
            FROM Utility_Account_Subscription__c
        ];

        for (Utility_Account_Subscription__c uas : uases) {
            if (uas.Utility_Account_Log__r.Account__r.Days_Past_Due__c > 67) {
                System.assertEquals('Inactive Subscription', uas.Next_Schedule_Z_Status__c);
            } else {
                System.assertEquals('Active Subscription', uas.Next_Schedule_Z_Status__c);
            }
        }

        System.assertEquals(0, MessagingService.emailsSent.size());
    }

    @IsTest static void testSetupDataForUASUpdateIsCorrect() {
        // Ensures all data is set up correctly
        List<Utility_Account_Log__c> ualList = [
            SELECT Id, Date_Utility_Account_Cancelled__c
            FROM Utility_Account_Log__c
        ];

        System.assertEquals(3, ualList.size());
        for (Utility_Account_Log__c ual : ualList) {
            System.assertEquals(null, ual.Date_Utility_Account_Cancelled__c);
        }

        List<Utility_Account_Subscription__c> uasList = [
            SELECT Id, Date_Removed_from_Project__c, Next_Schedule_Z_Status__c, Finaled__c
            FROM Utility_Account_Subscription__c
        ];

        System.assertEquals(3, uasList.size());
        for (Utility_Account_Subscription__c uas : uasList) {
            System.assertEquals(null, uas.Date_Removed_from_Project__c);
            System.assertEquals('Active Subscription', uas.Next_Schedule_Z_Status__c);
            System.assertEquals(false, uas.Finaled__c);
        }

        List<Case> caseList = [
            SELECT Id
            FROM Case
        ];

        System.assertEquals(0, caseList.size());
    }

    @IsTest static void testNoUASAreUpdated() {
        List<Utility_Account_Log__c> ualList = [
            SELECT Id, Date_Utility_Account_Cancelled__c
            FROM Utility_Account_Log__c
        ];

        Utility_Account_Log__c ualToUpdate = ualList[0];
        ualToUpdate.Name = 'Updated Name';
        update ualToUpdate;
        // Reassert setup data to ensure nothing has changed

        ualList = [
            SELECT Id, Date_Utility_Account_Cancelled__c
            FROM Utility_Account_Log__c
        ];

        System.assertEquals(3, ualList.size());
        for (Utility_Account_Log__c ual : ualList) {
            System.assertEquals(null, ual.Date_Utility_Account_Cancelled__c);
        }

        List<Utility_Account_Subscription__c> uasList = [
            SELECT Id, Date_Removed_from_Project__c, Next_Schedule_Z_Status__c, Finaled__c
            FROM Utility_Account_Subscription__c
        ];

        System.assertEquals(3, uasList.size());
        for (Utility_Account_Subscription__c uas : uasList) {
            System.assertEquals(null, uas.Date_Removed_from_Project__c);
            System.assertEquals('Active Subscription', uas.Next_Schedule_Z_Status__c);
            System.assertEquals(false, uas.Finaled__c);
        }

        //There should be a Partner Support case created for each corresponding account

        List<Case> caseList = [
            SELECT Id
            FROM Case
        ];

        System.assertEquals(0, caseList.size());
    }

    @IsTest static void testOneUASIsUpdated() {
        List<System_Properties__c> systemProperties = System_Properties__c.getAll().values();
        if (systemProperties.isEmpty()) {
            System_Properties__c property = new System_Properties__c(Name = 'System');
            property.Finaled_Case_Owner__c = 'Customer_Care';
            insert property;
        } else {
            systemProperties[0].Finaled_Case_Owner__c = 'Customer_Care';
            update systemProperties[0];
        }

        Utility_Account_Log__c ualToUpdate = [
            SELECT Id, Date_Utility_Account_Cancelled__c
            FROM Utility_Account_Log__c
            WHERE Account__r.Name = 'Prop Account 1'
        ];

        Date today = Date.today();

        ualToUpdate.Date_Utility_Account_Cancelled__c = today;

        update ualToUpdate;

        // Verify that the UASs associated with the UAL that wasn't updated was not affected

        List<Utility_Account_Subscription__c> uasNotUpdatedList = [
            SELECT Id, Date_Removed_from_Project__c, Next_Schedule_Z_Status__c, Finaled__c
            FROM Utility_Account_Subscription__c
            WHERE Utility_Account_Log__r.Date_Utility_Account_Cancelled__c = NULL
        ];

        // UAS with no Date on Date_Removed_from_Project__c should not be affected by update

        System.assertEquals(2, uasNotUpdatedList.size());
        for (Utility_Account_Subscription__c uas : uasNotUpdatedList) {
            System.assertEquals(null, uas.Date_Removed_from_Project__c);
            System.assertEquals('Active Subscription', uas.Next_Schedule_Z_Status__c);
            System.assertEquals(false, uas.Finaled__c);
        }

        List<Utility_Account_Subscription__c> uasUpdatedList = [
            SELECT Id, Date_Removed_from_Project__c, Next_Schedule_Z_Status__c, Finaled__c
            FROM Utility_Account_Subscription__c
            WHERE Utility_Account_Log__r.Date_Utility_Account_Cancelled__c != NULL
        ];

        System.assertEquals(1, uasUpdatedList.size());
        for (Utility_Account_Subscription__c uas : uasUpdatedList) {
            System.assertEquals(today, uas.Date_Removed_from_Project__c);
            System.assertEquals('Inactive Subscription', uas.Next_Schedule_Z_Status__c);
            System.assertEquals(true, uas.Finaled__c);
        }

        //There should be a Partner Support case created for each corresponding account

        List<Case> caseList = [
            SELECT Id
            FROM Case
        ];

        System.assertEquals(1, caseList.size());
    }

    @IsTest static void testAllUASAreUpdated() {
        List<System_Properties__c> systemProperties = System_Properties__c.getAll().values();
        if (systemProperties.isEmpty()) {
            System_Properties__c property = new System_Properties__c(Name = 'System');
            property.Finaled_Case_Owner__c = 'Customer_Care';
            insert property;
        } else {
            systemProperties[0].Finaled_Case_Owner__c = 'Customer_Care';
            update systemProperties[0];
        }

        List<Utility_Account_Log__c> ualList = [
            SELECT Id, Date_Utility_Account_Cancelled__c
            FROM Utility_Account_Log__c
        ];

        System.assertEquals(3, ualList.size());

        Date today = Date.today();

        for (Utility_Account_Log__c ual : ualList) {
            ual.Date_Utility_Account_Cancelled__c = today;
        }

        update ualList;

        List<Utility_Account_Subscription__c> uasUpdatedList = [
            SELECT Id, Date_Removed_from_Project__c, Next_Schedule_Z_Status__c, Finaled__c
            FROM Utility_Account_Subscription__c
            WHERE Utility_Account_Log__r.Date_Utility_Account_Cancelled__c != NULL
        ];

        System.assertEquals(3, uasUpdatedList.size());

        for (Utility_Account_Subscription__c uas : uasUpdatedList) {
            System.assertEquals(today, uas.Date_Removed_from_Project__c);
            System.assertEquals('Inactive Subscription', uas.Next_Schedule_Z_Status__c);
            System.assertEquals(true, uas.Finaled__c);
        }

        //There should be a Partner Support case created for each corresponding account

        List<Case> caseList = [
            SELECT Id
            FROM Case
        ];

        System.assertEquals(3, caseList.size());
    }

    @IsTest static void setupDataForOppCancellationIsCorrect() {
        // Assert all Opps are active
        List<Opportunity> oppList = [
            SELECT Id, StageName, Product_Line__c
            FROM Opportunity
        ];

        System.assertEquals(3, oppList.size());
        for (Opportunity opp : oppList) {
            System.assertEquals('Complete', opp.StageName);
            System.assertEquals('Community Solar', opp.Product_Line__c);
        }

        // Assert all Sched Z Subscriptions are Active
        List<Schedule_Z_Subscription__c> schedZList = [
            SELECT Id, Schedule_Z_Status__c, Schedule_Z__c
            FROM Schedule_Z_Subscription__c
        ];

        List<Schedule_Z__c> sz = [SELECT Id, Name FROM Schedule_Z__c];

        System.assertEquals(3, schedZList.size());
        for (Schedule_Z_Subscription__c schedZ : schedZList) {
            System.assertEquals('Billing', schedZ.Schedule_Z_Status__c);
        }

        //Assert all UAS have no reason for cancellation

        List<Utility_Account_Subscription__c> uasList = [
            SELECT Id, Reason_for_Cancellation__c
            FROM Utility_Account_Subscription__c
        ];

        System.assertEquals(3, uasList.size());
        for (Utility_Account_Subscription__c uas : uasList) {
            System.assertEquals(null, uas.Reason_for_Cancellation__c);
        }

        // Assert Accounts have no outstanding balance.  There should be a total of 6 accounts - 3 property and 3 parent.

        List<Account> acctList = [
            SELECT Id, Total_Outstanding_Balance_Merge__c
            FROM Account
        ];

        System.assertEquals(6, acctList.size());
        for (Account acct : acctList) {
            System.assertEquals(0, acct.Total_Outstanding_Balance_Merge__c);
        }

        // Assert there are no Schedule Z's that qualify for cancellation

        Date sixMonthsAgo = Date.Today().addDays(-181);

        List<Schedule_Z_Subscription__c> qualifyingSchedZList = [
            SELECT Id, Utility_Account_Subscription__r.Opportunity__c
            FROM Schedule_Z_Subscription__c
            WHERE Utility_Account_Subscription__r.Next_Schedule_Z_Status__c = 'Inactive Subscription'
            AND (Schedule_Z_Status__c = 'Replaced with newly Enacted Schedule Z'
            OR Utility_Account_Subscription__r.Reason_for_Cancellation__c = 'Utility Account Cancelled')
            AND (Utility_Account_Subscription__r.Utility_Account_Log__r.Account__r.Total_Outstanding_Balance_Merge__c = 0
            OR Utility_Account_Subscription__r.Utility_Account_Log__r.Account__r.Last_Bill_Send_Date_New_Charges__c > :sixMonthsAgo)
            AND Utility_Account_Subscription__r.Opportunity__r.StageName != 'Cancelled'
        ];

        System.assertEquals(0, qualifyingSchedZList.size());
    }

    @IsTest static void testNoOppsAreCancelled() {
        // Run method and assert that no opportunities are cancelled because there are no system bills yet
        List<System_Bill__c> systemBills = [
            SELECT Id
            FROM System_Bill__c
        ];
        System.assertEquals(0, systemBills.size());

        Test.startTest();
        CSCancellationService.cancelOpportunities(CSCancellationService.getOpportunitiesToCancel());
        Test.stopTest();

        List<Opportunity> oppList = [
            SELECT Id, StageName
            FROM Opportunity
        ];

        System.assertEquals(3, oppList.size());
        for (Opportunity opp : oppList) {
            System.assertEquals('Complete', opp.StageName);
        }
    }

    @IsTest static void testOppCancellationOnWaitlistCancellation() {
        // Delete Schedule Z Subscriptions to make it look like the customer has not been subscribed
        List<Schedule_Z_Subscription__c> szses = [
            SELECT Id
            FROM Schedule_Z_Subscription__c
        ];
        delete szses;

        // Set UASes to inactive, since a waitlist customer wouldn't have an active subscription
        List<Utility_Account_Subscription__c> uases = [
            SELECT Id, Opportunity__c
            FROM Utility_Account_Subscription__c
        ];
        for (Utility_Account_Subscription__c uas : uases) {
            uas.Next_Schedule_Z_Status__c = 'Inactive Subscription';
        }
        update uases;

        List<Opportunity> oppList = [
            SELECT Id, Account.Id, Account.Cancellation_Request_Date__c, StageName
            FROM Opportunity
        ];
        System.assertEquals(3, oppList.size());

        List<Account> accounts = new List<Account>();
        for (Opportunity opportunity : oppList) {
            System.assertEquals(null, opportunity.Account.Cancellation_Request_Date__c);
            System.assertEquals('Complete', opportunity.StageName);
            accounts.add(
                new Account(
                    Id = opportunity.Account.Id,
                    Cancellation_Reason__c = 'Other',
                    Cancellation_Request_Date__c = Date.today()
                )
            );
        }
        // Simulate the customer requesting their account be cancelled, which should set the UAS to Inactive Subscription
        update accounts;

        Map<Id, Opportunity> opportunityMap = new Map<Id, Opportunity>(OpportunitiesSelector.selectAllCompleteCSWithUASesAndSystemBills());
        for (Opportunity opportunity : opportunityMap.values()) {
            System.assert(Opportunities.isCancelledWaitlist(opportunityMap.get(opportunity.Id)));
        }

        Test.startTest();
        CSCancellationService.cancelOpportunities(CSCancellationService.getOpportunitiesToCancel());
        Test.stopTest();

        oppList = [
            SELECT Id, StageName
            FROM Opportunity
        ];

        System.assertEquals(3, oppList.size());
        for (Opportunity opp : oppList) {
            System.assertEquals('Cancelled', opp.StageName);
        }
    }

    // Transferring subscriptions shouldn't be cancelled, even if they are on a waitlist.
    @IsTest static void testOppCancellationOnWaitlistButTransferring() {
        // Delete Schedule Z Subscriptions to make it look like the customer has not been subscribed
        List<Schedule_Z_Subscription__c> szses = [
            SELECT Id
            FROM Schedule_Z_Subscription__c
        ];
        delete szses;

        // Set UASes to inactive, since a waitlist customer wouldn't have an active subscription, and transferring to test
        List<Utility_Account_Subscription__c> uases = [
            SELECT Id, Opportunity__c
            FROM Utility_Account_Subscription__c
        ];
        for (Utility_Account_Subscription__c uas : uases) {
            uas.Transferring_Subsc_to_Another_UAS__c = true;
            uas.Next_Schedule_Z_Status__c = 'Inactive Subscription';
        }
        update uases;

        List<Opportunity> oppList = [
            SELECT Id, Account.Id, Account.Cancellation_Request_Date__c, StageName
            FROM Opportunity
        ];
        System.assertEquals(3, oppList.size());

        List<Account> accounts = new List<Account>();
        for (Opportunity opportunity : oppList) {
            System.assertEquals(null, opportunity.Account.Cancellation_Request_Date__c);
            System.assertEquals('Complete', opportunity.StageName);
            accounts.add(
                new Account(
                    Id = opportunity.Account.Id,
                    Cancellation_Reason__c = 'Other',
                    Cancellation_Request_Date__c = Date.today()
                )
            );
        }
        // Simulate the customer requesting their account be cancelled, which should set the UAS to Inactive Subscription
        update accounts;

        Map<Id, Opportunity> opportunityMap = new Map<Id, Opportunity>(OpportunitiesSelector.selectAllCompleteCSWithUASesAndSystemBills());
        for (Opportunity opportunity : opportunityMap.values()) {
            System.assert(Opportunities.isCancelledWaitlist(opportunityMap.get(opportunity.Id)));
            System.assert(Opportunities.allUASesTransferring(opportunityMap.get(opportunity.Id)));
        }

        Test.startTest();
        CSCancellationService.cancelOpportunities(CSCancellationService.getOpportunitiesToCancel());
        Test.stopTest();

        oppList = [
            SELECT Id, StageName
            FROM Opportunity
        ];

        System.assertEquals(3, oppList.size());
        for (Opportunity opp : oppList) {
            System.assertEquals('Complete', opp.StageName);
        }
    }

    @IsTest static void testOppCancellationOnBillingCompletionWithActiveUAS() {
        List<Utility_Account_Subscription__c> uases = [
            SELECT Id, Name, Utility_Account_Log__c, Opportunity__c, Next_Schedule_Z_Status__c,
                Annual_kwh_subscription_future__c, calculated_annual_cost_of_electricity__c, Subscribed_Annual_Cost_of_Electricity__c
            FROM Utility_Account_Subscription__c
            WHERE Name = '0000234'
        ];
        List<Utility_Account_Subscription__c> newUASes = uases.deepClone();
        for (Utility_Account_Subscription__c utilityAccountSubscription : newUASes) {
            utilityAccountSubscription.Name += ' Clone';
        }
        insert newUASes;

        // Creates bills for accounts that are dated 1/1/2018, implying all of these accounts are done billing.
        List<Shared_Solar_System__c> sss = [SELECT Id FROM Shared_Solar_System__c ORDER BY Name LIMIT 1];
        createBills(Date.newInstance(2018, 1, 1), sss[0].Id);

        // Set one of the uases to Inactive, so there's one Active and one Inactive
        newUASes[0].Next_Schedule_Z_Status__c = 'Inactive Subscription';
        update newUASes;

        List<System_Bill__c> systemBills = [
            SELECT Id, Date__c, Opportunity__c, Opportunity__r.StageName, (
                SELECT Id, Utility_Account_Subscription__c, Utility_Account_Subscription__r.Next_Schedule_Z_Status__c
                FROM Utility_Account_Subscription_Bills__r
                ORDER BY Utility_Account_Subscription__r.Next_Schedule_Z_Status__c
            )
            FROM System_Bill__c
        ];

        Map<Id, Opportunity> opportunityMap = new Map<Id, Opportunity>(OpportunitiesSelector.selectAllCompleteCSWithUASesAndSystemBills());
        Boolean foundOpp = false;
        for (System_Bill__c systemBill : systemBills) {
            if (opportunityMap.get(systemBill.Opportunity__c) != null) {
                foundOpp = true;
                System.assert(Opportunities.finishedBilling(opportunityMap.get(systemBill.Opportunity__c)));
                System.assert(!Opportunities.isCancelledWaitlist(opportunityMap.get(systemBill.Opportunity__c)));
                System.assert(Opportunities.hasActiveUASes(opportunityMap.get(systemBill.Opportunity__c)));
                System.assert(!Opportunities.allUASesTransferring(opportunityMap.get(systemBill.Opportunity__c)));
            }
        }
        System.assert(foundOpp);

        // Since there's a single opportunity for a single system, we generate a single bill with a single UAS that's still active
        System.assertEquals(1, systemBills.size());
        System.assertEquals(2, systemBills[0].Utility_Account_Subscription_Bills__r.size());
        System.assertEquals('Active Subscription', systemBills[0].Utility_Account_Subscription_Bills__r[0].Utility_Account_Subscription__r.Next_Schedule_Z_Status__c);
        System.assertEquals('Inactive Subscription', systemBills[0].Utility_Account_Subscription_Bills__r[1].Utility_Account_Subscription__r.Next_Schedule_Z_Status__c);
        System.assertEquals(Date.newInstance(2018,1,1), systemBills[0].Date__c);
        System.assertEquals('Complete', systemBills[0].Opportunity__r.StageName);

        Test.startTest();
        CSCancellationService.cancelOpportunities(CSCancellationService.getOpportunitiesToCancel());
        Test.stopTest();

        List<Opportunity> oppList = [
            SELECT Id, StageName
            FROM Opportunity
            WHERE Id = :systemBills[0].Opportunity__c
        ];
        // The System Bill's opportunity shouldn't be cancelled, since it has an active UAS even though it has an inactive UAS
        System.assertEquals(1, oppList.size());
        System.assertEquals('Complete', oppList[0].StageName);
    }

    @IsTest static void testOppCancellationOnBillingCompletion() {
        // Creates bills for accounts that are dated 1/1/2018, implying all of these accounts are done billing.
        List<Shared_Solar_System__c> sss = [SELECT Id FROM Shared_Solar_System__c ORDER BY Name LIMIT 1];
        createBills(Date.newInstance(2018, 1, 1), sss[0].Id);

        List<Utility_Account_Subscription__c> uases = [SELECT Id FROM Utility_Account_Subscription__c];
        for (Utility_Account_Subscription__c utilityAccountSubscription : uases) {
            utilityAccountSubscription.Next_Schedule_Z_Status__c = 'Inactive Subscription';
        }
        update uases;

        List<System_Bill__c> systemBills = [
            SELECT Id, Date__c, Opportunity__c, Opportunity__r.StageName, (
                SELECT Id, Utility_Account_Subscription__c, Utility_Account_Subscription__r.Next_Schedule_Z_Status__c
                FROM Utility_Account_Subscription_Bills__r
            )
            FROM System_Bill__c
        ];

        Map<Id, Opportunity> opportunityMap = new Map<Id, Opportunity>(OpportunitiesSelector.selectAllCompleteCSWithUASesAndSystemBills());
        Boolean foundOpp = false;
        for (System_Bill__c systemBill : systemBills) {
            if (opportunityMap.get(systemBill.Opportunity__c) != null) {
                foundOpp = true;
                System.assert(Opportunities.finishedBilling(opportunityMap.get(systemBill.Opportunity__c)));
                System.assert(!Opportunities.isCancelledWaitlist(opportunityMap.get(systemBill.Opportunity__c)));
                System.assert(!Opportunities.hasActiveUASes(opportunityMap.get(systemBill.Opportunity__c)));
                System.assert(!Opportunities.allUASesTransferring(opportunityMap.get(systemBill.Opportunity__c)));
            }
        }
        System.assert(foundOpp);

        // Since there's a single opportunity for a single system, we generate a single bill with a single UAS that's still active
        System.assertEquals(1, systemBills.size());
        System.assertEquals(1, systemBills[0].Utility_Account_Subscription_Bills__r.size());
        System.assertEquals('Inactive Subscription', systemBills[0].Utility_Account_Subscription_Bills__r[0].Utility_Account_Subscription__r.Next_Schedule_Z_Status__c);
        System.assertEquals(Date.newInstance(2018,1,1), systemBills[0].Date__c);
        System.assertEquals('Complete', systemBills[0].Opportunity__r.StageName);

        Test.startTest();
        CSCancellationService.cancelOpportunities(CSCancellationService.getOpportunitiesToCancel());
        Test.stopTest();

        List<Opportunity> oppList = [
            SELECT Id, StageName
            FROM Opportunity
            WHERE Id = :systemBills[0].Opportunity__c
        ];
        // The System Bill's opportunity should be cancelled, since it doesn't have an active UAS and hasn't had a recent bill generated
        System.assertEquals(1, oppList.size());
        System.assertEquals('Cancelled', oppList[0].StageName);
    }

    @IsTest static void testOppCancellationOnBillingCompletionForAnchors() {
        // Switch all opps to anchors
        List<Opportunity> opps = [SELECT Id FROM Opportunity];
        for (Opportunity opportunity : opps) {
            opportunity.Customer_Group__c = 'Anchor';
        }
        update opps;

        // Creates bills for accounts that are dated 1/1/2018, implying all of these accounts are done billing.
        List<Shared_Solar_System__c> sss = [SELECT Id FROM Shared_Solar_System__c ORDER BY Name LIMIT 1];
        createBills(Date.newInstance(2018, 1, 1), sss[0].Id);

        List<Utility_Account_Subscription__c> uases = [SELECT Id FROM Utility_Account_Subscription__c];
        for (Utility_Account_Subscription__c utilityAccountSubscription : uases) {
            utilityAccountSubscription.Next_Schedule_Z_Status__c = 'Inactive Subscription';
        }
        update uases;

        List<System_Bill__c> systemBills = [
            SELECT Id, Date__c, Opportunity__c, Opportunity__r.StageName, (
                SELECT Id, Utility_Account_Subscription__c, Utility_Account_Subscription__r.Next_Schedule_Z_Status__c
                FROM Utility_Account_Subscription_Bills__r
            )
            FROM System_Bill__c
        ];

        Map<Id, Opportunity> opportunityMap = new Map<Id, Opportunity>(OpportunitiesSelector.selectAllCompleteCSWithUASesAndSystemBills());
        // Since there's a single opportunity for a single system, we generate a single bill with a single UAS that's still active
        System.assertEquals(1, systemBills.size());
        System.assertEquals(0, opportunityMap.size(), 'There shouldn\t be any opportunities selected, since they\'re all anchors');
        System.assertEquals('Complete', systemBills[0].Opportunity__r.StageName);

        Test.startTest();
        CSCancellationService.cancelOpportunities(CSCancellationService.getOpportunitiesToCancel());
        Test.stopTest();

        List<Opportunity> oppList = [
            SELECT Id, StageName
            FROM Opportunity
            WHERE Id = :systemBills[0].Opportunity__c
        ];
        // The System Bill's opportunity shouldn't be cancelled since it's an anchor
        System.assertEquals(1, oppList.size());
        System.assertEquals('Complete', oppList[0].StageName);

    }

    @IsTest static void testOppCancellationOnBillingCompletionWithTransferringSubscriptions() {
        Util.disableTrigger('Disable_Client_Objects_Trigger__c');
        List<Utility_Account_Subscription__c> uases = [
            SELECT Id, Name, Utility_Account_Log__c, Opportunity__c, Next_Schedule_Z_Status__c,
                Annual_kwh_subscription_future__c, calculated_annual_cost_of_electricity__c, Subscribed_Annual_Cost_of_Electricity__c
            FROM Utility_Account_Subscription__c
        ];
        List<Utility_Account_Subscription__c> newUASes = uases.deepClone();
        for (Utility_Account_Subscription__c utilityAccountSubscription : newUASes) {
            utilityAccountSubscription.Name += ' Clone';
        }
        insert newUASes;

        // Creates bills for accounts that are dated 1/1/2018, implying all of these accounts are done billing.
        List<Shared_Solar_System__c> sss = [SELECT Id FROM Shared_Solar_System__c ORDER BY Name DESC];
        createBills(Date.newInstance(2018, 1, 1), sss[0].Id);
        Test.startTest();
        createBills(Date.newInstance(2018, 1, 1), sss[1].Id);

        // Update UASes to match test scenarios in
        // https://www.lucidchart.com/documents/edit/28ddde15-529b-4b09-b858-35bba5e77e37/5
        for (Utility_Account_Subscription__c utilityAccountSubscription : newUASes) {
            switch on utilityAccountSubscription.Name {
                when '0000236 Clone' {
                    utilityAccountSubscription.Transferring_Subsc_to_Another_UAS__c = true;
                    utilityAccountSubscription.Next_Schedule_Z_Status__c = 'Inactive Subscription';
                } when '0000238 Clone' {
                    utilityAccountSubscription.Transferring_Subsc_to_Another_UAS__c = false;
                    utilityAccountSubscription.Next_Schedule_Z_Status__c = 'Inactive Subscription';
                }
            }
        }
        update newUASes;
        for (Utility_Account_Subscription__c utilityAccountSubscription : uases) {
            switch on utilityAccountSubscription.Name {
                when '0000236', '0000238' {
                    utilityAccountSubscription.Transferring_Subsc_to_Another_UAS__c = true;
                    utilityAccountSubscription.Next_Schedule_Z_Status__c = 'Inactive Subscription';
                }
            }
        }
        update uases;

        List<System_Bill__c> systemBills = [
            SELECT Id, Date__c, Opportunity__c, Opportunity__r.StageName, (
                SELECT Id, Utility_Account_Subscription__c, Utility_Account_Subscription__r.Next_Schedule_Z_Status__c
                FROM Utility_Account_Subscription_Bills__r
            )
            FROM System_Bill__c
        ];

        Map<Id, Opportunity> opportunityMap = new Map<Id, Opportunity>(OpportunitiesSelector.selectAllCompleteCSWithUASesAndSystemBills());
        for (System_Bill__c systemBill : systemBills) {
            Opportunity opp = opportunityMap.get(systemBill.Opportunity__c);
            if (opp != null) {
                System.assert(Opportunities.finishedBilling(opp));
                System.assert(!Opportunities.isCancelledWaitlist(opp));
                switch on opp.Name {
                    when 'Jordan Jordan 0000236' {
                        System.assert(!Opportunities.hasActiveUASes(opp));
                        System.assert(Opportunities.allUASesTransferring(opp));
                    } when 'Jordan Jordan 0000238' {
                        System.assert(!Opportunities.hasActiveUASes(opp));
                        System.assert(!Opportunities.allUASesTransferring(opp));
                    }
                }
            } else {
                System.assert(false, 'Didn\'t find an opportunity for system bill');
            }
        }

        // Since there's a single opportunity for a single system, we generate a single bill with a single UAS that's still active
        System.assertEquals(2, systemBills.size());
        System.assertEquals('Complete', systemBills[0].Opportunity__r.StageName);
        System.assertEquals('Complete', systemBills[1].Opportunity__r.StageName);

        CSCancellationService.cancelOpportunities(CSCancellationService.getOpportunitiesToCancel());
        Test.stopTest();

        List<Opportunity> oppList = [
            SELECT Id, Name, StageName
            FROM Opportunity
            ORDER BY Name
        ];
        // The System Bill's opportunity should be cancelled, since it doesn't have an active UAS and hasn't had a recent bill generated
        System.assertEquals(3, oppList.size());
        System.assertEquals('Jordan Jordan 0000234', oppList[0].Name);
        System.assertEquals('Complete', oppList[0].StageName);
        System.assertEquals('Jordan Jordan 0000236', oppList[1].Name);
        System.assertEquals('Complete', oppList[1].StageName);
        System.assertEquals('Jordan Jordan 0000238', oppList[2].Name);
        System.assertEquals('Cancelled', oppList[2].StageName);
    }

    @IsTest static void testSetupDataForAccountDateRemovedIsCorrect() {
        // Ensures all data is set up correctly
        List<Account> propAccts = [
            SELECT Id, Name, Date_Removed_from_Project__c,
            (SELECT Id, Account__c FROM Utility_Account_Logs__r)
            FROM Account
            WHERE RecordType.Name = 'Property'
            ORDER BY Name
        ];

        System.assertEquals(3, propAccts.size());
        System.assertEquals('Prop Account 1', propAccts[0].Name);
        System.assertEquals('Prop Account 2', propAccts[1].Name);
        System.assertEquals('Prop Account 3', propAccts[2].Name);
        System.assertEquals(null, propAccts[0].Date_Removed_from_Project__c);
        System.assertEquals(null, propAccts[1].Date_Removed_from_Project__c);
        System.assertEquals(null, propAccts[2].Date_Removed_from_Project__c);
        System.assertEquals(1, propAccts[0].Utility_Account_Logs__r.size());
        System.assertEquals(1, propAccts[1].Utility_Account_Logs__r.size());
        System.assertEquals(1, propAccts[2].Utility_Account_Logs__r.size());

        List<Utility_Account_Subscription__c> uasList = [
            SELECT Id, Date_Removed_from_Project__c, Total_Count_of_Schedule_Zs__c,
                Utility_Account_Log__r.Account__c
            FROM Utility_Account_Subscription__c
        ];

        System.assertEquals(3, uasList.size());

        // We cycle through the UAS List to ensure that each account has one schedule z
        // We also verify that no UAS has the Date_Removed_from_Project__c populated
        for (Utility_Account_Subscription__c uas : uasList) {
            System.assertEquals(1, uas.Total_Count_of_Schedule_Zs__c);
            System.assertEquals(null, uas.Date_Removed_from_Project__c);
        }
    }

    @IsTest static void testNoAccountIsUpdated() {
        Test.startTest();
        CSCancellationService.processAccountsRemovedFromAllProjects(CSCancellationService.getAccountsRemovedFromAllProjectsWithUpdatedDate());
        Test.stopTest();

        List<Account> propAccts = [
            SELECT Id, Name, Date_Removed_from_Project__c,
            (SELECT Id, Account__c FROM Utility_Account_Logs__r)
            FROM Account
            WHERE RecordType.Name = 'Property'
            ORDER BY Name
        ];

        // Both Account's UASs have no value for Date_Removed_from_Project__c and therefore should remain unchanged.
        System.assertEquals(3, propAccts.size());
        System.assertEquals('Prop Account 1', propAccts[0].Name);
        System.assertEquals('Prop Account 2', propAccts[1].Name);
        System.assertEquals('Prop Account 3', propAccts[2].Name);
        System.assertEquals(null, propAccts[0].Date_Removed_from_Project__c);
        System.assertEquals(null, propAccts[1].Date_Removed_from_Project__c);
        System.assertEquals(null, propAccts[2].Date_Removed_from_Project__c);
    }

    @IsTest static void testAccountWithCancelledUASIsUpdated() {
        // Set up an account with two UALs that are removed at different times
        Shared_Solar_System__c sss1 = [SELECT Id FROM Shared_Solar_System__c WHERE Name = 'SSS1'];
        Account propAcct1 = [SELECT Id FROM Account WHERE Name = 'Prop Account 1'];
        Product2 normalCSProduct = [SELECT Id FROM Product2 WHERE Name = 'BlueWave Community Solar'];
        Schedule_Z__c scheduleZ1 = [SELECT Id FROM Schedule_Z__c WHERE Name = '18-0515 Oxford Barrett St. P1'];
        Utility_Account_Log__c ual4 = new Utility_Account_Log__c(
            Name = '0000239',
            Account__c = propAcct1.Id,
            Annual_Cost_of_Electricity__c = 1000,
            Name_on_Account__c = 'Name four'
        );
        insert ual4;
        Opportunity opportunityFour =
            new Opportunity(Name = 'Jordan Jordan',
                AccountId = propAcct1.Id,
                Shared_Solar_System__c = sss1.Id,
                StageName = 'Complete',
                Product__c = normalCSProduct.Id,
                Product_Line__c = 'Community Solar',
                CloseDate = System.today());
        insert opportunityFour;
        Utility_Account_Subscription__c uasFour =
            new Utility_Account_Subscription__c(Name = '0000239',
                Utility_Account_Log__c = ual4.Id,
                Opportunity__c = opportunityFour.Id,
                Next_Schedule_Z_Status__c = 'Active Subscription',
                Annual_kwh_subscription_future__c = 4000,
                calculated_annual_cost_of_electricity__c = 4000,
                Subscribed_Annual_Cost_of_Electricity__c = 4000);
        insert uasFour;
        uasFour.Customer_Subscription_KW_DC_STATIC__c = 25;
        update uasFour;

        Schedule_Z_Subscription__c newSubscription = new Schedule_Z_Subscription__c(
            Customer_Subscription_kW_DC__c = 25,
            Utility_Account_Subscription__c = uasFour.Id,
            Schedule_Z__c = scheduleZ1.Id,
            Number_of_Decimal_Places__c = 2,
            System_Size_kW_DC__c = 1445.86
        );
        insert newSubscription;

        List<Utility_Account_Subscription__c> uasToUpdate = [
            SELECT Id, Opportunity__c, Date_Removed_from_Project__c, Most_Recent_Enacted_ALSS__c, (SELECT Id FROM Schedule_Z_Subscriptions__r)
            FROM Utility_Account_Subscription__c
            WHERE Utility_Account_Log__r.Account__r.Name = 'Prop Account 1'
        ];
        System.assertEquals(2, uasToUpdate.size());
        for (Utility_Account_Subscription__c utilityAccountSubscription : uasToUpdate) {
            System.assertEquals(1, utilityAccountSubscription.Schedule_Z_Subscriptions__r.size());
        }

        Date twentyDaysAgo = Date.today() - 20;

        // Should be set when the UAL is marked finalled
        uasToUpdate[0].Date_Removed_from_Project__c = twentyDaysAgo;
        uasToUpdate[0].Next_Schedule_Z_Status__c = 'Inactive Subscription';
        // Should be set when an Allocation Schedule is Enacted
        uasToUpdate[0].Most_Recent_Enacted_ALSS__c = uasToUpdate[0].Schedule_Z_Subscriptions__r[0].Id;
        update uasToUpdate[0];

        List<Opportunity> opportunities = [
            SELECT Id, StageName, Date_Removed_from_Project__c,
            (SELECT Id, Next_Schedule_Z_Status__c FROM Utility_Account_Subscriptions__r)
            FROM Opportunity
            WHERE Id = :uasToUpdate[0].Opportunity__c
        ];
        System.assertNotEquals(null, opportunities[0].Date_Removed_from_Project__c);
        System.assertEquals('Complete', opportunities[0].StageName);
        // This would be performed when the CSCancellationScheduler runs if the Opp was done billing. We're not setting
        // up system bills here (that's tested in testOppCancellationOnBillingCompletion* tests), so we'll force the
        // opp to go to Cancelled.
        opportunities[0].StageName = 'Cancelled';
        update opportunities[0];

        CSCancellationService.processAccountsRemovedFromAllProjects(CSCancellationService.getAccountsRemovedFromAllProjectsWithUpdatedDate());

        // We shouldn't have marked Prop Account 1 as Removed from Project, since it has one of two UASes marked as Removed
        List<Account> propAccts = [
            SELECT Id, Name, Date_Removed_from_Project__c,
            (SELECT Id, Account__c FROM Utility_Account_Logs__r)
            FROM Account
            WHERE RecordType.Name = 'Property'
            ORDER BY Name
        ];

        // None of the accounts should be marked as removed (Account 1 will get removed when we remove both of it's UASes)
        System.assertEquals('Prop Account 1', propAccts[0].Name);
        System.assertEquals('Prop Account 2', propAccts[1].Name);
        System.assertEquals('Prop Account 3', propAccts[2].Name);
        System.assertEquals(null, propAccts[0].Date_Removed_from_Project__c);
        System.assertEquals(null, propAccts[1].Date_Removed_from_Project__c);
        System.assertEquals(null, propAccts[2].Date_Removed_from_Project__c);

        // We'll mark the other UAS as removed
        uasToUpdate[1].Date_Removed_from_Project__c = twentyDaysAgo - 20;
        uasToUpdate[1].Next_Schedule_Z_Status__c = 'Inactive Subscription';
        uasToUpdate[1].Most_Recent_Enacted_ALSS__c = uasToUpdate[1].Schedule_Z_Subscriptions__r[0].Id;
        update uasToUpdate[1];

        opportunities = [
            SELECT Id, StageName, Date_Removed_from_Project__c,
            (SELECT Id, Next_Schedule_Z_Status__c FROM Utility_Account_Subscriptions__r)
            FROM Opportunity
            WHERE Id = :uasToUpdate[1].Opportunity__c
        ];
        System.assertNotEquals(null, opportunities[0].Date_Removed_from_Project__c);
        System.assertEquals('Complete', opportunities[0].StageName);
        // This would be performed when the CSCancellationScheduler runs if the Opp was done billing. We're not setting
        // up system bills here (that's tested in testOppCancellationOnBillingCompletion* tests), so we'll force the
        // opp to go to Cancelled.
        opportunities[0].StageName = 'Cancelled';
        update opportunities[0];

        CSCancellationService.processAccountsRemovedFromAllProjects(CSCancellationService.getAccountsRemovedFromAllProjectsWithUpdatedDate());

        propAccts = [
            SELECT Id, Name, Date_Removed_from_Project__c,
            (SELECT Id, Account__c FROM Utility_Account_Logs__r)
            FROM Account
            WHERE RecordType.Name = 'Property'
            ORDER BY Name
        ];

        // Now, Prop Account 1 should be marked as removed
        System.assertEquals('Prop Account 1', propAccts[0].Name);
        System.assertEquals('Prop Account 2', propAccts[1].Name);
        System.assertEquals('Prop Account 3', propAccts[2].Name);
        System.assertEquals(twentyDaysAgo, propAccts[0].Date_Removed_from_Project__c);
        System.assertEquals(null, propAccts[1].Date_Removed_from_Project__c);
        System.assertEquals(null, propAccts[2].Date_Removed_from_Project__c);
        Util.printSOQLLimit('a');
        Util.printCPULimit('b');
    }

    @IsTest static void testAccountMissingScheduleZsNotUpdated() {
        List<Utility_Account_Subscription__c> uasToUpdate = [
            SELECT Id, Date_Removed_from_Project__c
            FROM Utility_Account_Subscription__c
            WHERE Utility_Account_Log__r.Account__r.Name = 'Prop Account 1'
        ];

        List<Schedule_Z_Subscription__c> propAcct1SchedZ = [
            SELECT Id
            FROM Schedule_Z_Subscription__c
            WHERE Utility_Account_Subscription__r.Utility_Account_Log__r.Account__r.Name = 'Prop Account 1'
        ];

        Date dateRemoved = Date.today() - 20;

        for (Utility_Account_Subscription__c uas : uasToUpdate) {
            uas.Date_Removed_from_Project__c = dateRemoved;
        }

        delete propAcct1SchedZ;
        update uasToUpdate;

        Test.startTest();
        CSCancellationService.processAccountsRemovedFromAllProjects(CSCancellationService.getAccountsRemovedFromAllProjectsWithUpdatedDate());
        Test.stopTest();

        List<Account> propAccts = [
            SELECT Id, Name, Date_Removed_from_Project__c,
            (SELECT Id, Account__c, Number_of_Removed_UASes__c, Number_of_Subscribed_UASes__c, Last_Date_UAS_Removed_From_Project__c FROM Utility_Account_Logs__r)
            FROM Account
            WHERE RecordType.Name = 'Property'
            ORDER BY Name
        ];

        // Prop Account 1 should not be updated since its UASs have no Schedule_Z_Subscriptions
        // even though its UASs were updated.
        System.assertEquals('Prop Account 1', propAccts[0].Name);
        System.assertEquals('Prop Account 2', propAccts[1].Name);
        System.assertEquals('Prop Account 3', propAccts[2].Name);
        System.assertEquals(null, propAccts[0].Date_Removed_from_Project__c);
        System.assertEquals(null, propAccts[1].Date_Removed_from_Project__c);
        System.assertEquals(null, propAccts[2].Date_Removed_from_Project__c);
    }

    @IsTest static void testAllAccountsDateRemovedAreUpdated() {
        List<Utility_Account_Subscription__c> uasToUpdate = [
            SELECT Id, Opportunity__c, Date_Removed_from_Project__c, (SELECT Id FROM Schedule_Z_Subscriptions__r)
            FROM Utility_Account_Subscription__c
        ];

        Date dateRemoved = Date.today() - 20;
        Datetime dateRemovedDT = Datetime.newInstance(dateRemoved.year(), dateRemoved.month(), dateRemoved.day());
        String dateRemovedString = dateRemovedDT.format('MM/dd/yyyy');

        // We'll also mark opportunities as cancelled, which the CSCancellationScheduler would do if the opportunities
        // were done billing. We haven't set up system bills here, and that's tested in testOppCancellationOnBillingCompletion*
        // tests, so we'll force the opp to be Cancelled.
        List<Opportunity> opportunitiesToMarkCancelled = new List<Opportunity>();
        for (Utility_Account_Subscription__c uas : uasToUpdate) {
            uas.Date_Removed_from_Project__c = dateRemoved;
            uas.Next_Schedule_Z_Status__c = 'Inactive Subscription';
            uas.Most_Recent_Enacted_ALSS__c = uas.Schedule_Z_Subscriptions__r[0].Id;
            opportunitiesToMarkCancelled.add(
                new Opportunity(
                    Id = uas.Opportunity__c,
                    StageName = 'Cancelled'
                )
            );
        }
        update uasToUpdate;
        update opportunitiesToMarkCancelled;

        Test.startTest();
        CSCancellationService.processAccountsRemovedFromAllProjects(CSCancellationService.getAccountsRemovedFromAllProjectsWithUpdatedDate());
        Test.stopTest();

        List<Account> propAccts = [
            SELECT Id, Name, Date_Removed_from_Project__c,
            (SELECT Id, Account__c FROM Utility_Account_Logs__r)
            FROM Account
            WHERE RecordType.Name = 'Property'
            ORDER BY Name
        ];

        // All accounts are updated since all UASs have Date Removed From Project populated

        System.assertEquals('Prop Account 1', propAccts[0].Name);
        System.assertEquals('Prop Account 2', propAccts[1].Name);
        System.assertEquals('Prop Account 3', propAccts[2].Name);
        System.assertEquals(dateRemoved, propAccts[0].Date_Removed_from_Project__c);
        System.assertEquals(dateRemoved, propAccts[1].Date_Removed_from_Project__c);
        System.assertEquals(dateRemoved, propAccts[2].Date_Removed_from_Project__c);

        for (Messaging.Email email : MessagingService.emailsSent) {
            Messaging.SingleEmailMessage sem = (Messaging.SingleEmailMessage) email;
            System.assert(sem.getHtmlBody().contains(dateRemovedString));
        }
    }

    @IsTest static void testSetUpDataForUASNotOnNewScheduleZ() {
        List<Schedule_Z__c> scheduleZsReplaced = [
            SELECT Id,
            (SELECT Id, Utility_Account_Subscription__c
            FROM Schedule_Z_Subscriptions__r)
            FROM Schedule_Z__c
            WHERE Date_Schedule_Z_Retired_by_Utility__c != NULL
        ];

        System.assertEquals(0, scheduleZsReplaced.size());

        List<Schedule_Z__c> schedZInProgress = [
            SELECT Id, Shared_Solar_System__c,
            (SELECT Id, Utility_Account_Subscription__c
            FROM Schedule_Z_Subscriptions__r)
            FROM Schedule_Z__c
            WHERE Status__c != 'Replaced'
            AND Status__c != 'Rejected by Utility'
        ];

        List<Utility_Account_Subscription__c> uasList = [
            SELECT Id, Date_Removed_from_Project__c
            FROM Utility_Account_Subscription__c
        ];

        System.assertEquals(3, uasList.size());

        for (Utility_Account_Subscription__c uas : uasList) {
            System.assertEquals(null, uas.Date_Removed_from_Project__c);
        }
    }

    @IsTest static void testUASNotOnNewScheduleZ() {
        Schedule_Z__c scheduleZ = [
            SELECT Id, Status__c, Shared_Solar_System__c, Date_Schedule_Z_Retired_by_Utility__c, Date_Enacted_by_Utility__c,
            (SELECT Id, Utility_Account_Subscription__c, Utility_Account_Subscription__r.Date_Removed_from_Project__c
            FROM Schedule_Z_Subscriptions__r)
            FROM Schedule_Z__c
            LIMIT 1
        ];

        // There should be one enacted SZ, one UAS and one schedule Z subscription, and it shouldn't be removed from project
        System.assertEquals(Date.newInstance(2018,1,1), scheduleZ.Date_Enacted_by_Utility__c);
        System.assertEquals(1, scheduleZ.Schedule_Z_Subscriptions__r.size());
        System.assertEquals(null, scheduleZ.Schedule_Z_Subscriptions__r[0].Utility_Account_Subscription__r.Date_Removed_from_Project__c);

        // Mark the UASes as inactive
        Utility_Account_Subscription__c uas = new Utility_Account_Subscription__c(
            Id = scheduleZ.Schedule_Z_Subscriptions__r[0].Utility_Account_Subscription__c,
            Next_Schedule_Z_Status__c = 'Inactive Subscription'
        );
        update uas;

        uas = [
            SELECT Id, Date_Removed_from_Project__c
            FROM Utility_Account_Subscription__c
            WHERE Id = : uas.Id
        ];
        // It's still not marked as removed yet
        System.assertEquals(null, uas.Date_Removed_from_Project__c);

        // Create a new schedule z, which shouldn't create new new schedule z subscription, since the UAS is inactive
        Schedule_Z__c newScheduleZ = new Schedule_Z__c(
            Status__c = 'QC In Process',
            Shared_Solar_System__c = scheduleZ.Shared_Solar_System__c
        );
        insert newScheduleZ;

        newScheduleZ.Status__c = 'Enacted by Utility';
        update newScheduleZ;

        newScheduleZ = [
            SELECT Id, Status__c, Shared_Solar_System__c, Date_Schedule_Z_Retired_by_Utility__c,
            (SELECT Id, Utility_Account_Subscription__c FROM Schedule_Z_Subscriptions__r)
            FROM Schedule_Z__c
            WHERE Id = :newScheduleZ.Id
        ];

        System.assertEquals(0, newScheduleZ.Schedule_Z_Subscriptions__r.size());

        uas = [
            SELECT Id, Date_Removed_from_Project__c
            FROM Utility_Account_Subscription__c
            WHERE Id = : uas.Id
        ];

        // Now it should be marked as removed
        System.assertEquals(Date.today(), uas.Date_Removed_from_Project__c);
    }

    // Because we sometimes create Schedule Z's as Enacted, as opposed to updating the status to Enacted
    @IsTest static void testUASNotOnNewScheduleZOnCreate() {
        Schedule_Z__c scheduleZ = [
            SELECT Id, Status__c, Shared_Solar_System__c, Date_Schedule_Z_Retired_by_Utility__c, Date_Enacted_by_Utility__c,
            (SELECT Id, Utility_Account_Subscription__c, Utility_Account_Subscription__r.Date_Removed_from_Project__c
            FROM Schedule_Z_Subscriptions__r)
            FROM Schedule_Z__c
            LIMIT 1
        ];

        // There should be one enacted SZ, one UAS and one schedule Z subscription, and it shouldn't be removed from project
        System.assertNotEquals(null, scheduleZ.Date_Enacted_by_Utility__c);
        System.assertEquals(1, scheduleZ.Schedule_Z_Subscriptions__r.size());
        System.assertEquals(null, scheduleZ.Schedule_Z_Subscriptions__r[0].Utility_Account_Subscription__r.Date_Removed_from_Project__c);

        // Mark the UASes as inactive
        Utility_Account_Subscription__c uas = new Utility_Account_Subscription__c(
            Id = scheduleZ.Schedule_Z_Subscriptions__r[0].Utility_Account_Subscription__c,
            Next_Schedule_Z_Status__c = 'Inactive Subscription'
        );
        update uas;

        uas = [
            SELECT Id, Date_Removed_from_Project__c
            FROM Utility_Account_Subscription__c
            WHERE Id = : uas.Id
        ];
        // It's still not marked as removed yet
        System.assertEquals(null, uas.Date_Removed_from_Project__c);

        // Create a new schedule z, which shouldn't create new new schedule z subscription, since the UAS is inactive
        Schedule_Z__c newScheduleZ = scheduleZ.clone();
        newScheduleZ.Status__c = 'Enacted by Utility';
        Date dateScheduleZReplaced = Date.today() - 20;
        newScheduleZ.Date_Enacted_by_Utility__c = dateScheduleZReplaced;
        insert newScheduleZ;

        newScheduleZ = [
            SELECT Id, Status__c, Shared_Solar_System__c, Date_Schedule_Z_Retired_by_Utility__c,
            (SELECT Id, Utility_Account_Subscription__c FROM Schedule_Z_Subscriptions__r)
            FROM Schedule_Z__c
            WHERE Id = :newScheduleZ.Id
        ];

        System.assertEquals(0, newScheduleZ.Schedule_Z_Subscriptions__r.size());

        uas = [
            SELECT Id, Date_Removed_from_Project__c
            FROM Utility_Account_Subscription__c
            WHERE Id = : uas.Id
        ];

        // Now it should be marked as removed
        System.assertEquals(dateScheduleZReplaced, uas.Date_Removed_from_Project__c);
    }

    @IsTest static void testUASIsNotUpdatedCriteriaOne() {
        Schedule_Z__c scheduleZToUpdate = [
            SELECT Id, Status__c, Date_Schedule_Z_Retired_by_Utility__c
            FROM Schedule_Z__c
            LIMIT 1
        ];

        // Here we do not update the SchedZ Date Retired by Utility so the UAS should not be updated.
        scheduleZToUpdate.Status__c = 'Replaced';
        System.assertEquals(null, scheduleZToUpdate.Date_Schedule_Z_Retired_by_Utility__c);

        update scheduleZToUpdate;

        Schedule_Z__c updatedSchedZ = [
            SELECT Id, Date_Schedule_Z_Retired_by_Utility__c,
            (SELECT Id, Utility_Account_Subscription__c
            FROM Schedule_Z_Subscriptions__r)
            FROM Schedule_Z__c
            WHERE Id = :scheduleZToUpdate.Id
        ];

        System.assertEquals(1, updatedSchedZ.Schedule_Z_Subscriptions__r.size());

        Id uasID;
        for (Schedule_Z_Subscription__c szs : updatedSchedZ.Schedule_Z_Subscriptions__r) {
            uasID = szs.Utility_Account_Subscription__c;
        }

        Utility_Account_Subscription__c updatedUAS = [
            SELECT Id, Date_Removed_from_Project__c
            FROM Utility_Account_Subscription__c
            WHERE Id = :uasID
        ];

        System.assertEquals(null, updatedUAS.Date_Removed_from_Project__c);
    }

    @IsTest static void testUASIsNotUpdatedCriteriaTwo() {
        Schedule_Z__c scheduleZToUpdate = [
            SELECT Id, Status__c, Date_Schedule_Z_Retired_by_Utility__c
            FROM Schedule_Z__c
            LIMIT 1
        ];

        // Here we do not update the SchedZ Status so the UAS should not be updated.
        scheduleZToUpdate.Date_Schedule_Z_Retired_by_Utility__c = System.today();
        System.assertEquals('Billing', scheduleZToUpdate.Status__c);

        update scheduleZToUpdate;

        Schedule_Z__c updatedSchedZ = [
            SELECT Id, Date_Schedule_Z_Retired_by_Utility__c,
            (SELECT Id, Utility_Account_Subscription__c
            FROM Schedule_Z_Subscriptions__r)
            FROM Schedule_Z__c
            WHERE Id = :scheduleZToUpdate.Id
        ];

        System.assertEquals(1, updatedSchedZ.Schedule_Z_Subscriptions__r.size());

        Id uasID;
        for (Schedule_Z_Subscription__c szs : updatedSchedZ.Schedule_Z_Subscriptions__r) {
            uasID = szs.Utility_Account_Subscription__c;
        }

        Utility_Account_Subscription__c updatedUAS = [
            SELECT Id, Date_Removed_from_Project__c
            FROM Utility_Account_Subscription__c
            WHERE Id = :uasID
        ];

        System.assertEquals(null, updatedUAS.Date_Removed_from_Project__c);
    }

    @IsTest static void testSetupDataForAccountsClosedIsCorrect() {
        List<Opportunity> allOpps = [
            SELECT Id, StageName
            FROM Opportunity
        ];

        System.assertEquals(3, allOpps.size());
        for (Opportunity opp : allOpps) {
            System.assertEquals('Complete', opp.StageName);
        }

        List<Account> acctList = [
          SELECT Id, Name, Cancellation_Request_Date__c, Status__c
          FROM Account
          WHERE RecordType.Name = 'Property'
        ];

        System.assertEquals(3, acctList.size());
        for (Account acct : acctList) {
            System.assertEquals('Open', acct.Status__c);
            System.assertEquals(null, acct.Cancellation_Request_Date__c);
        }
    }

    @IsTest static void testAccountIsNotClosedWithActiveOpps() {
        Account acctToUpdate = [
            SELECT Id
            FROM Account
            WHERE Name = 'Prop Account 1'
        ];

        acctToUpdate.Cancellation_Reason__c = 'Customer Moved';
        acctToUpdate.Cancellation_Request_Date__c = System.today();

        update acctToUpdate;

        acctToUpdate = [
            SELECT Id, Status__c, Cancellation_Request_Date__c
            FROM Account
            WHERE Name = 'Prop Account 1'
        ];

        System.assertEquals('Open', acctToUpdate.Status__c);
        System.assertEquals(System.today(), acctToUpdate.Cancellation_Request_Date__c);
    }

    @IsTest static void testOneAccountIsClosed() {
        Account propAcct1 = [SELECT Id FROM Account WHERE Name = 'Prop Account 1'];
        Shared_Solar_System__c sss1 = [SELECT Id FROM Shared_Solar_System__c WHERE Name = 'SSS1'];
        Product2 normalCSProduct = [SELECT Id FROM Product2 WHERE Name = 'BlueWave Community Solar'];

        Opportunity opportunitytwo =
            new Opportunity(Name = 'Jordan Jordan',
                AccountId = propAcct1.Id,
                Shared_Solar_System__c = sss1.Id,
                StageName = 'Complete',
                Product__c = normalCSProduct.Id,
                Product_Line__c = 'Community Solar',
                CloseDate = System.today()
            );
        insert opportunitytwo;

        propAcct1.Cancellation_Reason__c = 'Customer Moved';
        propAcct1.Cancellation_Request_Date__c = System.today();

        MessagingService.onlyUseActiveTemplates = false;
        update propAcct1;
        System.assertEquals(1, MessagingService.emailsSent.size());
        MessagingService.emailsSent = null;

        List<Opportunity> oppsToUpdate = [
          SELECT Id
          FROM Opportunity
          WHERE AccountId = :propAcct1.Id
        ];

        oppsToUpdate[0].StageName = 'Cancelled';

        update oppsToUpdate[0];

        propAcct1 = [
            SELECT Id, Status__c, Cancellation_Request_Date__c
            FROM Account
            WHERE Name = 'Prop Account 1'
        ];

        System.assertEquals(System.today(), propAcct1.Cancellation_Request_Date__c);
        System.assertNotEquals('Closed', propAcct1.Status__c);

        oppsToUpdate[1].StageName = 'Cancelled';

        update oppsToUpdate[1];

        propAcct1 = [
            SELECT Id, Status__c, Cancellation_Request_Date__c
            FROM Account
            WHERE Name = 'Prop Account 1'
        ];

        System.assertEquals(System.today(), propAcct1.Cancellation_Request_Date__c);
        System.assertEquals('Closed', propAcct1.Status__c);
        System.assertEquals(1, MessagingService.emailsSent.size());
    }

    @IsTest static void testAllAccountsAreClosed() {
        List<Account> acctsToClose = [
            SELECT Id
            FROM Account
            WHERE RecordType.Name = 'Property'
        ];

        List<Id> acctIdList = new List<Id>();

        for (Account acct : acctsToClose) {
            acctIdList.add(acct.Id);
            acct.Cancellation_Reason__c = 'Customer Moved';
            acct.Cancellation_Request_Date__c = System.today();
        }

        update acctsToClose;

        List<Opportunity> oppsToCancel = [
            SELECT Id
            FROM Opportunity
            WHERE AccountId = :acctIdList
        ];

        for (Opportunity opp : oppsToCancel) {
            opp.StageName = 'Cancelled';
        }

        update oppsToCancel;

        acctsToClose = [
            SELECT Id, Status__c, Cancellation_Request_Date__c
            FROM Account
            WHERE RecordType.Name = 'Property'
        ];

        for (Account acct : acctsToClose) {
            System.assertEquals('Closed', acct.Status__c);
            System.assertEquals(System.today(), acct.Cancellation_Request_Date__c);
        }
    }

    @IsTest static void testEndToEndCancellationOneAccount() {
        Date today = System.today();

        // Create a bill they haven't paid
        Shared_Solar_System__c sss1 = [SELECT Id FROM Shared_Solar_System__c WHERE Name = 'SSS1'];
        createBills(today - 46, sss1.Id);

        Test.startTest();
        Account acct = [
            SELECT Id
            FROM Account
            WHERE Name = 'Prop Account 1'
        ];

        acct.Cancellation_Reason__c = 'Customer Moved';
        acct.Cancellation_Request_Date__c = today;

        update acct;

        // the action above should set next schedule z status to Inactive

        Utility_Account_Log__c ual = [
            SELECT Id, (SELECT Id FROM Utility_Account_Subscriptions__r)
            FROM Utility_Account_Log__c
            WHERE Account__r.Id = :acct.Id
        ];

        ual.Date_Utility_Account_Cancelled__c = today;

        update ual;

        ual.Utility_Account_Subscriptions__r[0].Transferring_Subsc_to_Another_UAS__c = false;
        update ual.Utility_Account_Subscriptions__r[0];

        CSCancellationScheduler cscs = new CSCancellationScheduler();
        cscs.execute(null);
        Test.stopTest();

        acct = [
            SELECT Id, Status__c
            FROM Account
            WHERE Name = 'Prop Account 1'
        ];

        List<Opportunity> oppList = [
          SELECT Id, StageName
          FROM Opportunity
          WHERE AccountId = :acct.Id
        ];

        System.assertEquals('Closed', acct.Status__c);
        for (Opportunity opp : oppList) {
            System.assertEquals('Cancelled', opp.StageName);
        }
    }

    @IsTest
    public static void testConflictingCancellationParagraphs() {
        // We want to test the case where there is a single Account with multiple Opportunities assigned to products
        // with conflicting cancellation information (for instance, SMART and SREC).
        Product2 publicCSProduct = [SELECT Id FROM Product2 WHERE Name = 'BlueWave Public Offtake CS' LIMIT 1];

        // First we need to set up a new opportunity and subscription
        Opportunity opportunity = [
            SELECT Id, Name, AccountId, Shared_Solar_System__c, StageName, Product__c, Product_Line__c, CloseDate
            FROM Opportunity
            LIMIT 1
        ];
        Opportunity newOpp = opportunity.clone(false);
        newOpp.Product__c = publicCSProduct.Id;
        insert newOpp;

        Utility_Account_Subscription__c uas = [
            SELECT Id, Name, Utility_Account_Log__c, Opportunity__c, Next_Schedule_Z_Status__c,
                Annual_kwh_subscription_future__c, calculated_annual_cost_of_electricity__c, Subscribed_Annual_Cost_of_Electricity__c
            FROM Utility_Account_Subscription__c
            WHERE Opportunity__c = :opportunity.Id
            LIMIT 1
        ];
        Utility_Account_Subscription__c newUAS = uas.clone(false);
        newUAS.Opportunity__c = newOpp.Id;
        insert newUAS;

        Map<Account, Map<String, String>> accountCancellationTextMap =
            CSCancellationService.accountToCancellationParagraphs(UASSelector.selectByAccounts(new Set<Id>{opportunity.AccountId}));
        System.assertEquals(1, accountCancellationTextMap.keySet().size());
        System.assertEquals(1, accountCancellationTextMap.values().size());
        List<Account> accounts = new List<Account>(accountCancellationTextMap.keySet());
        System.assertEquals(opportunity.AccountId, accounts[0].Id);
        System.assertEquals(
            CSCancellationService.DEFAULT_CANCELLATION_PARAGRAPH_TWO,
            accountCancellationTextMap.values()[0].get(CSCancellationService.CANCELLATION_PARAGRAPH_TWO_LABEL)
        );
        System.assertEquals(
            CSCancellationService.DEFAULT_CANCELLATION_PARAGRAPH_THREE,
            accountCancellationTextMap.values()[0].get(CSCancellationService.CANCELLATION_PARAGRAPH_THREE_LABEL)
        );
    }

    @IsTest
    public static void testNonConflictingCancellationParagraphs() {
        // We want to test the case where there is a single Account with multiple Opportunities assigned to products
        // with the same cancellation information (for instance, two SMART products).
        // First we need to set up a new opportunity and subscription
        Opportunity opportunity = [
            SELECT Id, Name, AccountId, Shared_Solar_System__c, StageName, Product__c, Product_Line__c, CloseDate,
                Product__r.Cancellation_Paragraph_Two__c, Product__r.Cancellation_Paragraph_Three__c
            FROM Opportunity
            LIMIT 1
        ];
        Opportunity newOpp = opportunity.clone(false);
        insert newOpp;

        Utility_Account_Subscription__c uas = [
            SELECT Id, Name, Utility_Account_Log__c, Opportunity__c, Next_Schedule_Z_Status__c,
                Annual_kwh_subscription_future__c, calculated_annual_cost_of_electricity__c, Subscribed_Annual_Cost_of_Electricity__c
            FROM Utility_Account_Subscription__c
            WHERE Opportunity__c = :opportunity.Id
            LIMIT 1
        ];
        Utility_Account_Subscription__c newUAS = uas.clone(false);
        newUAS.Opportunity__c = newOpp.Id;
        insert newUAS;

        Map<Account, Map<String, String>> accountCancellationTextMap =
            CSCancellationService.accountToCancellationParagraphs(UASSelector.selectByAccounts(new Set<Id>{opportunity.AccountId}));
        System.assertEquals(1, accountCancellationTextMap.keySet().size());
        System.assertEquals(1, accountCancellationTextMap.values().size());
        List<Account> accounts = new List<Account>(accountCancellationTextMap.keySet());
        System.assertEquals(opportunity.AccountId, accounts[0].Id);
        System.assertNotEquals(null, opportunity.Product__r.Cancellation_Paragraph_Two__c);
        System.assertNotEquals(null, opportunity.Product__r.Cancellation_Paragraph_Three__c);
        System.assertEquals(
            opportunity.Product__r.Cancellation_Paragraph_Two__c,
            accountCancellationTextMap.values()[0].get(CSCancellationService.CANCELLATION_PARAGRAPH_TWO_LABEL)
        );
        System.assertEquals(
            opportunity.Product__r.Cancellation_Paragraph_Three__c,
            accountCancellationTextMap.values()[0].get(CSCancellationService.CANCELLATION_PARAGRAPH_THREE_LABEL)
        );
    }

    @IsTest
    public static void testMissingCancellationParagraphs() {
        Opportunity opportunity = [
            SELECT Id, Name, AccountId, Shared_Solar_System__c, StageName, Product__c, Product_Line__c, CloseDate,
                Product__r.Cancellation_Paragraph_Two__c
            FROM Opportunity
            LIMIT 1
        ];
        opportunity.Product__r.Cancellation_Paragraph_Two__c = null;
        update opportunity.Product__r;

        Boolean exceptionCaught = false;
        try {
            CSCancellationService.accountToCancellationParagraphs(UASSelector.selectByAccounts(new Set<Id>{opportunity.AccountId}));
        } catch (Exception bwe) {
            exceptionCaught = true;
            System.assert(bwe.getMessage().contains('Cancellation Paragraph Two'));
        }
        System.assertEquals(true, exceptionCaught);

        opportunity.Product__r.Cancellation_Paragraph_Two__c = 'P2';
        update opportunity.Product__r;

        exceptionCaught = false;
        try {
            CSCancellationService.accountToCancellationParagraphs(UASSelector.selectByAccounts(new Set<Id>{opportunity.AccountId}));
        } catch (Util.BWException bwe) {
            exceptionCaught = true;
            System.assert(false);
        }
        System.assertEquals(false, exceptionCaught);

    }

    @IsTest
    private static void testGetAccountsWithDateRemovedSet() {
        List<Account> accounts;
        String accountWithOneExpiredOppNotRemoved =
            '[{"attributes":{"type":"Account","url":"/services/data/v47.0/sobjects/Account/0010a00001RmBuQAAV"},' +
            '"Id":"0010a00001RmBuQAAV",' +
            '"Name":"12313",' +
            '"RecordTypeId":"012j00000010HeQAAU",' +
            '"Utility_Account_Logs__r":{"totalSize":1,"done":true,"records":[{"attributes":{"type":"Utility_Account_Log__c","url":"/services/data/v47.0/sobjects/Utility_Account_Log__c/a1b0a000003hRhlAAE"},"Account__c":"0010a00001RmBuQAAV","Id":"a1b0a000003hRhlAAE","Name":"12314214","Number_of_Removed_UASes__c":0,"Number_of_Subscribed_UASes__c":0}]},' +
            '"Opportunities":{"totalSize":1,"done":true,"records":[{"attributes":{"type":"Opportunity","url":"/services/data/v47.0/sobjects/Opportunity/0060a00000gYhdrAAC"},"AccountId":"0010a00001RmBuQAAV","Id":"0060a00000gYhdrAAC","StageName":"Expired"}]}}]';
        accounts = (List<Account>) JSON.deserialize(accountWithOneExpiredOppNotRemoved, List<Account>.class);
        System.assertEquals(0, CSCancellationService.getAccountsWithDateRemovedSet(accounts).size(), 'Expected no accounts to set a Date Removed From Project');

        String accountWithTwoCancelledButNotRemovedOpps =
            '[{"attributes":{"type":"Account","url":"/services/data/v47.0/sobjects/Account/0010a00001Tf2j2AAB"},' +
            '"Id":"0010a00001Tf2j2AAB",' +
            '"Name":"127 Main Street Realty",' +
            '"Send_Bills_Contact__c":"0030a000026UGX6AAO",' +
            '"RecordTypeId":"012j00000010HeQAAU",' +
            '"Utility_Account_Logs__r":{"totalSize":3,"done":true,"records":[{"attributes":{"type":"Utility_Account_Log__c","url":"/services/data/v47.0/sobjects/Utility_Account_Log__c/a1b0a000004DDJMAA4"},"Account__c":"0010a00001Tf2j2AAB","Id":"a1b0a000004DDJMAA4","Name":"88148-888","Number_of_Removed_UASes__c":0,"Number_of_Subscribed_UASes__c":0},{"attributes":{"type":"Utility_Account_Log__c","url":"/services/data/v47.0/sobjects/Utility_Account_Log__c/a1b0a000004DDJWAA4"},"Account__c":"0010a00001Tf2j2AAB","Id":"a1b0a000004DDJWAA4","Name":"00885-8888","Number_of_Removed_UASes__c":0,"Number_of_Subscribed_UASes__c":0},{"attributes":{"type":"Utility_Account_Log__c","url":"/services/data/v47.0/sobjects/Utility_Account_Log__c/a1b0a000004DDJbAAO"},"Account__c":"0010a00001Tf2j2AAB","Id":"a1b0a000004DDJbAAO","Name":"88148-88888","Number_of_Removed_UASes__c":0,"Number_of_Subscribed_UASes__c":0}]},' +
            '"Opportunities":{"totalSize":2,"done":true,"records":[{"attributes":{"type":"Opportunity","url":"/services/data/v47.0/sobjects/Opportunity/0060a00000ge0sGAAQ"},"AccountId":"0010a00001Tf2j2AAB","Id":"0060a00000ge0sGAAQ","StageName":"Cancelled"},{"attributes":{"type":"Opportunity","url":"/services/data/v47.0/sobjects/Opportunity/0060a00000ge0sHAAQ"},"AccountId":"0010a00001Tf2j2AAB","Id":"0060a00000ge0sHAAQ","StageName":"Cancelled"}]},"Send_Bills_Contact__r":{"attributes":{"type":"Contact","url":"/services/data/v47.0/sobjects/Contact/0030a000026UGX6AAO"},"Id":"0030a000026UGX6AAO","FirstName":"James","Email":"foo@bar.com"}}]';
        accounts = (List<Account>) JSON.deserialize(accountWithTwoCancelledButNotRemovedOpps, List<Account>.class);
        System.assertEquals(0, CSCancellationService.getAccountsWithDateRemovedSet(accounts).size(), 'Expected no accounts to set a Date Removed From Project');

        String accountWithDuplicateAndNotRemovedOpps =
            '[{"attributes":{"type":"Account","url":"/services/data/v47.0/sobjects/Account/0010a00001ZKcEvAAL"},' +
            '"Id":"0010a00001ZKcEvAAL",' +
            '"Name":"NY DUPLICATE ACCT",' +
            '"Send_Bills_Contact__c":"0030a00002F2vZrAAJ",' +
            '"RecordTypeId":"012j00000010HeQAAU",' +
            '"Utility_Account_Logs__r":{"totalSize":1,"done":true,"records":[{"attributes":{"type":"Utility_Account_Log__c","url":"/services/data/v47.0/sobjects/Utility_Account_Log__c/a1b0a000002b9ZQAAY"},"Account__c":"0010a00001ZKcEvAAL","Id":"a1b0a000002b9ZQAAY","Name":"100188888","Number_of_Removed_UASes__c":0,"Number_of_Subscribed_UASes__c":0}]},' +
            '"Opportunities":{"totalSize":1,"done":true,"records":[{"attributes":{"type":"Opportunity","url":"/services/data/v47.0/sobjects/Opportunity/0060a00000jF7lzAAC"},"AccountId":"0010a00001ZKcEvAAL","Id":"0060a00000jF7lzAAC","StageName":"DUPLICATE"}]},"Send_Bills_Contact__r":{"attributes":{"type":"Contact","url":"/services/data/v47.0/sobjects/Contact/0030a00002F2vZrAAJ"},"Id":"0030a00002F2vZrAAJ","FirstName":"Guy","Email":"foo@bar.com"}}]';

        accounts = (List<Account>) JSON.deserialize(accountWithDuplicateAndNotRemovedOpps, List<Account>.class);
        System.assertEquals(0, CSCancellationService.getAccountsWithDateRemovedSet(accounts).size(), 'Expected no accounts to set a Date Removed From Project');

        Datetime removedDate = Datetime.newInstance(2019,3,25);
        String accountWithCancelledAndRemovedOpp =
            '[{"attributes":{"type":"Account","url":"/services/data/v47.0/sobjects/Account/001j0000011mR6LAAU"},' +
            '"Id":"001j0000011mR6LAAU",' +
            '"Name":"128 Main Street Realty - Cancelled",' +
            '"Send_Bills_Contact__c":"003j000001LJTYKAA5",' +
            '"RecordTypeId":"012j00000010HeQAAU",' +
            '"Utility_Account_Logs__r":{"totalSize":1,"done":true,"records":[{"attributes":{"type":"Utility_Account_Log__c","url":"/services/data/v47.0/sobjects/Utility_Account_Log__c/a1bj0000001hmg0AAA"},"Account__c":"001j0000011mR6LAAU","Id":"a1bj0000001hmg0AAA","Name":"1665-","Number_of_Removed_UASes__c":1,"Number_of_Subscribed_UASes__c":1,"Last_Date_UAS_Removed_From_Project__c":"2019-03-25"}]},' +
            '"Opportunities":{"totalSize":1,"done":true,"records":[{"attributes":{"type":"Opportunity","url":"/services/data/v47.0/sobjects/Opportunity/006j000000VVn3EAAT"},"AccountId":"001j0000011mR6LAAU","Id":"006j000000VVn3EAAT","Date_Removed_from_Project__c":"'+removedDate.format('yyyy-MM-dd')+'","StageName":"Cancelled"}]},"Send_Bills_Contact__r":{"attributes":{"type":"Contact","url":"/services/data/v47.0/sobjects/Contact/003j000001LJTYKAA5"},"Id":"003j000001LJTYKAA5","FirstName":"James","Email":"foo@bar.com","Additional_Email__c":"foo@bar.com"}}]';

        accounts = (List<Account>) JSON.deserialize(accountWithCancelledAndRemovedOpp, List<Account>.class);
        System.assertEquals(1, CSCancellationService.getAccountsWithDateRemovedSet(accounts).size(), 'Expected an account to get Date Removed set');
        System.assertEquals(
            removedDate.date(),
            CSCancellationService.getAccountsWithDateRemovedSet(accounts)[0].Date_Removed_from_Project__c,
            'Expected Date Removed From Project to get set with the latest Opp Date Removed From Project');

        Datetime laterRemovedDate = Datetime.newInstance(2020,1,13);
        String accountWithTwoCompleteAndRemovedOpps =
            '[{"attributes":{"type":"Account","url":"/services/data/v47.0/sobjects/Account/0010a00001Pw94HAAR"},' +
            '"Id":"0010a00001Pw94HAAR",' +
            '"Name":"Complete LLC",' +
            '"Send_Bills_Contact__c":"0030a0000203IjxAAE",' +
            '"RecordTypeId":"012j00000010HeQAAU",' +
            '"Utility_Account_Logs__r":{"totalSize":1,"done":true,"records":[{"attributes":{"type":"Utility_Account_Log__c","url":"/services/data/v47.0/sobjects/Utility_Account_Log__c/a1b0a000003hJn2AAE"},"Account__c":"0010a00001Pw94HAAR","Id":"a1b0a000003hJn2AAE","Name":"89259-7777","Number_of_Removed_UASes__c":2,"Number_of_Subscribed_UASes__c":2,"Last_Date_UAS_Removed_From_Project__c":"2020-01-13"}]},' +
            '"Opportunities":{"totalSize":2,"done":true,"records":[{"attributes":{"type":"Opportunity","url":"/services/data/v47.0/sobjects/Opportunity/0060a00000fRdh7AAC"},"AccountId":"0010a00001Pw94HAAR","Id":"0060a00000fRdh7AAC","Date_Removed_from_Project__c":"'+laterRemovedDate.format('yyyy-MM-dd')+'","StageName":"Complete"},{"attributes":{"type":"Opportunity","url":"/services/data/v47.0/sobjects/Opportunity/0060a00000fRdh8AAC"},"AccountId":"0010a00001Pw94HAAR","Id":"0060a00000fRdh8AAC","Date_Removed_from_Project__c":"2019-07-26","StageName":"Complete"}]},"Send_Bills_Contact__r":{"attributes":{"type":"Contact","url":"/services/data/v47.0/sobjects/Contact/0030a0000203IjxAAE"},"Id":"0030a0000203IjxAAE","FirstName":"Ronald","Email":"foo@bar.com"}}]';
        accounts = (List<Account>) JSON.deserialize(accountWithTwoCompleteAndRemovedOpps, List<Account>.class);
        System.assertEquals(0, CSCancellationService.getAccountsWithDateRemovedSet(accounts).size(), 'Expected to not get a Date Removed From Project until the opps are cancelled');

        String accountWithTwoCancelledAndRemovedOpps =
            '[{"attributes":{"type":"Account","url":"/services/data/v47.0/sobjects/Account/0010a00001Pw94HAAR"},' +
                '"Id":"0010a00001Pw94HAAR",' +
                '"Name":"Complete LLC",' +
                '"Send_Bills_Contact__c":"0030a0000203IjxAAE",' +
                '"RecordTypeId":"012j00000010HeQAAU",' +
                '"Utility_Account_Logs__r":{"totalSize":1,"done":true,"records":[{"attributes":{"type":"Utility_Account_Log__c","url":"/services/data/v47.0/sobjects/Utility_Account_Log__c/a1b0a000003hJn2AAE"},"Account__c":"0010a00001Pw94HAAR","Id":"a1b0a000003hJn2AAE","Name":"89259-7777","Number_of_Removed_UASes__c":2,"Number_of_Subscribed_UASes__c":2,"Last_Date_UAS_Removed_From_Project__c":"2020-01-13"}]},' +
                '"Opportunities":{"totalSize":2,"done":true,"records":[{"attributes":{"type":"Opportunity","url":"/services/data/v47.0/sobjects/Opportunity/0060a00000fRdh7AAC"},"AccountId":"0010a00001Pw94HAAR","Id":"0060a00000fRdh7AAC","Date_Removed_from_Project__c":"'+laterRemovedDate.format('yyyy-MM-dd')+'","StageName":"Cancelled"},{"attributes":{"type":"Opportunity","url":"/services/data/v47.0/sobjects/Opportunity/0060a00000fRdh8AAC"},"AccountId":"0010a00001Pw94HAAR","Id":"0060a00000fRdh8AAC","Date_Removed_from_Project__c":"2019-07-26","StageName":"Cancelled"}]},"Send_Bills_Contact__r":{"attributes":{"type":"Contact","url":"/services/data/v47.0/sobjects/Contact/0030a0000203IjxAAE"},"Id":"0030a0000203IjxAAE","FirstName":"Ronald","Email":"foo@bar.com"}}]';
        accounts = (List<Account>) JSON.deserialize(accountWithTwoCancelledAndRemovedOpps, List<Account>.class);
        System.assertEquals(1, CSCancellationService.getAccountsWithDateRemovedSet(accounts).size(), 'Expected to not get a Date Removed From Project until the opps are cancelled');
        System.assertEquals(
            laterRemovedDate.date(),
            CSCancellationService.getAccountsWithDateRemovedSet(accounts)[0].Date_Removed_from_Project__c,
            'Expected Date Removed From Project to get set with the latest Opp Date Removed From Project');

        String accountWithOneRemovedOneDuplicateOpp =
            '[{"attributes":{"type":"Account","url":"/services/data/v47.0/sobjects/Account/0010a00001Pw94HAAR"},' +
            '"Id":"0010a00001Pw94HAAR",' +
            '"Name":"Complete LLC",' +
            '"Send_Bills_Contact__c":"0030a0000203IjxAAE",' +
            '"RecordTypeId":"012j00000010HeQAAU",' +
            '"Utility_Account_Logs__r":{"totalSize":1,"done":true,"records":[{"attributes":{"type":"Utility_Account_Log__c","url":"/services/data/v47.0/sobjects/Utility_Account_Log__c/a1b0a000003hJn2AAE"},"Account__c":"0010a00001Pw94HAAR","Id":"a1b0a000003hJn2AAE","Name":"89259-7777","Number_of_Removed_UASes__c":2,"Number_of_Subscribed_UASes__c":2,"Last_Date_UAS_Removed_From_Project__c":"2020-01-13"}]},' +
            '"Opportunities":{"totalSize":2,"done":true,"records":[{"attributes":{"type":"Opportunity","url":"/services/data/v47.0/sobjects/Opportunity/0060a00000fRdh7AAC"},"AccountId":"0010a00001Pw94HAAR","Id":"0060a00000fRdh7AAC","Date_Removed_from_Project__c":"'+laterRemovedDate.format('yyyy-MM-dd')+'","StageName":"Cancelled"},{"attributes":{"type":"Opportunity","url":"/services/data/v47.0/sobjects/Opportunity/0060a00000fRdh8AAC"},"AccountId":"0010a00001Pw94HAAR","Id":"0060a00000fRdh8AAC","StageName":"DUPLICATE"}]},"Send_Bills_Contact__r":{"attributes":{"type":"Contact","url":"/services/data/v47.0/sobjects/Contact/0030a0000203IjxAAE"},"Id":"0030a0000203IjxAAE","FirstName":"Ronald","Email":"foo@bar.com"}}]';
        accounts = (List<Account>) JSON.deserialize(accountWithOneRemovedOneDuplicateOpp, List<Account>.class);
        System.assertEquals(1, CSCancellationService.getAccountsWithDateRemovedSet(accounts).size(), 'Expected an account to get Date Removed set');
        System.assertEquals(
            laterRemovedDate.date(),
            CSCancellationService.getAccountsWithDateRemovedSet(accounts)[0].Date_Removed_from_Project__c,
            'Expected Date Removed From Project to get set with the latest Opp Date Removed From Project, ignoring non-active opps');


    }
}