/*************************************************************************************
 * Created By: peteryao on 2019-04-18  
 * Description: 
 * Test: 
 *************************************************************************************/
@IsTest
@SuppressWarnings('PMD')
public with sharing class ZuoraAPIMock implements HttpCalloutMock {
    public static String genericId = '2c92c0f96a6e3c3f016a6fc817180743';

    public HttpResponse respond(HttpRequest req) {
        // Only send a mock response for a specific endpoint and method.
        String endpoint = req.getEndpoint();
        String method = req.getMethod();

        // Create a fake response
        if (endpoint.contains('rsa-signatures')) {
            return getRSASignatures();
        }  else if (endpoint.contains('/oauth/token')) {
            return getOAuthToken();
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
        } else if (endpoint.contains('query/jobs')) {
            return getDataQuery(endpoint);
        } else if (endpoint.contains('owl-auw2-sbx01-query-result')){
            return getDataQueryData(endpoint);
        } else if (endpoint.contains('/v1/action/query') && req.getBody().contains(' FROM Invoice')) {
            return getInvoices();
        } else if (endpoint.contains('/v1/action/query') && req.getBody().contains(' FROM RatePlanCharge')) {
            return getRatePlanCharge(req.getBody());
        } else if (endpoint.contains('/v1/action/query') && req.getBody().contains(' FROM Account')) {
            return getAccount();
        } else if (endpoint.contains('v1/action/query')) {
            return getActionQuery(req.getBody());
        } else if (endpoint.contains('v1/action/delete')) {
            return getActionDelete(req.getBody());
        } else if (endpoint.contains('v1/orders/subscriptionOwner')) {
            return getOrderByOwnerResponse(endpoint);
        } else if (endpoint.contains('v1/orders')) {
            return getOrderResponse(req.getBody());
        } else if (endpoint.contains('v1/object/invoice')) {
            return getInvoiceResponse(endpoint);
        } else if (endpoint.contains('/v1/creditmemos') && method.contains('POST')) {
            return postCreditMemo();
        } else if (endpoint.contains('/v1/debitmemos') && method.contains('POST')) {
            return createDebitMemo();
        } else if (endpoint.contains('/v1/creditmemos/') && endpoint.contains('/items')) {
            return getCreditMemoItems();
        } else if (endpoint.contains('/v1/invoices/') && endpoint.contains('/items')) {
            return getInvoiceItem(endpoint);
        } else if (endpoint.contains('/v1/debitmemos/') && endpoint.contains('/items')) {
            return getDebitMemoItems(endpoint);
        } else if (endpoint.contains('/v1/creditmemos?status=Posted') || endpoint.contains('/v1/creditmemos/')) {
            return getCreditMemos(endpoint);
        } else if (endpoint.contains('/v1/debitmemos') && method.contains('GET')) {
            return getDebitMemos(endpoint);
        } else if (endpoint.contains('/v1/payments') && req.getBody().contains('Electronic') && method == 'POST') {
            return createElectronicPayment();
        }  else if (endpoint.contains('/v1/payments') && method == 'POST') {
            return createPayment(endpoint);
        }  else if (endpoint.contains('/v1/payments') && method == 'GET') {
            return getPayment(endpoint);
        }  else if (endpoint.contains('/v1/payments') && method == 'PUT') {
            return getPayment(endpoint);
        } else if (endpoint.contains('/v1/paymentgateways')) {
            return getGateways();
        } else if (endpoint.contains('/v1/object/bill-run')) {
            return getBillRun();
        } else if (endpoint.contains('/v1/object/rate-plan-charge/')) {
            return getRatePlanCharge(endpoint);
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

    private static HttpResponse getOAuthToken() {
        HttpResponse res = getJSON();
        res.setBody('{"access_token":"aff6cd3b49934212980e6e0836fe0964",' +
            '"token_type":"bearer",' +
            '"expires_in":3598,' +
            '"scope":"entity.2c92c0f8-68a2-023a-0168-a79e7dfa3f31 ' +
            'platform.write service.usage.delete service.usage.update' +
            ' service.usage.write tenant.30689 ' +
            'user.2c92c0f8694d2ce701694fe8a4d25ba5",' +
            '"jti":"aff6cd3b49934212980e6e0836fe0964"}'
        );
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

    public static HttpResponse getAccount(){
        HttpResponse res = getJSON();
        res.setBody('{"records":' +
            '[{"AccountNumber":"BWC-000024383",' +
            '"Id":"2c92c0f86b78f56c016b7b00480c2e24",' +
            '"AutoPay":false,' +
            '"CreatedDate":"2019-06-21T13:05:44.000-04:00",' +
            '"Name":"ABJustin  Jenkins",' +
            '"Status":"Active","BillCycleDay":15,' +
            '"Balance":230.00,' +
            '"InvoiceTemplateId":"2c92c0f868a2023a0168a79eb021418d",' +
            '"CrmId":"0013D00000nFbD2QAK",' +
            '"BillToId":"2c92c0f86b78f56c016b7b00487a2e25",' +
            '"PaymentTerm":"Net 30",' +
            '"DefaultPaymentMethodId":"2c92c0f86a0c41a5016a1f41d63a2f96",' +
            '"Batch":"Batch1"}],' +
            '"size":1,' +
            '"done":true}'
        );
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
                if (contact.FirstName == null) {
                    saveResult.Success = false;
                } else {
                    saveResult.Id = genericId;
                    saveResult.Success = true;
                }
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
        } else if (body.contains('"type":"PaymentMethod"')){
            String responseBody = '[{"Success":true,"Id":"2c92c0f86a0c41a5016a1f41d63a2f96"}]';
            res.setBody(responseBody);
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

    public static HttpResponse getOrderByOwnerResponse(String endpoint) {
        HttpResponse res = getJSON();
        if (endpoint.contains('ThrowException')) {
            throw new Util.BWException('Test callout exception');
        }
        if (endpoint.contains('ExistingAccount') || endpoint.contains('CID')) {
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
                '"success" : true';
            if (endpoint.contains('ExistingAccountPage') && !endpoint.contains('page=2')) {
                response += ', "nextPage" : "https://rest.apisandbox.zuora.com/v1/orders/subscriptionOwner/ExistingAccount?page=2&pageSize=20"}';
            } else {
                response += '}';
            }
            if (endpoint.contains('CID')) {
                // Since client Id and SSS Id will change in each SF environment, set them dynamically:
                String clientId = endpoint.substring(endpoint.indexOf('CID') + 3, endpoint.indexOf('SID'));
                String sssId = endpoint.substring(endpoint.indexOf('SID') + 3, endpoint.indexOf('END'));
                response = response.replace('Goldman', clientId);
                response = response.replace('Barrett', sssId);
            }
            res.setBody(response);
        } else if (endpoint.contains('2c92c0f96c8afb5d016c8c5b4d4c7b6e')) {
            String response = '{"success":true,"orders":[{"subscriptions":[{"subscriptionNumber":"A-S00014355","orderActions":[{"type" : "AddProduct","triggerDates":[{"triggerDate":"2019-01-07","name":"ContractEffective"},{"triggerDate":"2019-01-07","name":"ServiceActivation"},{"triggerDate":"2019-01-07","name":"CustomerAcceptance"}],"sequence":0,"createSubscription":null,"addProduct":{"productRatePlanId":"2c92c0f869c8e5c50169caec86e07095","newRatePlanId":"2c92c0fb6c8afb49016c8c5ba8d521ff","chargeOverrides":[{"productRatePlanChargeId":"2c92c0f969c8f15e0169caed586a1909","customFields":{"Project__c":"SSS-000023","ClientOwner__c":"BW-0023170"},"chargeNumber":"C-00022737"}]}}],"newVersion":3,"baseVersion":2}],"processingOptions":null,"orderNumber":"O-00193847","orderDate":"2019-01-07","existingAccountNumber":"BW-0023842"},{"subscriptions":[{"subscriptionNumber":"A-S00014355","orderActions":[{"type" : "AddProduct","triggerDates":[{"triggerDate":"2019-01-07","name":"ContractEffective"},{"triggerDate":"2019-01-07","name":"ServiceActivation"},{"triggerDate":"2019-01-07","name":"CustomerAcceptance"}],"sequence":0,"createSubscription":null,"addProduct":{"productRatePlanId":"2c92c0f869c8e5c50169caec86e07095","newRatePlanId":"2c92c0fb6c8afb49016c8c5ba8d521ff","chargeOverrides":[{"productRatePlanChargeId":"2c92c0f969c8f15e0169caed586a1909","customFields":{"Project__c":"SSS-000023","ClientOwner__c":"BW-0024201"},"chargeNumber":"C-00022737"}]}}],"newVersion":3,"baseVersion":2}],"processingOptions":null,"orderNumber":"O-00193847","orderDate":"2019-01-07","existingAccountNumber":"BW-0023842"},{"subscriptions":[{"subscriptionNumber":"A-S00014355","orderActions":[{"type" : "AddProduct","triggerDates":[{"triggerDate":"2019-01-07","name":"ContractEffective"},{"triggerDate":"2019-01-07","name":"ServiceActivation"},{"triggerDate":"2019-01-07","name":"CustomerAcceptance"}],"sequence":0,"createSubscription":null,"addProduct":{"productRatePlanId":"2c92c0f869c8e5c50169caec86e07095","newRatePlanId":"2c92c0fb6c8afb49016c8c5ba8d521ff","chargeOverrides":[{"productRatePlanChargeId":"2c92c0f969c8f15e0169caed586a1909","customFields":{"Project__c":"SSS-000024","ClientOwner__c":"BW-0023170"},"chargeNumber":"C-00022737"}]}}],"newVersion":3,"baseVersion":2}],"processingOptions":null,"orderNumber":"O-00193847","orderDate":"2019-01-07","existingAccountNumber":"BW-0023842"},{"subscriptions":[{"subscriptionNumber":"A-S00014355","orderActions":[{"type" : "AddProduct","triggerDates":[{"triggerDate":"2019-01-07","name":"ContractEffective"},{"triggerDate":"2019-01-07","name":"ServiceActivation"},{"triggerDate":"2019-01-07","name":"CustomerAcceptance"}],"sequence":0,"createSubscription":null,"addProduct":{"productRatePlanId":"2c92c0f869c8e5c50169caec86e07095","newRatePlanId":"2c92c0fa6c8aee2e016c8c5ba717392d","chargeOverrides":[{"productRatePlanChargeId":"2c92c0f969c8f15e0169caed586a1909","customFields":{"Project__c":"SSS-000098","ClientOwner__c":"BW-00000385"},"chargeNumber":"C-00022736"}]}}],"newVersion":2,"baseVersion":1}],"processingOptions":null,"orderNumber":"O-00193846","orderDate":"2019-01-07","existingAccountNumber":"BW-0023842"},{"subscriptions":[{"subscriptionNumber":"A-S00014355","orderActions":[{"type" : "CreateSubscription","triggerDates":[{"triggerDate":"2019-01-07","name":"ContractEffective"},{"triggerDate":"2019-01-07","name":"ServiceActivation"},{"triggerDate":"2019-01-07","name":"CustomerAcceptance"}],"sequence":0,"createSubscription":{"terms":{"renewalTerms":[{"periodType":null,"period":null}],"renewalSetting":null,"initialTerm":{"termType":"EVERGREEN","startDate":null,"periodType":null,"period":null},"autoRenew":null},"subscriptionNumber":null,"subscribeToRatePlans":[{"productRatePlanId":"2c92c0f869c8e5c50169caec86e07095","chargeOverrides":[{"productRatePlanChargeId":"2c92c0f969c8f15e0169caed586a1909","customFields":{"Project__c":"SSS-000099","ClientOwner__c":"BW-00000385"},"chargeNumber":"C-00022735"}]}]},"addProduct":null}],"newVersion":1,"baseVersion":null}],"processingOptions":null,"orderNumber":"O-00193845","orderDate":"2019-01-07","existingAccountNumber":"BW-0023842"}],"nextPage":null}';
            res.setBody(response);
        } else {
            ZuoraAPI.OrderBySubscriptionOwner obso = new ZuoraAPI.OrderBySubscriptionOwner();
            obso.success = true;
            res.setBody(JSON.serialize(obso));
        }

        return res;
    }

    public static HttpResponse getInvoiceResponse(String endpoint) {
        HttpResponse res = getJSON();
        if (endpoint.contains('invoice-item') && endpoint.contains('2c92c0856cbe2e20016cc133cbd76420')) {
            res.setBody('{' +
                '"ServiceEndDate":"2019-05-09",' +
                '"Id":"2c92c0856cbe2e20016cc133cbd76420",' +
                '"ChargeDate":"2019-08-23T21:18:43.000-04:00",' +
                '"AccountingCode":"Usage Revenue",' +
                '"UnitPrice":1,' +
                '"SubscriptionId":"2c92c0fb6cb90e40016cc12be2293d4e",' +
                '"ProcessingType":0,' +
                '"UOM":"Dollars",' +
                '"Quantity":363.88,' +
                '"InvoiceId":"2c92c0866cbe2e04016cc13441ff3f23",' +
                '"ChargeAmount":134.70,' +
                '"ServiceStartDate":"2019-04-10",' +
                '"ChargeName":"Utility Credit",' +
                '"SKU":"SKU-00000002",' +
                '"RatePlanChargeId":"2c92c0f96ae3b195016ae5e3665e0c08"' +
                '}'
            );
        } else if (endpoint.contains('invoice-item') && endpoint.contains('2c92c0856cbe2e20016cc133cbd86421')) {
            res.setBody('{' +
                '"ServiceEndDate":"2019-05-09",' +
                '"Id":"2c92c0856cbe2e20016cc133cbd86421",' +
                '"ChargeDate":"2019-08-23T21:18:43.000-04:00",' +
                '"AccountingCode":"Usage Revenue",' +
                '"UnitPrice":1,' +
                '"SubscriptionId":"2c92c0fb6cb90e40016cc12be2293d4e",' +
                '"ProcessingType":0,' +
                '"UOM":"Dollars",' +
                '"Quantity":363.88,' +
                '"InvoiceId":"2c92c0866cbe2e04016cc13441ff3f23",' +
                '"ChargeAmount":120.21,' +
                '"ServiceStartDate":"2019-04-10",' +
                '"ChargeName":"Utility Credit",' +
                '"SKU":"SKU-00000002",' +
                '"RatePlanChargeId":"2c92c0f96ae3b195016ae5e3668e0c15"' +
                '}'
            );
        } else if (endpoint.contains('zzz123_')){
            res.setBody('{"Success":true,"Id":"2c92c0f86a0c41a5016a1f41d63a2f96"}');
        } else {
            ZuoraAPI.Invoice result = new ZuoraAPI.Invoice();
            result.id = '12345';
            result.accountId = 'BW-00000076';
            result.amount = 123.45;
            result.balance = 23.45;
            result.Body = 'SGVsbG8gV29ybGQ=';
            result.InvoiceNumber = 'INV-12345';
            res.setBody(JSON.serialize(result));
        }
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

    private static HttpResponse getCreditMemos(String endpoint) {
        HttpResponse res = getJSON();
        if (endpoint.contains('NOCREDITMEMOS')) {
            res.setBody('{"creditmemos" : [ ],"success" : true}');
        } else if (endpoint.contains('LOTSACREDITMEMOS')) {
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
                '"autoApplyUponPosting" : true }], "Success" : true, "NextPage" : "foo" } ');
        } else {
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
        }
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
            '"creditTaxItems" : [ ] } ], "success" : true}');
        return res;
    }

    private static HttpResponse getRatePlanCharge(String reqBody){
        HttpResponse res = getJSON();
        if (reqBody.contains('2c92c0f96ae3b195016ae5e3665e0c08')) {
            String ratePlan = '{"ClientOwner__c":"BW-00000385",' +
                '"Id":"2c92c0f96ae3b195016ae5e3665e0c08",' +
                '"ChargeNumber":"C-00003171",' +
                '"Name":"Utility Credit",' +
                '"Project__c":"SSS-000099"}';
            if (reqBody.contains('query')) {
                res.setBody('{"records":[' + ratePlan + '], "size":1,"done":true}');
            } else {
                res.setBody(ratePlan);
            }
        } else if (reqBody.contains('2c92c0f96ae3b195016ae5e3668e0c15')){
            String ratePlan = '{"ClientOwner__c":"BW-00000385",' +
                '"Id":"2c92c0f96ae3b195016ae5e3668e0c15",' +
                '"ChargeNumber":"C-00003171",' +
                '"Name":"Utility Credit",' +
                '"Project__c":"SSS-000098"}';
            if (reqBody.contains('query')) {
                res.setBody('{"records":[' + ratePlan + '], "size":1,"done":true}');
            } else {
                res.setBody(ratePlan);
            }
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
        } else if (endpoint.contains('ThrowException')) {
            throw new Util.BWException('Test callout exception');
        }

        return res;
    }

    private static HttpResponse createDebitMemo(){
        HttpResponse res = getJSON();
        res.setBody(
            '{ "id" : "2c92c0fa6a3458e1016a45ac238e0d66", ' +
                '"number" : "CM00000049", ' +
                '"accountId" : "2c92c0f869c8e5c50169dfb877685bd8", ' +
                '"debitMemoDate" : "2019-04-22", ' +
                '"amount" : 34.00, ' +
                '"reasonCode" : "BW - Initiated Credit", ' +
                '"Project__c" : "Project A Oak Road", ' +
                '"ClientOwner__c" : "SSS-0000123", ' +
                '"CRM_ID__c" : "a0p0j00000CwTIHAA3", ' +
                '"success" : true }'
        );
        return res;
    }

    private static HttpResponse getDebitMemos(String endpoint) {
        HttpResponse res = getJSON();
        if (endpoint.contains('2c92c0fa6cbe34cb016cc13290452db4')) {
            res.setBody('{' +
                '"id":"2c92c0fa6cbe34cb016cc13290452db4",' +
                '"number":"DM00014524",' +
                '"accountId":"2c92c0f86cbe3367016cc12b3f614b8f",' +
                '"debitMemoDate":"2019-06-07",' +
                '"currency":"USD",' +
                '"dueDate":"2019-07-07",' +
                '"postedOn":"2019-08-23 21:16:52",' +
                '"postedById":"2c92c0f96a01b91f016a050fad50160a",' +
                '"status":"Posted",' +
                '"amount":13.670000000,' +
                '"beAppliedAmount":13.670000000,' +
                '"autoPay":true,' +
                '"transferredToAccounting":"No",' +
                '"reasonCode":"Late Fee",' +
                '"Project__c":"SSS-000024",' +
                '"ClientOwner__c":"BW-0023170",' +
                '"CRM_ID__c":"a2GS0000001gmUAMAY",' +
                '"success":true' +
                '}');
        } else {
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
        }
        return res;
    }

    private static HttpResponse getDebitMemoItems(String endpoint) {
        HttpResponse res = getJSON();
        if (endpoint.contains('ThrowException')) {
            throw new Util.BWException('Callout exception');
        } else {
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
        }
        return res;
    }

    private static HttpResponse createElectronicPayment(){
        HttpResponse res = getJSON();
        res.setBody(
            '{ "id" : "2c92c0fa6c2d46c2016c5271d6004086", ' +
                '"number" : "P-00000269", ' +
                '"status" : "Processed", ' +
                '"type" : "Electronic", ' +
                '"accountId" : "2c92c0f86b78f56c016b7b00480c2e24", ' +
                '"amount" : 23.000000000, ' +
                '"appliedAmount" : 0E-9, ' +
                '"unappliedAmount" : 23.000000000, ' +
                '"refundAmount" : 0E-9, ' +
                '"creditBalanceAmount" : 0E-9, ' +
                '"currency" : "USD", ' +
                '"effectiveDate" : "2019-08-02", ' +
                '"comment" : null, ' +
                '"paymentMethodId" : "2c92c0f86a0c41a5016a1f41d63a2f96", ' +
                '"paymentMethodSnapshotId" : "2c92c0fa6c2d46c2016c5271d6004085", ' +
                '"authTransactionId" : null, ' +
                '"bankIdentificationNumber" : null, ' +
                '"gatewayId" : "2c92c0f9699ec9fe0169a68ab88b6ae3", ' +
                '"gatewayOrderId" : null, ' +
                '"gatewayResponse" : "This transaction has been approved.", ' +
                '"gatewayResponseCode" : "1", ' +
                '"gatewayState" : "Submitted", ' +
                '"markedForSubmissionOn" : null, ' +
                '"referenceId" : "60125341308", ' +
                '"secondPaymentReferenceId" : null, ' +
                '"softDescriptor" : null, ' +
                '"softDescriptorPhone" : null, ' +
                '"submittedOn" : "2019-08-02 09:08:08", ' +
                '"settledOn" : null, "cancelledOn" : null, ' +
                '"createdDate" : "2019-08-02 09:08:07", ' +
                '"createdById" : "2c92c0f968a20f350168ca0efb2309e7", ' +
                '"updatedDate" : "2019-08-02 09:08:08", ' +
                '"updatedById" : "2c92c0f968a20f350168ca0efb2309e7", ' +
                '"TransactionId__c" : null, "ClientOwner__c" : null, ' +
                '"financeInformation" : { "bankAccountAccountingCode" : "11504 - ACH", ' +
                '"bankAccountAccountingCodeType" : "Cash", ' +
                '"unappliedPaymentAccountingCode" : "20006 - Trust Payable", ' +
                '"unappliedPaymentAccountingCodeType" : "OtherLiabilities", ' +
                '"transferredToAccounting" : "No" }, ' +
                '"success" : true }');
        return res;
    }

    private static HttpResponse getDataQuery(String endpoint){
        HttpResponse res = getJSON();
        if (endpoint.contains('queryStillInProcess')){
            // Check on query, but its still in process:
            res.setBody(
                '{"data":{"id":"7742a20c-18ea-4fde-b185-4aed364ce22c",' +
                    '"query":"SHOW Columns FROM Account",' +
                    '"queryStatus":"in_progress",' +
                    '"remainingRetries":3,"retries":3,' +
                    '"updatedOn":"2019-08-19T17:48:41.837Z"}}'
            );
        } else if (endpoint.contains('queryFailed')){
            // Check on query, but its still in process:
            res.setBody(
                '{"data":{' +
                    '"queryStatus" : "failed", ' +
                    '"id" : "7742a20c-18ea-4fde-b185-4aed364ce22c",' +
                    '"errorCode" : "LINK_00000001", ' +
                    '"errorMessage" : "Query failed (#20190816_130023_10875_snsq9): line 1:"' +
                    '}}'
            );
        } else if (endpoint.contains('queryCompleted')){
            // Check on query, and its complete:
            res.setBody(
                '{"data":{"id":"7742a20c-18ea-4fde-b185-4aed364ce22c",' +
                    '"query":"SHOW Columns FROM Account",' +
                    '"queryStatus":"completed",' +
                    '"dataFile":"https://owl-auw2-sbx01-query-result.s3.us-west-2.amazonaws.com/' +
                    '7f4b1caf-6cb8-4f3c-bdda-dd8133043f73_1023727654544428.json?X-Amz-Security-Toke' +
                    'n=FQoGZXIvYXdzEAgaDAmOEyd0LkZoFr3y6iKVBI3MwM768d1NPeFNnl8vqSLSzReta6AgJj' +
                    '%2FmouYCx8%2F1KhQLGLAzTON00uro0Z%2BYzLlMeWR97%2Bgvs7%2BLI34JtCkctX' +
                    '%2BAlpp0uDc1%2F1sfdY7HOTzlJkn2jkIjrENvpqy5XKysaMJ8Bc3S0WGaoioIMzC' +
                    '%2F%2BI8%2B1M3YKKs2cumQ8aXoSa0h5A1BsVeguSl8JlJhJZZSew3Z9wVJl8y9f' +
                    'OskrACvYTfpywhLUaUgL3bBTL1I%2FVGC%2FPlKqBCEy6KCiVJL3zjaovITHmNjwnRxz' +
                    'xMtbFsJspWR6t7HFIN0j%2BkG17h9CYu5yathF%2BKVm%2F1t5gY0kfcuPoMQGyL%2Ffg' +
                    'ZQTH2LUa3K%2BSBRE4lv1o1EBb2xLUfOsrOflnFtq%2BjqGOHMqEyIolTTPRrsOv3u3Ok' +
                    'N0Wen%2BYsAfSHx4DziLLZqSXX06MjOIblNirYrOkOJkP7lx3GG%2FortPVbM2MiWFGAQJ6RX0W' +
                    'vlrn0bOz5hpOYvHOAtDMOEhouHmH6aFTpjcPCZcGGuSLeEE75%2FMyxf5jaKiXyRIcwgOir' +
                    '%2FUiHiFcZL7%2FyiX7JRLufdwQEic9LkgCAYb4rHCPqHh21Bji4dvrp3%2B82Y%2BYiS9fH' +
                    'la7lYM%2Fl2iYcNp5sP7ssEvYRhfY9u8UHj5fossmNtEFOz1oGKZUnKzs5kuJJgfb%2BlYDn' +
                    '71Y6tdXQYptcMmdEDmwu%2F7XA%2BllPk4miQmtjHqf7CKP3x6uoF&X-Amz-Algorithm=A' +
                    'WS4-HMAC-SHA256&X-Amz-Date=20190819T175244Z&X-Amz-SignedHeaders=host&X-Amz' +
                    '-Expires=604800&X-Amz-Credential=ASIAQXFLO6OTKH3EOP4C%2F20190819%2Fus-west' +
                    '-2%2Fs3%2Faws4_request&X-Amz-Signature=e029cc85d8660a2a89623124eeb6e052909d' +
                    '9951650cffcc7335aa3c247c5447",' +
                    '"outputRows":52,' +
                    '"processingTime":1182,' +
                    '"remainingRetries":3,' +
                    '"retries":3,' +
                    '"updatedOn":"2019-08-19T17:52:44.504Z"}}'
            );
        } else if (endpoint.contains('7742a20c-18ea-4fde-b185-4aed364ce22c')){
            // Check on query, and its complete:
            res.setBody(
                '{"data":{"id":"7742a20c-18ea-4fde-b185-4aed364ce22c",' +
                    '"query":"SHOW Columns FROM Account",' +
                    '"queryStatus":"completed",' +
                    '"dataFile":"https://owl-auw2-sbx01-query-result.s3.us-west-2.amazonaws.com/' +
                    'LINK_CONTAINS_RETURN_GL_OBJECT' +
                    '_1023727654544428.json?X-Amz-Security-Toke' +
                    'n=FQoGZXIvYXdzEAgaDAmOEyd0LkZoFr3y6iKVBI3MwM768d1NPeFNnl8vqSLSzReta6AgJj' +
                    '%2FmouYCx8%2F1KhQLGLAzTON00uro0Z%2BYzLlMeWR97%2Bgvs7%2BLI34JtCkctX' +
                    '%2BAlpp0uDc1%2F1sfdY7HOTzlJkn2jkIjrENvpqy5XKysaMJ8Bc3S0WGaoioIMzC' +
                    '%2F%2BI8%2B1M3YKKs2cumQ8aXoSa0h5A1BsVeguSl8JlJhJZZSew3Z9wVJl8y9f' +
                    'OskrACvYTfpywhLUaUgL3bBTL1I%2FVGC%2FPlKqBCEy6KCiVJL3zjaovITHmNjwnRxz' +
                    'xMtbFsJspWR6t7HFIN0j%2BkG17h9CYu5yathF%2BKVm%2F1t5gY0kfcuPoMQGyL%2Ffg' +
                    'ZQTH2LUa3K%2BSBRE4lv1o1EBb2xLUfOsrOflnFtq%2BjqGOHMqEyIolTTPRrsOv3u3Ok' +
                    'N0Wen%2BYsAfSHx4DziLLZqSXX06MjOIblNirYrOkOJkP7lx3GG%2FortPVbM2MiWFGAQJ6RX0W' +
                    'vlrn0bOz5hpOYvHOAtDMOEhouHmH6aFTpjcPCZcGGuSLeEE75%2FMyxf5jaKiXyRIcwgOir' +
                    '%2FUiHiFcZL7%2FyiX7JRLufdwQEic9LkgCAYb4rHCPqHh21Bji4dvrp3%2B82Y%2BYiS9fH' +
                    'la7lYM%2Fl2iYcNp5sP7ssEvYRhfY9u8UHj5fossmNtEFOz1oGKZUnKzs5kuJJgfb%2BlYDn' +
                    '71Y6tdXQYptcMmdEDmwu%2F7XA%2BllPk4miQmtjHqf7CKP3x6uoF&X-Amz-Algorithm=A' +
                    'WS4-HMAC-SHA256&X-Amz-Date=20190819T175244Z&X-Amz-SignedHeaders=host&X-Amz' +
                    '-Expires=604800&X-Amz-Credential=ASIAQXFLO6OTKH3EOP4C%2F20190819%2Fus-west' +
                    '-2%2Fs3%2Faws4_request&X-Amz-Signature=e029cc85d8660a2a89623124eeb6e052909d' +
                    '9951650cffcc7335aa3c247c5447",' +
                    '"outputRows":52,' +
                    '"processingTime":1182,' +
                    '"remainingRetries":3,' +
                    '"retries":3,' +
                    '"updatedOn":"2019-08-19T17:52:44.504Z"}}'
            );
        } else {
            // Submit new query, get back id:
            res.setBody(
                '{"data":{"id":"7742a20c-18ea-4fde-b185-4aed364ce22c",' +
                    '"query":"SHOW Columns FROM Account",' +
                    '"queryStatus":"accepted",' +
                    '"remainingRetries":3,' +
                    '"retries":3,' +
                    '"updatedOn":"2019-08-19T17:33:45.675Z"}}'
            );
        }
        return res;
    }

    private static HttpResponse getDataQueryData(String endpoint){
        HttpResponse res = getJSON();
        if (endpoint.contains('LINK_CONTAINS_RETURN_GL_OBJECT')){
            res.setBody(
                '' +
                    '{"Project":"SSS-000070","Client":"BW-0011514","GLDate":"2019-03-01",' +
                    '"CustomerAccount":"BW-0013285","Amount":19.690000,' +
                    '"AccountId":"2c92c0f96c8596ce016c8718b27c3c3c",' +
                    '"ExternalId":"2c92c0fa6c8aee2e016c926763d231d0"} ' +
                    '{"Project":"SSS-000019","Client":"BW-0009470","GLDate":"2019-05-01",' +
                    '"CustomerAccount":"bw-04639","Amount":328.330000,' +
                    '"AccountId":"2c92c0f96c8596ce016c87202b9d2a80",' +
                    '"ExternalId":"2c92c0fa6c8aee37016c928a815955c0"} ' +
                    '{"Project":"SSS-000087","Client":"BW-0011514","GLDate":"2019-07-01",' +
                    '"CustomerAccount":"bw-00803","Amount":19.100000,' +
                    '"AccountId":"2c92c0f86c858923016c872551192523",' +
                    '"ExternalId":"2c92c0fb6c8afb33016c928738435224"} ' +
                    '{"Project":"SSS-000070","Client":"BW-0011514","GLDate":"2019-01-01",' +
                    '"CustomerAccount":"BW-0013262","Amount":34.000000,' +
                    '"AccountId":"2c92c0f86c858922016c871893cd7504",' +
                    '"ExternalId":"2c92c0fb6c8afb4e016c926615190872"} ' +
                    '{"Project":"SSS-000071","Client":"BW-0011514","GLDate":"2019-03-01",' +
                    '"CustomerAccount":"BW-0012690","Amount":33.890000,' +
                    '"AccountId":"2c92c0f96c8596ce016c8717ebc26323",' +
                    '"ExternalId":"2c92c0fb6c8afb4e016c926d8fd03f5a"} ' +
                    '{"Project":"SSS-000068","Client":"BW-0011514","GLDate":"2019-06-01",' +
                    '"CustomerAccount":"BW-0013802","Amount":22.470000,' +
                    '"AccountId":"2c92c0f96c8596ce016c87194923685d",' +
                    '"ExternalId":"2c92c0fb6c8afb4e016c925afaec2e13"} ' +
                    '{"Project":"SSS-000071","Client":"BW-0011514","GLDate":"2019-07-08",' +
                    '"CustomerAccount":"BW-0012618","Amount":112.980000,' +
                    '"AccountId":"2c92c0f86c858923016c8717c67d1209",' +
                    '"ExternalId":"2c92c0fb6c8afb4e016c9262b7c86b11"} ' +
                    '{"Project":"SSS-000087","Client":"BW-0011514","GLDate":"2019-06-01",' +
                    '"CustomerAccount":"BW-0013995","Amount":74.290000,' +
                    '"AccountId":"2c92c0f86c85891e016c871a28a541ad",' +
                    '"ExternalId":"2c92c0fb6c8afb49016c926205805ebf"} ' +
                    '{"Project":"SSS-000019","Client":"BW-0009470","GLDate":"2019-01-07",' +
                    '"CustomerAccount":"bw-04803","Amount":301.920000,' +
                    '"AccountId":"2c92c0f96c8596ce016c87208eb10692",' +
                    '"ExternalId":"2c92c0fa6c8aee24016c928961437a75"} ' +
                    '{"Project":"SSS-000016","Client":"BW-0009470","GLDate":"2019-03-29",' +
                    '"CustomerAccount":"BW-0007283","Amount":173.960000,' +
                    '"AccountId":"2c92c0f86c858922016c87172a376e9d",' +
                    '"ExternalId":"2c92c0fa6c8aee24016c929406a2570f"} ' +
                    '{"Project":"SSS-000069","Client":"BW-0011514","GLDate":"2019-06-01",' +
                    '"CustomerAccount":"BW-0012937","Amount":86.920000,' +
                    '"AccountId":"2c92c0f86c858923016c871832b214cb",' +
                    '"ExternalId":"2c92c0fa6c8aee2e016c925f61d86a9b"} ' +
                    '{"Project":"SSS-000070","Client":"BW-0011514","GLDate":"2019-04-01",' +
                    '"CustomerAccount":"BW-0013318","Amount":26.440000,' +
                    '"AccountId":"2c92c0f96c8596ce016c8718b5383c60",' +
                    '"ExternalId":"2c92c0fa6c8aee37016c926a024f5f0e"} ' +
                    '{"Project":"SSS-000070","Client":"BW-0011514","GLDate":"2018-12-01",' +
                    '"CustomerAccount":"BW-0013262","Amount":117.780000,' +
                    '"AccountId":"2c92c0f86c858922016c871893cd7504",' +
                    '"ExternalId":"2c92c0fb6c8afb49016c92661341028a"} ' +
                    '{"Project":"SSS-000070","Client":"BW-0011514","GLDate":"2019-04-01",' +
                    '"CustomerAccount":"BW-0013274","Amount":14.400000,' +
                    '"AccountId":"2c92c0f86c858922016c8718952b7510",' +
                    '"ExternalId":"2c92c0fa6c8aee2e016c92668a082a3f"}'
            );
        } else {
            res.setBody(
                '{"Column":"accountnumber","Type":"varchar","Extra":"","Comment":"AccountNumber"}' +
                    '{"Column":"additionalemailaddresses","Type":"varchar","Extra":"","Comment":"AdditionalEmailAddresses"}' +
                    '{"Column":"allowinvoiceedit","Type":"boolean","Extra":"","Comment":"AllowInvoiceEdit"}' +
                    '{"Column":"autopay","Type":"boolean","Extra":"","Comment":"AutoPay"}' +
                    '{"Column":"balance","Type":"decimal(18,6)","Extra":"","Comment":"Balance"}' +
                    '{"Column":"batch","Type":"varchar","Extra":"","Comment":"Batch"}' +
                    '{"Column":"bcdsettingoption","Type":"varchar","Extra":"","Comment":"BcdSettingOption"}' +
                    '{"Column":"billcycleday","Type":"bigint","Extra":"","Comment":"BillCycleDay"}' +
                    '{"Column":"taxexemptissuingjurisdiction","Type":"varchar","Extra":"","Comment":"TaxExemptIssuingJurisdiction"}' +
                    '{"Column":"taxexemptstatus","Type":"varchar","Extra":"","Comment":"TaxExemptStatus"}' +
                    '{"Column":"totaldebitmemobalance","Type":"decimal(18,6)","Extra":"","Comment":"TotalDebitMemoBalance"}' +
                    '{"Column":"totalinvoicebalance","Type":"decimal(18,6)","Extra":"","Comment":"TotalInvoiceBalance"}' +
                    '{"Column":"unappliedbalance","Type":"decimal(18,6)","Extra":"","Comment":"UnappliedBalance"}' +
                    '{"Column":"unappliedcreditmemoamount","Type":"decimal(18,6)","Extra":"","Comment":"UnappliedCreditMemoAmount"}' +
                    '{"Column":"updatedbyid","Type":"varchar","Extra":"","Comment":"UpdatedById"}' +
                    '{"Column":"updateddate","Type":"timestamp with time zone","Extra":"","Comment":"UpdatedDate"}' +
                    '{"Column":"vatid","Type":"varchar","Extra":"","Comment":"VATId"}'
            );
        }
        return res;
    }

    private static HttpResponse createPayment(String endpoint) {
        HttpResponse res = getJSON();
        res.setBody('{' +
            '"id" : "2c92c0fa6c2d46c2016c4593e3f47daf",' +
            '"number" : "P-00000255",' +
            '"status" : "Processed",' +
            '"type" : "External",' +
            '"accountId" : "2c92c0f96c2d540e016c443c4263679d",' +
            '"amount" : 5.020000000,' +
            '"appliedAmount" : 0E-9,' +
            '"unappliedAmount" : 5.020000000,' +
            '"refundAmount" : 0E-9,' +
            '"creditBalanceAmount" : 0E-9,' +
            '"currency" : "USD",' +
            '"effectiveDate" : "2019-07-02",' +
            '"comment" : null,' +
            '"paymentMethodId" : "2c92c0f868a2023a0168a79e7f4f3f70",' +
            '"paymentMethodSnapshotId" : null,' +
            '"authTransactionId" : null,' +
            '"bankIdentificationNumber" : null,' +
            '"gatewayId" : null,' +
            '"gatewayOrderId" : null,' +
            '"gatewayResponse" : null,' +
            '"gatewayResponseCode" : null,' +
            '"gatewayState" : "NotSubmitted",' +
            '"markedForSubmissionOn" : null,' +
            '"referenceId" : null,' +
            '"secondPaymentReferenceId" : null,' +
            '"softDescriptor" : null,' +
            '"softDescriptorPhone" : null,' +
            '"submittedOn" : null,' +
            '"settledOn" : null,' +
            '"cancelledOn" : null,' +
            '"createdDate" : "2019-07-30 21:10:15",' +
            '"createdById" : "2c92c0f96a01b91f016a050fad50160a",' +
            '"updatedDate" : "2019-07-30 21:10:15",' +
            '"updatedById" : "2c92c0f96a01b91f016a050fad50160a",' +
            '"TransactionId__c" : null,' +
            '"ClientOwner__c" : null,' +
            '"financeInformation" : {' +
            '"bankAccountAccountingCode" : "11504 - Check",' +
            '"bankAccountAccountingCodeType" : "Cash",' +
            '"unappliedPaymentAccountingCode" : "20006 - Trust Payable",' +
            '"unappliedPaymentAccountingCodeType" : "OtherLiabilities",' +
            '"transferredToAccounting" : "No"' +
            '},' +
            '"success" : true}');
        return res;
    }

    private static HttpResponse getGateways() {
        HttpResponse res = getJSON();
        res.setBody('{ "paymentgateways" : [ { ' +
            '"id" : "2c92c0f9699ec9fe0169a68ab88b6ae3", ' +
            '"name" : "Default Gateway Name", ' +
            '"type" : "Authorize", ' +
            '"isDefault" : true, ' +
            '"isActive" : true }, { ' +
            '"id" : "2c92c0f8699ebeac0169a6891cd862d1",' +
            ' "name" : "Bluewave Testing Auth.Net", ' +
            '"type" : "Authorize", ' +
            '"isDefault" : false, ' +
            '"isActive" : true }, { ' +
            '"id" : "2c92c0f9697a318001698330cdee1e81", ' +
            '"name" : "Not Default Gateway", ' +
            '"type" : "Sample", ' +
            '"isDefault" : false, ' +
            '"isActive" : true } ], ' +
            '"success" : true }');
        return res;
    }

    private static HttpResponse getPayment(String endpoint) {
        HttpResponse res = getJSON();
        if (endpoint.contains('itemparts')) {
            if (endpoint.contains('2c92c0fb6cb90e40016cc137e1c255a8')) {
                res.setBody('{"itemParts":[' +
                    '{"id":"2c92c0fb6cb90e40016cc137e1c1559c","invoiceItemId":null,"debitMemoItemId":"2c92c0fa6cbe34cb016cc132905e2db5","amount":13.670000000}' +
                    '],' +
                    '"success":true}');
            } else {
                res.setBody('{"itemParts":[' +
                    '{"id":"2c92c0fb6cb90e40016cc137e1c05598","invoiceItemId":"2c92c0856cbe2e20016cc133cbd76420","debitMemoItemId":null,"amount":134.700000000},' +
                    '{"id":"2c92c0fb6cb90e40016cc137e1c0559a","invoiceItemId":"2c92c0856cbe2e20016cc133cbd86421","debitMemoItemId":null,"amount":120.210000000}' +
                    '],' +
                    '"success":true}'
                );
            }
        } else if (endpoint.contains('parts')) {
            res.setBody('{"parts":[' +
                '{"id":"2c92c0fb6cb90e40016cc137e1c255a8","debitMemoId":"2c92c0fa6cbe34cb016cc13290452db4","invoiceId":null,"amount":13.670000000},' +
                '{"id":"2c92c0fb6cb90e40016cc137e1c255a3","debitMemoId":null,"invoiceId":"2c92c0856cbe2e20016cc133cbb1641b","amount":254.910000000}],' +
                '"success":true}');
        } else if (endpoint.contains('ALREADYRETURNED')) {
            res.setBody('{' +
                '"type":"External",' +
                '"paymentMethodId":"2c92c0f868a2023a0168a79e7f4f3f70",' +
                '"id":"2c92c0fb6cb90e36016cc137e05d46dc",' +
                '"effectiveDate":"2019-06-20",' +
                '"amount":1668.290000000,' +
                '"ResponseStatus__c" : "Returned",' +
                '"accountId":"2c92c0f96c8afb5d016c8c5b4d4c7b6e"' +
                '}');
        } else {
            res.setBody('{' +
                '"type":"External",' +
                '"paymentMethodId":"2c92c0f868a2023a0168a79e7f4f3f70",' +
                '"id":"2c92c0fb6cb90e36016cc137e05d46dc",' +
                '"effectiveDate":"2019-06-20",' +
                '"amount":1668.290000000,' +
                '"accountId":"2c92c0f96c8afb5d016c8c5b4d4c7b6e",' +
                '"success":true' +
                '}');
        }
        return res;
    }

    private static HttpResponse getBillRun() {
        HttpResponse res = getJSON();
        res.setBody('{"Success":true,"Id":"2c92c0f86d1fd442016d217fbaeb6278"}');
        return res;
    }
}