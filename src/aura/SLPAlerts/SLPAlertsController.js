({
    doInit : function(component, event, helper) {
        var action = component.get("c.getPartnerAlerts");        
        action.setCallback(this,function(resp){ 
            if(resp.getState() == 'SUCCESS') {
                component.set("v.partnerAlerts", resp.getReturnValue());
            }
            else {
                $A.log("Errors", resp.getError());
            }
        });        
        $A.enqueueAction(action);
    },

    openAlert : function(component, event, helper) {
        var alert = component.find("partnerAlert");
        $A.util.removeClass(alert, 'noDisplay');
        var source = event.getSource();
        var customerLoanId = source.get("v.class");
        var action = component.get("c.getPartnerAlert");

        action.setParams({alertId : customerLoanId});
        action.setCallback(this,function(resp){
            if(resp.getState() == 'SUCCESS') {
                component.set("v.partnerAlert", resp.getReturnValue());
            }
            else {
                $A.log("Errors", resp.getError());
            }
        });
        $A.enqueueAction(action);
    },

    closeAlert : function(component, event, helper) {
        var alert = component.find("partnerAlert");
        $A.util.addClass(alert, 'noDisplay');
        component.set("v.partnerAlert", null);
    },
})