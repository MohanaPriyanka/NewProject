/*************************************************************************************
Created By Jordan Pentaleri 08/2019
Tested By: ZuoraDataQueryServiceTest
*************************************************************************************/

public class ZuoraDataQueryAsyncService implements Queueable, Database.AllowsCallouts {
    public ZuoraDataQueryService.DataQueryResult zuoraQueryResult;
    public ZuoraDataQueryService.DataQueryRequest attemptedQuery;

    public void execute(QueueableContext context) {
        try {
            checkZuoraQueryStatus();
        } catch(Exception excep) {
            String errorMessage = String.valueOf(zuoraQueryResult) + '\n' + excep.getMessage() + '\n' + excep.getStackTraceString();
            Logger.logNow('ZuoraDataQueryAsyncService', 'runCheck', errorMessage);
        }
    }

    private void checkZuoraQueryStatus(){
        zuoraQueryResult = ZuoraDataQueryService.checkDataQueryStatus(zuoraQueryResult);
        Integer minutesToRetry = 120;
        List<System_Properties__c> systemProperties = System_Properties__c.getAll().values();
        if (systemProperties.size() > 0 && systemProperties[0].get('Zuora_Data_Query_Minutes_To_Retry__c') != null) {
            minutesToRetry = (Integer)systemProperties[0].get('Zuora_Data_Query_Minutes_To_Retry__c');
        }
        if (zuoraQueryResult.data.queryStatus != null && zuoraQueryResult.data.id != null) {
            // Query can be fired from UI or from Apex
            // If made from UI, update existing record
            // If made from Apex, insert new record
            Zuora_Data_Query__c dataQuery = new Zuora_Data_Query__c();
            dataQuery.Zuora_Id__c = zuoraQueryResult.data.id;
            dataQuery.Status__c = zuoraQueryResult.data.queryStatus;
            if (attemptedQuery.recordId != null) {
                dataQuery.Id = attemptedQuery.recordId;
            }

            // If job is complete, save data to record
            // If job failed, save errors to record
            // If not complete, update status then re-queue job:
            if (zuoraQueryResult.data.queryStatus == 'completed') {
                dataQuery = handleCompletedQuery(dataQuery);
            } else if (zuoraQueryResult.data.queryStatus == 'failed' && attemptedQuery.numberOfRetries > 0){
                // Because we sometimes see system issues in Zuora (due to the volume of requests at certain times)
                // we want to schedule a retry a few hours after the initial request:
                attemptedQuery.numberOfRetries -= 1;
                ZuoraDataQueryService newQueryJob = new ZuoraDataQueryService();
                newQueryJob.scheduledQuery = attemptedQuery;
                Datetime dt = Datetime.now().addMinutes(minutesToRetry);
                String cronExpress = '0 '+ dt.minute() + ' ' + dt.hour() + ' ' + dt.day() + ' ' + dt.month() + ' ?';
                System.schedule('DataQuery: ' + dataQuery.Zuora_Id__c,cronExpress,newQueryJob);
                Logger.logNow(
                    'ZuoraDataQueryAsyncService',
                    'scheduledRetry',
                    'Retrying this Query in ' + String.valueOf(minutesToRetry) + ' minutes: ' + String.valueOf(attemptedQuery) + String.valueOf(zuoraQueryResult),
                    'WARN'
                );
                dataQuery.Data_From_Zuora__c = 'Will Retry: ' + String.valueOf(zuoraQueryResult);
            } else if (zuoraQueryResult.data.queryStatus == 'failed'){
                dataQuery.Data_From_Zuora__c = 'Will not retry, hit error: ' + String.valueOf(zuoraQueryResult);
            }
            upsert dataQuery Id;
            if (zuoraQueryResult.data.queryStatus == 'in_progress' || zuoraQueryResult.data.queryStatus == 'accepted') {
                attemptedQuery.recordId = dataQuery.Id;
                queueCheckDataQueryStatus(zuoraQueryResult, attemptedQuery);
            }
        }
    }

    public static void queueCheckDataQueryStatus( ZuoraDataQueryService.DataQueryResult zuoraQueryResult,
                                                  ZuoraDataQueryService.DataQueryRequest queryToExecute){
        ZuoraDataQueryAsyncService checkStatus = new ZuoraDataQueryAsyncService();
        checkStatus.attemptedQuery = queryToExecute;
        checkStatus.zuoraQueryResult = zuoraQueryResult;
        System.enqueueJob(checkStatus);
    }

    private Zuora_Data_Query__c handleCompletedQuery (Zuora_Data_Query__c dataQueryToUpdate){
        try {
            zuoraQueryResult.getDataFromDataQuery();
            String dataAsString = zuoraQueryResult.data.allData;
            dataQueryToUpdate.Link_To_File__c = zuoraQueryResult.data.dataFile;
            // Truncate because Link_To_File__c contains the actual data, Data_From_Zuora__c should really only
            // be used for small data sets or as a preview:
            dataQueryToUpdate.Data_From_Zuora__c = dataAsString.subString(0, math.min(dataAsString.length(), 131000));
            dataQueryToUpdate.Output_Rows__c = zuoraQueryResult.data.outputRows;
            if (dataAsString != '{}') {
                ZuoraDataQueryService.handlePostQueryJob(dataAsString, attemptedQuery.method);
            }
        } catch(Exception excep) {
            String errorMessage = String.valueOf(zuoraQueryResult) + '\n' + excep.getMessage() + '\n' + excep.getStackTraceString();
            Logger.logNow('ZuoraDataQueryAsyncService', 'handleCompletedQuery', errorMessage);
        }
        return dataQueryToUpdate;
    }
}