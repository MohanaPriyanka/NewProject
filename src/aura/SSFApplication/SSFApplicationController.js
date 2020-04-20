/**
 * Created by peteryao on 3/5/20.
 */

({
    doInit: function(component) {
        component.set('v.getInfo', true);
        component.set('v.getPayment', false);
        component.set('v.showComplete', false);
    },

    handleConsents : function(component, event) {
        component.set('v.lead', event.getParams());
        console.log(event.getParams());
        component.set('v.getInfo', false);
        component.set('v.getPayment', true);
        component.set('v.showComplete', false);
    },

    onPaymentMethodComplete : function(component, event, helper) {
        let paymentPageResponse = event.getParams();
        component.set('v.showSpinner', true);
        component.set('v.spinnerMessage', 'Completing your application');
        if (!paymentPageResponse || !paymentPageResponse.paymentMethod ||
            !paymentPageResponse.paymentMethod.CreatedDate || !paymentPageResponse.paymentMethod.Id) {
            helper.logError("SSFApplicationController", "onPaymentMethodComplete", JSON.stringify(event.getParams()), component.get("v.lead"));
            helper.showFinalPage(component);
            return;
        }

        // Because we don't get the payment method expiration date back from Zuora, we need to calculate it ourselves
        let paymentExpirationDate = new Date(paymentPageResponse.paymentMethod.CreatedDate);
        paymentExpirationDate.setDate(paymentExpirationDate.getDate() + 10);

        let propertyAccount = {
            leadId: component.get('v.lead.id'),
            email: component.get('v.lead.email'),
            id: component.get('v.lead.propertyAccounts[0].id'),
            zuoraPaymentRefId: paymentPageResponse.paymentMethod.Id,
            zuoraPaymentRefIdExpirationDate: paymentExpirationDate
        };
        let restLead = {
            id: component.get('v.lead.id'),
            email: component.get('v.lead.email'),
            applicationCompleteDate: new Date()
        };

        helper.savePaymentMethodToAccount(propertyAccount).then(
            (resolveResult) => {
                helper.finishApplication(restLead).then(
                    (resolveResult) => {
                        helper.showFinalPage(component);
                    },
                    (rejectResult) => {
                        helper.logError("SSFApplicationController", "onPaymentMethodComplete", JSON.stringify(rejectResult), component.get("v.lead"));
                        helper.showFinalPage(component);
                    }
                );
            },
            (rejectResult) => {
                helper.logError("SSFApplicatioNController", "onPaymentMethodComplete", JSON.stringify(rejectResult), component.get("v.lead"));
                helper.showFinalPage(component);
            }
        );

    },

    showComplete: function(component, event, helper) {
        console.log('all complete event received');
        helper.showFinalPage(component);
    }
});