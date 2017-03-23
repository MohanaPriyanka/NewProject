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

        var actionDashboardWidgets = component.get("c.getDashboardWidgets");        
        actionDashboardWidgets.setCallback(this,function(resp){
            if(resp.getState() == 'SUCCESS') {
                var widgets = resp.getReturnValue();
                component.set("v.widgets", resp.getReturnValue());
            }
            else {
                $A.log("Errors", resp.getError());
            }
        });    
        $A.enqueueAction(actionDashboardWidgets);          

        //The following block of code retrieves the user's license type to determine what to display on the UI
        var actionLicenseType = component.get("c.getLicenseType");        
        actionLicenseType.setCallback(this,function(resp){
            if(resp.getState() == 'SUCCESS') {
                if(resp.getReturnValue().length > 0){
                    if(resp.getReturnValue() == 'Executive')
                    component.set("v.licenseType", true);
                }
            }    
            else {
                $A.log("Errors", resp.getError());
            }
        });    
        $A.enqueueAction(actionLicenseType);                         
        
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
    
    removeDisplay : function(component, event, helper) {
    	var widgetsToggle = component.find("disbursalWidgets");
        var partnerLogo = component.find("partnerLogo");	
        $A.util.addClass(widgetsToggle, 'noDisplayBar');
        $A.util.addClass(partnerLogo, 'noDisplayBar');
	},    
    
    showDisplay : function(component, event, helper) {
    	var widgetsToggle = component.find("disbursalWidgets");
        var partnerLogo = component.find("partnerLogo");	
        $A.util.removeClass(widgetsToggle, 'noDisplayBar');
        $A.util.removeClass(partnerLogo, 'noDisplayBar');
	},    
})