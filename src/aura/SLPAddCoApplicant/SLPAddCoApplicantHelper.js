({
    showWarning : function(component, fieldName) {
        $A.util.addClass(component.find("formBody"), 'noDisplay');  
        $A.util.addClass(component.find("buttonLink"), 'noDisplay'); 
        $A.util.addClass(component.find("buttonEmail"), 'noDisplay'); 
        $A.util.removeClass(component.find("continueButton"), 'noDisplay');  
        $A.util.removeClass(component.find(fieldName), 'noDisplay'); 
    },
    
    continueAnyway : function(component) {   
        $A.util.removeClass(component.find("formBody"), 'noDisplay');  
        $A.util.removeClass(component.find("buttonLink"), 'noDisplay'); 
        $A.util.removeClass(component.find("buttonEmail"), 'noDisplay'); 
        $A.util.addClass(component.find("continueButton"), 'noDisplay');  
        $A.util.addClass(component.find("alreadyHasCoApp"), 'noDisplay'); 
        $A.util.addClass(component.find("alreadySentEmail"), 'noDisplay'); 
    },
    
    closeWindow : function(component) {
        $A.util.removeClass(component.find("greyout"), 'slds-backdrop_open'); 
        $A.util.addClass(component.find("greyout"), 'slds-backdrop_hide');  
        $A.util.removeClass(component.find("smallWindow"), 'slds-fade-in-open'); 
        $A.util.addClass(component.find("smallWindow"), 'slds-fade-in-hide');  
    },
    
    emailSuccess : function (component) {
        $A.util.addClass(component.find("formBody"), 'noDisplay');  
        $A.util.addClass(component.find("buttonLink"), 'noDisplay');  
        $A.util.addClass(component.find("buttonEmail"), 'noDisplay'); 
        $A.util.removeClass(component.find("emailSentText"), 'noDisplay');
        $A.util.addClass(component.find("emailErrorText"), 'noDisplay'); 
        $A.util.removeClass(component.find("doneRedirect"), 'noDisplay');
        $A.util.addClass(component.find("closeButton"), 'noDisplay');
    },
    
    enterInfoNow : function(component, helper) {            
        $A.util.addClass(component.find("windowFooter"), 'noDisplay'); 
        $A.util.addClass(component.find("formBody"), 'noDisplay'); 
        $A.util.addClass(component.find("emailErrorText"), 'noDisplay'); 
        $A.util.removeClass(component.find("backButton"), 'noDisplay'); 
        component.set("v.enterNow", "TRUE");
    },
    
    backButton : function(component, helper) {            
        $A.util.removeClass(component.find("windowFooter"), 'noDisplay'); 
        $A.util.removeClass(component.find("formBody"), 'noDisplay'); 
        $A.util.addClass(component.find("backButton"), 'noDisplay'); 
        component.set("v.enterNow", "");
    },
    
})