({
	doInit : function(component, event, helper) {
		var totalCostandDisbrsals = component.get("c.getTotalCostandDisbrsals");        
        totalCostandDisbrsals.setCallback(this,function(resp){
            if(resp.getState() == 'SUCCESS') {
                component.set("v.totalCostandDisbrsals", resp.getReturnValue());
            }
            else {
                $A.log("Errors", resp.getError());
            }
        });    
        $A.enqueueAction(totalCostandDisbrsals); 
        
        var actionAlerts = component.get("c.getPartnerAlerts");        
        actionAlerts.setCallback(this,function(resp){
            if(resp.getState() == 'SUCCESS') {
                var alertTheme = component.find("partnerAlertTheme");                   
                if(resp.getReturnValue().length > 0){
                    component.set("v.partnerAlerts", resp.getReturnValue());
                    component.set("v.alertPrompt", true);
                    //the code below is to change the color of the header on the alerts pop-up
                    // if(resp.getReturnValue()[0].Importance__c == 'Urgent') {
                    //     $A.util.addClass(alertTheme, 'slds-theme--error');  
                    //     $A.util.removeClass(alertTheme, 'slds-theme--success'); 
                    //     $A.util.removeClass(alertTheme, 'slds-theme--warning');           
                    // }else if (resp.getReturnValue()[0].Importance__c == 'Important') {
                    //     $A.util.addClass(alertTheme, 'slds-theme--warning');  
                    //     $A.util.removeClass(alertTheme, 'slds-theme--success'); 
                    //     $A.util.removeClass(alertTheme, 'slds-theme--error');                     
                    // }else if (resp.getReturnValue()[0].Importance__c == 'Normal'){
                    //     $A.util.addClass(alertTheme, 'slds-theme--success');  
                    //     $A.util.removeClass(alertTheme, 'slds-theme--warning'); 
                    //     $A.util.removeClass(alertTheme, 'slds-theme--error');     
                    // }
                }
            }    
            else {
                $A.log("Errors", resp.getError());
            }
        });    
        $A.enqueueAction(actionAlerts);                    
        
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