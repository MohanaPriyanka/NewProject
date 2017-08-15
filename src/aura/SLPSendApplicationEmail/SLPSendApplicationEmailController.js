({
doInit: function(component, event, helper) {
   
},    

openEmailCustomerModal: function(component, event, helper) {
    var actionGetPartnerRecord = component.get("c.getPartnerRecord");        
    actionGetPartnerRecord.setCallback(this,function(resp){
        if (resp.getState() == 'SUCCESS') {
            component.set("v.partnerRecord", resp.getReturnValue());
            if (resp.getReturnValue().State__c === 'MA') {
                if (resp.getReturnValue().Default_Application__c != 'Massachusetts Solar Loan Program') {
                    helper.setWindowToBWSL(component);
                } else {
                    helper.setWindowToMSLP(component);
                }                    
            } else {
                helper.setWindowToBWSL(component);                                 
            }
        } else {
            helper.logError("SLPSendApplicationEmailController", "openEmailCustomerModal", resp.getError());
        }
    });    
    $A.enqueueAction(actionGetPartnerRecord);    
    var modalToggle = event.getParam("openModal");    
    if (modalToggle == "openModal") {                                        
        $A.util.removeClass(component.find('emailCustomerModal'), 'slds-fade-in-hide');
        $A.util.addClass(component.find('emailCustomerModal'), 'slds-fade-in-open');     
    }           
},   

closeEmailCustomerModal: function(component, event, helper) {
    var partnerRecord = component.get("v.partnerRecord");
    var emailButton = component.find('sendEmailButton');
    if (partnerRecord.State__c == "MA") {
        component.find('emailMSLP').set("v.value", null);        
    }
    component.find('emailBWSL').set("v.value", null);

    var modal = component.find('emailCustomerModal');
    $A.util.removeClass(modal, 'slds-fade-in-open');
    $A.util.addClass(modal, 'slds-fade-in-hide');  

    emailButton.set("v.disabled",false);
    emailButton.set("v.label","Send");
     
    var evtCustomerWindow = $A.get("e.c:SLPSendApplicationEmailEvent");
    evtCustomerWindow.setParams({"closeModal": "closeModal"});
    evtCustomerWindow.fire();         
},    

emailModalSelectMSLP: function(component, event, helper) {
    helper.setWindowToMSLP(component);
},             

emailModalSelectBWSL: function(component, event, helper) {
    helper.setWindowToBWSL(component);                                       
},                    

sendCustomerApplication : function(component, event, helper) {
    var partnerRecord = component.get("v.partnerRecord");    
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
            helper.disableButton(component, 'sendEmailButton', 'Email Sent!');       
            if (partnerRecord.State__c == "MA") {
                component.find('emailMSLP').set("v.value", null);
            }
            component.find('emailBWSL').set("v.value", null);                  
        } else {
            helper.logError("SLPSendApplicationEmailEvent", "sendCustomerApplication", resp.getError());
            $A.log("Errors", resp.getError());                      
        }
    });                                                   
    $A.enqueueAction(actionSendApp);               
},   
})