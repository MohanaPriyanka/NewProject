({
    getLead : function(component) {
        var action = component.get("c.getLead");
        action.setParams({"leadId" : component.get("v.leadId")});
        action.setCallback(this,function(resp){
            if(resp.getState() == 'SUCCESS') {
                var lead = resp.getReturnValue();
                component.set("v.lead", lead);
                component.set("v.bestFICO",
                              Math.max(lead.Personal_Credit_Report_Co_Applicant__r.LASERCA__Credit_Score_TransUnion__c,
                                       lead.Personal_Credit_Report__r.LASERCA__Credit_Score_TransUnion__c));
                component.set("v.combinedIncome",
                              lead.Annual_Income_Currency__c + lead.Co_Applicant_Income__c);
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

    getSolarLoanStatusOptions : function(component) {
        var slApprovalAction = component.get("c.getSLApprovalStatus");
        var slasInputSel = component.find("SolarLoanApprovalStatus");
        var slasOpts=[];
        slApprovalAction.setCallback(this, function(a) {
            for(var i=0;i< a.getReturnValue().length;i++){
                slasOpts.push({"class": "optionClass", label: a.getReturnValue()[i], value: a.getReturnValue()[i]});
            }
            slasInputSel.set("v.options", slasOpts);

        });
        $A.enqueueAction(slApprovalAction);
    },
    
    getCreditNoticeOptions : function(component) {
        var arsAction = component.get("c.getCreditNoticeOptions");
        var input1 = component.find("CoAppAdverseCreditNotice1");
        var opts=[];
        arsAction.setCallback(this, function(a) {
            for(var i=0;i< a.getReturnValue().length;i++){
                opts.push({"class": "optionClass", label: a.getReturnValue()[i], value: a.getReturnValue()[i]});
            }
            input1.set("v.options", opts);

        });
        $A.enqueueAction(arsAction); 
    },

})
