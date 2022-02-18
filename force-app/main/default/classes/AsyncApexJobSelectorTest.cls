/**
 * Created by JeffreyParlin on 9/11/2020.
 */
@isTest
public with sharing class AsyncApexJobSelectorTest {

    @IsTest
    private static void testGetBatchCompletions() {
        // Test setup
        Account a = new Account(Name = 'Test');
        GenericBatchDMLOperation batch = new GenericBatchDMLOperation(
            new List<Account>{a},
            'Insert'
        );

        // Run test
        Test.startTest();
        Id BatchId = Database.executeBatch(batch);
        Test.stopTest();

        // Verify results
        AsyncApexJob[] batchResults = AsyncApexJobSelector.getBatchCompletions(new List<String>{BatchId});
        system.assert(!batchResults.isEmpty(),'getBatchCompletions returned no rows in Test');
    }

}