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
        var allCustomers = component.find("alertCard");   
        $A.util.removeClass(allCustomers, 'noDisplayBar');
        
        var source = event.getSource();
        var customerLoanId = source.get("v.class");
        var action = component.get("c.getPartnerAlert");

        action.setParams({parnterId : customerLoanId});
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

})