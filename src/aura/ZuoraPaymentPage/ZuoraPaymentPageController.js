/**
 * Created by peteryao on 2019-04-11.
 */
({
    doInit: function(component, event, helper) {
        var getPaymentPageMetadataAction = component.get('c.getPageMetadataWithDomain');
        var hostname = window.location.hostname;

        getPaymentPageMetadataAction.setParams({
            "domain" : hostname
        });

        getPaymentPageMetadataAction.setCallback(this, function(resp) {
            if (resp.getState() === 'SUCCESS') {
                component.set('v.paymentPageMetadata', resp.getReturnValue());
            } else {
                helper.logError('ZuoraPaymentPageController', 'doInit', JSON.stringify(resp.getError()));
            }
        });
        $A.enqueueAction(getPaymentPageMetadataAction);
    },

    renderPaymentFrame: function(component, event, helper) {
        var paymentPageMetadata = component.get('v.paymentPageMetadata');
        var paymentType = component.get('v.paymentType');
        var paymentPageId, rsaSignature;
        if (paymentType === 'Credit Card') {
            paymentPageId = paymentPageMetadata.ccPaymentPageId;
            rsaSignature = paymentPageMetadata.ccRsaSignature;
        } else if (paymentType === 'ACH') {
            paymentPageId = paymentPageMetadata.achPaymentPageId;
            rsaSignature = paymentPageMetadata.achRsaSignature;
        } else {
            return;
        }
        var params = {
            tenantId: rsaSignature.tenantId,
            id:paymentPageId,
            token:rsaSignature.token,
            signature:rsaSignature.signature,
            style:"inline",
            key:rsaSignature.key,
            submitEnabled:"true",
            url:paymentPageMetadata.zuoraSetting.Hosted_Payment_Page_URI__c
        };
        var prepopulatedFields = {};
        Z.render(params,prepopulatedFields,$A.getCallback(function(response) {
            // If successful, get the payment method and return it too
            if (response.success && response.refId) {
                var getPaymentMethodAction = component.get('c.getPaymentMethod');
                getPaymentMethodAction.setParam('refId', response.refId);
                getPaymentMethodAction.setCallback(this, function(paymentMethodResponse) {
                    if (paymentMethodResponse.getState() === 'SUCCESS') {
                        var completeEvent = $A.get('e.c:ZuoraPaymentPageComplete');
                        completeEvent.setParam('response', response);
                        completeEvent.setParam('paymentMethod', paymentMethodResponse.getReturnValue());
                        completeEvent.fire();
                    } else {
                        // we didn't get payment information back, but we can still have the customer input payment
                        // info in the contract
                        var completeEventError = $A.get('e.c:ZuoraPaymentPageComplete');
                        completeEventError.setParams({'response': response});
                        completeEventError.fire();
                    }
                });
                $A.enqueueAction(getPaymentMethodAction);
            } else {
                // response.success was false, or there was no refId. There are a variety of reasons for failure:
                // https://knowledgecenter.zuora.com/CB_Billing/LA_Hosted_Payment_Pages/B_Payment_Pages_2.0/N_Error_Handling_for_Payment_Pages_2.0#Hosted_Page_Validation_Errors
                // We'll still continue since the customer can input payment info directly in the contract
                var completeEvent = $A.get('e.c:ZuoraPaymentPageComplete');
                completeEvent.setParams({'response': response});
                completeEvent.fire();
            }
        }));
    }
})