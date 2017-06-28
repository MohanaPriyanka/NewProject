({
    getLead : function(component) {
        var action = component.get("c.getLead");
        action.setParams({"leadId" : component.get("v.leadId")});
        action.setCallback(this,function(resp){
            if(resp.getState() == 'SUCCESS') {
                var lead = resp.getReturnValue();
                component.set("v.lead", lead);
                if (lead.Personal_Credit_Report_Co_Applicant__r &&
                    lead.Personal_Credit_Report__r) {
                    component.set("v.hasCoApp", true);
                    component.set("v.bestFICO",
                                  Math.max((lead.Personal_Credit_Report_Co_Applicant__r.LASERCA__Credit_Score_TransUnion__c || 0),
                                           (lead.Personal_Credit_Report__r.LASERCA__Credit_Score_TransUnion__c || 0)));
                } else if (lead.Personal_Credit_Report__r) {
                    component.set("v.bestFICO",
                                  (lead.Personal_Credit_Report__r.LASERCA__Credit_Score_TransUnion__c || 0));
                }
                component.set("v.combinedIncome",
                              (lead.Annual_Income_Currency__c || 0) + (lead.Co_Applicant_Income__c || 0));
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
    },

    savePCR : function(component, id, field, value) {
        var lead = component.get("v.lead");
        var pcr = new Object();
        pcr = {'sobjectType': 'LASERCA__Personal_Credit_Report__c',
               'Id': id};
        pcr[field] = value;
        var action = component.get("c.updatePCR");
        action.setParams({"pcr": pcr});
        action.setCallback(this, function(resp) {
            if (resp.getState() != "SUCCESS") {
                var appEvent = $A.get("e.c:ApexCallbackError");
                appEvent.setParams({"className" : "LoanUnderwritingController",
                                    "methodName" : "updateReviewStatus",
                                    "errors" : resp.getError()});
                appEvent.fire();
            }
        });
        $A.enqueueAction(action);
        
    },

    getReviewStatusOptions : function(component) {
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

    getCreditNoticeOptions : function(component) {
        var action = component.get("c.getCreditNoticeOptions");
        var input1 = component.find("AdverseCreditNotice");
        var opts=[];
        action.setCallback(this, function(a) {
            for(var i=0;i< a.getReturnValue().length;i++){
                opts.push({"class": "optionClass", label: a.getReturnValue()[i], value: a.getReturnValue()[i]});
            }
            input1.set("v.options", opts);

        });
        $A.enqueueAction(action); 
    },

    getDescendantProp: function(obj, desc) {
        var arr = desc.split(".");
        while(arr.length && (obj = obj[arr.shift()]));
        return obj;
    },    
})
