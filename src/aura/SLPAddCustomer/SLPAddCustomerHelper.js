({
    startSpinner : function(component, name) {
        var spinner = component.find(name);
        var evt = spinner.get("e.toggle");
        evt.setParams({ isVisible : true });
        evt.fire();
    },
    stopSpinner : function(component, spinnerName) {
        var spinner = component.find(spinnerName);
        var evt = spinner.get("e.toggle");
        evt.setParams({ isVisible : false });
        evt.fire();
    },
    handleCreditCheckResponse : function(component, divToShow) {
        $A.util.addClass(component.find("creditStatus"), 'noDisplay');
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
                        component.set("v.creditStatusErrorText", resp.getReturnValue());
                        helper.handleCreditCheckResponse(component, 'creditResultError');
                    }
                } else {
                    var appEvent = $A.get("e.c:ApexCallbackError");
                    appEvent.setParams({"className" : "SLPAddCustomerHelper",
                                "methodName" : "checkCreditStatus",
                                "errors" : resp.getError()});
                    appEvent.fire();
                    window.clearInterval(component.get("v.creditStatusPoller"));
                }
            });
        $A.enqueueAction(action);
    }
})
