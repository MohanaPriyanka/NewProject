({
    doInit : function(component, event, helper) {
        var action = component.get("c.getLoanInfo");
        action.setParams({"leadId" : component.get("v.leadId")});
        action.setCallback(this,function(resp){
            if(resp.getState() == 'SUCCESS') {
                component.set("v.loanInfo", resp.getReturnValue());
            } else {
                $A.log("Errors", resp.getError());
                var appEvent = $A.get("e.c:ApexCallbackError");
                appEvent.setParams({"className" : "LoanUnderwritingController",
                    "methodName" : "doInit",
                    "errors" : resp.getError()});
                appEvent.fire();
                $A.log("Errors", resp.getError());
            }
        });
        $A.enqueueAction(action);
    }
})
