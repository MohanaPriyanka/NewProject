({
    errorsInForm : function(component, helper, lead) {
        var errorMessage = "";
        errorMessage = errorMessage + helper.checkFieldValidity(component, lead.Email, "emailAddressElement", "shake", null, 50, true, true, false, "Please enter a valid email address. The email you entered is: " + lead.Email, false, "email");
        errorMessage = errorMessage + helper.checkFieldValidity(component, lead.FirstName, "firstNameElement", "shake", null, 30, true, true, true, "Please enter a valid first name. The first name you entered is: " + lead.FirstName, false, "standard");
        errorMessage = errorMessage + helper.checkFieldValidity(component, lead.LastName, "lastNameElement", "shake", null, 30, true, true, true, "Please enter a valid last name. The last name you entered is: " + lead.lastName, false, "standard");
        errorMessage = errorMessage +
                       helper.getFieldError(component,
                           {'fieldValue': lead.System_Cost__c, 'fieldId': "systemCostElement", 'fieldType': 'currency', 'errorMessage': 'Please enter a System Cost'});
   
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
        if (lead.System_Cost__c < 0) {
            helper.setInputToError(component, "systemCostElement", "shake");
            errorMessage = errorMessage + "You may not enter a negative system cost." + "\n" + "\n";
        } else {
            helper.setInputToCorrect(component, "systemCostElement" );
        }
        if (lead.LASERCA__Home_State__c === 'MA') {
            if (!lead.Product__c) {
                helper.setInputToError(component, "productElement", "shake");
                errorMessage = errorMessage + "Please select a Product" + "\n" + "\n";
            } else {
                helper.setInputToCorrect(component, "productElement" );
            }
            if (!lead.SREC_Product__c) {
                helper.setInputToError(component, "srecElement", "shake");
                errorMessage = errorMessage + "Please select an SREC Product" + "\n" + "\n";
            }
        } else {
            // If they haven't selected a product, don't include undefined in the lead, it results in 
            // "An internal sever error has occured Error ID: 798891498-91509 (119852647)"
            if (!lead.Product__c) {
                delete lead['Product__c'];
            }
        }
        if (errorMessage.length > 0) {
            return errorMessage;
        }
    },

    removeButtonsAndShowSpinner : function(component, event, helper) {
        $A.util.addClass(component.find('sendEmailModalButtons'), 'noDisplay');
        this.startSpinner(component, "emailSpinner");
    }, 

    startApplication : function(component, event, helper) {
        var newLead = component.get("v.newLead");
        var downPayment = component.get("v.downPayment");
        newLead.Requested_Loan_Amount__c = newLead.System_Cost__c - downPayment;
        var availableLoanProducts = component.get("v.availableLoanProducts");
        var errors = helper.errorsInForm(component, helper, newLead);
        if (errors == null) {
            helper.startSpinner(component, 'emailSpinner');
            newLead.Product_Program__c = helper.getProductProgram(availableLoanProducts, newLead.Product__c);
            // We don't want to set a product for MA loans - just MSLP vs non-MSLP
            if (newLead.Product__c === 'MSLP' || newLead.Product__c === 'BlueWave Solar Loan') {
                delete newLead.Product__c;
            }
            var leadPromise = helper.createLead(component, helper, newLead);
            leadPromise.then($A.getCallback(function resolve(lead) {
                helper.emailApplication(component, helper, downPayment, lead);
            }));
        } else {
            helper.logError("SLPSendApplicationEmailController", "createLeadAndSendApplication", errors, newLead);
        }
    },

    createLead : function(component, helper, newLead) {
        return new Promise(function(resolve, reject) {
            var action = component.get("c.addNewLeadRecord");
            action.setParams({newLead: newLead});
            action.setCallback(this, function (resp) {
                if (resp.getState() === 'SUCCESS') {
                    resolve(resp.getReturnValue());
                } else {
                    helper.logError("SLPSendApplicationEmailEvent", "createLead", resp.getError(), resp.getReturnValue());
                    $A.log("Errors", resp.getError());
                }
            });
            $A.enqueueAction(action);
        });
    },

    emailApplication : function(component, helper, downPayment, newLead) {
        return new Promise(function(resolve) {
            var action = component.get("c.sendApplication");
            var loanAmount = newLead.System_Cost__c;
            if (downPayment) {
                loanAmount = loanAmount - downPayment;
            }
            action.setParams({
                newLead: newLead,
                loanAmount: loanAmount
            });
            action.setCallback(this, function (resp) {
                if (resp.getState() === 'SUCCESS') {
                    resolve();
                    helper.handleSuccessfulEmail(component, helper);
                } else {
                    helper.logError("SLPSendApplicationEmailEvent", "sendCustomerApplication", resp.getError(), newLead);
                    $A.log("Errors", resp.getError());
                }
            });
            $A.enqueueAction(action);
        });
    },

    handleSuccessfulEmail : function(component, helper) {
        $A.util.addClass(component.find('emailForm'), 'noDisplay');
        $A.util.removeClass(component.find('emailConfirmation'), 'noDisplay');
        $A.util.removeClass(component.find('sendEmailModalButtons'), 'noDisplay');

        helper.stopSpinner(component, "emailSpinner");
        helper.disableButton(component, 'sendEmailButton', 'Email Sent!');

        component.set('v.newLead.FirstName', null);
        component.set('v.newLead.LastName', null);
        component.set('v.newLead.Email', null);
        component.set('v.newLead.LASERCA__Home_State__c', null);
        component.set('v.downPayment', null);
        component.set('v.newLead.System_Cost__c', null);
        component.set('v.newLead.Product__c', null);
        component.set('v.newLead.Product_Program__c', null);
        component.set('v.availableLoanProducts', null);
        component.set('v.availableSRECProducts', null);
    },

    getAvailableLoanProducts : function(component, event, helper) { 
        var action = component.get("c.getProducts");
        action.setParams({state: component.get("v.newLead.LASERCA__Home_State__c"),
                          productType: 'Residential Loan'});
        action.setCallback(this,function(resp){
            if (resp.getState() == 'SUCCESS') {
                component.set("v.availableLoanProducts", resp.getReturnValue());
            } else {
                helper.logError("SLPSendApplicationEmailController", "availableLoanProducts", resp.getError());
            }
        });
        $A.enqueueAction(action);
    },

    getAvailableSRECProducts : function(component, event, helper) { 
        var action = component.get("c.getProducts");
        action.setParams({state: component.get("v.newLead.LASERCA__Home_State__c"),
                          productType: 'SREC'});
        action.setCallback(this,function(resp){
            if (resp.getState() == 'SUCCESS') {
                component.set("v.availableSRECProducts", resp.getReturnValue());
            } else {
                helper.logError("SLPSendApplicationEmailController", "availableSRECProducts", resp.getError());
            }
        });
        $A.enqueueAction(action);
    },

    // selectedId might be a Product ID or "BlueWave Solar Loan" or "MSLP" for MA
    getProductProgram : function(products, selectedId) {
        if (selectedId) {
            for (var p in products) {
                if (selectedId === products[p].Id) {
                    return products[p].Program__c;
                }
            }
            return selectedId;
        } else {
            return products[0].Program__c;
        }
    },
})
