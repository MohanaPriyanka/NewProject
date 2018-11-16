({
    checkCreditStatus : function(component, helper) {
        var leadId = component.get("v.lead.Id");
        var action = component.get("c.checkLeadCreditIfQualified");
        action.setParams({"leadId" : leadId});
        action.setCallback(this, function(resp) {
            if (resp.getState() === "SUCCESS") {
                helper.checkCreditResponse(component, helper, resp.getReturnValue());
            } else {
                helper.logError("CSAPCreditCheckHelper", "checkCreditStatus", resp.getError(), leadId);
                window.clearInterval(component.get("v.creditStatusPoller"));
                window.clearTimeout(component.get("v.creditStatusTimeoutID"));
            }
        });
        $A.enqueueAction(action);
    },
    checkBirthDate : function(component, event, helper) {
        component.set("v.ShowDateError", false);
        var errorMessage = "";
        var lead = component.get("v.lead");
        errorMessage += helper.getFieldError(component, {
            'fieldValue': lead.LASERCA__Birthdate__c,
            'fieldId': "birthdateElement",
            'errorMessage': "Enter or check Date of Birth (format: 01/01/2000)",
            'fieldType': 'date'
        });
        return errorMessage;
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
                if (returnValue.productList.length === 0){
                    console.log('error');
                } else if (returnValue.productList.length > 1){
                    component.set("v.showProgramPicklist", true);
                    component.set("v.productList", returnValue.productList);
                } else {
                    component.set("v.showProgramPicklist", false);
                    component.set("v.lead.Product__c", returnValue.productList[0].Id);
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