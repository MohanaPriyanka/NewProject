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
                if (component.get('v.paymentType')) {
                    helper.renderPaymentFrame(component);
                }
            } else {
                helper.logError('ZuoraPaymentPageController', 'doInit', JSON.stringify(resp.getError()));
            }
        });
        $A.enqueueAction(getPaymentPageMetadataAction);
    },

    renderPaymentFrame: function(component, event, helper) {
        helper.renderPaymentFrame(component);
    }
})