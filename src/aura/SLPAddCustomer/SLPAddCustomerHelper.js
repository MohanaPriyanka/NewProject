({
    startSpinner : function(component, name) {
        var spinner = component.find(name);
        if (spinner) {
            var evt = spinner.get("e.toggle");
            evt.setParams({ isVisible : true });
            evt.fire();
        }
    },
    stopSpinner : function(component, spinnerName) {
        var spinner = component.find(spinnerName);
        if (spinner) {
            var evt = spinner.get("e.toggle");
            evt.setParams({ isVisible : false });
            evt.fire();
        }
    },
    handleCreditCheckResponse : function(component, divToShow) {
        $A.util.addClass(component.find("creditStatus"), 'noDisplay');
        $A.util.addClass(component.find("editPencil"), 'noDisplay');
        $A.util.removeClass(component.find(divToShow), 'noDisplay');
        this.stopSpinner(component, "creditSpinner");
        window.clearInterval(component.get("v.creditStatusPoller"));
    },

    checkCreditStatus : function(component, helper) {
        var action = component.get("c.checkCreditStatus");
        action.setParams({"leadToQuery" : component.get("v.newLead")});
        action.setCallback(this, function(resp) {
                console.log(resp.getReturnValue());
                if (resp.getState() == "SUCCESS") {
                    if (resp.getReturnValue() == "Ready for Credit Check") {
                        // Don't do anything, credit check isn't done yet
                    } else if (resp.getReturnValue() == "Pre-Qualified") {
                        helper.handleCreditCheckResponse(component, 'creditResultPass');
                    } else if (resp.getReturnValue() == "Pending Credit Review") {
                        helper.handleCreditCheckResponse(component, 'creditResultPendingReview');
                    } else if (resp.getReturnValue() == "Unqualified") {
                        helper.handleCreditCheckResponse(component, 'creditResultUnqualified');
                    } else {
                        component.set("v.creditStatusErrorText", 'Error on Credit Report Log');
                        helper.handleCreditCheckResponse(component, 'creditResultError');
                    }
                } else {
                    helper.logError("SLPAddCustomerHelper", "checkCreditStatus", resp.getError());
                    window.clearInterval(component.get("v.creditStatusPoller"));
                    $A.util.addClass(component.find("editPencil"), 'noDisplay');
                }
            });
        $A.enqueueAction(action);
    },

    errorsInForm : function(component, helper, lead) {
        var errorMessage = "";
        errorMessage = errorMessage + helper.checkFieldValidity(component, lead.FirstName, "firstNameElement", "shake", null, true, false, true, "Please enter the Applicants's First Name without any special characters.", "standard");
        errorMessage = errorMessage + helper.checkFieldValidity(component, lead.LastName, "lastNameElement", "shake", null, true, false, true, "Please enter the Applicants's Last Name without any special characters.", "standard");
        errorMessage = errorMessage + helper.checkFieldValidity(component, lead.Email, "customerEmail", "shake", null, true, true, false, "Please enter a valid email address. The email you entered is: " + lead.Email, "email");
        errorMessage = errorMessage + helper.checkFieldValidity(component, lead.LASERCA__Birthdate__c, "dateOfBirth", "shake", null, false, null, null, "Please enter a Date of Birth in the format MM/DD/YYYY. Your date was entered as: " + lead.LASERCA__Birthdate__c, "date");
        errorMessage = errorMessage + helper.checkFieldValidity(component, lead.LASERCA__Home_Address__c, "homeAddressElement", "shake", null, true, false, true, "Please enter the Applicants's correct home address", "standard");
        errorMessage = errorMessage + helper.checkFieldValidity(component, lead.LASERCA__Home_City__c, "cityElement", "shake", null, true, false, true, "Please enter the Applicant's City", "standard");
        if (lead.LASERCA__Home_State__c == "Select") {
            helper.setInputToError(component, "stateElement", "shake");
            errorMessage = errorMessage + "Please enter a valid State" + "\n" + "\n";
        } else {
            helper.setInputToCorrect(component, "stateElement" );
        }
        if (component.get("v.downPayment") < 0) {
            helper.setInputToError(component, "downPaymentElement", "shake");
            errorMessage = errorMessage + "You may not enter a negative value as a down payment." + "\n" + "\n";
        } else {
            helper.setInputToCorrect(component, "downPaymentElement" );
        }
        // If they haven't selected a product, don't include undefined in the lead, it results in 
        // "An internal sever error has occured Error ID: 798891498-91509 (119852647)"
        if (!lead.Product__c) {
            delete lead['Product__c'];
        }
        
        errorMessage = errorMessage + helper.checkFieldValidity(component, lead.LASERCA__Home_Zip__c, "zipCodeElement", "shake", 5, false, false, false, "Please enter a valid 5 digit Zip Code", "standard");
        errorMessage = errorMessage + helper.checkFieldValidity(component, lead.Requested_Loan_Amount__c, "loanAmountElement", "shake", null, false, false, false, "Please enter this Applicant's requested loan amount", "standard");
        errorMessage = errorMessage + helper.checkFieldValidity(component, lead.System_Cost__c, "systemCostElement", "shake", null, false, false, false, "Please enter this Applicant's system installation cost", "standard");
        lead.LASERCA__SSN__c = lead.LASERCA__SSN__c.replace(/-/g,"");
        errorMessage = errorMessage + helper.checkFieldValidity(component, lead.LASERCA__SSN__c, "ssnElement", "shake", 9, false, false, false, "Please enter a valid 9 digit Social Security Number without any special characters/symbols.", "standard");
        errorMessage = errorMessage + helper.checkFieldValidity(component, lead.Annual_Income_Currency__c, "incomeElement", "shake", null, false, false, false, "Please enter this Applicant's estimated annual income", "standard");
        errorMessage = errorMessage + helper.checkFieldValidity(component, lead.Credit_Check_Acknowledged__c, "creditHistoryElement", "shake", null, true, false, false, "Please have the Applicant give BlueWave and Avidia Bank permission to access their credit history.", "standard");             
        errorMessage = errorMessage + helper.checkFieldValidity(component, lead.Privacy_Policy_Acknowledged__c, "privacyPolicyElement", "shake", null, true, false, false, "Please have the Applicant acknowledge BlueWave's Privacy Policy.", "standard");
        errorMessage = errorMessage + helper.checkFieldValidity(component, lead.Utility_Bill_Access_Acknowledged__c, "energyHistoryElement", "shake", null, true, false, false, "Please have the Applicant give BlueWave permission to access their energy billing history.", "standard");             

        if (errorMessage.length > 0) {
            return errorMessage;
        } else {
            return null;
        }
    },

    removeAddCustomerForm : function(component) {
        $A.util.addClass(component.find("applicationTabBar"), 'noDisplay');
        $A.util.addClass(component.find("bwApplicationHeader"), 'noDisplay');
        $A.util.addClass(component.find("inputForm"), 'noDisplay');
        $A.util.addClass(component.find("avidiaLogo"), 'noDisplay');
        $A.util.addClass(component.find("mslpDisclaimer"), 'noDisplay');
        $A.util.addClass(component.find("customerEmailButton"), 'noDisplay'); 
        $A.util.addClass(component.find("avidiaOriginatedDisclaimer"), 'noDisplay'); 
        $A.util.addClass(component.find("goBackToIBSLSelection"), 'noDisplay'); 
    },
   
    returnAddCustomerForm : function(component) {
        $A.util.removeClass(component.find("avidiaOriginatedDisclaimer"), 'noDisplay'); 
        $A.util.removeClass(component.find("inputForm"), 'noDisplay');
        $A.util.removeClass(component.find("applicationTabBar"), 'noDisplay');
    },

    showCreditCheckPage : function(component) {
        $A.util.removeClass(component.find("pullCreditButtons"), 'noDisplay');
        $A.util.removeClass(component.find("addedCustomerConfirmCredit"), 'noDisplay');
    },
    
    hideCreditCheckPage : function(component) {
        $A.util.addClass(component.find("pullCreditButtons"), 'noDisplay');
        $A.util.addClass(component.find("addedCustomerConfirmCredit"), 'noDisplay');
    },

    showMSLPApplication : function(component) {
        $A.util.removeClass(component.find("bwslAppTab"), 'slds-has-focus');
        $A.util.addClass(component.find("mslpAppTab"), 'slds-has-focus');
        $A.util.removeClass(component.find("mslpDisclaimer"), 'noDisplay');
    },

    showBWSLApplication : function(component) {
        $A.util.addClass(component.find("bwslAppTab"), 'slds-has-focus');
        $A.util.removeClass(component.find("mslpAppTab"), 'slds-has-focus');
        $A.util.addClass(component.find("mslpDisclaimer"), 'noDisplay');
    },

    removeErrorAnimations : function(component, animation) {
        $A.util.removeClass(component.find("firstNameElement"), animation);
        $A.util.removeClass(component.find("lastNameElement"), animation);
        $A.util.removeClass(component.find("customerEmail"), animation);
        $A.util.removeClass(component.find("dateOfBirth"), animation);
        $A.util.removeClass(component.find("homeAddressElement"), animation);
        $A.util.removeClass(component.find("cityElement"), animation); 
        $A.util.removeClass(component.find("stateElement"), animation);
        $A.util.removeClass(component.find("zipCodeElement"), animation);
        $A.util.removeClass(component.find("loanAmountElement"), animation); 
        $A.util.removeClass(component.find("systemCostElement"), animation);
        $A.util.removeClass(component.find("incomeElement"), animation);
        $A.util.removeClass(component.find("creditHistoryElement"), animation);
        $A.util.removeClass(component.find("privacyPolicyElement"), animation);
        $A.util.removeClass(component.find("energyHistoryElement"), animation);
        $A.util.removeClass(component.find("ssnElement"), animation);
    },

    getStates : function(component, event, helper) {
        var actionGetActiveStates = component.get("c.getActiveStates");
        actionGetActiveStates.setStorable();
        actionGetActiveStates.setCallback(this,function(resp) {
            if (resp.getState() == 'SUCCESS') {
                var opts=[{"class": "optionClass",
                           label: "Select",
                           value: ""}];
                for (var i=0;i< resp.getReturnValue().length;i++) {
                    opts.push({"class": "optionClass",
                               label: resp.getReturnValue()[i],
                               value: resp.getReturnValue()[i]});
                }
                component.find("state").set("v.options", opts);
            } else {
                helper.logError("SLPAddCustomerController", "doInit", resp.getError());
            }
        });
        $A.enqueueAction(actionGetActiveStates);
    },
    getAvailableProducts : function(component, event, helper) { 
        var action = component.get("c.getProducts");
        action.setParams({state: component.get("v.newLead.LASERCA__Home_State__c")});
        action.setCallback(this,function(resp){
            if (resp.getState() == 'SUCCESS') {
                var allStateProducts = resp.getReturnValue();
                var selectedProgram = component.get("v.newLead.Product_Program__c");
                // Product_Program__c isn't set by default, but we can use the DOER flag to figure it out.
                if (!selectedProgram) {
                    if (component.get("v.newLead.DOER_Solar_Loan__c")) {
                        selectedProgram = 'MSLP';
                    } else {
                        selectedProgram = 'BlueWave Solar Loan';
                    }
                }
                var availableProducts = [];
                for (var p in allStateProducts) {
                    if (selectedProgram === allStateProducts[p].Program__c) {
                        availableProducts.push(allStateProducts[p]);
                    }
                }
                component.set("v.availableProducts", availableProducts);
            } else {
                helper.logError("SLPAddCustomerHelper", "getAvailableProducts", resp.getError());
            }
        });
        $A.enqueueAction(action);
    },

    getProductName : function(productId, availableProducts) {
        for (var p in availableProducts) {
            if (availableProducts[p].Id === productId) {
                return availableProducts[p].Name;
            }
        }
        return null;
    }
})