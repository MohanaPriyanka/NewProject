/**
 * Created by mstackhouse on 8/1/2018.
 * Description: Mocks LetterStream API Responses
 * Test: LetterStreamServiceTest
 */

@IsTest
public class LetterStreamAPIMock implements HttpCalloutMock {
    public List<Account_Bill__c> accountBills;

    public LetterStreamAPIMock() {
        Account_Bill__c accountBill = new Account_Bill__c(
            Id = Util.getFakeId(Account_Bill__c.SObjectType)
        );
        accountBills = new List<Account_Bill__c>{accountBill};
    }

    public LetterStreamAPIMock(List<Account_Bill__c> accountBills) {
        this.accountBills = accountBills;
    }

    public HttpResponse respond(HttpRequest req) {
        // Only send a mock response for a specific endpoint and method.
        String endpoint = req.getEndpoint();

        String exampleResponse = '<?xml version="1.0" encoding="UTF-8"?>' +
            '<messages id="bluewave">' +
            '<message type="info">' +
            '<code>-100</code>' +
            '<details>Success</details>' +
            '<batch>' + Date.today().format() + '_Job_' + '1' + '</batch>' +
            '<quantity>' + accountBills.size() + '</quantity>' +
            '<cost>' + (accountBills.size() * 1.41) + '</cost>';
        for (Account_Bill__c accountBill : accountBills) {
            exampleResponse += '<doc>';
            exampleResponse += ('<id>' + accountBill.Id + '</id>');
            exampleResponse += '<job>1234567</job>';
            exampleResponse += '<cost>1.41</cost>';
            exampleResponse += '</doc>';
        }
        exampleResponse += '</message></messages>';
        HttpResponse response = new HttpResponse();
        response.setBody(exampleResponse);
        response.setStatus('200');
        response.setHeader('Content-Type', 'text/xml');
        return response;
    }
}