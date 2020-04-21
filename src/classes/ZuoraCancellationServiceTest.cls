/**
 * Created by peteryao on 4/21/20.
 */
@IsTest
public with sharing class ZuoraCancellationServiceTest {
    @IsTest
    private static void testStartDataQuery() {
        List<Zuora_Data_Query__c> queries = [SELECT Id, Query__c FROM Zuora_Data_Query__c];
        System.assertEquals(0, queries.size());
        ZuoraCancellationService.queryAndCancelAllSubscriptions();
        queries = [SELECT Id, Query__c FROM Zuora_Data_Query__c];
        System.assertEquals(1, queries.size());
    }

    @IsTest
    private static void testCancellationPostQueryJob() {
        ZuoraCancellationService cancellationService = new ZuoraCancellationService();
        String json = '[' +
            '{"Name":"A-S00027332","AccountNumber":"bw-04229"},' +
            '{"Name":"A-S00027339","AccountNumber":"bw-04278"},' +
            '{"Name":"A-S00027344","AccountNumber":"bw-04434"},' +
            '{"Name":"A-S00027364","AccountNumber":"bw-04163"},' +
            '{"Name":"A-S00027366","AccountNumber":"bw-04164"},' +
            '{"Name":"A-S00027371","AccountNumber":"bw-04171"},' +
            '{"Name":"A-S00027390","AccountNumber":"bw-04207"},' +
            '{"Name":"A-S00027394","AccountNumber":"bw-04250"},' +
            '{"Name":"A-S00027398","AccountNumber":"bw-04988"},' +
            '{"Name":"A-S00027404","AccountNumber":"bw-04421"}' +
            ']';
        Test.startTest();
        cancellationService.executePostQueryJob(null, json);
        Test.stopTest();

        System.assertEquals(10, ZuoraAPIHelper.endpointsCalled.size(), 'Expected a cancellation for each subscription retrieved');
        for (ZuoraAPIHelper.EndpointCall endpointCall : ZuoraAPIHelper.endpointsCalled) {
            System.assertEquals('/v1/orders', endpointCall.endpoint);
        }
    }
}