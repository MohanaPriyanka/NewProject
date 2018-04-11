({
    handleNavEvent : function(component, event, helper) {
        helper.handleNavEvent(component, event, helper, "SSNPage");
        
        if (component.get("v.abbrevStates") && component.get("v.abbrevStates").length === 0) {
            helper.getUSStates(component, "v.abbrevStates", true);
        }
    },
    goToSSNPage : function(component, event, helper) {
        component.set("v.page", "SSNPage");
    },
    goToPersonalInfoConfirmation : function(component, event, helper) {
        if(helper.validatePageFields(component)){
            var lead = component.get("v.lead");
            helper.saveSObject(component, lead.Id, "Lead", null, null, lead);
            component.set("v.page", "PersonalInfoConfirmation");
        }
    },
    checkCredit : function(component, event, helper) {
        if(helper.validatePageFields(component)){
            component.set("v.page", "CreditCheckResult");
            var lead = component.get("v.lead");
            helper.saveSObject(component, lead.Id, "Lead", null, null, lead);
            component.set('v.loading', true);
            // helper.startSpinner(component, "creditSpinner");
            // component.set("v.creditStatusText", "Pulling credit report...");
            // $A.util.removeClass(component.find("creditStatus"), "noDisplay");
            var action = component.get("c.pullCreditStatus");
            action.setParams({"lead" : lead});
            action.setCallback(this, function(resp) {
                if(resp.getState() == "SUCCESS") {
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

                    // checkCreditStatus should clearInterval if it finds a Credit Report Log or
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
    finishStage : function(component, event, helper) {
        helper.finishStage(component, event, helper);
    },
})
