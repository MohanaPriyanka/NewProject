/*************************************************************************************
Created By Jordan Pentaleri 08/2019
Tested By: ZuoraDataQueryServiceTest
*************************************************************************************/

public class ZuoraDataQueryAsyncService implements Queueable, Database.AllowsCallouts {
    public ZuoraDataQueryService.DataQueryResult zuoraQueryResult;
    public ZuoraDataQueryService.DataQueryRequest attemptedQuery;
    private static ZuoraDataQuerySelector zuoraDataQuerySelector = new ZuoraDataQuerySelector();

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
        Integer minutesToRetry = (Integer) Util.getSystemPropertyDecimal('Zuora_Data_Query_Minutes_To_Retry__c');
        minutesToRetry = minutesToRetry==0 ? 120 : minutesToRetry;

        if (zuoraQueryResult.data.queryStatus != null && zuoraQueryResult.data.id != null) {
            Zuora_Data_Query__c dataQuery = zuoraDataQuerySelector.selectDataQueryById(attemptedQuery.recordId);
            dataQuery.Zuora_Id__c = zuoraQueryResult.data.id;
            dataQuery.Status__c = zuoraQueryResult.data.queryStatus;

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
            update dataQuery;
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
            String dataAsString = convertDataQueryResponseToJSON(zuoraQueryResult.data.allData);
            dataQueryToUpdate.Link_To_File__c = zuoraQueryResult.data.dataFile;
            // Truncate because Link_To_File__c contains the actual data, Data_From_Zuora__c should really only
            // be used for small data sets or as a preview:
            dataQueryToUpdate.Data_From_Zuora__c = dataAsString.substring(0, Math.min(dataAsString.length(), 131000));
            dataQueryToUpdate.Output_Rows__c = zuoraQueryResult.data.outputRows;
            if (dataAsString != '[{}]' && dataQueryToUpdate.Processing_Parameter__c != null) {
                ZuoraDataQueryService.ProcessingParameter processingParameter =
                    (ZuoraDataQueryService.ProcessingParameter) JSON.deserialize(dataQueryToUpdate.Processing_Parameter__c, ZuoraDataQueryService.ProcessingParameter.class);
                ZuoraDataQueryService.handlePostQueryJob(dataAsString, processingParameter);
            }
        } catch(Exception excep) {
            String errorMessage = String.valueOf(zuoraQueryResult) + '\n' + excep.getMessage() + '\n' + excep.getStackTraceString();
            Logger.logNow('ZuoraDataQueryAsyncService', 'handleCompletedQuery', errorMessage);
        }
        return dataQueryToUpdate;
    }

    private String convertDataQueryResponseToJSON(String response) {
        response = response.replace('}','},');
        response = response.removeEnd(',');
        response = '[' + response + ']';
        response = response.replace('__c','_Zcustom');
        return response;
    }
}