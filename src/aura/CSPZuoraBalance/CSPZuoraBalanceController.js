({  doInit : function(component, event, helper) {
        var actionGetBalance = component.get("c.getAccountAndPayMethodFromZuora");

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

                if (zuoraAcct.numberOfGateways > 1) {
                    helper.getOutstandingItems(component, helper, zuoraAcct.account.Id);
                }
            } else {
                var errorMsg = 'An error has occurred. ' + $A.get("$Label.c.Company_Name") + ' has been notified. Please check back later';
                component.set("v.errorMessage", errorMsg);
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