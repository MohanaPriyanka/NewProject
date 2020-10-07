/**
 * Created by peteryao on 3/5/20.
 */

({
    doInit: function(component) {
        var loc;
        var href = decodeURIComponent(window.location.search.substring(1));
        var params = href.split('&');
        var param;
        var i;
        for(i = 0; i < params.length; i++) {
            param = params[i].split('=');
            if(param[0] === 'loc') {
                if(param[1] !== undefined) {
                    loc = param[1];
                }
                break;
            }
        }

        component.set('v.getPayment', false);
        if(loc === 'complete') {
            component.set('v.getInfo', false);
            component.set('v.showComplete', true);
        } else {
            component.set('v.getInfo', true);
            component.set('v.showComplete', false);
        }
    },

    handleConsents : function(component, event) {
        component.set('v.lead', event.getParams());
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
            applicationCompleteDate: new Date(),
            underwritingCriteria: component.get('v.lead.underwritingCriteria')
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
        helper.showFinalPage(component);
    }
});