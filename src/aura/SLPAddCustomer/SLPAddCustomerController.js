({ 
    doInit : function(component, event, helper) {
        var actionPartnerRecord = component.get("c.getPartnerRecord");        
        actionPartnerRecord.setCallback(this,function(resp){
            if (resp.getState() == 'SUCCESS') {
                component.set("v.partnerRecord", resp.getReturnValue());
                if (resp.getReturnValue().State__c == 'MA') {
                    component.set("v.newLead.DOER_Solar_Loan__c",true);  
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
            var appEvent = $A.get("e.c:ApexCallbackError");
            appEvent.setParams({"className" : "SLPAddCustomerController",
                                "methodName" : "addCustomer",
                                "errors" : "Please enter a Date of Birth in the format Month/Day/Year. We saw a date of: " + lead.LASERCA__Birthdate__c});
            appEvent.fire();
            return;
        }
        $A.util.addClass(component.find("SubmitButton"), 'noDisplay'); 
        helper.startSpinner(component, "leadSpinner");

        if (lead.LASERCA__Home_Address__c != null 
            && lead.LASERCA__Home_City__c != ''
            && lead.FirstName != ''
            && lead.LastName != ''
            && lead.Email != ''
            && lead.LASERCA__Social_Security_Number__c != ''
            && lead.System_Cost__c != null
            && lead.Annual_Income_Currency__c != null
            && lead.Credit_Check_Acknowledged__c == true
            && lead.Privacy_Policy_Acknowledged__c == true
            && lead.Utility_Bill_Access_Acknowledged__c == true) {
            var Action = component.get("c.addNewLeadRecord");
            Action.setParams({"newLead" : lead});
            
            Action.setCallback(this, function(resp) {
                    if(resp.getState() == "SUCCESS") {
                        component.set("v.newLead", resp.getReturnValue());
                        var inputForm = component.find("inputForm");
                        var pullCreditButtons = component.find("pullCreditButtons");
                        var mslpButton = component.find("mslpAppbutton");
                        var addedCustomerConfirmCredit = component.find("addedCustomerConfirmCredit");
                        var bwslButton = component.find("bwslAppButton");
                        var avidiaLogo = component.find("avidiaLogo");
                        var mslpDisclaimer = component.find("mslpDisclaimer");

                        $A.util.addClass(mslpButton, 'noDisplayBar'); 
                        $A.util.addClass(bwslButton, 'noDisplayBar');      
                        $A.util.addClass(inputForm, 'noDisplayBar'); 
                        $A.util.addClass(avidiaLogo, 'noDisplayBar');    
                        $A.util.addClass(mslpDisclaimer, 'noDisplayBar');
                        $A.util.removeClass(pullCreditButtons, 'noDisplayBar');
                        $A.util.removeClass(addedCustomerConfirmCredit, 'noDisplayBar');
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
                 
        var bwslButton = component.find("bwslAppButton");
        var mslpButton = component.find("mslpAppButton");
        var inputFormBox = component.find("inputFormBox");
        var avidiaLogo = component.find("avidiaLogo");
        var avidiaFooter = component.find("avidiaFooter");
        var mslpDisclaimer = component.find("mslpDisclaimer");

        $A.util.removeClass(bwslButton, 'noDisplayBar');      
        $A.util.addClass(mslpButton, 'noDisplayBar'); 
        $A.util.removeClass(avidiaLogo, 'noDisplay');  
        $A.util.removeClass(avidiaFooter, 'noDisplay');
        $A.util.removeClass(mslpDisclaimer, 'noDisplayBar');      

       // $A.util.addClass(inputFormBox, 'boxMSLP');      

                  
    }, 
    changeApplicationToBWSL : function(component, event, helper) {
        component.set("v.newLead.DOER_Solar_Loan__c",false);  
        component.set("v.newLead.Product_Program__c",'BlueWave Solar Loan');         

        var bwslButton = component.find("bwslAppButton");
        var mslpButton = component.find("mslpAppButton");
        var inputFormBox = component.find("inputFormBox");
        var avidiaLogo = component.find("avidiaLogo");
        var avidiaFooter = component.find("avidiaFooter");
        var mslpDisclaimer = component.find("mslpDisclaimer");


        $A.util.addClass(bwslButton, 'noDisplayBar');      
        $A.util.removeClass(mslpButton, 'noDisplayBar');
        $A.util.addClass(avidiaLogo, 'noDisplay');  
        $A.util.addClass(avidiaFooter, 'noDisplay');    
        $A.util.addClass(mslpDisclaimer, 'noDisplayBar');      

        //$A.util.removeClass(inputFormBox, 'boxMSLP'); 
                     
           
    },         



    
})