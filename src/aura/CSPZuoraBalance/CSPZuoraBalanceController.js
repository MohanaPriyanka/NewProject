({  doInit : function(component, event, helper) {
        var actionGetBalance = component.get("c.getAccountWithDefaultPaymentMethod");

        actionGetBalance.setParams({
            "sfAccountId" : component.get("v.recordId")
        });

        actionGetBalance.setCallback(this,function(resp){
            component.set("v.showSpinner", false);

            if (resp.getState() === 'SUCCESS') {
                var zuoraAcct = resp.getReturnValue();
                component.set("v.zuoraAccountAndPayMethod", zuoraAcct);
                component.set("v.myBill", zuoraAcct.account.Balance);
                component.set("v.autopay", zuoraAcct.account.AutoPay);

                if (zuoraAcct.paymentMethod) {
                    if (zuoraAcct.paymentMethod.Type === 'CreditCard') {
                        component.set("v.autopayMethod", zuoraAcct.paymentMethod.CreditCardMaskNumber);
                    } else {
                        component.set("v.autopayMethod", zuoraAcct.paymentMethod.AchAccountNumberMask);
                    }
                }
            } else {
                component.set("v.errorMessage", 'An error has occurred. BlueWave has been notified. Please check back later');
                component.set("v.showError", true);
            }
        });
        $A.enqueueAction(actionGetBalance);
    },

    openPaymentWindow : function(component, event, helper) {
        component.set("v.showZuoraPaymentCmp", true);
        component.set("v.makePaymentOrManageAutopay", true);
    },

    openAutopayWindow : function(component, event, helper) {
        component.set("v.showZuoraPaymentCmp", true);
        component.set("v.makePaymentOrManageAutopay", false);
    }
})