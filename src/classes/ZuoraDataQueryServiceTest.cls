@isTest
public class ZuoraDataQueryServiceTest {
    @TestSetup
    public static void testSetup(){
        ZuoraAPIHelperTest.testSetup();
    }

    @IsTest
    private static void submitDataQuery() {
        ZuoraDataQueryService.DataQueryResult result;
        result = ZuoraDataQueryService.submitDataQuery('SHOW Columns FROM Account');

        System.assertEquals('7742a20c-18ea-4fde-b185-4aed364ce22c', result.data.Id);
        System.assertEquals('accepted', result.data.queryStatus);
    }

    @IsTest
    private static void checkDataQueryStatus() {
        ZuoraDataQueryService.DataQueryResult result;
        result = ZuoraDataQueryService.submitDataQuery('SHOW Columns FROM Account');

        System.assertEquals('7742a20c-18ea-4fde-b185-4aed364ce22c', result.data.Id);
        System.assertEquals('accepted', result.data.queryStatus);

        // Changing the Id mocks the time it takes for Zuora to run the query:
        result.data.Id = 'queryStillInProcess';
        result = ZuoraDataQueryService.checkDataQueryStatus(result);
        System.assertEquals('in_progress', result.data.queryStatus);

        result.data.Id = 'queryCompleted';
        result = ZuoraDataQueryService.checkDataQueryStatus(result);
        System.assertEquals('completed', result.data.queryStatus);

        String allDataAsString = result.getDataFromDataQuery();
        System.assert(allDataAsString.length() > 200);
    }

    @IsTest
    private static void testQueryFromUI() {
        Test.startTest();
        Zuora_Data_Query__c newQueryFromUI = new Zuora_Data_Query__c();
        newQueryFromUI.Query__c = 'SHOW Columns FROM Account';
        insert newQueryFromUI;
        Test.stopTest();

        List<Zuora_Data_Query__c> queries = [
            SELECT Id, Query__c, Status__c, Zuora_Id__c, Data_From_Zuora__c
            FROM Zuora_Data_Query__c
        ];

        System.assertEquals(1, queries.size());
        System.assertEquals('7742a20c-18ea-4fde-b185-4aed364ce22c', queries[0].Zuora_Id__c);
        System.assertEquals('completed', queries[0].Status__c);
        String dataAsString = queries[0].Data_From_Zuora__c;
        System.assert(dataAsString.length() > 200);
    }

    @IsTest
    private static void testQueryFromApex() {
        List<Zuora_Data_Query__c> queries = [
            SELECT Id, Query__c, Status__c, Zuora_Id__c, Data_From_Zuora__c
            FROM Zuora_Data_Query__c
        ];
        System.assertEquals(0,queries.size());

        Test.startTest();
        ZuoraDataQueryService.callFromApex('SHOW Columns FROM Account', null);
        Test.stopTest();

        List<Zuora_Data_Query__c> updatedQueries = [
            SELECT Id, Query__c, Status__c, Zuora_Id__c, Data_From_Zuora__c
            FROM Zuora_Data_Query__c
        ];

        System.assertEquals(1,updatedQueries.size());
        System.assertEquals('7742a20c-18ea-4fde-b185-4aed364ce22c', updatedQueries[0].Zuora_Id__c);
        System.assertEquals('completed', updatedQueries[0].Status__c);
        String dataAsString = updatedQueries[0].Data_From_Zuora__c;
        System.assert(dataAsString.length() > 200);
    }

    @IsTest
    private static void testAsyncStatusUpdate() {
        List<Zuora_Data_Query__c> queries = [
            SELECT Id, Query__c, Status__c, Zuora_Id__c, Data_From_Zuora__c
            FROM Zuora_Data_Query__c
        ];
        System.assertEquals(0,queries.size());

        ZuoraDataQueryService.DataQueryResult result = new ZuoraDataQueryService.DataQueryResult();
        ZuoraDataQueryService.DataQueryData dataResult = new ZuoraDataQueryService.DataQueryData();
        dataResult.Id = 'queryCompleted';
        result.data = dataResult;

        ZuoraDataQueryService.DataQueryRequest request = new ZuoraDataQueryService.DataQueryRequest();

        Test.startTest();
        ZuoraDataQueryAsyncService.queueCheckDataQueryStatus(result, request);
        Test.stopTest();

        List<Zuora_Data_Query__c> updatedQueries = [
            SELECT Id, Query__c, Status__c, Zuora_Id__c, Data_From_Zuora__c
            FROM Zuora_Data_Query__c
        ];

        System.assertEquals(1,updatedQueries.size());
        System.assertEquals('7742a20c-18ea-4fde-b185-4aed364ce22c', updatedQueries[0].Zuora_Id__c);
        System.assertEquals('completed', updatedQueries[0].Status__c);
        String dataAsString = updatedQueries[0].Data_From_Zuora__c;
        System.assert(dataAsString.length() > 200);
    }

    @IsTest
    private static void testFailedAsyncUpdate() {
        List<Zuora_Data_Query__c> queries = [
            SELECT Id, Query__c, Status__c, Zuora_Id__c, Data_From_Zuora__c
            FROM Zuora_Data_Query__c
        ];
        System.assertEquals(0,queries.size());

        Zuora_Data_Query__c newQueryFromUI = new Zuora_Data_Query__c();
        insert newQueryFromUI;

        ZuoraDataQueryService.DataQueryResult result = new ZuoraDataQueryService.DataQueryResult();
        ZuoraDataQueryService.DataQueryData dataResult = new ZuoraDataQueryService.DataQueryData();
        dataResult.Id = 'queryFailed';
        result.data = dataResult;

        ZuoraDataQueryService.DataQueryRequest request = new ZuoraDataQueryService.DataQueryRequest();
        request.recordId = newQueryFromUI.Id;
        request.numberOfRetries = 3;

        Test.startTest();
        ZuoraDataQueryAsyncService.queueCheckDataQueryStatus(result, request);
        Test.stopTest();

        List<Zuora_Data_Query__c> updatedQueries = [
            SELECT Id, Query__c, Status__c, Zuora_Id__c, Data_From_Zuora__c
            FROM Zuora_Data_Query__c
        ];

        System.assertEquals(1,updatedQueries.size());
        System.assertEquals('7742a20c-18ea-4fde-b185-4aed364ce22c', updatedQueries[0].Zuora_Id__c);
        System.assertEquals('failed', updatedQueries[0].Status__c);
        String dataAsString = updatedQueries[0].Data_From_Zuora__c;
        System.assert(dataAsString.contains('Query failed'));

        Datetime dtNow = Datetime.now();

        List<AsyncApexJob> scheduledJobs = [
            SELECT ApexClassId, Id, JobItemsProcessed, JobType,
                Status, NumberOfErrors, MethodName
            FROM AsyncApexJob
            WHERE JobType = 'ScheduledApex'
        ];

        System.assertEquals(1,scheduledJobs.size());
    }
}