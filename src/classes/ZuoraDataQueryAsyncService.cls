/*************************************************************************************
Created By Jordan Pentaleri 08/2019
Tested By: ZuoraDataQueryServiceTest
*************************************************************************************/

public class ZuoraDataQueryAsyncService implements Queueable, Database.AllowsCallouts {
    public ZuoraDataQueryService.DataQueryResult zuoraQuery;
    public ZuoraDataQueryService.MethodToRunAfter method;
    public Id sfRecordId;

    public void execute(QueueableContext context) {
        try {
            checkZuoraQueryStatus();
        } catch(Exception excep) {
            String errorMessage = String.valueOf(zuoraQuery) + '\n' + excep.getMessage() + '\n' + excep.getStackTraceString();
            Logger.logNow('ZuoraDataQueryAsyncService', 'runCheck', errorMessage);
        }
    }

    public void checkZuoraQueryStatus(){
        zuoraQuery = ZuoraDataQueryService.checkDataQueryStatus(zuoraQuery);

        if (zuoraQuery.data.queryStatus != null && zuoraQuery.data.id != null) {
            // Query can be fired from UI or from Apex
            // If made from UI, update existing record
            // If made from Apex, insert new record
            Zuora_Data_Query__c dataQuery = new Zuora_Data_Query__c();
            dataQuery.Zuora_Id__c = zuoraQuery.data.id;
            dataQuery.Status__c = zuoraQuery.data.queryStatus;
            if (sfRecordId != null) {
                dataQuery.Id = sfRecordId;
            }

            // If job is complete, save data to record
            // If job failed, save errors to record
            // If not complete, update status then re-queue job:
            if (zuoraQuery.data.queryStatus == 'completed') {
                dataQuery = handleCompletedQuery(dataQuery);
            } else if (zuoraQuery.data.queryStatus == 'failed'){
                dataQuery.Data_From_Zuora__c = String.valueOf(zuoraQuery);
            }
            upsert dataQuery Id;
            if (zuoraQuery.data.queryStatus == 'in_progress' || zuoraQuery.data.queryStatus == 'accepted') {
                queueCheckDataQueryStatus(zuoraQuery, method , dataQuery.Id);
            }
        }
    }

    public static void queueCheckDataQueryStatus(   ZuoraDataQueryService.DataQueryResult zuoraQuery,
                                                    ZuoraDataQueryService.MethodToRunAfter methodToRun,
                                                    Id recordId) {
        ZuoraDataQueryAsyncService checkStatus = new ZuoraDataQueryAsyncService();
        checkStatus.zuoraQuery = zuoraQuery;
        checkStatus.method = methodToRun;
        checkStatus.sfRecordId = recordId;
        System.enqueueJob(checkStatus);
    }

    public Zuora_Data_Query__c handleCompletedQuery (Zuora_Data_Query__c dataQueryToUpdate){
        try {
            zuoraQuery = ZuoraDataQueryService.getDataFromDataQuery(zuoraQuery);
            String dataAsString = zuoraQuery.data.allData;
            dataQueryToUpdate.Link_To_File__c = zuoraQuery.data.dataFile;
            // Truncate because Link_To_File__c contains the actual data, Data_From_Zuora__c should really only
            // be used for small data sets or as a preview:
            dataQueryToUpdate.Data_From_Zuora__c = dataAsString.subString(0, math.min(dataAsString.length(), 131000));
            dataQueryToUpdate.Output_Rows__c = zuoraQuery.data.outputRows;
            if (dataAsString != '{}') {
                ZuoraDataQueryService.handlePostQueryJob(dataAsString, method);
            }
        } catch(Exception excep) {
            String errorMessage = String.valueOf(zuoraQuery) + '\n' + excep.getMessage() + '\n' + excep.getStackTraceString();
            Logger.logNow('ZuoraDataQueryAsyncService', 'handleCompletedQuery', errorMessage);
        }
        return dataQueryToUpdate;
    }
}