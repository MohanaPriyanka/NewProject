({
    doInit : function(component, event, helper) {
        var action = component.get("c.getLead");
        action.setParams({"leadId" : component.get("v.leadId")});
        action.setCallback(this,function(resp){
            if(resp.getState() == 'SUCCESS') {
                component.set("v.lead", resp.getReturnValue());
            } else {
                $A.log("Errors", resp.getError());
                var appEvent = $A.get("e.c:ApexCallbackError");
                appEvent.setParams({"className" : "LoanUnderwritingController",
                                    "methodName" : "doInit",
                                    "errors" : resp.getError()});
                appEvent.fire();
            }
        });
        $A.enqueueAction(action);

        var arsAction = component.get("c.getAvidiaReviewStatus");
        var inputsel = component.find("AvidiaReviewStatus");
        var opts=[];
        arsAction.setCallback(this, function(a) {
            for(var i=0;i< a.getReturnValue().length;i++){
                opts.push({"class": "optionClass", label: a.getReturnValue()[i], value: a.getReturnValue()[i]});
            }
            inputsel.set("v.options", opts);

        });
        $A.enqueueAction(arsAction); 
    },

    updateReviewStatus : function(component, event) {
        var lead = component.get("v.lead");
        var pcr = new Object();
        pcr = {'sobjectType': 'LASERCA__Personal_Credit_Report__c',
               'Id': lead.Personal_Credit_Report__r.Id,
               'Avidia_Review_Status__c': event.getSource().get("v.value")};
        var action = component.get("c.updatePCR");
        action.setParams({"pcr": pcr});
        action.setCallback(this, function(resp) {
            if (resp.getState() == "SUCCESS") {
                // Couldn't get this to work :(
                component.set("v.pageMessageText", "Update saved!");
                console.log(component.get("v.pageMessageText"));
                var pageMessage = component.find("pageMessage");
                $A.util.addClass(pageMessage, "slds-transition-hide");
            } else {
                var appEvent = $A.get("e.c:ApexCallbackError");
                appEvent.setParams({"className" : "LoanUnderwritingController",
                                    "methodName" : "updateReviewStatus",
                                    "errors" : resp.getError()});
                appEvent.fire();
            }                
        });
        component.set("v.pageMessageText", "Saving...");
        console.log(component.get("v.pageMessageText"));
        var pageMessage = component.find("pageMessage");
        $A.util.removeClass(pageMessage, 'slds-transition-hide');

        $A.enqueueAction(action);
    }
})
