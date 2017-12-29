({
    errorsInForm : function(component, helper, lead) {
        var errorMessage = "";
        errorMessage = errorMessage + helper.checkFieldValidity(component, lead.Email, "emailAddressElement", "shake", null, 50, true, true, false, "Please enter a valid email address. The email you entered is: " + lead.Email, "email");
        errorMessage = errorMessage + helper.checkFieldValidity(component, lead.Email, "firstNameElement", "shake", null, 30, true, true, true, "Please enter a valid first name. The first name you entered is: " + lead.FirstName, "standard");
        errorMessage = errorMessage + helper.checkFieldValidity(component, lead.Email, "lastNameElement", "shake", null, 30, true, true, true, "Please enter a valid last name. The last name you entered is: " + lead.lastName, "standard");
        errorMessage = errorMessage + helper.checkFieldValidity(component, lead.System_Cost__c, "systemCostElement", "shake", null, true, true, false, "Please provide this applicant's expected system cost.", "standard");
   
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
        if (lead.LASERCA__Home_State__c === 'MA') {
            if (!lead.Product__c) {
                helper.setInputToError(component, "productElement", "shake");
                errorMessage = errorMessage + "Please select a Product" + "\n" + "\n";
            } else {
                helper.setInputToCorrect(component, "productElement" );
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

    createLead : function(component, event, helper, downPayment, newLead) {
        var action = component.get("c.addNewLeadRecord");
        action.setParams({newLead : newLead});
        action.setCallback(this,function(resp){
            if (resp.getState() == 'SUCCESS') {
                this.emailApplication(component, event, helper, downPayment, resp.getReturnValue());
            } else {
                helper.logError("SLPSendApplicationEmailEvent", "createLead", resp.getError(), resp.getReturnValue());
                $A.log("Errors", resp.getError());
            }
        });
        $A.enqueueAction(action);
    },

    emailApplication : function(component, event, helper, downPayment, newLead) {
        var action = component.get("c.sendApplication");
        var loanAmount = newLead.System_Cost__c;
        if (downPayment) {
            loanAmount = loanAmount - downPayment;
        }
        action.setParams({newLead : newLead,
                          loanAmount : loanAmount});
        action.setCallback(this,function(resp){
            if (resp.getState() == 'SUCCESS') {
                helper.handleSuccessfulEmail(component, helper);
            } else {
                helper.logError("SLPSendApplicationEmailEvent", "sendCustomerApplication", resp.getError(), newLead);
                $A.log("Errors", resp.getError());
            }
        });
        $A.enqueueAction(action);
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
        component.set('v.availableProducts', null);
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
