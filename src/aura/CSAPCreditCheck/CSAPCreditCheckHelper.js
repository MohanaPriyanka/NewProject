({
    checkCreditStatus : function(component, helper) {
        var leadId = component.get("v.lead.Id");
        var action = component.get("c.checkLeadCreditIfQualified");
        action.setParams({"leadId" : leadId});
        action.setCallback(this, function(resp) {
            if (resp.getState() === "SUCCESS") {
                helper.checkCreditResponse(component, helper, resp.getReturnValue());
            } else {
                helper.logError("CSAPCreditCheckHelper", "checkCreditStatus", resp.getError(), lead);
                window.clearInterval(component.get("v.creditStatusPoller"));
                window.clearTimeout(component.get("v.creditStatusTimeoutID"));
            }
        });
        $A.enqueueAction(action);
    },

    checkCreditResponse : function(component, helper, returnValue) {
        var lead = component.get("v.lead");
        if (returnValue.sssCreditQualification === "Ready for Credit Check") {
            // Do not do anything, credit check is not done yet
        } else if (
            returnValue.sssCreditQualification === "Qualified" ||
            returnValue.sssCreditQualification === "Unqualified") {
            lead.Status = returnValue.sssCreditQualification;
            if (returnValue.sssCreditQualification === "Qualified") {
                if (returnValue.srecProduct != null && returnValue.smartProduct != null) {
                    component.set("v.showProgramPicklist", true);
                    component.set("v.srecProduct", returnValue.srecProduct);
                    component.set("v.smartProduct", returnValue.smartProduct);
                }
                if (returnValue.srecProduct != null && returnValue.smartProduct == null) {
                    component.set("v.showProgramPicklist", false);
                    component.set("v.lead.Product__c", returnValue.srecProduct.Id);
                }
                if (!returnValue.srecProduct == null && returnValue.smartProduct != null) {
                    component.set("v.showProgramPicklist", false);
                    component.set("v.lead.Product__c", returnValue.smartProduct.Id);
                }
            }
            component.set("v.creditChecked", true);
            component.set("v.lead", lead);
            $A.util.addClass(component.find("passedCreditText"), 'tada');
            helper.saveSObject(component, lead.Id, "Lead", null, null, lead);
            helper.handleCreditCheckResponse(component, helper);
        } else {
            component.set("v.creditStatusErrorText", returnValue.sssCreditQualification);
            helper.handleCreditCheckResponse(component, helper, "creditResultError");
        }
    },

    copyCreditFromPrevious : function(component, event, helper, secondaryLead) {
        window.setTimeout(function() {
            component.set("v.page", "CreditCheckResult");
        }, 3000);
        var lead = component.get("v.lead");
        helper.saveSObject(component, lead.Id, "Lead", null, null, lead);

        var actionFindPCR = component.get("c.checkForAlreadyRunCredit");
        actionFindPCR.setParams({"secondLead" : secondaryLead});
        actionFindPCR.setCallback(this, function(resp) {
            if (resp.getState() === "SUCCESS") {
                helper.checkCreditResponse(component, helper, resp.getReturnValue());
            } else {
                helper.logError("CSAPCreditCheckHelper", "copyCreditFromPrevious", resp.getError(), secondaryLead);
            }
        });
        $A.enqueueAction(actionFindPCR);
    },

    handleCreditCheckResponse : function(component, helper, divToShow) {
        $A.util.addClass(component.find("creditStatus"), "noDisplay");
        if (divToShow) {
            $A.util.removeClass(component.find(divToShow), "noDisplay");
        }
        window.clearInterval(component.get("v.creditStatusPoller"));
        window.clearTimeout(component.get("v.creditStatusTimeoutID"));
    },
})