({
    checkCreditStatus : function(component, helper) {
        var action = component.get("c.checkCreditStatus");
        const lead = helper.cleanLead(component);
        action.setParams({"leadToQuery" : lead});
        action.setCallback(this, function(resp) {
            if (resp.getState() === "SUCCESS") {
                helper.checkCreditResponse(component, helper, lead.Application_Type__c, resp.getReturnValue());
            } else {
                helper.logError("CAPCreditCheckHelper", "checkCreditStatus", resp.getError());
                console.log("poller from ccs: " + component.get("v.creditStatusPoller"));
                window.clearInterval(component.get("v.creditStatusPoller"));
                window.clearTimeout(component.get("v.creditStatusTimeoutID"));
                $A.util.addClass(component.find("editPencil"), 'noDisplay');
            }
        });
        $A.enqueueAction(action);
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
            component.set("v.creditStatusErrorText", returnValue);
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
        var customerEmailButton = component.find("customerEmailButton");
        var incomeFormButton = component.find("incomeFormButton");

        if (selected) {
            if (prodId !== component.get("v.lead.Product__c")) {
                helper.saveSObject(component, 
                                   component.get("v.lead.Id"),
                                   'Lead',
                                   'Product__c',
                                   prodId);
                component.set("v.lead.Product__c", prodId);
            }
            $A.util.removeClass(customerEmailButton, 'noDisplay');
            $A.util.removeClass(incomeFormButton, 'noDisplay');     
        } else {
            component.set("v.productId", null); 
            component.set("v.loanTerm", 0);
            component.set("v.allCustomers[0].Product__c", null);

            $A.util.addClass(customerEmailButton, 'noDisplay');
            $A.util.addClass(incomeFormButton, 'noDisplay');     
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
    }
})
