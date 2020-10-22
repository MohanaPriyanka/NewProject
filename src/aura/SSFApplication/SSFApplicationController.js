({
    doInit: function(component) {
        var loc;
        var href = decodeURIComponent(window.location.search.substring(1));
        var params = href.split('&');
        var param;
        var i;
        for (i = 0; i < params.length; i++) {
            param = params[i].split('=');
            if (param[0] === 'loc') {
                if (param[1] !== undefined) {
                    loc = param[1];
                }
                break;
            }
        }

        component.set('v.getPayment', false);
        if (loc === 'complete') {
            component.set('v.getInfo', false);
            component.set('v.showComplete', true);
        } else {
            component.set('v.getInfo', true);
            component.set('v.showComplete', false);
        }
    },

    handleConsents : function(component, event, helper) {
        var lead = event.getParams();
        var isPaymentInfoOnFile = helper.paymentInfoCollected(lead);
        if (isPaymentInfoOnFile) {
            helper.showFinalPage(component);
            return;
        }

        // Show get payment page if no payment information on file
        component.set('v.lead', lead);
        component.set('v.getInfo', false);
        component.set('v.getPayment', true);
        component.set('v.showComplete', false);
    },

    onPaymentMethodComplete : function(component, event, helper) {
        component.set('v.showSpinner', true);
        component.set('v.spinnerMessage', 'Completing your application');

        let paymentPageResponse = event.getParams();
        if (!paymentPageResponse || !paymentPageResponse.paymentMethod ||
            !paymentPageResponse.paymentMethod.CreatedDate || !paymentPageResponse.paymentMethod.Id)
        {
            let message = 'Payment page response: ' + JSON.stringify(paymentPageResponse) + '\n\nv.lead: '
                        + component.get("v.lead");
            helper.logError(
                component,
                'SSFApplicationController',
                'onPaymentMethodComplete',
                message
            );

            helper.showFinalPage(component);
            return;
        }

        // Because we don't get the payment method expiration date back from Zuora, we need to calc it ourselves
        let paymentExpirationDate = new Date(paymentPageResponse.paymentMethod.CreatedDate);
        paymentExpirationDate.setDate(paymentExpirationDate.getDate() + 10);

        let propertyAccount = {
            leadId: component.get('v.lead.id'),
            email: component.get('v.lead.email'),
            id: component.get('v.lead.propertyAccounts[0].id'),
            zuoraPaymentRefId: paymentPageResponse.paymentMethod.Id,
            zuoraPaymentRefIdExpirationDate: paymentExpirationDate
        };

        helper.savePaymentMethodToAccount(propertyAccount).then(
            (resolveResult) => {
                helper.finishApplication(component);
            },
            (rejectResult) => {
                let message = 'propertyAccount sent to server: ' + JSON.stringify(propertyAccount)
                              + '\n\n' + 'Callback received from server: ' + JSON.stringify(rejectResult);
                helper.logError(
                    component,
                    'SSFApplicationController',
                    'helper.savePaymentMethodToAccount',
                    message
                );

                helper.showFinalPage(component);
            }
        );
    },

    showComplete: function(component, event, helper) {
        helper.showFinalPage(component);
    }
});