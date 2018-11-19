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
                    component.set('v.contactAttachments', leadWithAttachments.contactAttachments);
                    var monthlyPayment = lead.Monthly_Payment__c;
                    if (lead.Product__r &&
                        lead.Product__r.DTI_After_Rate_Gross_Up__c) {
                        monthlyPayment =
                            (lead.Loan_Principal__c*(lead.Product__r.Loan_Interest_Rate__c+lead.Product__r.DTI_After_Rate_Gross_Up__c)/100/12) /
                            (1-Math.pow((1+(lead.Product__r.Loan_Interest_Rate__c+lead.Product__r.DTI_After_Rate_Gross_Up__c)/100/12),(-1*lead.Product__r.Loan_Term__c)));
                    }
                    component.set("v.monthlyPayment", monthlyPayment);
                    if (lead.Personal_Credit_Report_Co_Applicant__r &&
                        lead.Personal_Credit_Report__r) {
                        component.set("v.coAppPCRAttachment", leadWithAttachments.coAppPCRAttachment);
                        component.set("v.mainPCRAttachment", leadWithAttachments.mainPCRAttachment);
                        component.set("v.hasCoApp", true);
                        component.set("v.bestFICO",
                                      Math.max((lead.Personal_Credit_Report_Co_Applicant__r.LASERCA__Credit_Score_TransUnion__c || 0),
                                               (lead.Personal_Credit_Report__r.LASERCA__Credit_Score_TransUnion__c || 0)));
                        resolve(ltg);
                    } else if (lead.Personal_Credit_Report__r) {
                        component.set("v.mainPCRAttachment", leadWithAttachments.mainPCRAttachment);
                        component.set("v.bestFICO",
                                      (lead.Personal_Credit_Report__r.LASERCA__Credit_Score_TransUnion__c || 0));
                        resolve(ltg);
                    } else {
                        var appEvent = $A.get("e.c:ApexCallbackError");
                        appEvent.setParams({"className" : "LoanUnderwritingController",
                            "methodName" : "doInit",
                            "errors" : 'This lead did not have a Credit Report on it. ' +
                                       'Perhaps credit was frozen, and a blank credit report was returned which prevented it from being processed. ' +
                                       'Investigate this application from the Lead page before trying again.'});
                        appEvent.fire();
                        reject(resp);
                    }
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

        if (lead.Personal_Credit_Report__r.Adjusted_Income__c != null) {
            mainIncome = lead.Personal_Credit_Report__r.Adjusted_Income__c;
        } else {
            mainIncome = (lead.Annual_Income_Currency__c || 0);
        }

        if (component.get("v.hasCoApp")) {
            if (lead.Personal_Credit_Report_Co_Applicant__r.Adjusted_Income__c != null) {
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
        
        var loanPayment = component.get('v.monthlyPayment');
        if (mainPCR.Adjusted_DTI__c != null) {
            component.set("v.bestDTI", mainPCR.Adjusted_DTI__c);
        } else {
            if (coAppPCR) {
                var mainIncome=0, mainDebt=0, coAppIncome=0, coAppDebt=0;
                if (mainPCR.Adjusted_Income__c != null) {
                    mainIncome = mainPCR.Adjusted_Income__c/12;
                } else {
                    mainIncome = lead.Annual_Income_Currency__c/12;
                }
                mainDebt = mainPCR.Adjusted_Monthly_Personal_Debt__c;

                if (coAppPCR.Adjusted_Income__c != null) {
                    coAppIncome = coAppPCR.Adjusted_Income__c/12;
                } else {
                    coAppIncome = lead.Co_Applicant_Income__c/12;
                }
                coAppDebt = coAppPCR.Adjusted_Monthly_Personal_Debt__c;

                if (mainIncome + coAppIncome > 0) {
                    component.set("v.bestDTI", 100 * (mainDebt + coAppDebt + loanPayment) / (mainIncome + coAppIncome));
                } else {
                    component.set("v.bestDTI", null);
                }

            } else {
                if (mainPCR.Adjusted_Income__c != null) {
                    mainIncome = mainPCR.Adjusted_Income__c/12;
                } else {
                    mainIncome = lead.Annual_Income_Currency__c/12;
                }

                mainDebt = mainPCR.Adjusted_Monthly_Personal_Debt__c;

                if (mainIncome > 0) {
                    component.set("v.bestDTI", 100 * (mainDebt + loanPayment) / (mainIncome));
                } else {
                    component.set("v.bestDTI", mainPCR.DTI_After__c);
                }
            }
        }
    },
})