({
    openEmailCustomerModal: function(component, event, helper) {
        var action = component.get("c.getPartnerRecord");        
        action.setCallback(this,function(resp){
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
        $A.enqueueAction(action);    

        var modalToggle = event.getParam("openModal");    
        if (modalToggle == "openModal") {                                        
            helper.openModal(component);   
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

    changeProductProgram: function(component, event, helper) {
        var newLead = component.get("v.newLead");
        if (newLead.Product_Program__c === "BlueWave Solar Loan") {
            helper.setWindowToMSLP(component);
        } else if (newLead.Product_Program__c === "MSLP") {
            helper.setWindowToBWSL(component);
        }
    },                                

    createLeadAndSendApplication : function(component, event, helper) {  
        var newLead = component.get("v.newLead");
        //check for errors in the form's inputs      
        var errors = helper.errorsInForm(component, helper, newLead);
        if (errors == null) {
            helper.removeButtonsAndShowSpinner(component, event, helper);  
            helper.emailApplication(component, event, helper, newLead);
        } else {
            helper.logError("SLPSendApplicationEmailController", "createLeadAndSendApplication", errors);
            return;
        }          

        var actionCreateLead = component.get("c.addNewLeadRecord");   
        actionCreateLead.setParams({newLead : newLead});  
        actionCreateLead.setCallback(this,function(resp){ 
            if (resp.getState() == 'SUCCESS') {  

            } else {

            }
        });                                                   
        $A.enqueueAction(actionCreateLead);             
    },            
})