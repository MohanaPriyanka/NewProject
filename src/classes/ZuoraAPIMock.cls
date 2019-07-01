/*************************************************************************************
 * Created By: peteryao on 2019-04-18  
 * Description: 
 * Test: 
 *************************************************************************************/
@IsTest
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
        } else if (endpoint.contains('/v1/action/query') && req.getBody().contains(' FROM Invoice')) {
            return getInvoices();
        } else if (endpoint.contains('/v1/action/query') && req.getBody().contains(' FROM RatePlanCharge')) {
            return getRatePlanCharge(req.getBody());
        } else if (endpoint.contains('v1/action/query')) {
            return getActionQuery(req.getBody());
        } else if (endpoint.contains('v1/action/delete')) {
            return getActionDelete(req.getBody());
        } else if (endpoint.contains('v1/orders/subscriptionOwner')) {
            return getOrderByOwnerResponse(endpoint);
        } else if (endpoint.contains('v1/orders')) {
            return getOrderResponse(req.getBody());
        } else if (endpoint.contains('v1/object/invoice')) {
            return getInvoiceResponse(req.getBody());
        } else if (endpoint.contains('/v1/creditmemos/') && endpoint.contains('/items')) {
            return getCreditMemoItems();
        } else if (endpoint.contains('/v1/invoices/') && endpoint.contains('/items')) {
            return getInvoiceItem(endpoint);
        } else if (endpoint.contains('/v1/debitmemos/') && endpoint.contains('/items')) {
            return getDebitMemoItems();
        } else if (endpoint.contains('/v1/creditmemos?status=Posted') || endpoint.contains('/v1/creditmemos/')) {
            return getCreditMemos();
        } else if (endpoint.contains('/v1/debitmemos/')) {
            return getDebitMemos();
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
                '"ClientOwner__c" : "SSS-0000123", ' +
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
        } else if (body.contains('"type":"Usage"')) {
            return postUsage();
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
        if (body.contains('ExistingAccount') || body.contains('CID')) {
            String response = '{"orders" : [' +
                '{"orderNumber" : "O-00002360","existingAccountNumber" : "ExistingAccount",'+
                '"subscriptions" : [ {"subscriptionNumber" : "A-S00002141","orderActions" : ['+
                '{"type" : "AddProduct","addProduct" :'+
                '{"chargeOverrides" : [{"chargeNumber" : "C-00003075", "customFields" : {"Project__c" : "Dudley","ClientOwner__c" : "Goldman"}}]}} ]} ]},'+
                '{'+
                '"orderNumber" : "O-00002359","existingAccountNumber" : "ExistingAccount",'+
                '"subscriptions" : [ {"subscriptionNumber" : "A-S00002141","orderActions" : ['+
                '{"type" : "CreateSubscription","triggerDates" : [ {"triggerDate" : "2017-01-01","name" : "ContractEffective"}, ' +
                '{"triggerDate" : "2017-01-01","name" : "ServiceActivation"}, {"triggerDate" : "2017-01-01","name" : "CustomerAcceptance"} ], ' +
                '"createSubscription" : {"subscribeToRatePlans" : ['+
                '{"chargeOverrides" : [{"chargeNumber" : "C-00003076", "customFields" : {"Project__c" : "Barrett","ClientOwner__c" : "Goldman"}} ]} ]}} ]} ]} ],'+
                '"success" : true'+
                '}';
            if (body.contains('CID')) {
                // Since client Id and SSS Id will change in each SF environment, set them dynamically:
                String clientId = body.substring(body.indexOf('CID') + 3, body.indexOf('SID'));
                String sssId = body.substring(body.indexOf('SID') + 3, body.indexOf('END'));
                response = response.replace('Goldman', clientId);
                response = response.replace('Barrett', sssId);
            }
            res.setBody(response);
        } else {
            ZuoraAPI.OrderBySubscriptionOwner obso = new ZuoraAPI.OrderBySubscriptionOwner();
            obso.success = true;
            res.setBody(JSON.serialize(obso));
        }

        return res;
    }

    public static HttpResponse getInvoiceResponse(String body) {
        HttpResponse res = getJSON();
        ZuoraAPI.Invoice result = new ZuoraAPI.Invoice();
        result.id = '12345';
        result.accountId = 'BW-00000076';
        result.amount = 123.45;
        result.balance = 23.45;
        result.Body = 'SGVsbG8gV29ybGQ=';
        result.InvoiceNumber = 'INV-12345';
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

    private static HttpResponse getCreditMemos() {
        HttpResponse res = getJSON();
        res.setBody('{ "creditmemos" : [ { ' +
            '"id" : "2c92c0f86b1bc435016b1e94e99a44a7", ' +
            '"number" : "CM00000899", ' +
            '"accountId" : "2c92c0f96b1bd14b016b1e8ff191385b", ' +
            '"currency" : "USD", ' +
            '"creditMemoDate" : "2019-06-03", ' +
            '"targetDate" : null, ' +
            '"postedById" : "2c92c0f868e558450168f41d281b26c0", ' +
            '"postedOn" : "2019-06-03 14:23:29", ' +
            '"status" : "Posted", "amount" : 100.000000000, ' +
            '"taxAmount" : 0E-9, "totalTaxExemptAmount" : 0E-9, ' +
            '"unappliedAmount" : 120000.00, "refundAmount" : 0E-9, ' +
            '"appliedAmount" : 100.000000000, "comment" : "", ' +
            '"source" : "AdhocFromInvoice", "sourceId" : null,' +
            ' "referredInvoiceId" : "2c92c0956b1bcd0e016b1e93a1c153be", ' +
            '"reasonCode" : "Correcting invoice error", ' +
            '"createdDate" : "2019-06-03 14:23:24", ' +
            '"createdById" : "2c92c0f868e558450168f41d281b26c0", ' +
            '"updatedDate" : "2019-06-03 14:23:29", ' +
            '"updatedById" : "2c92c0f868e558450168f41d281b26c0", ' +
            '"cancelledOn" : null, ' +
            '"cancelledById" : null, ' +
            '"latestPDFFileId" : "2c92c08d6b1bd06b016b1e9525483791",' +
            ' "Project__c" : "SSS-000098", ' +
            '"ClientOwner__c" : "BW-00000385", ' +
            '"transferredToAccounting" : "No", ' +
            '"excludeFromAutoApplyRules" : false, ' +
            '"autoApplyUponPosting" : true }, ' +
            '{"id" : "2c92c0f86b26b2ae016b41aa16732d6c", ' +
            '"number" : "CM00000900", ' +
            '"accountId" : "2c92c0f86b26b2ae016b41a331477ec0", ' +
            '"currency" : "USD", ' +
            '"creditMemoDate" : "2019-06-10", ' +
            '"targetDate" : null, ' +
            '"postedById" : "2c92c0f868e558450168f41d281b26c0", ' +
            '"postedOn" : "2019-06-10 09:53:24", ' +
            '"status" : "Posted", ' +
            '"amount" : 100.000000000, ' +
            '"taxAmount" : 0E-9, ' +
            '"totalTaxExemptAmount" : 0E-9, ' +
            '"unappliedAmount" : 120000.00, ' +
            '"refundAmount" : 0E-9, ' +
            '"appliedAmount" : 100.000000000,' +
            '"comment" : "", ' +
            '"source" : "AdhocFromInvoice", ' +
            '"sourceId" : null, ' +
            '"referredInvoiceId" : "2c92c0996b3f9eab016b41a71fb86581", ' +
            '"reasonCode" : "Correcting invoice error", ' +
            '"createdDate" : "2019-06-10 09:53:14", ' +
            '"createdById" : "2c92c0f868e558450168f41d281b26c0", ' +
            '"updatedDate" : "2019-06-10 09:53:24", ' +
            '"updatedById" : "2c92c0f868e558450168f41d281b26c0", ' +
            '"cancelledOn" : null, "cancelledById" : null, ' +
            '"latestPDFFileId" : "2c92c08c6b26b1c0016b41aa41697c15", ' +
            '"Project__c" : "SSS-000098", ' +
            '"ClientOwner__c" : "BW-00000385", ' +
            '"transferredToAccounting" : "No", ' +
            '"excludeFromAutoApplyRules" : false, ' +
            '"autoApplyUponPosting" : true }] } ');
        return res;
    }

    private static HttpResponse getCreditMemoItems() {
        HttpResponse res = getJSON();
        res.setBody('{ "items" : [ { "id" : "2c92c0fa6ae3a459016ae5ed00b13a8b", ' +
            '"amount" : 12.000000000, ' +
            '"amountWithoutTax" : 12.000000000, ' +
            '"appliedAmount" : 0E-9, ' +
            '"refundAmount" : 0E-9, ' +
            '"unappliedAmount" : 120000.00, ' +
            '"comment" : "", ' +
            '"sku" : "SKU-00000002", ' +
            '"skuName" : "Utility Credit", ' +
            '"serviceStartDate" : "2016-02-01", ' +
            '"serviceEndDate" : "2070-02-25", ' +
            '"sourceItemType" : "ProductRatePlanCharge", ' +
            '"sourceItemId" : "2c92c0f969c8f15e0169caed586a1909", ' +
            '"createdDate" : "2019-05-23 14:21:15", ' +
            '"createdById" : "2c92c0f968a20f350168ca0efb2309e7",' +
            ' "updatedDate" : "2019-06-18 17:11:46", ' +
            '"updatedById" : "2c92c0f968a20f350168ca0efb2309e7", ' +
            '"subscriptionId" : null, ' +
            '"financeInformation" : { ' +
            '"onAccountAccountingCode" : "BW Initiated Credit", ' +
            '"onAccountAccountingCodeType" : "OnAccountReceivable", ' +
            '"deferredRevenueAccountingCode" : "Usage Revenue", ' +
            '"deferredRevenueAccountingCodeType" : "SalesRevenue", ' +
            '"recognizedRevenueAccountingCode" : "Usage Revenue", ' +
            '"recognizedRevenueAccountingCodeType" : "SalesRevenue", ' +
            '"revenueScheduleNumber" : null, ' +
            '"revenueRecognitionRuleName" : "Recognize upon invoicing" }, ' +
            '"creditTaxItems" : [ ] } ], "success" : true }');
        return res;
    }

    private static HttpResponse getRatePlanCharge(String reqBody){
        HttpResponse res = getJSON();
        if (reqBody.contains('2c92c0f96ae3b195016ae5e3665e0c08')) {
            res.setBody('{"records":[' +
                '{"ClientOwner__c":"BW-00000385",' +
                '"Id":"2c92c0f96ae3b195016ae5e3665e0c08",' +
                '"ChargeNumber":"C-00003171",' +
                '"Name":"Utility Credit",' +
                '"Project__c":"SSS-000099"}' +
                '],' +
                '"size":1,"done":true} ');
        } else if (reqBody.contains('2c92c0f96ae3b195016ae5e3668e0c15')){
            res.setBody('{"records":[' +
                '{"ClientOwner__c":"BW-00000385",' +
                '"Id":"2c92c0f96ae3b195016ae5e3665e0c08",' +
                '"ChargeNumber":"C-00003171",' +
                '"Name":"Utility Credit",' +
                '"Project__c":"SSS-000098"}' +
                '],' +
                '"size":1,"done":true}');
        }
        return res;
    }

    private static HttpResponse getInvoices() {
        HttpResponse res = getJSON();
        res.setBody('{"records":[' +
            '{"Amount":270,"Balance":270,"InvoiceDate":"2017-07-20","Id":"2c92c0856ae3a471016ae5ebd8fa5444",' +
            '"AccountId":"2c92c0f86ae3a4ad016ae5e247886605"},' +
            '{"Amount":810,"Balance":810,"InvoiceDate":"2019-06-13","Id":"2c92c0856b4f7c5e016b53bc25b43a8d",' +
            '"AccountId":"2c92c0f86ae3a4ad016ae5e247886605"}],' +
            '"size":2,"done":true}');
        return res;
    }

    private static HttpResponse getInvoiceItem(String endpoint) {
        HttpResponse res = getJSON();

        if (endpoint.contains('2c92c0856ae3a471016ae5ebd8fa5444')){
            res.setBody('{ "invoiceItems" : [ ' +
                '{ "id" : "2c92c0856ae3a471016ae5ebd90e5445", ' +
                '"subscriptionName" : "A-S00000152", ' +
                '"subscriptionId" : "2c92c0f96ae3b195016ae5e366470bff", ' +
                '"serviceStartDate" : "2017-06-01", ' +
                '"serviceEndDate" : "2017-06-30", ' +
                '"chargeAmount" : 90.000000000, ' +
                '"chargeDescription" : "", ' +
                '"chargeName" : "Utility Credit", ' +
                '"chargeId" : "2c92c0f96ae3b195016ae5e3665e0c08", ' +
                '"productName" : "Community Solar", ' +
                '"quantity" : 90.000000000, ' +
                '"taxAmount" : 0E-9, ' +
                '"unitOfMeasure" : "Dollars2", ' +
                '"chargeDate" : "2019-05-23 14:20:00", ' +
                '"chargeType" : "Usage", ' +
                '"processingType" : "Charge", ' +
                '"balance" : 90.000000000, ' +
                '"appliedToItemId" : null, ' +
                '"taxationItems" : ' +
                '{ "data" : [ ] }, ' +
                '"availableToCreditAmount" : 90.000000000 }, ' +
                '{ "id" : "2c92c0856ae3a471016ae5ebd90f5446", ' +
                '"subscriptionName" : "A-S00000152", ' +
                '"subscriptionId" : "2c92c0f96ae3b195016ae5e366470bff", ' +
                '"serviceStartDate" : "2017-06-01", ' +
                '"serviceEndDate" : "2017-06-30", ' +
                '"chargeAmount" : 180.000000000, ' +
                '"chargeDescription" : "", ' +
                '"chargeName" : "Utility Credit", ' +
                '"chargeId" : "2c92c0f96ae3b195016ae5e3668e0c15", ' +
                '"productName" : "Community Solar", ' +
                '"quantity" : 180.000000000, ' +
                '"taxAmount" : 0E-9, ' +
                '"unitOfMeasure" : "Dollars2", ' +
                '"chargeDate" : "2019-05-23 14:20:00", ' +
                '"chargeType" : "Usage", ' +
                '"processingType" : "Charge", ' +
                '"balance" : 180.000000000, ' +
                '"appliedToItemId" : null, ' +
                '"taxationItems" : ' +
                '{ "data" : [ ] }, ' +
                '"availableToCreditAmount" : 180.000000000 } ], ' +
                '"success" : true }');
        } else if (endpoint.contains('2c92c0856b4f7c5e016b53bc25b43a8d')){
            res.setBody('{ "invoiceItems" : [ ' +
                '{ "id" : "2c92c0856ae3a471016ae5ebd90e5445", ' +
                '"subscriptionName" : "A-S00000152", ' +
                '"subscriptionId" : "2c92c0f96ae3b195016ae5e366470bff", ' +
                '"serviceStartDate" : "2017-06-01", ' +
                '"serviceEndDate" : "2017-06-30", ' +
                '"chargeAmount" : 100.000000000, ' +
                '"chargeDescription" : "", ' +
                '"chargeName" : "Utility Credit", ' +
                '"chargeId" : "2c92c0f96ae3b195016ae5e3665e0c08", ' +
                '"productName" : "Community Solar", ' +
                '"quantity" : 100.000000000, ' +
                '"taxAmount" : 0E-9, ' +
                '"unitOfMeasure" : "Dollars2", ' +
                '"chargeDate" : "2019-05-23 14:20:00", ' +
                '"chargeType" : "Usage", ' +
                '"processingType" : "Charge", ' +
                '"balance" : 100.000000000, ' +
                '"appliedToItemId" : null, ' +
                '"taxationItems" : ' +
                '{ "data" : [ ] }, ' +
                '"availableToCreditAmount" : 100.000000000 }, ' +
                '{ "id" : "2c92c0856ae3a471016ae5ebd90f5446", ' +
                '"subscriptionName" : "A-S00000152", ' +
                '"subscriptionId" : "2c92c0f96ae3b195016ae5e366470bff", ' +
                '"serviceStartDate" : "2017-06-01", ' +
                '"serviceEndDate" : "2017-06-30", ' +
                '"chargeAmount" : 710.000000000, ' +
                '"chargeDescription" : "", ' +
                '"chargeName" : "Utility Credit", ' +
                '"chargeId" : "2c92c0f96ae3b195016ae5e3668e0c15", ' +
                '"productName" : "Community Solar", ' +
                '"quantity" :  710.000000000, ' +
                '"taxAmount" : 0E-9, ' +
                '"unitOfMeasure" : "Dollars2", ' +
                '"chargeDate" : "2019-05-23 14:20:00", ' +
                '"chargeType" : "Usage", ' +
                '"processingType" : "Charge", ' +
                '"balance" : 710.000000000, ' +
                '"appliedToItemId" : null, ' +
                '"taxationItems" : ' +
                '{ "data" : [ ] }, ' +
                '"availableToCreditAmount" : 710.000000000 } ], ' +
                '"success" : true }');
        }

        return res;
    }

    private static HttpResponse getDebitMemos() {
        HttpResponse res = getJSON();
        res.setBody('{ "debitmemos" : [ ' +
            '{ "id" : "2c92c0f96b695c76016b6c860fc277f4", ' +
            '"number" : "DM00000019", ' +
            '"accountId" : "2c92c0f86ae3a4ad016ae5e247886605", ' +
            '"debitMemoDate" : "2019-06-18", ' +
            '"currency" : "USD", ' +
            '"targetDate" : null, ' +
            '"dueDate" : "2019-07-18", ' +
            '"postedOn" : null, ' +
            '"postedById" : null, ' +
            '"status" : "Draft", ' +
            '"amount" : 30.000000000, ' +
            '"taxAmount" : 0E-9, ' +
            '"totalTaxExemptAmount" : 0E-9, ' +
            '"balance" : 30.000000000, ' +
            '"beAppliedAmount" : 0E-9, ' +
            '"autoPay" : true, "comment" : "", ' +
            '"referredInvoiceId" : "2c92c0856ae3a471016ae5ebd8fa5444", ' +
            '"transferredToAccounting" : "No", ' +
            '"reasonCode" : "Correcting invoice error",' +
            ' "createdDate" : "2019-06-18 17:37:33", ' +
            '"createdById" : "2c92c0f968a20f350168ca0efb2309e7", ' +
            '"updatedDate" : "2019-06-18 17:37:33", ' +
            '"updatedById" : "2c92c0f968a20f350168ca0efb2309e7", ' +
            '"cancelledOn" : null, "cancelledById" : null, ' +
            '"latestPDFFileId" : "2c92c08d6b695b82016b6c8611af519b", ' +
            '"Project__c" : "SSS-000098", "ClientOwner__c" : "BW-00000385", ' +
            '"RetryStatus__c" : null }, ' +
            '{ "id" : "2c92c0f86b1bc424016b1e95860909ce", ' +
            '"number" : "DM00000018", ' +
            '"accountId" : "2c92c0f96b1bd14b016b1e8ff191385b", ' +
            '"debitMemoDate" : "2019-06-03", ' +
            '"currency" : "USD", ' +
            '"targetDate" : null, ' +
            '"dueDate" : "2019-07-03", ' +
            '"postedOn" : "2019-06-03 14:24:12", ' +
            '"postedById" : "2c92c0f868e558450168f41d281b26c0", ' +
            '"status" : "Posted", ' +
            '"amount" : 50.000000000, ' +
            '"taxAmount" : 0E-9, ' +
            '"totalTaxExemptAmount" : 0E-9, ' +
            '"balance" : 50.000000000, ' +
            '"beAppliedAmount" : 0E-9, ' +
            '"autoPay" : true, "comment" : "", ' +
            '"referredInvoiceId" : "2c92c0956b1bcd0e016b1e93a1c153be", ' +
            '"transferredToAccounting" : "No", ' +
            '"reasonCode" : "Correcting invoice error",' +
            ' "createdDate" : "2019-06-03 14:24:04", ' +
            '"createdById" : "2c92c0f868e558450168f41d281b26c0", ' +
            '"updatedDate" : "2019-06-03 14:24:12", ' +
            '"updatedById" : "2c92c0f868e558450168f41d281b26c0", ' +
            '"cancelledOn" : null, "cancelledById" : null, ' +
            '"latestPDFFileId" : "2c92c08a6b1bc362016b1e95ad1837d1", ' +
            '"Project__c" : "SSS-000098", "ClientOwner__c" : "BW-00000385", ' +
            '"RetryStatus__c" : null }] }');
        return res;
    }

    private static HttpResponse getDebitMemoItems() {
        HttpResponse res = getJSON();
        res.setBody('{ "items" : [ ' +
            '{ "id" : "2c92c0f96b695c76016b6c860fcf77f5", ' +
            '"amount" : 20.000000000, ' +
            '"amountWithoutTax" : 20.000000000, ' +
            '"beAppliedAmount" : 0E-9, ' +
            '"balance" : 20.000000000, ' +
            '"sku" : "SKU-00000002", ' +
            '"skuName" : "Utility Credit", ' +
            '"serviceStartDate" : "2017-06-01", ' +
            '"serviceEndDate" : "2017-06-30", ' +
            '"sourceItemType" : "InvoiceDetail", ' +
            '"sourceItemId" : "2c92c0856ae3a471016ae5ebd90e5445", ' +
            '"createdDate" : "2019-06-18 17:37:33", ' +
            '"createdById" : "2c92c0f968a20f350168ca0efb2309e7", ' +
            '"updatedDate" : "2019-06-18 17:37:33", ' +
            '"updatedById" : "2c92c0f968a20f350168ca0efb2309e7", ' +
            '"comment" : "", ' +
            '"subscriptionId" : "2c92c0f96ae3b195016ae5e366470bff",' +
            ' "financeInformation" : { ' +
            '"deferredRevenueAccountingCode" : "Usage Revenue", ' +
            '"deferredRevenueAccountingCodeType" : "SalesRevenue", ' +
            '"recognizedRevenueAccountingCode" : "Usage Revenue", ' +
            '"recognizedRevenueAccountingCodeType" : "SalesRevenue", ' +
            '"revenueScheduleNumber" : null, ' +
            '"revenueRecognitionRuleName" : "Recognize upon invoicing" ' +
            '} }' +
            '] }');
        return res;
    }
}