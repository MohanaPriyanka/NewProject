({
	doInit : function(component, event, helper) {
        var actionAlerts = component.get("c.getPartnerAlerts");        
        actionAlerts.setCallback(this,function(resp){
            if(resp.getState() == 'SUCCESS') {
                if(resp.getReturnValue().length > 0){
                    component.set("v.partnerAlerts", resp.getReturnValue());
                    component.set("v.alertPrompt", true);
                }
            }    
            else {
                $A.log("Errors", resp.getError());
            }
        });    
        $A.enqueueAction(actionAlerts); 
        		
        var evtHideHeader = $A.get("e.c:SLPLandingPageEvent");
        evtHideHeader.setParams({"dashboardDisplay": "true"});
        evtHideHeader.fire(); 		
	}, 

    acknowledgeAlert : function(component, event, helper) { 
        var partnerAlertId = component.get("v.partnerAlerts[0].Id");
        var actionAcknowledgeAlert = component.get("c.acknowledgePartnerAlert");
        
        actionAcknowledgeAlert.setParams({partnerAlertId : partnerAlertId});
        actionAcknowledgeAlert.setCallback(this,function(resp){
            if(resp.getState() == 'SUCCESS') {
                var alert = component.find("partnerAlert");    
                $A.util.addClass(alert, 'noDisplay');            }
            else {
                $A.log("Errors", resp.getError());
            }
        });            
        $A.enqueueAction(actionAcknowledgeAlert); 

        $A.get('e.force:refreshView').fire();          
    },     

    closeAlert : function(component, event, helper) {

        var partnerAlertId = component.get("v.partnerAlerts[0].Id");
        var actionRemindLater = component.get("c.partnerAlertRemindLater");
        
        actionRemindLater.setParams({partnerAlertId : partnerAlertId});
        actionRemindLater.setCallback(this,function(resp){
            if(resp.getState() == 'SUCCESS') {
                var alert = component.find("partnerAlert");    
                $A.util.addClass(alert, 'noDisplay');            }
            else {
                $A.log("Errors", resp.getError());
            }
        });            
        $A.enqueueAction(actionRemindLater); 


        var alert = component.find("partnerAlert");    
        $A.util.addClass(alert, 'noDisplay');   
        $A.get('e.force:refreshView').fire();          
    },   	
})