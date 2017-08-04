({
    doInit : function(component, event, helper) {	 
        var leadRefId = component.get("v.leadId");
        var actionCheckForCoApps = component.get("c.checkForCoApps");
        
        actionCheckForCoApps.setParams({
            "leadId" : leadRefId,
        });
        
        actionCheckForCoApps.setCallback(this,function(response) {
            if(response.getState() === "SUCCESS") { 
             	if(response.getReturnValue()=== "hasCoApp") {
        			$A.util.addClass(component.find("formBody"), 'noDisplay');  
        			$A.util.addClass(component.find("buttonLink"), 'noDisplay'); 
        			$A.util.addClass(component.find("buttonEmail"), 'noDisplay'); 
        			$A.util.removeClass(component.find("alreadyHasCoApp"), 'noDisplay'); 
        			$A.util.removeClass(component.find("continueButton"), 'noDisplay'); 
                } else if (response.getReturnValue()=== "sentEmail") {
                    $A.util.removeClass(component.find("alreadySentEmail"), 'noDisplay'); 
                    $A.util.addClass(component.find("formBody"), 'noDisplay');  
        			$A.util.addClass(component.find("buttonLink"), 'noDisplay'); 
        			$A.util.addClass(component.find("buttonEmail"), 'noDisplay'); 
        			$A.util.removeClass(component.find("continueButton"), 'noDisplay'); 
                } else if (response.getReturnValue()==="clear") { 
                    // clear doesn't need to trigger any messages, but we need to differentiate clear from an error ie. null
                } else { 
                    var appEvent = $A.get("e.c:ApexCallbackError");
                	appEvent.setParams({"className" : "SLPAddCoApplicant",
                    					"methodName" : "checkForCoApps",
                    					"errors" : resp.getError()});
                	appEvent.fire();
                }
             } else { 
                var appEvent = $A.get("e.c:ApexCallbackError");
                appEvent.setParams({"className" : "SLPAddCoApplicant",
                    				"methodName" : "checkForCoApps",
                    				"errors" : resp.getError()});
                appEvent.fire();
             }
         }); 
                                 
         $A.enqueueAction(actionCheckForCoApps);
    },
    
    continueAnyway : function(component, event, helper) {	 
        $A.util.removeClass(component.find("formBody"), 'noDisplay');  
        $A.util.removeClass(component.find("buttonLink"), 'noDisplay'); 
        $A.util.removeClass(component.find("buttonEmail"), 'noDisplay'); 
        $A.util.addClass(component.find("alreadyHasCoApp"), 'noDisplay'); 
        $A.util.addClass(component.find("alreadySentEmail"), 'noDisplay'); 
        $A.util.addClass(component.find("continueButton"), 'noDisplay');  
    },
    
    closeWindow : function(component, event, helper) {
        $A.util.removeClass(component.find("greyout"), 'slds-backdrop_open'); 
        $A.util.addClass(component.find("greyout"), 'slds-backdrop_hide');  
        $A.util.removeClass(component.find("smallWindow"), 'slds-fade-in-open'); 
        $A.util.addClass(component.find("smallWindow"), 'slds-fade-in-hide');  
    },
    
    sendLinktoCoAppForm : function(component, event, helper) {            
       var actionSendLink = component.get("c.sendCoAppEmail");
       var coApp = component.get("v.coAppInfo"); 
	   var mainAppId = component.get("v.leadId"); 
        
        actionSendLink.setParams({
            "coAppInfo" : coApp, 
            "leadId" : mainAppId,
        });
        
        actionSendLink.setCallback(this,function(response) {
            if(response.getState() === "SUCCESS") { 
                if (response.getReturnValue() === "success") {
                	$A.util.addClass(component.find("formBody"), 'noDisplay');  
                	$A.util.addClass(component.find("buttonLink"), 'noDisplay');  
                	$A.util.addClass(component.find("buttonEmail"), 'noDisplay'); 
                	$A.util.removeClass(component.find("emailSentText"), 'noDisplay');
                    $A.util.addClass(component.find("emailErrorText"), 'noDisplay'); 
                } else {
                    $A.util.removeClass(component.find("emailErrorText"), 'noDisplay'); 
                }
            } else { 
                var appEvent = $A.get("e.c:ApexCallbackError");
                appEvent.setParams({"className" : "SLPAddCoApplicant",
                    				"methodName" : "sendCoAppEmail",
                    				"errors" : resp.getError()});
                appEvent.fire();
            }
         });                           
         $A.enqueueAction(actionSendLink);          
    },
    
    enterInfoNow : function(component, event, helper) {            
		$A.util.addClass(component.find("windowFooter"), 'noDisplay'); 
        $A.util.addClass(component.find("formBody"), 'noDisplay'); 
        $A.util.removeClass(component.find("backButton"), 'noDisplay'); 
        component.set("v.enterNow", "TRUE");
    },
    
    backButton : function(component, event, helper) {            
		$A.util.removeClass(component.find("windowFooter"), 'noDisplay'); 
        $A.util.removeClass(component.find("formBody"), 'noDisplay'); 
        $A.util.addClass(component.find("backButton"), 'noDisplay'); 
        component.set("v.enterNow", "");
    },
})