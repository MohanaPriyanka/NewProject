({
    initHelper : function(component, event) {
        return new Promise(function(resolve, reject) {
            var pcrId = component.get("v.pcr").Id;

            var action = component.get("c.getPCRDebt");
            action.setParams({"pcrId" : pcrId});
            action.setCallback(this,function(resp) {
                if (resp.getState() == 'SUCCESS') {
                    var pcr = resp.getReturnValue();
                    component.set("v.pcr.Adjusted_Monthly_Personal_Debt__c", pcr.Adjusted_Monthly_Personal_Debt__c);
                    component.set("v.adjustedDebt", pcr.Adjusted_Monthly_Personal_Debt__c);
                    component.set("v.tradeAccounts", pcr.LASERCA__Trade_Accounts__r);
                    resolve(pcr);
                } else {
                    $A.log("Errors", resp.getError());
                    var appEvent = $A.get("e.c:ApexCallbackError");
                    appEvent.setParams({"className" : "LoanUnderwritingApplicantDebtController",
                                        "methodName" : "doInit",
                                        "errors" : resp.getError()});
                    appEvent.fire();
                    reject(Error(resp.getError()));
                }
            });
            $A.enqueueAction(action);
        });
    },
})
