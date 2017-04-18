({
    doInit : function(component, event, helper) {


    },  
    
openEmailCustomerModal: function(component, event, helper) {
        var actionPartnerRecord = component.get("c.getPartnerRecord");        
        actionPartnerRecord.setCallback(this,function(resp){
            if (resp.getState() == 'SUCCESS') {
                component.set("v.partnerRecord", resp.getReturnValue());
                if (resp.getReturnValue().State__c == 'MA') {
                    component.set("v.productProgram","mslp");                                        
                    $A.util.removeClass(component.find("bwslEmailInput"), 'slds-active'); 
                    $A.util.addClass(component.find("mslpEmailInput"), 'slds-tabs--scoped__nav');    
                    $A.util.addClass(component.find("customerEmailButton"), 'slds-float--right');
                    $A.util.addClass(component.find('mslpEmailInput'), 'nimbusBackground'); 
                    $A.util.removeClass(component.find('bwslEmailInput'), 'nimbusBackground');
                } else {
                    $A.util.addClass(component.find("bwslEmailInput"), 'slds-tabs--scoped__nav'); 
                    $A.util.removeClass(component.find('mslpEmailInput'), 'nimbusBackground'); 
                    $A.util.addClass(component.find('bwslEmailInput'), 'nimbusBackground');      
                    component.set("v.productProgram","bwsl");                                        
                }
            } else {
                var appEvent = $A.get("e.c:ApexCallbackError");
                appEvent.setParams({"className" : "SLPSendApplicationEmailController",
                    "methodName" : "openEmailCustomerModal",
                    "errors" : resp.getError()});
                appEvent.fire();
            }
        });    
        $A.enqueueAction(actionPartnerRecord);    
        var modalToggle = event.getParam("openModal");    
        if (modalToggle == "openModal") {        
            var modal = component.find('emailCustomerModal');
            $A.util.removeClass(component.find("emailCustomerModal"), "animated bounceOutRight");
            $A.util.removeClass(component.find("emailCustomerModal"), "animated bounceOutRight");                                    
            $A.util.removeClass(modal, 'slds-fade-in-hide');
            $A.util.addClass(modal, 'slds-fade-in-open');     
        }           
},   

closeEmailCustomerModal: function(component, event, helper) {
    var emailButton = component.find('sendEmailButton');
    var customerEmailMSLP = component.find('emailMSLP');
    var customerEmailBWSL = component.find('emailBWSL');

    var modal = component.find('emailCustomerModal');
    $A.util.removeClass(modal, 'slds-fade-in-open');
    $A.util.addClass(modal, 'slds-fade-in-hide');  
    $A.util.removeClass(component.find("emailIcon"), "animated bounceOutRight");    

    emailButton.set("v.disabled",false);
    emailButton.set("v.label","Send");
    customerEmailMSLP.set("v.value", null);
    customerEmailBWSL.set("v.value", null);    
    
    var evtCustomerWindow = $A.get("e.c:SLPSendApplicationEmailEvent");
    evtCustomerWindow.setParams({"closeModal": "closeModal"});
    evtCustomerWindow.fire();         
},    

emailModalSelectMSLP: function(component, event, helper) {
    $A.util.addClass(component.find('sendEmailModalButtons'), 'noDisplay');    
    helper.startSpinner(component, "emailSpinner");
    $A.util.removeClass(component.find('bwslEmailInput'), 'slds-tabs--scoped__nav');
    $A.util.addClass(component.find('mslpEmailInput'), 'slds-tabs--scoped__nav');
    $A.util.addClass(component.find('mslpEmailInput'), 'nimbusBackground'); 
    $A.util.removeClass(component.find('bwslEmailInput'), 'nimbusBackground');    
    
    component.set("v.productProgram","mslp");          
    helper.stopSpinner(component, "emailSpinner");
    $A.util.removeClass(component.find('sendEmailModalButtons'), 'noDisplay');
},             

emailModalSelectBWSL: function(component, event, helper) {
    $A.util.addClass(component.find('sendEmailModalButtons'), 'noDisplay');    
    helper.startSpinner(component, "emailSpinner");    
    $A.util.addClass(component.find('bwslEmailInput'), 'slds-tabs--scoped__nav');
    $A.util.removeClass(component.find('mslpEmailInput'), 'slds-tabs--scoped__nav'); 
    $A.util.addClass(component.find('bwslEmailInput'), 'nimbusBackground');  
    $A.util.removeClass(component.find('mslpEmailInput'), 'nimbusBackground');    
    
    
    component.set("v.productProgram","bwsl");     
    helper.stopSpinner(component, "emailSpinner");
    $A.util.removeClass(component.find('sendEmailModalButtons'), 'noDisplay');                                                      
},                    

sendCustomerApplication : function(component, event, helper) {
    $A.util.addClass(component.find('sendEmailModalButtons'), 'noDisplay');
    helper.startSpinner(component, "emailSpinner");
    var productProgram = component.get("v.productProgram");
    var customerEmail = component.get("v.customerEmail");
    var actionSendApp = component.get("c.sendApplication");    

    actionSendApp.setParams({customerEmail : customerEmail,
      productProgram : productProgram});  

    actionSendApp.setCallback(this,function(resp){ 
        if (resp.getState() == 'SUCCESS') {
            helper.stopSpinner(component, "emailSpinner");
            $A.util.removeClass(component.find('sendEmailModalButtons'), 'noDisplay');
            var btn = event.getSource();
            btn.set("v.disabled",true);
            btn.set("v.label",'Email Sent!') 
            // $A.util.addClass(component.find("emailIcon"), "animated bounceOutRight");
            $A.util.addClass(component.find("emailCustomerModal"), "animated bounceOutRight");
            var emailButton = component.find('sendEmailButton');
            var customerEmailMSLP = component.find('emailMSLP');
            var customerEmailBWSL = component.find('emailBWSL');

            emailButton.set("v.disabled",false);
            emailButton.set("v.label","Send");
            customerEmailMSLP.set("v.value", null);
            customerEmailBWSL.set("v.value", null);    
            
            var evtCustomerWindow = $A.get("e.c:SLPSendApplicationEmailEvent");
            evtCustomerWindow.setParams({"closeModal": "closeModal"});
            evtCustomerWindow.fire();                 

            
        } else {
            var appEvent = $A.get("e.c:ApexCallbackError");
            appEvent.setParams({"className" : "SLPAddCustomerController",
                "methodName" : "sendCustomerApplication",
                "errors" : resp.getError()});
            appEvent.fire();
            $A.log("Errors", resp.getError());                      
        }
    });                                                   
    $A.enqueueAction(actionSendApp);               
},   
})