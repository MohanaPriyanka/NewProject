/*************************************************************************************
Created By Jordan Pentaleri 08/2019
Tested By: ZuoraDataQueryServiceTest
*************************************************************************************/

// Suppressing Excessive Public Count because so many methods/variables are shared between
// ZuoraDataQueryService and ZuoraDataQueryAsyncService, its hard to mark many as private:
@SuppressWarnings('PMD.ApexCRUDViolation, PMD.ExcessivePublicCount')
public without sharing class ZuoraDataQueryService implements Schedulable{
    private class DataQuery {
        private String compression;
        private DataQueryOutput output;
        private String outputFormat;
        private String query;
    }

    private class DataQueryOutput {
        private String target;
    }

    public class DataQueryResult {
        public DataQueryData data;
        private String code;
        private String message;

        public String getDataFromDataQuery(){
            HttpRequest request = new HttpRequest();
            request.setEndpoint(data.dataFile);
            request.setMethod('GET');

            HttpResponse response = new HttpResponse();
            if (Test.isRunningTest()) {
                response = new ZuoraAPIMock().respond(request);
            } else {
                response =  new Http().send(request);
            }
            this.data.allData = response.getBody();
            return data.allData;
        }
    }

    public class DataQueryData {
        public String id;
        public String queryStatus;
        public Integer outputRows;
        public String dataFile;
        public String allData;
        private String errorCode;
        private String errorMessage;
    }

    public class MethodToRunAfter {
        public String methodName;
        // optional variables:
        public Date startDate;
        public Date endDate;
        public Set<Id> recordIds;
    }

    public class DataQueryRequest{
        public String queryString;
        public Integer numberOfRetries;
        public Id recordId; // only populated for queries from UI (insert trigger)
        public MethodToRunAfter method; // only populated for apex/scheduled queries
    }

    public DataQueryRequest scheduledQuery;

    /*  Fired off insertion of Data Query record
        Even though this can handle >1 query at once, Zuora in practice, does not perform
        well when multiple queries are running at the same time. */
    public static void callFromTrigger(List<Zuora_Data_Query__c> sfDataQueries) {
        for (Zuora_Data_Query__c record : sfDataQueries){
            if (record.Query__c != null){
                DataQueryRequest query = new DataQueryRequest();
                query.queryString = record.Query__c;
                query.numberOfRetries = 0;
                query.recordId = record.Id;
                query.method = null;
                String queryToExecuteAsString = JSON.serialize(query);
                callDataQueryinFuture(queryToExecuteAsString);
            }
        }
    }

    public static void callFromApex(String queryString, MethodToRunAfter methodToRunWhenComplete) {
        DataQueryRequest query = new DataQueryRequest();
        query.queryString = queryString;
        query.numberOfRetries = 2;
        query.recordId = null;
        query.method = methodToRunWhenComplete;
        String queryToExecuteAsString = JSON.serialize(query);
        callDataQueryinFuture(queryToExecuteAsString);
    }

    public void execute(SchedulableContext ctx){
        String queryToExecuteAsString = JSON.serialize(scheduledQuery);
        callDataQueryinFuture(queryToExecuteAsString);
    }

    @Future(callout=true)
    @TestVisible
    private static void callDataQueryinFuture(String queryToExecuteAsString) {
        // To avoid 'Future Methods do not support parameter type error':
        DataQueryRequest request = new DataQueryRequest();
        if (queryToExecuteAsString != null) {
            request = (DataQueryRequest) JSON.deserialize(queryToExecuteAsString, DataQueryRequest.class);
        }
        DataQueryResult result = submitDataQuery(request.queryString);
        // If response comes back with errors, save messages to the Data Query record (ex. malformed query failures)
        if (result.code != null){
            Zuora_Data_Query__c dataQuery = new Zuora_Data_Query__c(
                Data_From_Zuora__c = String.valueOf(result),
                Status__c = 'failed'
            );
            if (request.recordId != null) {
                dataQuery.Id = request.recordId;
            }
            upsert dataQuery;
        // If successful, queue calls to check on the query status (in progress -> to complete)
        } else {
            ZuoraDataQueryAsyncService.queueCheckDataQueryStatus(result, request);
        }
    }

    @TestVisible
    private static DataQueryResult submitDataQuery(String queryString) {
        DataQueryResult dataResult = new DataQueryResult();
        try {
            DataQueryOutput outputTarget = new DataQueryOutput();
            outputTarget.target = 'S3';

            DataQuery dataQuery = new DataQuery();
            dataQuery.compression = 'NONE';
            dataQuery.output = outputTarget;
            dataQuery.outputFormat = 'JSON';
            dataQuery.query = queryString;

            HttpResponse response = ZuoraAPIHelper.callJSONEndpointWithOAuth('POST', '/query/jobs', dataQuery, false);
            dataResult = (DataQueryResult) JSON.deserialize(response.getBody(), DataQueryResult.class);
        } catch (Exception excep) {
            Logger.logNow('ZuoraDataQueryService', 'submitDataQuery', 'for query: ' + queryString + excep.getMessage() + '\n' + excep.getStackTraceString());
        }
        return dataResult;
    }

    public static DataQueryResult checkDataQueryStatus(DataQueryResult dataResult) {
        HttpResponse response = ZuoraAPIHelper.callJSONEndpointWithOAuth('GET','/query/jobs/' + dataResult.data.id,null, false);
        String responseBody = response.getBody();
        dataResult = (DataQueryResult)JSON.deserialize(responseBody, DataQueryResult.class);
        return dataResult;
    }

    public static void handlePostQueryJob(String response, MethodToRunAfter method){
        try {
            // Zuora's response isn't true JSON, so we have to modify to be able to deserialize:
            response = response.replace('}','},');
            response = response.substring(0,response.length()-1);
            response = '[' + response + ']';

            switch on method.methodName {
                // GL Methods: Insert one object's journal entries, then queue next object:
                when 'GL_InvoiceItem' {
                    ZuoraGLService.generalGLRecordInsert(response, 'InvoiceItem');
                    String queryString = ZuoraGLSelector.getCreditMemos(method.startDate, method.endDate);
                    method.methodName = 'GL_CreditMemo';
                    ZuoraDataQueryService.callFromApex(queryString,method);
                }
                when 'GL_CreditMemo' {
                    ZuoraGLService.generalGLRecordInsert(response, 'CreditMemo');
                    String queryString = ZuoraGLSelector.getDebitMemos(method.startDate, method.endDate);
                    method.methodName = 'GL_DebitMemo';
                    ZuoraDataQueryService.callFromApex(queryString,method);
                }
                when 'GL_DebitMemo' {
                    ZuoraGLService.generalGLRecordInsert(response, 'DebitMemo');
                    String queryString = ZuoraGLSelector.getPaymentPartsDM(method.startDate, method.endDate);
                    method.methodName = 'GL_PaymentPartDM';
                    ZuoraDataQueryService.callFromApex(queryString,method);
                }
                when 'GL_PaymentPartDM' {
                    ZuoraGLService.generalGLRecordInsert(response, 'PaymentPart');
                    String queryString = ZuoraGLSelector.getPaymentPartsIV(method.startDate, method.endDate);
                    method.methodName = 'GL_PaymentPartIV';
                    ZuoraDataQueryService.callFromApex(queryString,method);
                }
                when 'GL_PaymentPartIV' {
                    ZuoraGLService.generalGLRecordInsert(response, 'PaymentPart');
                }
                when 'updateDaysPastDue' {
                    ZuoraBillingAccountService.updateDaysPastDue(response,method.recordIds);
                }
                when 'updateCustomTemplateFields' {
                    ZuoraController.updateCustomTemplateFields(response);
                }
            }
        } catch (Exception excep) {
            Logger.logNow('ZuoraDataQueryService', 'handlePostQueryJob', 'for method: ' + method + excep.getMessage() + '\n' + excep.getStackTraceString());
        }
    }
}