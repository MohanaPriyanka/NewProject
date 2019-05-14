/**
 * Created by mstackhouse on 10/25/2018.
 */
({
    clearFields : function(component, event, helper) {
        let chOrder = component.get('v.chOrder');
        component.set('v.chOrder', { 'sobjectType': 'ChargentOrders__ChargentOrder__c',
            'ChargentOrders__Payment_Method__c' : '',
            'ChargentOrders__Bank_Name__c' : '',
            'ChargentOrders__Bank_Routing_Number__c' : '',
            'ChargentOrders__Bank_Account_Type__c' : '',
            'ChargentOrders__Bank_Account_Number__c' : '',
            'ChargentOrders__Bank_Account_Name__c' : '',
            'ChargentOrders__Billing_Email__c' : 'compliance@bluewavesolar.com',
            'ChargentOrders__Card_Type__c' : '',
            'ChargentOrders__Card_Number__c' : '',
            'ChargentOrders__Card_Expiration_Month__c' : '',
            'ChargentOrders__Card_Expiration_Year__c' : '',
            'ChargentOrders__Billing_Address__c' : '',
            'ChargentOrders__Billing_City__c' : '',
            'ChargentOrders__Billing_State__c' : '',
            'ChargentOrders__Billing_Zip_Postal__c' : '',
            'ChargentOrders__Billing_First_Name__c' : '',
            'ChargentOrders__Billing_Last_Name__c' : '',
            'Autopay_Only__c': chOrder.Autopay_Only__c});
    },

    handleNavEvent : function(component, event, helper) {
        if (event.getParam('options') && event.getParam('options').pageName) {
            helper.handleNavEvent(component, event, helper, event.getParam('options').pageName);
        } else {
            helper.handleNavEvent(component, event, helper, "PaymentInfo");
        }
        if (component.get('v.STAGENAME') === 'NAV_Payment_Information' && component.get('v.page') === 'PaymentInfo' && event.getParam("eventType")=== "INITIATED") {
            var actionStates = component.get("c.getStates");
            actionStates.setCallback(this,function(resp){
                if (resp.getState() === 'SUCCESS') {
                    component.set("v.States", resp.getReturnValue());
                } else {
                    component.set("v.States", "MA");
                }
            });
            $A.enqueueAction(actionStates);
            let thisYear = new Date().getFullYear();
            let years = [];
            for (let i=0; i<8; i++) {
                years.push(''+(thisYear + i));
            }
            component.set('v.expirationYears', years);

            var getProduct = component.get("c.getProduct");
            var lead = component.get("v.lead");
            getProduct.setParams({"productId": lead.Product__c});
            getProduct.setCallback(this, function(response) {
                if (response.getState() === 'SUCCESS') {
                    var product = response.getReturnValue();
                    if (product.Program__c.includes('SREC')) {
                        component.set("v.PaymentMethodsAccepted", [['Bank Account', 'ACH']]);
                    } else {
                        component.set("v.PaymentMethodsAccepted", [['Bank Account', 'ACH'],['Credit/Debit Card', 'Credit Card']]);
                    }

                }
            })
            if (lead.Product__c) {
                $A.enqueueAction(getProduct);
            }
        }
    },

    submitPaymentInfo : function(component, event, helper) {
        var chOrFields = component.get("v.chOrder");
        if(helper.validatePageFields(component)) {
            var insertOrderPromise = helper.insertOrders(component, chOrFields, helper, event);
            insertOrderPromise.then(
                $A.getCallback(function(result) {
                    component.set("v.Spinner", false);
                })
            );
        }
    },

    handleCompletedZuoraPayment : function(component, event, helper) {
        var response = event.getParam('response');
        var paymentMethod = event.getParam('paymentMethod');
        if (response.success) {
            var lead = component.get('v.lead');
            var leadToSave = {
                sobjectType: 'Lead',
                Id: lead.Id,
                Zuora_Payment_Ref_Id__c: response.refId,
                // Payment Methods expire in 240 hours
                Zuora_Payment_Ref_Id_Expiration_Date__c: new Date(Date.now()+240*60*60*1000).toJSON(),
                Loan_System_Information__c: JSON.stringify(paymentMethod)
            };
            var promise = helper.saveSObject(component, lead.Id, 'Lead', null, null, leadToSave);
            promise.then($A.getCallback(function resolve() {
                component.set('v.Spinner', false);
                helper.finishStage(component, event, helper);
            }));
        } else {
            helper.logError(
                'CSAPPaymentInfoController',
                'handleCompletedZuoraPayment',
                'Error submitting payment information, errorCode: ' + response.errorCode + ' errorMessage: ' + response.errorMessage,
                response);
        }
    },

    toggleZuoraContainer: function(component, event, helper) {
        var zuoraPaymentPage = component.find('ZuoraPaymentPage');
        $A.util.toggleClass(zuoraPaymentPage, 'disabledDiv');
    }
})