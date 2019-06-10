({
    checkCreditStatus : function(component, helper) {
        var action = component.get("c.checkCreditStatus");
        const lead = {
            sobjectType: 'Lead',
            Id: component.get('v.lead.Id')
        };
        action.setParams({"leadToQuery" : lead});
        action.setCallback(this, function(resp) {
            if (resp.getState() === "SUCCESS") {
                helper.checkCreditResponse(component, helper, lead.Application_Type__c, resp.getReturnValue());
            } else {
                var creditCheckErrors = component.get('v.creditCheckErrors');
                if (creditCheckErrors < 3 && resp.getError()) {
                    component.set('v.creditCheckErrors', creditCheckErrors + 1);
                    helper.raiseError("CAPCreditCheckHelper", "checkCreditStatus",
                        'Error received, but trying again for '
                        + (3 - creditCheckErrors) + ' times: ' + helper.getFirstError(resp.getError()), lead, {suppressAlert: true});
                } else {
                    helper.logError("CAPCreditCheckHelper", "checkCreditStatus", resp.getError(), lead);
                    window.clearInterval(component.get("v.creditStatusPoller"));
                    window.clearTimeout(component.get("v.creditStatusTimeoutID"));
                    $A.util.addClass(component.find("editPencil"), 'noDisplay');
                    component.set("v.creditStatusErrorText", helper.getFirstError(resp.getError()));
                    helper.handleCreditCheckResponse(component, helper, 'creditResultError');
                }
            }
        });
        $A.enqueueAction(action);
    },

    getFirstError : function(errors) {
        var firstError = '';
        if (errors[0] && errors[0].message) {
            firstError = errors[0].message;
        } else if (errors[0] && errors[0].pageErrors && errors[0].pageErrors.length > 0) {
            firstError = errors[0].pageErrors[0].message;
        } else if (errors[0] && errors[0].fieldErrors && errors[0].fieldErrors.length > 0) {
            // There might be more than one field error for different fields. Just get the first field which has
            // a status code, column, and message.

            const fieldWithError = errors[0].fieldErrors[Object.keys(errors[0].fieldErrors)[0]][0];
            firstError = fieldWithError.columnApiName + ': ' + fieldWithError.message;
        }
        return firstError;
    },

    checkCreditResponse : function(component, helper, applicationType, returnValue) {
        const lead = component.get('v.lead');
        if (returnValue === "Ready for Credit Check") {
            // Don't do anything, credit check isn't done yet
        } else if (
            returnValue === "Pre-Qualified" ||
            returnValue === "Pending Credit Review" ||
            returnValue === "Unqualified") {
            lead.Status = returnValue;
            component.set('v.lead', lead);
            helper.raiseNavEvent('LOCKPI');
            component.set('v.primaryChecked', true);
            if (lead.Application_Type__c === 'Joint') {
                helper.raiseNavEvent('LOCKJOINT');
                component.set('v.coAppChecked', true);
            }
            helper.handleCreditCheckResponse(component, helper);
        } else {
            component.set("v.creditStatusErrorText", 'Error on Credit Report Log');
            helper.handleCreditCheckResponse(component, helper, 'creditResultError');
        }
    },

    handleCreditCheckResponse : function(component, helper, divToShow) {
        $A.util.addClass(component.find("creditStatus"), 'noDisplay');
        if (divToShow) {
            $A.util.removeClass(component.find(divToShow), 'noDisplay');
        }
        helper.stopSpinner(component, 'creditSpinner');
        window.clearInterval(component.get("v.creditStatusPoller"));
        window.clearTimeout(component.get("v.creditStatusTimeoutID"));
    },

    updateProductSelection : function(component, event, helper) { 
        var source = event.getSource();
        var productId = source.get("v.class"); 
        var productTerm = source.get("v.name");
        // The value of the toggle before it was checked, e.g. if toggle is turned off,
        // this will be true
        var valueBeforeToggle = source.get("v.value");

        helper.toggleProductSelection(component, helper, productId, productTerm, !valueBeforeToggle);
    },

    toggleProductSelection : function(component, helper, prodId, term, selected) {
        if (selected) {
            if (prodId !== component.get("v.lead.Product__c")) {
                // Will cause the current checkbox to become unchecked
                component.set('v.lead.Product__c', null);
                helper.saveSObject(component, 
                                   component.get("v.lead.Id"),
                                   'Lead',
                                   'Product__c',
                                   prodId)
                .then($A.getCallback(function resolve(value) {
                    component.set("v.lead.Product__c", prodId);
                }));
            }
        } else {
            component.set("v.lead.Product__c", null);
        }
    },

    qualifyingProductSelected : function(component, productId) {
        var products = component.get("v.allProducts");
        for (var p in products) {
            if (products[p].Id === productId) {
                return true;
            }
        }
        return false;
    },

    createLoanAndEquipmentFunction : function(component, helper) {
        return new Promise(function(resolve) {
            //retrieve the customer's full information to display in the component
            let createLoanAction = component.get("c.createLoanAndEquipment");
            createLoanAction.setParams({
                'leadId' : component.get('v.lead.Id'),
                'email' : component.get('v.lead.Email')
            });
            createLoanAction.setCallback(this,function(resp) {
                if (resp.getState() === 'SUCCESS') {
                    component.set('v.systemInfoComplete', resp.getReturnValue());
                    resolve();
                } else {
                    helper.logError('CAPCreditCheckHelper', 'createLoanAndEquipment', 'Couldn\'t create loan or equipment', resp.getError());
                }
            });
            $A.enqueueAction(createLoanAction);
        });
    },
})