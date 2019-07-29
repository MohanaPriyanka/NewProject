/**
 * Created by mstackhouse on 10/25/2018.
 */
({
    showOrderCreated : function(component) {
        component.set("v.Spinner", false);
        component.set("v.ResponseText",  'Your payment data has been saved. You will receive an email from BlueWave momentarily.');
    },

    insertOrders : function(component, chargentFields, helper, event){
        return new Promise(function(resolve, reject) {
            var chOrder = component.get('v.chOrder');
            var lead = component.get('v.lead');

            var actionSubmit = component.get("c.insertChargentOrderOnLead");

            actionSubmit.setParams({
                "newOrder": chOrder,
                "lead": lead
            });

            component.set("v.loading", true);
            component.set("v.loadingText", "Saving payment info...");
            actionSubmit.setCallback(this,function(resp){
                if (resp.getState() === 'SUCCESS') {
                    helper.finishStage(component, event, helper);
                    // this should reset the payment info
                    component.set("v.SelectedPaymentMethod", "");
                    component.set("v.AutopayAcknowledgement", false);
                } else {
                    this.showError(component, 'Oops!', 'Error occurred on our end, Please try again');
                }
            });
            $A.enqueueAction(actionSubmit);
        });
    },

    storePaymentTerms : function(component, event, helper) {
        var lead = component.get('v.lead');
        var paymentTerms;
        if (component.get("v.paymentProvider") === 'Zuora') {
            paymentTerms = component.get('v.zuoraPaymentTerms');
        } else {
            paymentTerms = component.get('v.paymentTerms');
        }
        var termsType = 'Payment Terms';


        var action = component.get("c.saveTerms");
        action.setParams({
            "terms" : paymentTerms,
            "lead" : lead,
            "termsType" : termsType
        });
        action.setCallback(this, function(resp){
            if (resp.getState() !== "SUCCESS") {
                this.logError("CSAPPaymentInfo", "storePaymentTerms", resp.getError(), 'No task created to store Payment Consent for Lead: ' + lead.Id);
            }
        });
        $A.enqueueAction(action);
    },

    showError : function(component, header, message) {
        component.find('notifLib').showNotice({
            "variant": "error",
            "header": header,
            "message": message
        });
    }
})