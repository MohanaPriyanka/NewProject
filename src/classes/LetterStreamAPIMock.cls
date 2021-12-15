/**
 * Created by mstackhouse on 8/1/2018.
 * Description: Mocks LetterStream API Responses
 * Test: LetterStreamServiceTest
 */

@IsTest
public class LetterStreamAPIMock implements HttpCalloutMock {
    public HttpResponse respond(HttpRequest req) {
        String exampleResponse = '<?xml version="1.0" encoding="UTF-8"?>' +
            '<messages id="bluewave">' +
            '<message type="info">' +
            '<code>-100</code>' +
            '<details>Success</details>' +
            '<batch>' + Date.today().format() + '_Job_' + '1' + '</batch>' +
            '<quantity>1</quantity>' +
            '<cost>1.41</cost>';
        exampleResponse += '<doc>';
        exampleResponse += ('<id>' + 'sampleId' + '</id>');
        exampleResponse += '<job>1234567</job>';
        exampleResponse += '<cost>1.41</cost>';
        exampleResponse += '</doc>';
        exampleResponse += '</message></messages>';
        HttpResponse response = new HttpResponse();
        response.setBody(exampleResponse);
        response.setStatus('200');
        response.setHeader('Content-Type', 'text/xml');
        return response;
    }
}