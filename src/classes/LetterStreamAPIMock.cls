/**
 * Created by mstackhouse on 8/1/2018.
 * Description: Mocks LetterStream API Responses
 * Test: LetterStreamServiceTest
 */

@isTest
global class LetterStreamAPIMock implements WebServiceMock, HttpCalloutMock {
    global HTTPResponse respond(HTTPRequest req) {
        // Only send a mock response for a specific endpoint and method.
        String endpoint = req.getEndpoint();

        // Create a fake response
        if (endpoint == 'https://secure.letterstream.com/apis/') {
            return handleRequest();
        }
    }

    public static handleRequest() {

    }
}