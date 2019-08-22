/*************************************************************************************
Created By Jordan Pentaleri 08/2019
Tested By: ZuoraDataQueryServiceTest
*************************************************************************************/

public class ZuoraDataQueryService {
    public class DataQuery {
        public String compression;
        public DataQueryOutput output;
        public String outputFormat;
        public String query;
    }

    public class DataQueryOutput {
        public String target;
    }

    public class DataQueryResult {
        public DataQueryData data;
        public String code;
        public String message;
    }

    public class DataQueryData {
        public String id;
        public String queryStatus;
        public Integer outputRows;
        public String dataFile;
        public String allData;
        public String errorCode;
        public String errorMessage;
    }

    public class MethodToRunAfter {
        public String methodName;
        // optional variables:
        public Date startDate;
        public Date endDate;
    }

    /*  Fired off insertion of Data Query record
        Even though this can handle >1 query at once, Zuora in practice, does not perform
        well when multiple queries are running at the same time. */
    public static void callFromTrigger(List<Zuora_Data_Query__c> sfDataQueries) {
        for (Zuora_Data_Query__c record : sfDataQueries){
            if (record.Query__c != null){
                callDataQueryinFuture(record.Query__c, null, record.Id);
            }
        }
    }

    public static void callFromApex(String queryString, MethodToRunAfter methodToRunWhenComplete) {
        String methodAsString = JSON.serialize(methodToRunWhenComplete);
        callDataQueryinFuture(queryString, methodAsString, null);
    }

    @Future(callout=true)
    public static void callDataQueryinFuture(String queryString, String methodAsString, Id recordId) {
        // To avoid 'Future Methods do not support parameter type error':
        MethodToRunAfter methodToRunNext = new MethodToRunAfter();
        if (methodAsString != null) {
            methodToRunNext = (MethodToRunAfter) JSON.deserialize(methodAsString, MethodToRunAfter.class);
        }
        DataQueryResult result = submitDataQuery(queryString);
        // If response comes back with errors, save messages to the Data Query record (ex. malformed query failures)
        if (result.code != null){
            Zuora_Data_Query__c dataQuery = new Zuora_Data_Query__c(
                Data_From_Zuora__c = String.valueOf(result),
                Status__c = 'failed'
            );
            if (recordId != null) {
                dataQuery.Id = recordId;
            }
            upsert dataQuery;
        // If successful, queue calls to check on the query status (in progress -> to complete)
        } else {
            ZuoraDataQueryAsyncService.queueCheckDataQueryStatus(result, methodToRunNext, recordId);
        }
    }

    public static DataQueryResult submitDataQuery(String queryString) {
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

    public static DataQueryResult getDataFromDataQuery(DataQueryResult dataResult) {
        HttpRequest request = new HttpRequest();
        request.setEndpoint(dataResult.data.dataFile);
        request.setMethod('GET');

        HttpResponse response = new HttpResponse();
        if (Test.isRunningTest()) {
            response = new ZuoraAPIMock().respond(request);
        } else {
            response =  new Http().send(request);
        }
        dataResult.data.allData = response.getBody();
        return dataResult;
    }

    public static void handlePostQueryJob(String response, MethodToRunAfter method){
        try {
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
            }
        } catch (Exception excep) {
            Logger.logNow('ZuoraDataQueryService', 'handlePostQueryJob', 'for method: ' + method + excep.getMessage() + '\n' + excep.getStackTraceString());
        }
    }
}