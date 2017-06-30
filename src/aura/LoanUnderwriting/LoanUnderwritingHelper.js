({
    getLead : function(component) {
        var action = component.get("c.getLead");
        action.setParams({"leadId" : component.get("v.leadId")});
        action.setCallback(this,function(resp){
            if(resp.getState() == 'SUCCESS') {
                var leadWithAttachments = resp.getReturnValue();
                var lead = leadWithAttachments.lead;
                component.set("v.lead", lead);
                if (lead.Personal_Credit_Report_Co_Applicant__r &&
                    lead.Personal_Credit_Report__r) {
                    component.set("v.coAppPCRAttachment", leadWithAttachments.coAppPCRAttachment);
                    component.set("v.mainPCRAttachment", leadWithAttachments.mainPCRAttachment);
                    component.set("v.hasCoApp", true);
                    component.set("v.bestFICO",
                                  Math.max((lead.Personal_Credit_Report_Co_Applicant__r.LASERCA__Credit_Score_TransUnion__c || 0),
                                           (lead.Personal_Credit_Report__r.LASERCA__Credit_Score_TransUnion__c || 0)));
                } else if (lead.Personal_Credit_Report__r) {
                    component.set("v.mainPCRAttachment", leadWithAttachments.mainPCRAttachment);
                    component.set("v.bestFICO",
                                  (lead.Personal_Credit_Report__r.LASERCA__Credit_Score_TransUnion__c || 0));
                }
                component.set("v.combinedIncome",
                              (lead.Annual_Income_Currency__c || 0) + (lead.Co_Applicant_Income__c || 0));

                this.calculateApplicationDTI(component);
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

    calculateApplicationDTI : function(component) {
        var lead = component.get("v.lead");
        var mainPCR = lead.Personal_Credit_Report__r;
        var coAppPCR = lead.Personal_Credit_Report_Co_Applicant__r;

        if (component.get("v.hasCoApp")) {
            var mainIncome, mainDebt, coAppIncome, coAppDebt;
            if (mainPCR.Adjusted_Income__c) {
                mainIncome = mainPCR.Adjusted_Income__c/12;
            } else {
                mainIncome = mainPCR.Annual_Income_Currency__c/12;
            }

            if (coAppPCR.Adjusted_Income__c) {
                coAppIncome = coAppPCR.Adjusted_Income__c/12;
            } else {
                coAppIncome = lead.Co_Applicant_Income__c;
            }

            mainDebt = mainPCR.LASERCA__Sum_of_monthly_Personal_Debt__c;
            coAppDebt = coAppPCR.LASERCA__Sum_of_monthly_Personal_Debt__c;

            component.set("v.bestDTI", 100 * (mainDebt + coAppDebt) / (mainIncome + coAppIncome));

        } else {
            if (mainPCR.Adjusted_DTI__c) {
                component.set("v.bestDTI", mainPCR.Adjusted_DTI__c);
            } else {
                component.set("v.bestDTI", Math.max(mainPCR.DTI_After__c, mainPCR.DTI_Before__c));
            }
        }
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
})
