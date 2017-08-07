({
    doInit : function(component, event, helper) {    
        var leadVar = component.get("v.mainApplicant.Id");
        var actionCheckForCoApps = component.get("c.checkForCoApps");

        actionCheckForCoApps.setParams({
            "leadId" : leadVar,
        });
        
        actionCheckForCoApps.setCallback(this,function(response) {
            if(response.getState() === "SUCCESS") { 
                console.log(response.getReturnValue());
                if(response.getReturnValue() === "hasCoApp") {
                    helper.showWarning(component, "alreadyHasCoApp");
                } else if (response.getReturnValue() === "sentEmail") {
                    helper.showWarning(component, "alreadySentEmail");
                } else if (response.getReturnValue() ==="clear") { 
                    // clear doesn't need to trigger any messages, but we need to differentiate clear from an error ie. null
                } 
             } else { 
                helper.logError("SLPAddCoApplicant", "checkForCoApps", resp.getError());
             }
         }); 
                                 
         $A.enqueueAction(actionCheckForCoApps);
    },
    
    sendLinktoCoAppForm : function(component, event, helper) {            
       var actionSendLink = component.get("c.sendCoAppEmail");
       var coApp = component.get("v.coAppInfo"); 
       var mainApp = component.get("v.mainApplicant"); 
        
        actionSendLink.setParams({
            "coAppInfo" : coApp, 
            "mainApplicant" : mainApp,
        });
        
        actionSendLink.setCallback(this,function(response) {
            if(response.getState() === "SUCCESS") { 
                if (response.getReturnValue() === "success") {
                    helper.emailSuccess(component);
                } else {
                    $A.util.removeClass(component.find("emailErrorText"), 'noDisplay'); 
                }
            } else { 
                helper.logError("SLPAddCoApplicant", "sendCoAppEmail", resp.getError());
            }
         });                           
         $A.enqueueAction(actionSendLink);          
    },
    
    continueAnyway : function(component, event, helper) {    
        helper.continueAnyway(component);
    },
    
    closeWindow : function(component, event, helper) {
        helper.closeWindow(component);  
    },
    
    enterInfoNow : function(component, event, helper) {            
        helper.enterInfoNow(component);
    },
    
    backButton : function(component, event, helper) {            
        helper.backButton(component);
    },
    
})