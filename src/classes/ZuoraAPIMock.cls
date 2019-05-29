/*************************************************************************************
 * Created By: peteryao on 2019-04-18  
 * Description: 
 * Test: 
 *************************************************************************************/

global with sharing class ZuoraAPIMock implements HttpCalloutMock {
    public static String genericId = '2c92c0f96a6e3c3f016a6fc817180743';

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
        } else if (endpoint.contains('v1/object/account')) {
            return getGenericSuccess();
        } else if (endpoint.contains('v1/object/contact')) {
            return getGenericSuccess();
        } else if (endpoint.contains('v1/action/create')) {
            return getActionCreate(req.getBody());
        } else if (endpoint.contains('v1/action/update')) {
            return getActionUpdate(req.getBody());
        } else if (endpoint.contains('v1/action/query')) {
            return getActionQuery(req.getBody());
        } else if (endpoint.contains('v1/action/delete')) {
            return getActionDelete(req.getBody());
        } else if (endpoint.contains('v1/orders/subscriptionOwner')) {
            return getOrderByOwnerResponse(req.getBody());
        } else if (endpoint.contains('v1/orders')) {
            return getOrderResponse(req.getBody());
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

    public static HttpResponse postUsage() {
        HttpResponse res = getJSON();
        res.setBody(
            '[{"Success": true, "Id": "zuoraID_1_of_14"},' +
                '{"Errors":[{"Code":"MISSING_REQUIRED_VALUE","Message":"The AccountId or AccountNumber is required."}],"Success":false},' +
                '{"Success": true, "Id": "zuoraID_3_of_14"},' +
                '{"Success": true, "Id": "zuoraID_4_of_14"},' +
                '{"Success": true, "Id": "zuoraID_5_of_14"},' +
                '{"Success": true, "Id": "zuoraID_6_of_14"},' +
                '{"Success": true, "Id": "zuoraID_7_of_14"},' +
                '{"Errors":[{"Code":"MISSING_REQUIRED_VALUE","Message":"The AccountId or AccountNumber is required."}],"Success":false},' +
                '{"Success": true, "Id": "zuoraID_9_of_14"},' +
                '{"Success": true, "Id": "zuoraID_10_of_14"},' +
                '{"Success": true, "Id": "zuoraID_11_of_14"},' +
                '{"Success": true, "Id": "zuoraID_12_of_14"},' +
                '{"Errors":[{"Code":"MISSING_REQUIRED_VALUE","Message":"The AccountId or AccountNumber is required."}],"Success":false},' +
                '{"Success": true, "Id": "zuoraID_14_of_14"}]'
        );
        return res;
    }

    public static HttpResponse postCreditMemo() {
        HttpResponse res = getJSON();
        res.setBody(
            '{ "id" : "2c92c0fa6a3458e1016a45ac238e0d74", ' +
                '"number" : "CM00000049", ' +
                '"accountId" : "2c92c0f869c8e5c50169dfb877685bd8", ' +
                '"currency" : "USD", ' +
                '"creditMemoDate" : "2019-04-22", ' +
                '"targetDate" : null, ' +
                '"postedById" : null, ' +
                '"postedOn" : null, ' +
                '"status" : "Draft", ' +
                '"amount" : 34.00, ' +
                '"taxAmount" : 0.00, ' +
                '"totalTaxExemptAmount" : 0.00, ' +
                '"unappliedAmount" : 34.00, ' +
                '"refundAmount" : 0E-9, ' +
                '"appliedAmount" : 0E-9, ' +
                '"comment" : "Comment", ' +
                '"source" : "AdhocFromPrpc", ' +
                '"sourceId" : null, ' +
                '"referredInvoiceId" : null, ' +
                '"reasonCode" : "BW - Initiated Credit", ' +
                '"createdDate" : "2019-04-22 15:31:10", ' +
                '"createdById" : "2c92c0f968a20f350168ca0efb2309e7", ' +
                '"updatedDate" : "2019-04-22 15:31:10", ' +
                '"updatedById" : "2c92c0f968a20f350168ca0efb2309e7", ' +
                '"cancelledOn" : null, "cancelledById" : null, ' +
                '"latestPDFFileId" : null, ' +
                '"Project__c" : "Project A Oak Road", ' +
                '"CRM_ID__c" : "a0p0j00000CwTIHAA3", ' +
                '"transferredToAccounting" : "No", ' +
                '"excludeFromAutoApplyRules" : false, ' +
                '"autoApplyUponPosting" : false, ' +
                '"success" : true }'
        );
        return res;
    }

    public static HttpResponse getActionCreate(String body) {
        HttpResponse res = getJSON();
        if (body.contains('ThrowException')) {
            throw new Util.BWException('Test callout exception');
        } else if (body.contains('"type":"Account"')) {
            AccountActionItems actionItems = (AccountActionItems) JSON.deserialize(body, AccountActionItems.class);
            List<ZuoraAPI.SaveResult> saveResults = new List<ZuoraAPI.SaveResult>();
            for (ZuoraAPI.ZuoraAccount account : actionItems.objects) {
                ZuoraAPI.SaveResult saveResult = new ZuoraAPI.SaveResult();
                saveResult.Id = genericId;
                saveResult.Success = true;
                saveResults.add(saveResult);
            }
            res.setBody(JSON.serialize(saveResults));
        } else if (body.contains('"type":"Contact"')) {
            ContactActionItems actionItems = (ContactActionItems) JSON.deserialize(body, ContactActionItems.class);
            List<ZuoraAPI.SaveResult> saveResults = new List<ZuoraAPI.SaveResult>();
            for (ZuoraAPI.ZuoraContact contact : actionItems.objects) {
                ZuoraAPI.SaveResult saveResult = new ZuoraAPI.SaveResult();
                saveResult.Id = genericId;
                saveResult.Success = true;
                saveResults.add(saveResult);
            }
            res.setBody(JSON.serialize(saveResults));
        } else {
            throw new Util.BWException('Unhandled action create: ' + body);
        }
        return res;
    }

    public static HttpResponse getActionUpdate(String body) {
        HttpResponse res = getJSON();
        if (body.contains('ThrowException')) {
            throw new Util.BWException('Test callout exception');
        } else if (body.contains('"type":"Account"')) {
            AccountActionItems actionItems = (AccountActionItems) JSON.deserialize(body, AccountActionItems.class);
            List<ZuoraAPI.SaveResult> saveResults = new List<ZuoraAPI.SaveResult>();
            for (ZuoraAPI.ZuoraAccount account : actionItems.objects) {
                ZuoraAPI.SaveResult saveResult = new ZuoraAPI.SaveResult();
                saveResult.Id = genericId;
                saveResult.Success = true;
                saveResults.add(saveResult);
            }
            res.setBody(JSON.serialize(saveResults));
        } else {
            throw new Util.BWException('Unhandled action create: ' + body);
        }
        return res;
    }

    public static HttpResponse getActionQuery(String body) {
        HttpResponse res = getJSON();
        // SELECT Id FROM Account:
        res.setBody('{"records":[{"Id":"2c92c0f869330b78016949ef5a7517ab"}],"size":1,"done":true}');
        return res;
    }

    public static HttpResponse getActionDelete(String body) {
        HttpResponse res = getJSON();
        res.setBody('[{"id": "2c93808457d787030157e031fcd34e19","success": true}]');
        return res;
    }

    public static HttpResponse getOrderResponse(String body) {
        HttpResponse res = getJSON();
        if (body.contains('ThrowException')) {
            throw new Util.BWException('Test callout exception');
        }
        ZuoraAPI.OrderActionResult result = new ZuoraAPI.OrderActionResult();
        result.success = true;
        result.orderNumber = 'O-00000104';
        result.accountNumber = 'BW-00000076';
        result.status = 'Completed';
        result.subscriptions = new List<ZuoraAPI.SubscriptionResult>();
        ZuoraAPI.SubscriptionResult subscriptionResult = new ZuoraAPI.SubscriptionResult();
        subscriptionResult.subscriptionNumber = 'A-S00000090';
        subscriptionResult.status = 'Active';
        result.subscriptions.add(subscriptionResult);
        res.setBody(JSON.serialize(result));
        return res;
    }

    public static HttpResponse getOrderByOwnerResponse(String body) {
        HttpResponse res = getJSON();
        if (body.contains('ThrowException')) {
            throw new Util.BWException('Test callout exception');
        }
        ZuoraAPI.OrderBySubscriptionOwner result = new ZuoraAPI.OrderBySubscriptionOwner();
        result.success = true;
        res.setBody(JSON.serialize(result));
        return res;
    }

    private static HttpResponse getGenericSuccess() {
        HttpResponse res = getJSON();
        res.setBody('{"Success":true,"Id":"' + genericId + '"}');
        return res;
    }

    public static HttpResponse getJSON() {
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        res.setStatusCode(200);
        return res;
    }

    // When we deserialize into ZuoraAPI.ActionItems, we get this error because of the generic objects attribute:
    // Apex Type unsupported in JSON: Object
    // So we'll define a concrete type to use just for this mock
    public class AccountActionItems {
        public String type;
        public List<ZuoraAPI.ZuoraAccount> objects;
    }
    public class ContactActionItems {
        public String type;
        public List<ZuoraAPI.ZuoraContact> objects;
    }
}