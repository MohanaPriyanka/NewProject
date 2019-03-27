({
    handleNavEvent : function(component, event, helper) {
        if (event.getParam('options') && event.getParam('options').pageName) {
            helper.handleNavEvent(component, event, helper, event.getParam('options').pageName);
            if (event.getParam('options').pageName == 'CreditAlreadyRun') {
                var lead = component.get("v.lead");
                helper.copyCreditFromPrevious(component, event, helper, lead);
            }

        } else {
            helper.handleNavEvent(component, event, helper, "CreditCheckResult");
        }

        if (component.get("v.page") === 'CreditCheckResult' && event.getParam("eventType")=== "INITIATED"){
            var a = component.get("c.checkCredit");
            $A.enqueueAction(a);
        }
        
        if (component.get("v.abbrevStates") && component.get("v.abbrevStates").length === 0) {
            helper.getUSStates(component, "v.abbrevStates", true);
        }
    },

    checkCredit : function(component, event, helper) {
        if (helper.validatePageFields(component)) {
            component.set("v.page", "CreditCheckResult");
            var lead = component.get("v.lead");
            helper.saveSObject(component, lead.Id, "Lead", null, null, lead);
            component.set('v.loading', true);

            var action = component.get("c.pullCreditStatus");
            action.setParams({"lead" : lead});
            action.setCallback(this, function(resp) {
                if (resp.getState() == "SUCCESS") {
                    window.setTimeout(function() {
                        $A.util.removeClass(component.find("creditStatus"), "noDisplay");
                        component.set("v.creditStatusText", "Sending request to TransUnion...");
                    }, 3000);
                    window.setTimeout(function() {
                        component.set("v.creditStatusText", "Waiting for TransUnion to process...");
                    }, 6000);
                    window.setTimeout(function() {
                        component.set("v.creditStatusText", "Checking for results...");
                    }, 9000);
                    window.setTimeout(function() {
                        var creditPollerInterval = window.setInterval($A.getCallback(helper.checkCreditStatus),
                            2000, component, helper);
                        component.set("v.creditStatusPoller", creditPollerInterval);
                    }, 10000);

                    // checkCreditStatus should clearInterval it finds a Credit Report Log or
                    // a Credit Report on the Lead, but just in case, stop checking after a minute
                    const timeoutInterval = window.setTimeout(function() {
                        component.set("v.creditStatusText",
                            "Credit request timed out, please wait a minute, refresh the page, and log in again");
                        window.clearInterval(component.get("v.creditStatusPoller"));
                    }, component.get("v.creditStatusTimeout"));
                    component.set("v.creditStatusTimeoutID", timeoutInterval);
                } else {
                    $A.util.removeClass(component.find("SubmitButton"), "noDisplay");

                    helper.logError("CSAPCreditCheckController", "checkCredit",
                        "There was an issue running credit, but has been logged. Please call Customer Care at the number below for assistance.",
                        resp.getError());
                }
            });
            $A.enqueueAction(action);
        }
    },
    goToPersonalInfoConfirmation : function(component, event, helper) {
        var errorMessage = helper.checkBirthDate(component, event, helper);
        if (errorMessage != ""){
            component.set("v.ShowDateError", true);
        } else {
            if (helper.validatePageFields(component)) {
                var lead = component.get("v.lead");
                helper.saveSObject(component, lead.Id, "Lead", null, null, lead);
                component.set("v.page", "PersonalInfoConfirmation");
            }
        }
    },

    finishStage : function(component, event, helper) {
        var lead = component.get("v.lead");
        helper.saveSObject(component, lead.Id, 'Lead', 'Product__c', lead.Product__c);
        component.set('v.programType', 'SREC');
        if (lead.Status =="Qualified" && component.get("v.creditStatusErrorText") == undefined) {
            helper.finishStage(component, event, helper);
        } else {
            component.set("v.page", "Unqualified");
        }
    },
})