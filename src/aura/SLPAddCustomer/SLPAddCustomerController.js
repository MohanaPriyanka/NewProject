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
                        $A.util.addClass(component.find("bwslAppButton"), 'noDisplayBar');      
                        $A.util.removeClass(component.find("mslpAppButton"), 'noDisplayBar');
                        $A.util.addClass(component.find("avidiaLogo"), 'noDisplay');  
                        $A.util.addClass(component.find("avidiaFooter"), 'noDisplay');    
                        $A.util.addClass(component.find("mslpDisclaimer"), 'noDisplayBar');   
                    }                  
                }                
            } else {
                var appEvent = $A.get("e.c:ApexCallbackError");
                appEvent.setParams({"className" : "SLPAddCustomerController",
                    "methodName" : "doInit",
                    "errors" : resp.getError()});
                appEvent.fire();

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
        if (!helper.validDate(lead.LASERCA__Birthdate__c)) {
            $A.util.addClass(component.find("dateOfBirth"), 'slds-has-error');  
            var appEvent = $A.get("e.c:ApexCallbackError");
            appEvent.setParams({"className" : "SLPAddCustomerController",
                                "methodName" : "addCustomer",
                                "errors" : "Please enter a Date of Birth in the format MM/DD/YYYY. Your date was entered as: " + lead.LASERCA__Birthdate__c});
            appEvent.fire();
            return;
        }
        $A.util.removeClass(component.find("dateOfBirth"), 'slds-has-error');          
        $A.util.addClass(component.find("SubmitButton"), 'noDisplay'); 
        helper.startSpinner(component, "leadSpinner");

        if (lead.LASERCA__Home_Address__c != null 
            && lead.LASERCA__Home_City__c != ''
            && lead.FirstName != ''
            && lead.LastName != ''
            && lead.Email != ''
            && lead.LASERCA__SSN__c != ''
            && lead.Requested_Loan_Amount__c != null
            && lead.Annual_Income_Currency__c != null
            && lead.Credit_Check_Acknowledged__c == true
            && lead.Privacy_Policy_Acknowledged__c == true
            && lead.Utility_Bill_Access_Acknowledged__c == true) {
            var Action = component.get("c.addNewLeadRecord");
            Action.setParams({"newLead" : lead});
            
            Action.setCallback(this, function(resp) {
                    if(resp.getState() == "SUCCESS") {
                        component.set("v.newLead", resp.getReturnValue());

                        $A.util.addClass(component.find("mslpAppbutton"), 'noDisplay'); 
                        $A.util.addClass(component.find("bwslAppButton"), 'noDisplay');      
                        $A.util.addClass(component.find("inputForm"), 'noDisplay'); 
                        $A.util.addClass(component.find("avidiaLogo"), 'noDisplay');    
                        $A.util.addClass(component.find("mslpDisclaimer"), 'noDisplay');
                        $A.util.addClass(component.find("customerEmailButton"), 'noDisplay'); 
                        $A.util.removeClass(component.find("pullCreditButtons"), 'noDisplay');
                        $A.util.removeClass(component.find("addedCustomerConfirmCredit"), 'noDisplay');
                    } else {
                        helper.stopSpinner(component, "leadSpinner");
                        $A.util.removeClass(component.find("SubmitButton"), 'noDisplay'); 

                        var appEvent = $A.get("e.c:ApexCallbackError");
                        appEvent.setParams({"className" : "SLPAddCustomerController",
                                            "methodName" : "addCustomer",
                                            "errors" : resp.getError()});
                        appEvent.fire();
                    }
                }); 
            $A.enqueueAction(Action);
        } else {
            alert("Please acknowledge our privacy policy, give BlueWave permission " +
                  "to access credit history, energy history and fill out all of the fields on this form.");

            helper.stopSpinner(component, 'leadSpinner');
            $A.util.removeClass(component.find("SubmitButton"), 'noDisplay'); 
        }
    },
    
    checkCredit : function(component, event, helper) {
        $A.util.addClass(component.find("pullCreditButtons"), 'noDisplay'); 
        $A.util.addClass(component.find("mslpAppButton"), 'noDisplay'); 
        $A.util.addClass(component.find("bwslAppButton"), 'noDisplay'); 
        $A.util.addClass(component.find("customerEmailButton"), 'noDisplay'); 

        helper.startSpinner(component, 'creditSpinner');

        var lead = component.get("v.newLead");
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

                        var appEvent = $A.get("e.c:ApexCallbackError");
                        appEvent.setParams({"className" : "SLPAddCustomerController",
                                            "methodName" : "checkCredit",
                                            "errors" : resp.getError()});
                        appEvent.fire();
                        $A.log("Errors", resp.getError());
                    }
                });
            $A.enqueueAction(action);
        } else {
            var appEvent = $A.get("e.c:ApexCallbackError");
            appEvent.setParams({"className" : "SLPAddCustomerController",
                                "methodName" : "checkCredit",
                                "errors" : "No Customer (Lead) ID was found when checking credit: " + lead});
            appEvent.fire();
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

        $A.util.removeClass(component.find("bwslAppButton"), 'noDisplayBar');      
        $A.util.addClass(component.find("mslpAppButton"), 'noDisplayBar'); 
        $A.util.removeClass(component.find("avidiaLogo"), 'noDisplay');  
        $A.util.removeClass(component.find("avidiaFooter"), 'noDisplay');
        $A.util.removeClass(component.find("mslpDisclaimer"), 'noDisplayBar');                        
    }, 
    changeApplicationToBWSL : function(component, event, helper) {
        component.set("v.newLead.DOER_Solar_Loan__c",false);  
        component.set("v.newLead.Product_Program__c",'BlueWave Solar Loan');         

        $A.util.addClass(component.find("bwslAppButton"), 'noDisplayBar');      
        $A.util.removeClass(component.find("mslpAppButton"), 'noDisplayBar');
        $A.util.addClass(component.find("avidiaLogo"), 'noDisplay');  
        $A.util.addClass(component.find("avidiaFooter"), 'noDisplay');    
        $A.util.addClass(component.find("mslpDisclaimer"), 'noDisplayBar');      
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
