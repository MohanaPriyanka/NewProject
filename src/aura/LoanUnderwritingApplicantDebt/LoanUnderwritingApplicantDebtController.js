({
    doInit : function(component, event, helper) {
        var pcrId = component.get("v.pcr").Id;

        var action = component.get("c.getPCRDebt");
        action.setParams({"pcrId" : pcrId});
        action.setCallback(this,function(resp) {
            if (resp.getState() == 'SUCCESS') {
                var pcr = resp.getReturnValue();
                console.log(pcr);
                component.set("v.tradeAccounts", pcr.LASERCA__Trade_Accounts__r);
            } else {
                $A.log("Errors", resp.getError());
                var appEvent = $A.get("e.c:ApexCallbackError");
                appEvent.setParams({"className" : "LoanUnderwritingApplicantDebtController",
                                    "methodName" : "doInit",
                                    "errors" : resp.getError()});
                appEvent.fire();
            }
        });
        $A.enqueueAction(action);
    },

    display : function(component, event, helper) {
        console.log('display');
        helper.toggleHelper(component, event);
    },

    displayOut : function(component, event, helper) {
        console.log('displayOut');
        helper.toggleHelper(component, event);
    }    
})
