({ 
    doInit : function(component, event, helper) {
        var actionPartnerRecord = component.get("c.getPartnerRecord");        
        actionPartnerRecord.setCallback(this,function(resp){
            if (resp.getState() == 'SUCCESS') {
                component.set("v.partnerRecord", resp.getReturnValue());
                if (resp.getReturnValue().State__c == 'MA') {
                    component.set("v.newLead.DOER_Solar_Loan__c",true);                                       
                    $A.util.addClass(component.find("customerEmailButton"), 'slds-float--right');  
                    if (resp.getReturnValue().Default_Application__c != 'Massachusetts Solar Loan Program') {
                        component.set("v.newLead.DOER_Solar_Loan__c",false);  
                        component.set("v.newLead.Product_Program__c",'BlueWave Solar Loan');    
                        helper.showBWSLApplication(component); 
                    } else {
                        helper.showMSLPApplication(component);          
                    }
                }                
            } else {
                helper.logError("SLPAddCustomerController", "doInIt", resp.getERror());
            }
        });    
        $A.enqueueAction(actionPartnerRecord);

        var actionGetTimeout = component.get("c.getCreditCheckTimeout");
        actionGetTimeout.setCallback(this,function(resp) {
            if(resp.getState() == 'SUCCESS') {
                component.set("v.creditStatusTimeout", resp.getReturnValue());
            } else {
                component.set("v.creditStatusTimeout", 60000);
            }
        });
        $A.enqueueAction(actionGetTimeout);
    },        

    addCustomer : function(component, event, helper) {
        var lead = component.get("v.newLead");
        var errors = helper.errorsInForm(component, helper, lead);
        if (errors != null) {
            helper.logError("SLPAddCustomerController", "addCustomer", errors);
            return;
        }

        $A.util.addClass(component.find("SubmitButton"), 'noDisplay'); 
        helper.startSpinner(component, "leadSpinner");
        
        lead.LASERCA__SSN__c = lead.LASERCA__SSN__c.replace(/-/g,"");
        var Action = component.get("c.addNewLeadRecord");
        Action.setParams({"newLead" : lead});
        
        Action.setCallback(this, function(resp) {
            if (resp.getState() == "SUCCESS") {
                component.set("v.newLead", resp.getReturnValue());
                component.get("v.newLead").LASERCA__Birthdate__c = component.get("v.newLead").LASERCA__Birthdate__c.replace(/T00:00:00.000Z/,"");
                helper.removeAddCustomerForm(component);
                helper.removeErrorAnimations(component, "shake");
                helper.showCreditCheckPage(component);
            } else {
                helper.stopSpinner(component, "leadSpinner");
                $A.util.removeClass(component.find("SubmitButton"), 'noDisplay'); 
                helper.logError("SLPAddCustomerController", "addCustomer", "We've encountered an issue while trying to add this applicant. Please verify that all of the applicant's information has been entered in correctly and try again. If the issue persists, please call (888) 817-2703 for support");
            }
        }); 
        $A.enqueueAction(Action);        
    },
    
    checkCredit : function(component, event, helper) {
        $A.util.addClass(component.find("pullCreditButtons"), 'noDisplay');  
        helper.startSpinner(component, 'creditSpinner');
        var lead = component.get("v.newLead");
        lead.LASERCA__Birthdate__c = lead.LASERCA__Birthdate__c.replace(/T00:00:00.000Z/,"");
        if (!$A.util.isUndefinedOrNull(lead.Id)) {
            var self = this;
            var action = component.get("c.pullCreditStatus");
            action.setParams({"lead" : lead});
            action.setCallback(this, function(resp) {
                    if(resp.getState() == "SUCCESS") {
                        window.setTimeout(function() {
                                $A.util.removeClass(component.find("creditStatus"), 'noDisplay');
                                component.set("v.creditStatusText", "Sending request to TransUnion");
                            }, 3000);
                        window.setTimeout(function() {
                                component.set("v.creditStatusText", "Waiting for TransUnion to process...");
                            }, 6000);
                        window.setTimeout(function() {
                                component.set("v.creditStatusText", "Checking for results...");
                            }, 9000);
                        window.setTimeout(function() {
                                var creditPollerInterval = window.setInterval($A.getCallback(helper.checkCreditStatus), 2000, component, helper);
                                component.set("v.creditStatusPoller", creditPollerInterval);
                            }, 10000);

                        // checkCreditStatus should clearInterval if it finds a Credit Report Log or
                        // a Credit Report on the Lead, but just in case, stop checking after a minute
                        window.setTimeout(function() {
                                component.set("v.creditStatusText", 
                                              "Credit request timed out, please check the Pending Customers tab above");
                                helper.stopSpinner(component, 'creditSpinner');
                                window.clearInterval(component.get("v.creditStatusPoller"));
                            }, component.get("v.creditStatusTimeout"));
                    } else {
                        helper.stopSpinner(component, 'creditSpinner');
                        $A.util.removeClass(component.find("SubmitButton"), 'noDisplay'); 

                        helper.logError("SLPAddCustomerController", "checkCredit",   "There was an issue running credit on this applicant. The error has been logged and you'll need to start the application over again. We apologize for this inconvenience. Please make sure you enter social security number correctly and leave out any sort of special characters in the applicant's name");    
                        $A.log("Errors", "There was an issue running credit on this applicant. The error has been logged and you'll need to start the application over again. We apologize for this inconvenience. Please make sure you enter social security number correctly and leave out any sort of special characters in the applicant's name");        
                        $A.util.addClass(component.find("pullCreditButtons"), 'noDisplay');         
                        $A.util.removeClass(component.find("addAnotherCustomerButton"), 'noDisplay'); 
                        component.set("v.newLead", lead);
                    }
                });
            $A.enqueueAction(action);
        } else {
            helper.logError("SLPAddCustomerController", "checkCredit", "No Customer (Lead) ID was found when checking credit: " + lead);            
        }
    },

    navigateAddAnotherCustomer : function(component, event, helper) {
        var urlEvent = $A.get("e.force:navigateToURL");
        urlEvent.setParams({
          "url": '/slpaddcustomer'

        });
        urlEvent.fire();                
    },

    navigateCreditStatus : function(component, event, helper) {
        var urlEvent = $A.get("e.force:navigateToURL");
        urlEvent.setParams({
          "url": '/slpcreditstatus?leadId=' + component.get("v.newLead.Id")
        });
        urlEvent.fire();                
    }, 

    navigateToMSLP : function(component, event, helper) {

        var urlEvent = $A.get("e.force:navigateToURL");
        urlEvent.setParams({
          "url": 'https://forms.bluewaverenewables.com/381458?'

        });
        urlEvent.fire();                
    },       

    changeApplicationToMSLP : function(component, event, helper) {
        component.set("v.newLead.DOER_Solar_Loan__c",true);  
        component.set("v.newLead.Product_Program__c",'MSLP');                
        helper.showMSLPApplication(component);                    
    }, 
    changeApplicationToBWSL : function(component, event, helper) {
        component.set("v.newLead.DOER_Solar_Loan__c",false);  
        component.set("v.newLead.Product_Program__c",'BlueWave Solar Loan');      
        helper.showBWSLApplication(component);     
    },         

    openEmailCustomerModal : function(component, event, helper) {
        var modalBackground = component.find('emailCustomerModalBackground');
        $A.util.removeClass(modalBackground, 'slds-backdrop--hide');
        $A.util.addClass(modalBackground, 'slds-backdrop--open');     
        var evtCustomerWindow = $A.get("e.c:SLPSendApplicationEmailEvent");
        evtCustomerWindow.setParams({"openModal": "openModal"});
        evtCustomerWindow.fire();                
    },   

    closeEmailCustomerModal: function(component, event, helper) {
        var modalToggle = event.getParam("closeModal");    
        if (modalToggle == "closeModal") {
            var modalBackground = component.find('emailCustomerModalBackground');
            $A.util.removeClass(modalBackground, 'slds-backdrop--open');
            $A.util.addClass(modalBackground, 'slds-backdrop--hide');    
        }
    },    

    emailModalSelectMSLP: function(component, event, helper) {
        $A.util.removeClass(component.find('bwslEmailInput'), 'slds-tabs--scoped__nav');
        $A.util.addClass(component.find('mslpEmailInput'), 'slds-tabs--scoped__nav');
        component.set("v.productProgram","mslp");                                        
    },             

    emailModalSelectBWSL: function(component, event, helper) {
        $A.util.addClass(component.find('bwslEmailInput'), 'slds-tabs--scoped__nav');
        $A.util.removeClass(component.find('mslpEmailInput'), 'slds-tabs--scoped__nav'); 
        component.set("v.productProgram","bwsl");                                                       
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
            } else {
                helper.logError("SLPAddCustomerController", "sendCustomerApplication", resp.getERror());
                $A.log("Errors", resp.getError());                      
            }
        });                                                   
        $A.enqueueAction(actionSendApp);               
    }, 
    
    returnToEdit : function(component, event, helper) {
        helper.returnAddCustomerForm(component);
        helper.hideCreditCheckPage(component);
        helper.stopSpinner(component, "leadSpinner");
        $A.util.removeClass(component.find("EditButton"), 'noDisplay'); 
    },   
    
    updateCustomer : function(component, event, helper) {
        var actionUpdate = component.get("c.updateLeadRecord");
        var leadToUpdate = component.get("v.newLead");
        var errors = helper.errorsInForm(component, helper, leadToUpdate);
        if (errors != null) {
            helper.logError("SLPAddCustomerController", "updateLeadRecord", errors);
            return;
        }
        
        $A.util.addClass(component.find("EditButton"), 'noDisplay'); 
        helper.startSpinner(component, "leadSpinner");
        
        leadToUpdate.LASERCA__SSN__c = leadToUpdate.LASERCA__SSN__c.replace(/-/g,"");
        
		actionUpdate.setParams({"updatedLead" : leadToUpdate});
        
        actionUpdate.setCallback(this, function(resp) {
                    if(resp.getState() == "SUCCESS") {
                        component.set("v.newLead", resp.getReturnValue());
                        helper.removeAddCustomerForm(component);
                        helper.showCreditCheckPage(component);
                        helper.stopSpinner(component, "leadSpinner");
                    } else {
                        $A.util.removeClass(component.find("EditButton"), 'noDisplay'); 
                        helper.stopSpinner(component, "leadSpinner");

                        var appEvent = $A.get("e.c:ApexCallbackError");
                        appEvent.setParams({"className" : "SLPAddCustomerController",
                                            "methodName" : "updateLeadRecord",
                                            "errors" : resp.getError()});
                        appEvent.fire();
                    }
                }); 
         $A.enqueueAction(actionUpdate);
    },
    
    openAddCoApplicant : function(component, event, helper) {    
       var ldRecord = component.get("v.newLead.Id");
        
       $A.createComponent(
		  "c:SLPAddCoApplicant", 
          {"leadId": ldRecord}, 
           
       function(newButton, status, errorMessage){
          if (status === "SUCCESS") {
 		       var body = component.get("v.body");
               body.push(newButton);
               component.set("v.body", body);
          }
          else if (status === "INCOMPLETE") {
               console.log("No response from server or client is offline.")
          }
          else if (status === "ERROR") {
               console.log("Error: " + errorMessage);
          }
          }
          );               
    },
})