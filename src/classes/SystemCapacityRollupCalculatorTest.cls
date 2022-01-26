/**
 * @description Created by jeffparlin on 9/13/21.
 * Purely system integration tests intended for realtime rollup calculations processed by SystemCapacityRollupCalculator
 */
@IsTest
public without sharing class SystemCapacityRollupCalculatorTest {

    @TestSetup
    private static void insertTestData() {
        SharedSolarSystemHandlerTest.setupData();
    }

    @IsTest
    private static void testUtilityTrigger() {
        // Test AFTER_UPDATE on UtilityTrigger -- update Average_Demand_Threshold__c
        Shared_Solar_System__c sss = [
            SELECT Id, Committed_Demand_Capacity__c
            FROM Shared_Solar_System__c
            WHERE Name = 'SSS 2'
            LIMIT 1
        ];
        System.assertEquals(29.4624, sss.Committed_Demand_Capacity__c, 'Invalid current committed demand capacity');
        Utility__c utility = [
            SELECT Id
            FROM Utility__c
            WHERE Name = 'Eversource'
        ];
        utility.Average_Demand_Threshold__c = 200;
        update utility;
        sss = [
            SELECT Id, Pending_Demand_Capacity__c, Committed_Demand_Capacity__c, Demand_Customer_System_Utilization__c
            FROM Shared_Solar_System__c
            WHERE Name = 'SSS 2'
            LIMIT 1
        ];
        System.assertEquals(0, sss.Pending_Demand_Capacity__c, 'Invalid pending demand capacity after demand thresh change');
        System.assertEquals(0, sss.Committed_Demand_Capacity__c, 'Invalid committed demand capacity after demand thresh change');
        System.assertEquals(0, sss.Demand_Customer_System_Utilization__c, 'Invalid demand sys util after demand thresh change');

        // Test disabled utility trigger causing no recalculation
        Util.disableTrigger('Disable_UtilityTrigger__c');
        utility.Average_Demand_Threshold__c = 25;
        update utility;
        sss = [
            SELECT Id, Pending_Demand_Capacity__c, Committed_Demand_Capacity__c, Demand_Customer_System_Utilization__c
            FROM Shared_Solar_System__c
            WHERE Name = 'SSS 2'
            LIMIT 1
        ];
        System.assertEquals(0, sss.Pending_Demand_Capacity__c, 'Invalid pending demand capacity after demand thresh change');
        System.assertEquals(0, sss.Committed_Demand_Capacity__c, 'Invalid committed demand capacity after demand thresh change');
        System.assertEquals(0, sss.Demand_Customer_System_Utilization__c, 'Invalid demand sys util after demand thresh change');
    }

    @IsTest
    private static void testUtilityAccountLogTrigger() {
        // Test AFTER_UPDATE on UtilityTrigger
        Shared_Solar_System__c sss = [
            SELECT Id, Pending_Demand_Capacity__c, Committed_Demand_Capacity__c, Demand_Customer_System_Utilization__c
            FROM Shared_Solar_System__c
            WHERE Name = 'SSS 2'
            LIMIT 1
        ];
        // 2 UASes:  6.1538 , 0.2308 = 6.3846
        // 1 Anchor: 23.0769
        // All UASes (UAL: Average_Demand__c) are "Demand" => committed demand capacity on SSS should be sum of UASes
        // Subscription Orders use the rounded version of the subscription
        System.assertEquals(0, sss.Pending_Demand_Capacity__c, 'All opps are Complete and subscriptions active, no pending data');
        System.assertEquals(29.4624, sss.Committed_Demand_Capacity__c, 'Invalid committed demand capacity');

        // Set exclusion criteria for demand capacity on UAL 2, which should remove committed demand capacity from SSS
        Id ualId = [SELECT Id FROM Utility_Account_Log__c WHERE Name = '0000236'].Id;
        update new Utility_Account_Log__c(
            Id = ualId,
            Exclude_from_Demand_Capacity__c = true
        );
        Shared_Solar_System__c sssUpdated = [
            SELECT Committed_Demand_Capacity__c, Demand_Customer_System_Utilization__c, Pending_Demand_Capacity__c
            FROM Shared_Solar_System__c WHERE Name = 'SSS 2' LIMIT 1
        ];
        System.assertEquals(0, sssUpdated.Pending_Demand_Capacity__c, 'All opps are Complete and subscriptions active, no pending data');
        System.assertEquals(23.3088, sssUpdated.Committed_Demand_Capacity__c, 'Incorrect committed demand capacity');
        System.assertEquals(72.84, sssUpdated.Demand_Customer_System_Utilization__c, 'Incorrect demand utilization');

        // Reset state and check SSS
        update new Utility_Account_Log__c(
            Id = ualId,
            Exclude_from_Demand_Capacity__c = false
        );
        sssUpdated = [
            SELECT Committed_Demand_Capacity__c, Demand_Customer_System_Utilization__c, Pending_Demand_Capacity__c
            FROM Shared_Solar_System__c WHERE Name = 'SSS 2' LIMIT 1
        ];
        System.assertEquals(0, sss.Pending_Demand_Capacity__c, 'All opps are Complete and subscriptions active, no pending data');
        System.assertEquals(29.4624, sss.Committed_Demand_Capacity__c, 'Invalid committed demand capacity');

        // Test AFTER_UPDATE -- change Average_Demand__c to below utility threshold
        update new Utility_Account_Log__c(
            Id = ualId,
            Average_Demand__c = 10
        );
        sssUpdated = [
            SELECT Committed_Demand_Capacity__c, Demand_Customer_System_Utilization__c, Pending_Demand_Capacity__c
            FROM Shared_Solar_System__c WHERE Name = 'SSS 2' LIMIT 1
        ];
        System.assertEquals(0, sssUpdated.Pending_Demand_Capacity__c, 'All opps are Complete and subscriptions active, no pending data');
        System.assertEquals(23.3088, sssUpdated.Committed_Demand_Capacity__c, 'Incorrect committed demand capacity');
        System.assertEquals(72.84, sssUpdated.Demand_Customer_System_Utilization__c, 'Incorrect demand utilization');
    }

    @IsTest
    private static void testOpportunityTrigger() {
        // Test AFTER_UPDATE on UtilityTrigger
        Shared_Solar_System__c sss = [
            SELECT Id, Pending_Demand_Capacity__c, Committed_Demand_Capacity__c
            FROM Shared_Solar_System__c
            WHERE Name = 'SSS 2'
            LIMIT 1
        ];
        // 2 UASes:  6.1538 , 0.2308 = 6.3846
        // 1 Anchor: 23.0769
        // All UASes (UAL: Average_Demand__c) are "Demand" => committed demand capacity on SSS should be sum of UASes
        // Subscription Orders use the rounded version of the subscription
        System.assertEquals(0, sss.Pending_Demand_Capacity__c, 'All opps are Complete and subscriptions active, no pending data');
        System.assertEquals(29.4624, sss.Committed_Demand_Capacity__c, 'Invalid committed demand capacity');

        // Move Opportunity from 'Complete' to any other stage, notice that pending and committed fields change
        Opportunity opp = [
            SELECT Id
            FROM Opportunity
            WHERE Name = 'Alyssa Testcase2 0000236'
        ];
        opp.StageName = 'Pending Perch Signature';
        update opp;

        sss = [
            SELECT Id, Pending_Demand_Capacity__c, Committed_Demand_Capacity__c
            FROM Shared_Solar_System__c
            WHERE Name = 'SSS 2'
            LIMIT 1
        ];
        System.assertEquals(6.1536, sss.Pending_Demand_Capacity__c, 'Invalid pending demand due to opp change');
        System.assertEquals(23.3088, sss.Committed_Demand_Capacity__c, 'Invalid pending demand due to opp change');

        // Modify opp customer group to anchor
        sss = [
            SELECT Id, Client_Acq_Pending_Anchor_Capacity__c
            FROM Shared_Solar_System__c
            WHERE Name = 'SSS 2'
            LIMIT 1
        ];
        System.assertEquals(0, sss.Client_Acq_Pending_Anchor_Capacity__c, 'Invalid pending anchor capacity');
        opp.Customer_Group__c = 'Anchor';
        update opp;
        sss = [
            SELECT Id, Client_Acq_Pending_Anchor_Capacity__c
            FROM Shared_Solar_System__c
            WHERE Name = 'SSS 2'
            LIMIT 1
        ];
        System.assertEquals(6.1536, sss.Client_Acq_Pending_Anchor_Capacity__c, 'Pending anchor capacity should have updated from opp chg');
    }

    @IsTest
    private static void testUASAfterInsert() {
        Shared_Solar_System__c sss = [
            SELECT Id, Pending_Demand_Capacity__c, Committed_Demand_Capacity__c
            FROM Shared_Solar_System__c
            WHERE Name = 'SSS 2'
            LIMIT 1
        ];
        // 2 UASes:  6.1538 , 0.2308 = 6.3846
        // 1 Anchor: 23.0769
        // All UASes (UAL: Average_Demand__c) are "Demand" => committed demand capacity on SSS should be sum of UASes
        // Subscription Orders use the rounded version of the subscription
        System.assertEquals(0, sss.Pending_Demand_Capacity__c, 'All opps are Complete and subscriptions active, no pending data');
        System.assertEquals(29.4624, sss.Committed_Demand_Capacity__c, 'Invalid committed demand capacity');

        Utility_Account_Subscription__c existingUAS = [
            SELECT Utility_Account_Log__c, Opportunity__c, Shared_Solar_System__c, Sizing_Method__c, Next_Schedule_Z_Status__c
            FROM Utility_Account_Subscription__c
            WHERE Name = '0000236'
        ];
        Utility_Account_Subscription__c newUAS = existingUAS.clone();
        insert newUAS;
        TestSOCreator.createByCapacity(newUAS, 8000);

        Shared_Solar_System__c sssAfterInsert = [
            SELECT Id, Pending_Demand_Capacity__c, Committed_Demand_Capacity__c
            FROM Shared_Solar_System__c
            WHERE Name = 'SSS 2'
            LIMIT 1
        ];
        System.assertEquals(0, sssAfterInsert.Pending_Demand_Capacity__c, 'Invalid rollup after insertion of new UAS');
        System.assertEquals(35.6160, sssAfterInsert.Committed_Demand_Capacity__c, 'Invalid rollup after insertion of new UAS');
    }

    @IsTest
    private static void testUASAfterUpdate() {
        // Test innocuous change that should not adjust capacity fields
        Shared_Solar_System__c sss = [
            SELECT Id, Pending_Demand_Capacity__c, Committed_Demand_Capacity__c
            FROM Shared_Solar_System__c
            WHERE Name = 'SSS 2'
            LIMIT 1
        ];
        // 2 UASes:  6.1538 , 0.2308 = 6.3846
        // 1 Anchor: 23.0769
        // All UASes (UAL: Average_Demand__c) are "Demand" => committed demand capacity on SSS should be sum of UASes
        // Subscription Orders use the rounded version of the subscription
        System.assertEquals(0, sss.Pending_Demand_Capacity__c, 'All opps are Complete and subscriptions active, no pending data');
        System.assertEquals(29.4624, sss.Committed_Demand_Capacity__c, 'Invalid committed demand capacity');

        Utility_Account_Subscription__c existingUAS = [
            SELECT Utility_Account_Log__c, Opportunity__c, Shared_Solar_System__c, Sizing_Method__c, Next_Schedule_Z_Status__c
            FROM Utility_Account_Subscription__c
            WHERE Name = '0000236'
        ];
        existingUAS.Name = '0000236b';
        update existingUAS;

        sss = [
            SELECT Id, Pending_Demand_Capacity__c, Committed_Demand_Capacity__c
            FROM Shared_Solar_System__c
            WHERE Name = 'SSS 2'
            LIMIT 1
        ];
        System.assertEquals(0, sss.Pending_Demand_Capacity__c, 'Incorrect pending capacity on system');
        System.assertEquals(29.4624, sss.Committed_Demand_Capacity__c, 'Invalid committed demand capacity');

        // Test change that should trigger rollup recalculation resulting in different system capacity values
        // Increase one subscription:
        Subscription_Order__c resizeSubscriptionOrder = new Subscription_Order__c(
            Utility_Account_Subscription__c = existingUAS.Id,
            New_Annual_kWh__c = 16000,
            Type__c = 'Resize',
            Approval_Status__c = 'Approved',
            Effective_Date__c = System.now()
        );
        insert resizeSubscriptionOrder;

        sss = [
            SELECT Id, Pending_Demand_Capacity__c, Committed_Demand_Capacity__c
            FROM Shared_Solar_System__c
            WHERE Name = 'SSS 2'
            LIMIT 1
        ];
        System.assertEquals(0, sss.Pending_Demand_Capacity__c, 'Incorrect pending capacity on system');
        System.assertEquals(35.6160, sss.Committed_Demand_Capacity__c, 'Invalid committed demand capacity');
    }

    @IsTest
    private static void testUASAfterDeleteUndelete() {
        // Test deletion of UAS
        Shared_Solar_System__c sss = [
            SELECT Id, Pending_Demand_Capacity__c, Committed_Demand_Capacity__c
            FROM Shared_Solar_System__c
            WHERE Name = 'SSS 2'
            LIMIT 1
        ];
        // 2 UASes:  6.1538 , 0.2308 = 6.3846
        // 1 Anchor: 23.0769
        // All UASes (UAL: Average_Demand__c) are "Demand" => committed demand capacity on SSS should be sum of UASes
        // Subscription Orders use the rounded version of the subscription
        System.assertEquals(0, sss.Pending_Demand_Capacity__c, 'Invalid pending demand capacity');
        System.assertEquals(29.4624, sss.Committed_Demand_Capacity__c, 'Invalid committed demand capacity');

        Utility_Account_Subscription__c existingUAS = [
            SELECT Utility_Account_Log__c, Opportunity__c, Shared_Solar_System__c, Sizing_Method__c, Next_Schedule_Z_Status__c
            FROM Utility_Account_Subscription__c
            WHERE Name = '0000236'
        ];
        delete existingUAS;

        sss = [
            SELECT Id, Pending_Demand_Capacity__c, Committed_Demand_Capacity__c
            FROM Shared_Solar_System__c
            WHERE Name = 'SSS 2'
            LIMIT 1
        ];
        System.assertEquals(0, sss.Pending_Demand_Capacity__c, 'Invalid pending demand capacity');
        System.assertEquals(23.3088, sss.Committed_Demand_Capacity__c, 'Invalid committed demand capacity after deleting UAS');

        // Undelete UAS previously deleted, validate that SSS has updated data now?
        undelete [SELECT Id FROM Utility_Account_Subscription__c WHERE Id =: existingUAS.Id ALL ROWS];
        sss = [
            SELECT Id, Pending_Demand_Capacity__c, Committed_Demand_Capacity__c
            FROM Shared_Solar_System__c
            WHERE Name = 'SSS 2'
            LIMIT 1
        ];
        System.assertEquals(0, sss.Pending_Demand_Capacity__c, 'Invalid pending demand capacity');
        System.assertEquals(29.4624, sss.Committed_Demand_Capacity__c, 'Invalid committed demand capacity');
    }
}