({
	doInit : function(component, event, helper) {
        
        // var actionAlerts = component.get("c.getPartnerAlerts");        
        // actionAlerts.setCallback(this,function(resp){
        //     if(resp.getState() == 'SUCCESS') {
        //         var alertTheme = component.find("partnerAlertTheme");                   
        //         if(resp.getReturnValue().length > 0){
        //             component.set("v.partnerAlerts", resp.getReturnValue());
        //             component.set("v.alertPrompt", true);
        //         }
        //     }    
        //     else {
        //         $A.log("Errors", resp.getError());
        //     }
        // });    
        // $A.enqueueAction(actionAlerts);   
        
        var actionLogo = component.get("c.getPartnerLogo");        
        actionLogo.setCallback(this,function(resp){
            if(resp.getState() == 'SUCCESS') {
                component.set("v.partnerLogo", resp.getReturnValue());
            }
            else {
                $A.log("Errors", resp.getError());
            }
        });    
        $A.enqueueAction(actionLogo);
    }

        
	},

    // acknowledgeAlert : function(component, event, helper) { 
    //     var partnerAlertId = component.get("v.partnerAlerts[0].Id");
    //     var actionAcknowledgeAlert = component.get("c.acknowledgePartnerAlert");
        
    //     actionAcknowledgeAlert.setParams({partnerAlertId : partnerAlertId});
    //     actionAcknowledgeAlert.setCallback(this,function(resp){
    //         if(resp.getState() == 'SUCCESS') {
    //             var alert = component.find("partnerAlert");    
    //             $A.util.addClass(alert, 'noDisplay');            }
    //         else {
    //             $A.log("Errors", resp.getError());
    //         }
    //     });            
    //     $A.enqueueAction(actionAcknowledgeAlert); 

    //     $A.get('e.force:refreshView').fire();          
    // },     

    // closeAlert : function(component, event, helper) {

    //     var partnerAlertId = component.get("v.partnerAlerts[0].Id");
    //     var actionRemindLater = component.get("c.partnerAlertRemindLater");
        
    //     actionRemindLater.setParams({partnerAlertId : partnerAlertId});
    //     actionRemindLater.setCallback(this,function(resp){
    //         if(resp.getState() == 'SUCCESS') {
    //             var alert = component.find("partnerAlert");    
    //             $A.util.addClass(alert, 'noDisplay');            }
    //         else {
    //             $A.log("Errors", resp.getError());
    //         }
    //     });            
    //     $A.enqueueAction(actionRemindLater); 


    //     var alert = component.find("partnerAlert");    
    //     $A.util.addClass(alert, 'noDisplay');   
    //     $A.get('e.force:refreshView').fire();          
    // },         
    
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