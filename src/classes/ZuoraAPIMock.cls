/*************************************************************************************
 * Created By: peteryao on 2019-04-18  
 * Description: 
 * Test: 
 *************************************************************************************/

global with sharing class ZuoraAPIMock implements HttpCalloutMock {
    global HttpResponse respond(HttpRequest req) {
        // Only send a mock response for a specific endpoint and method.
        String endpoint = req.getEndpoint();

        // Create a fake response
        if (endpoint.contains('rsa-signatures')) {
            return getRSASignatures();
        } else if (endpoint.contains('payment-method')) {
            return getPaymentMethod();
        } else if (endpoint.contains('error')) {
            return getError();
        } else {
            return null;
        }
    }

    private static HttpResponse getError() {
        HttpResponse res = getJSON();
        res.setBody('{' +
            '"success" : false,' +
            '"processId" : "CF0CA553D1BCC2E9",' +
            '"reasons" : [ {' +
            '"code" : 59010020,' +
            '"message" : "There is no hosted page with id \'2c92c0f86a073552016a081d7330157\'."' +
            '} ]' +
            '}');
        return res;
    }

    private static HttpResponse getRSASignatures() {
        HttpResponse res = getJSON();
        res.setBody('{' +
            '"signature" : "VL7d7uWfqAltF6XdBRIcjzq9PsK0I8ujn8o+lJzYoNYK+12oRa+MqG3+PvY/GAMluJCYQEgKXYNc0M0qTBJbgfIwC/EGYHzejKdZ2xtdOVGYkChJePRCpxG+YC7xgJI0oiKxRJmCWU/rYAYjaasVvhfJfG0H4a8Ay3t3NIXWFZQGxi7Rvz2EzVOuU0mYPUFIpyAe+yP3yHdv9v96fJMmGdxyf3HRvhw9+7bh1KlDWSsN9gjaV37cUBpUhJoCnHCGEwZyywcXSNlBIilXF+nE6zSHq2flNaUS2zWmFnNGpNvLMkA3FJ6rLpXkNN3DEt4/gbU3Jz5Sh++zGoBYVhV28A==",'+
            '"token" : "gIZRABPzLJjsxk5BEAhgrdJe7pjVM7cP",' +
            '"tenantId" : "30689",' +
            '"key" : "MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAnUbOqAz8j7zKK3dYwdUw/8RJjx6NA5kkQSwCjutHaKpkLsi2bxRRiZfjKiaivXbDWmqSI+n6wxW7b+4tq8IT6h6ot7QknSsTxXBNTfQ74L4S/AOKb3O2QDZgw9BMN7jPd+HbFvJRYPney87Vze5n43u4ZHzoYKrbIuaOk6LHGfQmo5YeBLA69S1Uha8DS+5eiS7UQv5I1ZwRUw/C71ZP4xE0Sn+fjKwgoABrVnU2y/bBwJc3SWGQdoLbJyi6NEQSzExisIuafcA9LL4lPaaA9L76zhBz+3xyQGc6MxNHQT7th+Q+negZBsM2VVTPPrvCsdX+gxL19yBjleuA6mtQbQIDAQAB",' +
            '"success" : true}');
        return res;
    }

    private static HttpResponse getPaymentMethod() {
        HttpResponse res = getJSON();
        res.setBody('{' +
            '"CreditCardExpirationMonth":2,' +
            '"Active":false,' +
            '"Id":"2c92c0f86a0c41a5016a1f41d63a2f96",' +
            '"CreditCardExpirationYear":2022,' +
            '"UpdatedDate":"2019-04-15T04:29:28.000+00:00",' +
            '"CreditCardPostalCode":"12345",' +
            '"IsCompany":false,' +
            '"CreditCardType":"AmericanExpress",' +
            '"LastTransactionStatus":"Approved",' +
            '"UpdatedById":"3",' +
            '"BankIdentificationNumber":"370000",' +
            '"CreatedDate":"2019-04-15T04:29:28.000+00:00",' +
            '"TotalNumberOfProcessedPayments":0,' +
            '"PaymentMethodStatus":"Active",' +
            '"NumConsecutiveFailures":0,' +
            '"TotalNumberOfErrorPayments":0,' +
            '"CreditCardMaskNumber":"***********0002",' +
            '"CreatedById":"3",' +
            '"LastTransactionDateTime":"2019-04-15T04:29:29.000+00:00",' +
            '"UseDefaultRetryRule":true,' +
            '"Type":"CreditCard",' +
            '"CreditCardHolderName":"Test"' +
            '}');
        return res;
    }

    public static HttpResponse getJSON() {
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        res.setStatusCode(200);
        return res;
    }
}