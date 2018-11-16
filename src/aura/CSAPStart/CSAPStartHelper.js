({
    login : function(component, event, helper) {
        var promise = helper.getLeadRecord(component, event, helper);
        promise.then($A.getCallback(function resolve(retVal) {
            var lead = retVal;
            if(lead != null){
                if (lead.CSAP_Stage__c) {
                    component.set("v.page", "");
                    helper.raiseNavEvent("COMPLETED", {"stageName": lead.CSAP_Stage__c, "lead": lead});
                }else{
                    component.set("v.lead", lead);
                    helper.finishStage(component, event, helper);
                }
            }else{
                alert("Incorrect email address. Please verify your email address.");
            }
        }));
    },
    getLeadRecord : function(component, event, helper) {
        return new Promise(function(resolve, reject) {
            var action = component.get("c.getLead");
            action.setParams({
                "leadId": component.get("v.leadId"),
                "email" : component.get("v.leadEmail")
            });
            action.setCallback(this, function(resp) {
                if (resp.getState() === "SUCCESS") {
                    var retVal = resp.getReturnValue();
                    resolve(retVal);
                } else if (resp.getState() === "ERROR") {
                    var appEvent = $A.get("e.c:ApexCallbackError");
                    appEvent.setParams({"className" : "CSAPStartHelper",
                                        "methodName" : "getLeadRecord",
                                        "errors" : resp.getError(),
                                        "developerInfo" : component.get("v.leadId")});
                    appEvent.fire();
                    reject(resp.getError());
                } else {
                    reject(Error("Unknown error"));
                }
            });
            $A.enqueueAction(action);
        });
    },
})