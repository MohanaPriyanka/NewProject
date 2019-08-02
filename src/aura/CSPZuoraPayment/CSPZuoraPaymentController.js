({  doInit : function(component, event, helper) {
        helper.doInItHelper(component, event, helper);
    },

    onAutopayChange : function(component, event, helper) {
        helper.handleAutopayChange(component, event, helper);
    },

    onPaymentAmountChange : function(component, event, helper) {
        helper.handlePaymentAmountChange(component, event, helper);
    },

    onPaymentMethodChange : function(component, event, helper){
        var response = event.getParam('response');
        var paymentMethod = event.getParam('paymentMethod');
        if (response.success) {
            if (paymentMethod.Type == 'CreditCard'){
                component.set("v.currentPaymentMethod", paymentMethod.CreditCardMaskNumber);
            } else if (paymentMethod.Type == 'ACH') {
                component.set("v.currentPaymentMethod", paymentMethod.AchAccountNumberMask);
            }
            component.set("v.newPaymentMethodId",paymentMethod.Id);
            component.set("v.showCardPaymentMethod", false);
            helper.linkPayMethodToAccount(component, event, helper);
            helper.checkAllRequiredFields(component, event, helper);
        } else {
            var errorMessage = 'A system error occurred while submitting your payment method. We have been notified and will contact you with further instructions.';
            this.finishAndShowMessage(component, event, helper, errorMessage);
        }
    },

    agreeToAutopay : function(component, event, helper) {
        component.set("v.AutopayAgree",true);
        helper.checkAllRequiredFields(component, event, helper);
    },

    sendToZuora : function(component, event, helper) {
        helper.sendToZuoraHelper(component, event, helper);
    },

    toggleCardPaymentAmount : function(component, event, helper) {
        component.set("v.showCardPaymentAmount", !component.get("v.showCardPaymentAmount"));
    },

    toggleCardPaymentMethod : function(component, event, helper) {
        component.set("v.showCardPaymentMethod", !component.get("v.showCardPaymentMethod"));
    },

    toggleCardAutopay : function(component, event, helper) {
        component.set("v.showCardAutopay", !component.get("v.showCardAutopay"));
    },

    closeAutopayOpenAmount : function(component, event, helper) {
        component.set("v.showCardAutopay", false);
        if (component.get("v.makePaymentOrManageAutopay")){
            component.set("v.showCardPaymentAmount", true);
        } else {
            component.set("v.showCardPaymentMethod", true);
        }
    },

    closeAmountOpenMethod : function(component, event, helper) {
        component.set("v.showCardPaymentAmount", false);
        component.set("v.showCardPaymentMethod", true);
    },

    returnToMyAccount : function(component, event, helper) {
        $A.get('e.force:refreshView').fire();
    },
})