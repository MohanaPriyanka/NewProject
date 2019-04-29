({
    doInit: function(component, event, helper) {
        var email = component.get("v.email");
        if (email) {
            component.set("v.email", decodeURIComponent(email));
        }
        var partnerId = component.get("v.partnerId");
        if (partnerId) {
            component.set("v.partnerId", decodeURIComponent(partnerId));

            //Check partnerId to determine CSAP process
            var action = component.get("c.checkApplicationPartner");
            action.setParams({"partnerId": component.get("v.partnerId")});
            action.setCallback(this, function(resp) {
                if(resp.getState() === 'SUCCESS') {
                    var partnerApp = resp.getReturnValue();
                    component.set("v.partnerApp", partnerApp);
                } else {
                    this.logError('CSAPApplication', 'checkApplicationPartner', resp.getError(), component.get('v.partnerId'));
                }
            });
            $A.enqueueAction(action);

        }
        var salesRepId = component.get("v.salesRepId");
        if (salesRepId) {
            component.set("v.salesRepId", decodeURIComponent(salesRepId));
        }
        var referralCode = component.get("v.referralCode");
        if (referralCode) {
            component.set("v.referralCode", decodeURIComponent(referralCode));
        }

        var paymentProviderAction = component.get('c.zuoraEnabled');
        paymentProviderAction.setCallback(this, function(paymentProviderResponse) {
            if (paymentProviderResponse.getState() === 'SUCCESS') {
                if (paymentProviderResponse.getReturnValue()) {
                    component.set('v.paymentProvider', 'Zuora');
                } else {
                    component.set('v.paymentProvider', 'Chargent');
                }
            } else {
                this.logError('CSAPApplication', 'doInit', paymentProviderResponse.getError(), paymentProviderResponse);
                component.set('v.paymentProvider', 'Chargent');
            }
        });
        $A.enqueueAction(paymentProviderAction);
    },
})