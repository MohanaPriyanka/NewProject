({
    doInit : function(component, event, helper) {
        var actionPartnerRecord = component.get("c.getPartnerRecord");
        actionPartnerRecord.setCallback(this,function(resp){
            if (resp.getState() == 'SUCCESS') {
                var partner = resp.getReturnValue();
                component.set("v.partnerRecord", partner);
                if (partner.Accounts__r[0] &&
                    partner.Accounts__r[0].Disable_New_Loan_Applications_in_Portal__c) {
                    component.set("v.disableOrigination", true);
                }
                if (partner.State__c == 'MA') {
                    $A.util.addClass(component.find("customerEmailButton"), 'slds-float--right');
                    if (partner.Default_Application__c != 'Massachusetts Solar Loan Program') {
                        component.set("v.newLead.DOER_Solar_Loan__c",false);
                        component.set("v.newLead.Product_Program__c",'BlueWave Solar Loan');
                    } else {
                        component.set("v.newLead.DOER_Solar_Loan__c",true);
                        component.set("v.newLead.Product_Program__c",'MSLP');
                    }
                }
            } else {
                helper.logError("SLPAddCustomerController", "doInit", resp.getError());
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

        helper.getStates(component, event, helper);

        var promise = helper.getSLPSettings(component, event, helper);
        promise.then($A.getCallback(function resolve(settings) {
            component.set('v.iblsRequired', settings[0].Require_IBLS_for_MSL_Loans__c);
        }));
    },

    checkAvidiaOriginated : function(component, event, helper) {
        if (component.get("v.newLead.LASERCA__Home_State__c") != 'MA') {
            component.set("v.newLead.Product_Program__c", "BlueWave Solar Loan");
            component.set("v.newLead.DOER_Solar_Loan__c",false);
        } 
        var actionGetLender = component.get("c.getLenderOfRecord");
        actionGetLender.setStorable();
        actionGetLender.setParams({"state": component.get("v.newLead.LASERCA__Home_State__c")});
        actionGetLender.setCallback(this,function(resp) {
            if (resp.getState() == 'SUCCESS') {
                if (resp.getReturnValue().includes("Avidia")) {
                    component.set("v.avidiaOriginated", true);
                } else {
                    component.set("v.avidiaOriginated", false);
                }
            } else {
                helper.logError("SLPAddCustomerController", "getOriginator", resp.getError());
            }
        });
        $A.enqueueAction(actionGetLender);
        helper.getAvailableProducts(component, event, helper);
    },

    addCustomer : function(component, event, helper) {
        var lead = component.get("v.newLead");

        var downPayment = component.get("v.downPayment");
        if (!downPayment) {
            downPayment = 0;
        }
        lead.Requested_Loan_Amount__c = lead.System_Cost__c - downPayment;
        var availableProducts = component.get("v.availableProducts");
        if (availableProducts.length === 1) {
            lead.Product__c = availableProducts[0].Id;
        }
        var errors = helper.errorsInForm(component, helper, lead);
        if (errors != null) {
            helper.logError("SLPAddCustomerController", "addCustomer", errors, lead);
            return;
        }

        $A.util.addClass(component.find("SubmitButton"), 'noDisplay');
        helper.startSpinner(component, "leadSpinner");

        lead.LASERCA__SSN__c = lead.LASERCA__SSN__c.replace(/-/g,"");
        var action = component.get("c.addNewLeadRecord");
        action.setParams({"newLead" : lead});

        action.setCallback(this, function(resp) {
            if (resp.getState() == "SUCCESS") {
                component.set("v.newLead", resp.getReturnValue());
                component.get("v.newLead").LASERCA__Birthdate__c = component.get("v.newLead").LASERCA__Birthdate__c.replace(/T00:00:00.000Z/,"");
                component.set("v.selectedProductName", helper.getProductName(resp.getReturnValue().Product__c, availableProducts));
                helper.removeAddCustomerForm(component);
                helper.removeErrorAnimations(component, "shake");
                helper.showCreditCheckPage(component);
            } else {
                helper.stopSpinner(component, "leadSpinner");
                $A.util.removeClass(component.find("SubmitButton"), 'noDisplay');
                helper.logError("SLPAddCustomerController", "addCustomer", "We've encountered an issue while trying to add this applicant. Please verify that all of the applicant's information has been entered in correctly and try again. If the issue persists, please call (888) 817-2703 for support", lead);
            }
        });
        $A.enqueueAction(action);
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
        sessionStorage.setItem('leadId', component.get("v.newLead.Id"));
        sessionStorage.setItem('leadName', component.get("v.newLead.FirstName") + ' ' + component.get("v.newLead.LastName"));
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
        component.set("v.iblsEligible",false);
        helper.getAvailableProducts(component, event, helper);
        component.set("v.loading",true);
        component.set("v.loadingText","You are being directed to the application for the Massachusetts Solar Loan Program...");
        window.setTimeout(function() {
            component.set("v.loading",false);
        }, 2000);
    },

    changeApplicationToBWSL : function(component, event, helper) {
        component.set("v.newLead.DOER_Solar_Loan__c",false);
        component.set("v.newLead.Product_Program__c",'BlueWave Solar Loan');
        component.set("v.iblsEligible",false);
        helper.getAvailableProducts(component, event, helper);
        component.set("v.loading",true);
        component.set("v.loadingText","You are being directed to the application for BlueWave's Solar Loan Product...");
        window.setTimeout(function() {
            component.set("v.loading",false);
        }, 2000);
    },

    setToMSLPEligible : function(component, event, helper) {
        helper.startSpinner(component, 'iblsElibilitySpinner');
        helper.stopSpinner(component, 'iblsElibilitySpinner');
        var category = component.get("v.newLead.IBLS_Category__c");
        if (category == 'Category 1' || category == 'Category 2') {
            component.set("v.iblsEligible",true);
        } else {
            component.set("v.iblsEligible", false);
        }
    },

    returnToEdit : function(component, event, helper) {
        helper.returnAddCustomerForm(component);
        helper.hideCreditCheckPage(component);
        $A.util.addClass(component.find('creditResultError'), 'noDisplay');
        helper.stopSpinner(component, "leadSpinner");
        $A.util.removeClass(component.find("EditButton"), 'noDisplay');
    },

    updateCustomer : function(component, event, helper) {
        var actionUpdate = component.get("c.updateLeadRecord");
        var leadToUpdate = component.get("v.newLead");
        var downPayment = component.get("v.downPayment");
        if (!downPayment) {
            downPayment = 0;
        }
        leadToUpdate.Requested_Loan_Amount__c = leadToUpdate.System_Cost__c - downPayment;
        var availableProducts = component.get("v.availableProducts");
        if (availableProducts.length === 1) {
            leadToUpdate.Product__c = availableProducts[0].Id;
        }
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
                        component.get("v.newLead").LASERCA__Birthdate__c = component.get("v.newLead").LASERCA__Birthdate__c.replace(/T00:00:00.000Z/,"");
                        component.set("v.selectedProductName", helper.getProductName(resp.getReturnValue().Product__c, availableProducts));
                    } else {
                        $A.util.removeClass(component.find("EditButton"), 'noDisplay');
                        helper.stopSpinner(component, "leadSpinner");
                        helper.logError("SLPAddCustomer", "updateLeadRecord", resp.getERror());
                    }
                });
         $A.enqueueAction(actionUpdate);
    },

    openAddCoApplicant : function(component, event, helper) {
        var ldRecord = component.get("v.newLead");

        $A.createComponent(
            "c:SLPAddCoApplicant",
            {"mainApplicant": ldRecord},

            function(newButton, status, errorMessage){
                if (status === "SUCCESS") {
                       var body = component.get("v.body");
                       body.push(newButton);
                       component.set("v.body", body);
                } else if (status === "INCOMPLETE") {
                       console.log("No response from server or client is offline.")
                } else if (status === "ERROR") {
                       console.log("Error: " + errorMessage);
                }
            }
        );
    },
})