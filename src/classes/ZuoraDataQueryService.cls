/*************************************************************************************
Created By Jordan Pentaleri 08/2019
Tested By: ZuoraDataQueryServiceTest,ZuoraPaymentServiceTest (for retry testing)
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

        public String getQueryId() {
            if (data != null) {
                return data.id;
            }
            return null;
        }

        public String getQueryStatus() {
            if (data != null) {
                return data.queryStatus;
            }
            return null;
        }

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

    public class ProcessingParameter {
        public String className;
        // optional variables:
        public String methodName;
        public Date startDate;
        public Date endDate;
        public Map<String,Date> optionalDates;
        public Set<Id> recordIds;
        public Map<String, Integer> optionalIntegers;
        public Map<String, String> optionalStrings;
        public Map<String, Boolean> optionalBooleans;
        private final String RETRY_ON_EXCEPTION = 'RetryOnException';
        @TestVisible
        private final String RETRY_ATTEMPT = 'RetryAttempt';
        public ProcessingParameter() {
        }
        public ProcessingParameter(String className) {
            this.className = className;
        }
        public void enableRetries() {
            if (optionalBooleans == null) {
                optionalBooleans = new Map<String, Boolean>();
            }
            optionalBooleans.put(RETRY_ON_EXCEPTION, true);
            if (optionalIntegers == null) {
                optionalIntegers = new Map<String, Integer>();
            }
            optionalIntegers.put(RETRY_ATTEMPT, 0);
        }
        public Boolean shouldRetry(Decimal maxRetries) {
            if (optionalBooleans == null || optionalIntegers == null) {
                return false;
            }
            Boolean retryOnBWException = optionalBooleans.get(RETRY_ON_EXCEPTION);
            Integer retryAttempt = optionalIntegers.get(RETRY_ATTEMPT);
            return (retryOnBWException != null && retryOnBWException &&
                retryAttempt != null && retryAttempt <= maxRetries);
        }
        public void incrementRetryAttempt() {
            if (optionalIntegers == null) {
                return;
            }
            optionalIntegers.put(RETRY_ATTEMPT, optionalIntegers.get(RETRY_ATTEMPT)+1);
        }
    }

    public interface Processor {
        void executePostQueryJob(ProcessingParameter method, String response);
    }

    public class DataQueryRequest{
        public String queryString;
        public Integer numberOfRetries;
        public Id recordId;
        public DataQueryRequest() {
        }
        public DataQueryRequest(Zuora_Data_Query__c zuoraDataQuery) {
            this.queryString = zuoraDataQuery.Query__c;
            this.numberOfRetries = Integer.valueOf(zuoraDataQuery.Number_of_Retries__c);
            this.recordId = zuoraDataQuery.Id;
        }
    }

    public DataQueryRequest scheduledQuery;

    /*  Fired off insertion of Data Query record
        Even though this can handle >1 query at once, Zuora in practice, does not perform
        well when multiple queries are running at the same time. */
    public static void callFromTrigger(List<Zuora_Data_Query__c> sfDataQueries) {
        for (Zuora_Data_Query__c record : sfDataQueries){
            if (record.Query__c != null && record.Zuora_Id__c == null) {
                DataQueryRequest query = new DataQueryRequest();
                query.queryString = record.Query__c;
                query.numberOfRetries = (Integer) record.Number_of_Retries__c;
                query.recordId = record.Id;
                String queryToExecuteAsString = JSON.serialize(query);
                callDataQueryInFuture(queryToExecuteAsString);
            }
        }
    }

    public static Zuora_Data_Query__c callFromApexWithCallout(String queryString, ProcessingParameter processingParameter) {
        ZuoraDataQueryService.DataQueryResult dataQueryResult = ZuoraDataQueryService.submitDataQuery(queryString);
        Zuora_Data_Query__c zuoraDataQuery = new Zuora_Data_Query__c(
            Query__c = queryString,
            Processing_Parameter__c = JSON.serialize(processingParameter, true),
            Number_of_Retries__c = 2,
            Zuora_Id__c = dataQueryResult.getQueryId(),
            Status__c = dataQueryResult.getQueryStatus()
        );
        insert zuoraDataQuery;
        ZuoraDataQueryAsyncService.queueCheckDataQueryStatus(dataQueryResult, new DataQueryRequest(zuoraDataQuery));
        return zuoraDataQuery;
    }

    public static void callFromApex(String queryString, ProcessingParameter processingParameter) {
        Zuora_Data_Query__c zuoraDataQuery = new Zuora_Data_Query__c(
            Query__c = queryString,
            Processing_Parameter__c = JSON.serialize(processingParameter, true),
            Number_of_Retries__c = 2
        );
        insert zuoraDataQuery;
    }

    public void execute(SchedulableContext ctx){
        String queryToExecuteAsString = JSON.serialize(scheduledQuery);
        callDataQueryInFuture(queryToExecuteAsString);
    }

    @Future(Callout=true)
    @TestVisible
    private static void callDataQueryInFuture(String queryToExecuteAsString) {
        try {
            // To avoid 'Future Methods do not support parameter type error':
            DataQueryRequest request = new DataQueryRequest();
            if (queryToExecuteAsString != null) {
                request = (DataQueryRequest) JSON.deserialize(queryToExecuteAsString, DataQueryRequest.class);
            }
            DataQueryResult result = submitDataQuery(request.queryString);
            // If response comes back with errors, save messages to the Data Query record (ex. malformed query failures)
            if (result.code != null){
                Zuora_Data_Query__c dataQuery = new Zuora_Data_Query__c(
                    Id = request.recordId,
                    Data_From_Zuora__c = String.valueOf(result),
                    Status__c = 'failed'
                );
                update dataQuery;
                // If successful, queue calls to check on the query status (in progress -> to complete)
            } else {
                ZuoraDataQueryAsyncService.queueCheckDataQueryStatus(result, request);
            }
        } catch (Exception e) {
            Logger.logLater('ZuoraDataQueryService', 'callDataQueryInFuture', e.getMessage() + '\n' + e.getStackTraceString(), Logger.ERROR);
        } finally {
            Logger.flushLogs();
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

    public static void handlePostQueryJob(String response, ProcessingParameter method){
        if (method != null && method.className != null) {
            Processor jobToProcess = (Processor) Type.forName(method.className).newInstance();
            jobToProcess.executePostQueryJob(method, response);
            Logger.logNow('ZuoraDataQueryService', 'handlePostQueryJob', Util.getLimits() + '\n' + JSON.serialize(method), Logger.INFO);
        }
    }

    public class RetriableException extends Exception {}
}