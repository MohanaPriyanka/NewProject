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
        Shared_Solar_System__c SSS = [
            SELECT Id, Committed_Demand_Capacity__c
            FROM Shared_Solar_System__c
            WHERE Name = 'SSS 2'
            LIMIT 1
        ];
        System.assertEquals(29.4624, SSS.Committed_Demand_Capacity__c, 'Invalid current committed demand capacity');
        Utility__c utility = [
            SELECT Id
            FROM Utility__c
            WHERE Name = 'Eversource'
        ];
        utility.Average_Demand_Threshold__c = 200;
        update utility;
        SSS = [
            SELECT Id, Pending_Demand_Capacity__c, Committed_Demand_Capacity__c, Demand_Customer_System_Utilization__c
            FROM Shared_Solar_System__c
            WHERE Name = 'SSS 2'
            LIMIT 1
        ];
        System.assertEquals(0, SSS.Pending_Demand_Capacity__c, 'Invalid pending demand capacity after demand thresh change');
        System.assertEquals(0, SSS.Committed_Demand_Capacity__c, 'Invalid committed demand capacity after demand thresh change');
        System.assertEquals(0, SSS.Demand_Customer_System_Utilization__c, 'Invalid demand sys util after demand thresh change');
    }

    @IsTest
    private static void testUtilityAccountLogTrigger() {
        // Test AFTER_UPDATE on UtilityTrigger
        Shared_Solar_System__c SSS = [
            SELECT Id, Pending_Demand_Capacity__c, Committed_Demand_Capacity__c, Demand_Customer_System_Utilization__c
            FROM Shared_Solar_System__c
            WHERE Name = 'SSS 2'
            LIMIT 1
        ];
        // 2 UASes:  6.1538 , 0.2308 = 6.3846
        // 1 Anchor: 23.0769
        // All UASes (UAL: Average_Demand__c) are "Demand" => committed demand capacity on SSS should be sum of UASes
        // Subscription Orders use the rounded version of the subscription
        System.assertEquals(0, SSS.Pending_Demand_Capacity__c, 'All opps are Complete and subscriptions active, no pending data');
        System.assertEquals(29.4624, SSS.Committed_Demand_Capacity__c, 'Invalid committed demand capacity');

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
        System.assertEquals(0, SSS.Pending_Demand_Capacity__c, 'All opps are Complete and subscriptions active, no pending data');
        System.assertEquals(29.4624, SSS.Committed_Demand_Capacity__c, 'Invalid committed demand capacity');

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
        Shared_Solar_System__c firstSSS = [
            SELECT Id, Pending_Demand_Capacity__c, Committed_Demand_Capacity__c
            FROM Shared_Solar_System__c
            WHERE Name = 'SSS 2'
            LIMIT 1
        ];
        // 2 UASes:  6.1538 , 0.2308 = 6.3846
        // 1 Anchor: 23.0769
        // All UASes (UAL: Average_Demand__c) are "Demand" => committed demand capacity on SSS should be sum of UASes
        // Subscription Orders use the rounded version of the subscription
        System.assertEquals(0, firstSSS.Pending_Demand_Capacity__c, 'All opps are Complete and subscriptions active, no pending data');
        System.assertEquals(29.4624, firstSSS.Committed_Demand_Capacity__c, 'Invalid committed demand capacity');

        // Move Opportunity from 'Complete' to any other stage, notice that pending and committed fields change
        Opportunity opp = [
            SELECT Id
            FROM Opportunity
            WHERE Name = 'Alyssa Testcase2 0000236'
        ];
        opp.StageName = 'Pending BlueWave Review';
        update opp;

        firstSSS = [
            SELECT Id, Pending_Demand_Capacity__c, Committed_Demand_Capacity__c
            FROM Shared_Solar_System__c
            WHERE Name = 'SSS 2'
            LIMIT 1
        ];
        System.assertEquals(6.1536, firstSSS.Pending_Demand_Capacity__c, 'Invalid pending demand due to opp change');
        System.assertEquals(23.3088, firstSSS.Committed_Demand_Capacity__c, 'Invalid pending demand due to opp change');
    }

    @IsTest
    private static void testUASAfterInsert() {
        Shared_Solar_System__c SSS = [
            SELECT Id, Pending_Demand_Capacity__c, Committed_Demand_Capacity__c
            FROM Shared_Solar_System__c
            WHERE Name = 'SSS 2'
            LIMIT 1
        ];
        // 2 UASes:  6.1538 , 0.2308 = 6.3846
        // 1 Anchor: 23.0769
        // All UASes (UAL: Average_Demand__c) are "Demand" => committed demand capacity on SSS should be sum of UASes
        // Subscription Orders use the rounded version of the subscription
        System.assertEquals(0, SSS.Pending_Demand_Capacity__c, 'All opps are Complete and subscriptions active, no pending data');
        System.assertEquals(29.4624, SSS.Committed_Demand_Capacity__c, 'Invalid committed demand capacity');

        Utility_Account_Subscription__c existingUAS = [
            SELECT Utility_Account_Log__c, Opportunity__c, Shared_Solar_System__c, Sizing_Method__c, Next_Schedule_Z_Status__c,
                Annual_kwh_subscription_future__c
            FROM Utility_Account_Subscription__c
            WHERE Name = '0000236'
        ];
        Utility_Account_Subscription__c newUAS = existingUAS.clone();
        insert newUAS;

        Shared_Solar_System__c SSSafterInsert = [
            SELECT Id, Pending_Demand_Capacity__c, Committed_Demand_Capacity__c
            FROM Shared_Solar_System__c
            WHERE Name = 'SSS 2'
            LIMIT 1
        ];
        System.assertEquals(0, SSSafterInsert.Pending_Demand_Capacity__c, 'Invalid rollup after insertion of new UAS');
        System.assertEquals(35.6160, SSSafterInsert.Committed_Demand_Capacity__c, 'Invalid rollup after insertion of new UAS');
    }

    @IsTest
    private static void testUASAfterUpdate() {
        // Test innocuous change that should not adjust capacity fields
        Shared_Solar_System__c SSS = [
            SELECT Id, Pending_Demand_Capacity__c, Committed_Demand_Capacity__c
            FROM Shared_Solar_System__c
            WHERE Name = 'SSS 2'
            LIMIT 1
        ];
        // 2 UASes:  6.1538 , 0.2308 = 6.3846
        // 1 Anchor: 23.0769
        // All UASes (UAL: Average_Demand__c) are "Demand" => committed demand capacity on SSS should be sum of UASes
        // Subscription Orders use the rounded version of the subscription
        System.assertEquals(0, SSS.Pending_Demand_Capacity__c, 'All opps are Complete and subscriptions active, no pending data');
        System.assertEquals(29.4624, SSS.Committed_Demand_Capacity__c, 'Invalid committed demand capacity');

        Utility_Account_Subscription__c existingUAS = [
            SELECT Utility_Account_Log__c, Opportunity__c, Shared_Solar_System__c, Sizing_Method__c, Next_Schedule_Z_Status__c,
                Annual_kwh_subscription_future__c
            FROM Utility_Account_Subscription__c
            WHERE Name = '0000236'
        ];
        existingUAS.Name = '0000236b';
        update existingUAS;

        SSS = [
            SELECT Id, Pending_Demand_Capacity__c, Committed_Demand_Capacity__c
            FROM Shared_Solar_System__c
            WHERE Name = 'SSS 2'
            LIMIT 1
        ];
        System.assertEquals(0, SSS.Pending_Demand_Capacity__c, 'Incorrect pending capacity on system');
        System.assertEquals(29.4624, SSS.Committed_Demand_Capacity__c, 'Invalid committed demand capacity');

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

        SSS = [
            SELECT Id, Pending_Demand_Capacity__c, Committed_Demand_Capacity__c
            FROM Shared_Solar_System__c
            WHERE Name = 'SSS 2'
            LIMIT 1
        ];
        System.assertEquals(0, SSS.Pending_Demand_Capacity__c, 'Incorrect pending capacity on system');
        System.assertEquals(35.6160, SSS.Committed_Demand_Capacity__c, 'Invalid committed demand capacity');
    }

    @IsTest
    private static void testUASAfterDeleteUndelete() {
        // Test deletion of UAS
        Shared_Solar_System__c SSS = [
            SELECT Id, Pending_Demand_Capacity__c, Committed_Demand_Capacity__c
            FROM Shared_Solar_System__c
            WHERE Name = 'SSS 2'
            LIMIT 1
        ];
        // 2 UASes:  6.1538 , 0.2308 = 6.3846
        // 1 Anchor: 23.0769
        // All UASes (UAL: Average_Demand__c) are "Demand" => committed demand capacity on SSS should be sum of UASes
        // Subscription Orders use the rounded version of the subscription
        System.assertEquals(0, SSS.Pending_Demand_Capacity__c, 'Invalid pending demand capacity');
        System.assertEquals(29.4624, SSS.Committed_Demand_Capacity__c, 'Invalid committed demand capacity');

        Utility_Account_Subscription__c existingUAS = [
            SELECT Utility_Account_Log__c, Opportunity__c, Shared_Solar_System__c, Sizing_Method__c, Next_Schedule_Z_Status__c,
                Annual_kwh_subscription_future__c
            FROM Utility_Account_Subscription__c
            WHERE Name = '0000236'
        ];
        delete existingUAS;

        SSS = [
            SELECT Id, Pending_Demand_Capacity__c, Committed_Demand_Capacity__c
            FROM Shared_Solar_System__c
            WHERE Name = 'SSS 2'
            LIMIT 1
        ];
        System.assertEquals(0, SSS.Pending_Demand_Capacity__c, 'Invalid pending demand capacity');
        System.assertEquals(23.3088, SSS.Committed_Demand_Capacity__c, 'Invalid committed demand capacity after deleting UAS');

        // Undelete UAS previously deleted, validate that SSS has updated data now?
        undelete [SELECT Id FROM Utility_Account_Subscription__c WHERE Id =: existingUAS.Id ALL ROWS];
        SSS = [
            SELECT Id, Pending_Demand_Capacity__c, Committed_Demand_Capacity__c
            FROM Shared_Solar_System__c
            WHERE Name = 'SSS 2'
            LIMIT 1
        ];
        System.assertEquals(0, SSS.Pending_Demand_Capacity__c, 'Invalid pending demand capacity');
        System.assertEquals(29.4624, SSS.Committed_Demand_Capacity__c, 'Invalid committed demand capacity');
    }
}