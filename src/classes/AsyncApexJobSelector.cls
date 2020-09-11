/*************************************************************************************
 * Created By: Jeff Parlin on 2020-09-11
 * Description: Can extend fflib_SObjectSelector
 * Test: AsyncApexJobSelector
 *************************************************************************************/

public without sharing class AsyncApexJobSelector {

    /**
     * Selector to return Batch Jobs meeting the criteria of 'Aborted', 'Completed', or 'Failed'
     * </p>
     * Intended for use with Flows and <code>c-bluewave-batch-result</code>
     *
     * @param batchIds List of Batch IDs to query
     *
     * @return AsyncApexJob[] - List of SObjects corresponding to Batch process instances
     */
    @AuraEnabled(cacheable=false)
    public static List<AsyncApexJob> getBatchCompletions(List<String> batchIds) {
        // Query information on Batch
        return [
            SELECT
                CompletedDate,
                ExtendedStatus,
                Id,
                JobItemsProcessed,
                JobType,
                NumberOfErrors,
                Status,
                TotalJobItems
            FROM AsyncApexJob
            WHERE Id IN :batchIds AND Status IN ('Aborted', 'Completed', 'Failed') AND JobType = 'BatchApex'
        ];
    }

}