/**
 * Created by PeterYao_6fwtfg1 on 3/13/2022.
 */
@IsTest
private with sharing class PerchOneAPIHelperTest {
    @IsTest
    private static void testPerchOneCallout() {
        GraphQLNode node = new GraphQLNode('foo');
        GraphQLQuery query = new GraphQLQuery(node, null);
        Account account = new Account(Name='Foo');
        String expectedResponse = JSON.serialize(account);
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new PerchOneMock(expectedResponse));
        HttpResponse response = new PerchOneAPIHelper().callGraphQlEndpoint('POST', query);
        Test.stopTest();

        System.assertEquals(expectedResponse, response.getBody(),
            'Expected to get a response from the callout');

    }

    private class PerchOneMock implements HttpCalloutMock {
        private String response;
        public PerchOneMock(String response) {
            this.response = response;
        }
        public HttpResponse respond(HttpRequest request) {
            HttpResponse httpResponse = new HttpResponse();
            httpResponse.setHeader('Content-Type', 'application/json');
            httpResponse.setStatusCode(200);
            httpResponse.setBody(response);
            return httpResponse;
        }
    }

}