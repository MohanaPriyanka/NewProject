({
    getLead : function(component) {
        // in the context of Promise, 'this' is not the helper.
        var ltg = this;
        return new Promise(function(resolve, reject) {
            var action = component.get("c.getLead");
            action.setParams({"leadId" : component.get("v.leadId")});
            action.setCallback(this,function(resp) {
                if (resp.getState() === 'SUCCESS') {
                    var leadWithAttachments = resp.getReturnValue();
                    var lead = leadWithAttachments.lead;
                    component.set("v.lead", lead);
                    if (lead.Manual_Credit_Decline__c) {
                        component.set("v.declineMainButtonLabel", "Main Applicant Adverse Notice Sent");
                    } else {
                        component.set("v.declineMainButtonLabel", "Decline Main Applicant");
                    }
                    if (lead.Co_App_Manual_Credit_Decline__c) {
                        component.set("v.declineCoAppButtonLabel", "Co-Applicant Adverse Notice Sent");
                    } else {
                        component.set("v.declineCoAppButtonLabel", "Decline Co-Applicant");
                    }
                    
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
                    resolve(ltg);
                } else {
                    var appEvent = $A.get("e.c:ApexCallbackError");
                    appEvent.setParams({"className" : "LoanUnderwritingController",
                                        "methodName" : "doInit",
                                        "errors" : resp.getError()});
                    appEvent.fire();
                    reject(resp);
                }
            });
            $A.enqueueAction(action);
        });
    },

    calculateApplicationIncome : function(component) {
        var lead = component.get("v.lead");
        var mainPCR = lead.Personal_Credit_Report__r;
        var coAppPCR = lead.Personal_Credit_Report_Co_Applicant__r;
        var mainIncome = 0, coAppIncome = 0;

        if (lead.Personal_Credit_Report__r.Adjusted_Income__c) {
            mainIncome = lead.Personal_Credit_Report__r.Adjusted_Income__c;
        } else {
            mainIncome = (lead.Annual_Income_Currency__c || 0);
        }

        if (component.get("v.hasCoApp")) {
            if (lead.Personal_Credit_Report_Co_Applicant__r.Adjusted_Income__c) {
                coAppIncome = lead.Personal_Credit_Report_Co_Applicant__r.Adjusted_Income__c;
            } else {
                coAppIncome = (lead.Co_Applicant_Income__c || 0);
            }
        }
        component.set("v.combinedIncome", mainIncome + coAppIncome);
    },

    calculateApplicationDTI : function(component) {
        var lead = component.get("v.lead");
        var mainPCR = lead.Personal_Credit_Report__r;
        var coAppPCR = lead.Personal_Credit_Report_Co_Applicant__r;

        var mainIncome=0, mainDebt=0, coAppIncome=0, coAppDebt=0;
        if (mainPCR.Adjusted_Income__c != null) {
            mainIncome = mainPCR.Adjusted_Income__c/12;
        } else {
            mainIncome = lead.Annual_Income_Currency__c/12;
        }
        mainDebt = mainPCR.Adjusted_Monthly_Personal_Debt__c;

        if (coAppPCR) {
            if (coAppPCR.Adjusted_Income__c != null) {
                coAppIncome = coAppPCR.Adjusted_Income__c/12;
            } else {
                coAppIncome = lead.Co_Applicant_Income__c/12;
            }
            coAppDebt = coAppPCR.Adjusted_Monthly_Personal_Debt__c;
        }
        
        var dti = 100 * (mainDebt + coAppDebt) / (mainIncome + coAppIncome);
        if (mainIncome + coAppIncome > 0) {
            component.set("v.bestDTI", 100 * (mainDebt + coAppDebt) / (mainIncome + coAppIncome));
        } else {
            component.set("v.bestDTI", null);
        }            
    },
})
