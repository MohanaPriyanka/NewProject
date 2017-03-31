({ 
    doInit : function(component, event, helper) {
        var actionPartnerRecord = component.get("c.getPartnerRecord");        
        actionPartnerRecord.setCallback(this,function(resp){
            if(resp.getState() == 'SUCCESS') {
                component.set("v.partnerRecord", resp.getReturnValue());
            }
            else {
                $A.log("Errors", resp.getError());
            }
        });    
        $A.enqueueAction(actionPartnerRecord);        
    },    

    addCustomer : function(component, event, helper) {
        $A.util.addClass(component.find("SubmitButton"), 'noDisplay'); 
        // $A.util.removeClass(component.find("leadSpinner"), 'slds-hide');
        var spinner = component.find("leadSpinner");
        var evt = spinner.get("e.toggle");
        evt.setParams({ isVisible : true });
        evt.fire();

        var lead = component.get("v.newLead");
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
                        // $A.util.addClass(component.find("leadSpinner"), 'slds-hide'); 
                        var spinner2 = component.find('leadSpinner');
                        var evt2 = spinner.get("e.toggle");
                        evt2.setParams({ isVisible : false });
                        evt2.fire();

                        var submitButton2 = component.find("SubmitButton");
                        $A.util.removeClass(submitButton2, 'noDisplay'); 

                        var appEvent = $A.get("e.c:ApexCallbackError");
                        appEvent.setParams({"className" : "SLPAddCustomerController",
                                            "methodName" : "addCustomer",
                                            "errors" : resp.getError()});
                        appEvent.fire();
                        $A.log("Errors", resp.getError());
                    }
                }); 
            $A.enqueueAction(Action);
        } else {
            alert("Please acknowledge our privacy policy, give BlueWave permission " +
                  "to access credit history, energy history and fill out all of the fields on this form.");

            // $A.util.addClass(component.find("leadSpinner"), 'slds-hide'); 
            var spinner2 = component.find('leadSpinner');
            var evt2 = spinner.get("e.toggle");
            evt2.setParams({ isVisible : false });
            evt2.fire();

            var submitButton2 = component.find("SubmitButton");
            $A.util.removeClass(submitButton2, 'noDisplay'); 
        }
    },
    
    checkCredit : function(component, event, helper) {
        $A.util.addClass(component.find("pullCreditButtons"), 'noDisplay'); 
        // $A.util.removeClass(component.find("creditSpinner"), 'slds-hide');
        var spinner = component.find("creditSpinner");
        var evt = spinner.get("e.toggle");
        evt.setParams({ isVisible : true });
        evt.fire();

        var lead = component.get("v.newLead");
        if (!$A.util.isUndefinedOrNull(lead.Id)) {
            var self = this;
            var action = component.get("c.pullCreditStatus");
            action.setParams({"lead" : lead});
            action.setCallback(this, function(resp) {
                    if(resp.getState() == "SUCCESS") {
                        // Checkbox checked
                        window.setTimeout(function() {
                                $A.util.removeClass(component.find("creditStatus"), 'noDisplay');
                                component.set("v.creditStatusText", "Sending request to TransUnion");
                            }, 2000);
                        window.setTimeout(function() {
                                component.set("v.creditStatusText", "Waiting for TransUnion to process...");
                            }, 4000);
                        window.setTimeout(function() {
                                component.set("v.creditStatusText", "Checking for results...");
                            }, 7000);
                        window.setTimeout(function() {
                                var creditPollerInterval = window.setInterval(helper.checkCreditStatus, 2000, component);
                                component.set("v.creditStatusPoller", creditPollerInterval);
                            }, 9000);
                        // checkCreditStatus should clearInterval if it finds a Credit Report Log or
                        // a Credit Report on the Lead, but just in case, stop checking after a minute
                        window.setTimeout(function() {
                                var evt2 = component.find('creditSpinner').get("e.toggle");
                                evt2.setParams({ isVisible : false });
                                evt2.fire();

                                window.clearInterval(component.get("v.creditStatusPoller"));
                            }, 60000);
                    } else {
                        // $A.util.addClass(component.find("creditSpinner"), 'slds-hide');
                        var spinner2 = component.find('creditSpinner');
                        var evt2 = spinner.get("e.toggle");
                        evt2.setParams({ isVisible : false });
                        evt2.fire();

                        var submitButton2 = component.find("SubmitButton");
                        $A.util.removeClass(submitButton2, 'noDisplay'); 

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
            alert("No Lead ID?!");
        }
    },

    getProducts : function(component, event, helper) { 
        var leadId = component.get("v.newLead.Id");
        $A.util.removeClass(component.find("productTable"), 'noDisplayBar');
        $A.util.addClass(component.find("addedCustomerConfirmCredit"), 'noDisplayBar');
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
          "url": '/slpcreditstatus'

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
        var mslpDisclaimer = component.find("mslpDisclaimer");

        $A.util.removeClass(bwslButton, 'noDisplayBar');      
        $A.util.addClass(mslpButton, 'noDisplayBar'); 
        $A.util.removeClass(avidiaLogo, 'noDisplay');  
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
        var mslpDisclaimer = component.find("mslpDisclaimer");


        $A.util.addClass(bwslButton, 'noDisplayBar');      
        $A.util.removeClass(mslpButton, 'noDisplayBar');
        $A.util.addClass(avidiaLogo, 'noDisplay');   
        $A.util.addClass(mslpDisclaimer, 'noDisplayBar');      

        //$A.util.removeClass(inputFormBox, 'boxMSLP'); 
                     
           
    },         



    
})