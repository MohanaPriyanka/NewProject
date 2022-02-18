/**
 * Created by jeffr on 3/2/2021.
 */
@IsTest
public with sharing class DefaultUtilityFeeSelectorTest {

    private static Utility__c insertUtility() {
        Utility__c utility = new Utility__c(
            Name = 'Utility'
        );
        insert utility;
        return utility;
    }

    @IsTest
    private static void getActiveUCBRecordForUtilityTest() {
        // Test Setup
        Utility__c utility = insertUtility();
        Default_Utility_Fee__c feeRecordOne = new Default_Utility_Fee__c(
            Type__c = 'UCB',
            Utility_Admin_Fee__c = 0.01, // Percent
            Start_Date__c = Date.today().addDays(-1),
            End_Date__c = Date.today().addDays(30),
            Method_for_UCB_Utility_Admin__c = 'CDG Subscription Fee',
            Utility__c = utility.Id
        );
        Default_Utility_Fee__c feeRecordTwo = new Default_Utility_Fee__c(
            Type__c = 'UCB',
            Utility_Admin_Fee__c = 0.01, // Percent
            Start_Date__c = Date.today().addDays(-31),
            End_Date__c = Date.today().addDays(-1),
            Method_for_UCB_Utility_Admin__c = 'Calculated Credits',
            Utility__c = utility.Id
        );
        Default_Utility_Fee__c feeRecordThree = new Default_Utility_Fee__c(
            Type__c = 'UCB',
            Utility_Admin_Fee__c = 0.01, // Percent
            Start_Date__c = Date.today().addDays(-62),
            End_Date__c = Date.today().addDays(-32),
            Method_for_UCB_Utility_Admin__c = 'Calculated Credits',
            Utility__c = utility.Id
        );
        List<Default_Utility_Fee__c> feeRecords = new List<Default_Utility_Fee__c>{
            feeRecordOne, feeRecordTwo, feeRecordThree
        };
        insert feeRecords;

        // Test run & verify query results
        DefaultUtilityFeeSelector selector = new DefaultUtilityFeeSelector();
        Default_Utility_Fee__c feeRecordFromQuery = selector.getActiveUCBRecordForUtility(utility.Id);

        // Assertions
        System.assert(feeRecordFromQuery != null, 'Query for Default_Utility_Fee__c should return a result');
        System.assertEquals(feeRecords[0].Utility_Admin_Fee__c, feeRecordFromQuery.Utility_Admin_Fee__c, 'Incorrect field val');
        System.assertEquals(feeRecords[0].Start_Date__c, feeRecordFromQuery.Start_Date__c, 'Incorrect field val');
        System.assertEquals('CDG Subscription Fee', feeRecordFromQuery.Method_for_UCB_Utility_Admin__c, 'Incorrect picklist val');
    }
}