({
    doInit : function(component, event, helper) {
        helper.getLead(component);
        helper.getPicklistOptions(component,
                                  'LASERCA__Personal_Credit_Report__c', 
                                  'Avidia_Review_Status__c',
                                  component.find("AvidiaReviewStatus"));
    },

    updateReviewStatus : function(component, event, helper) {
        var lead = component.get("v.lead");
        helper.savePCR(component,
                       lead.Personal_Credit_Report__r.Id,
                       'Avidia_Review_Status__c',
                       event.getSource().get("v.value"));
    },
        
    emailCreditDecline : function(component, event, helper) {
        var lead = component.get("v.lead");
        if (!lead.Personal_Credit_Report__r.Adverse_Credit_Notice_1__c) {
            alert("ADVERSE CREDIT NOTICE NOT SENT - " +
                  "PLEASE PROVIDE CONTENT FOR THE ADVERSE CREDIT NOTICE IN THE PERSONAL CREDIT REPORT");
        } else if(!lead.Personal_Credit_Report__r.LASERCA__Code__c) {
            alert("ADVERSE CREDIT NOTICE NOT SENT - " +
                  "PLEASE MANUALLY ENTER CREDIT DENIAL CODES FROM PDF ATTACHMENT ON CREDIT REPORT");
        } else { 
            var action = component.get("c.updateManualCreditDecline");
            action.setParams({"lead": lead,
                              "coApplicant": false});
            action.setCallback(this, function(resp) {
                if (resp.getState() == "SUCCESS") {
                    helper.getLead(component);
                    alert("Adverse Credit Notice has been sent to the Main Applicant.");
                    component.set("v.declineMainButtonLabel", "Main Applicant Adverse Notice Sent");
                } else {
                    var appEvent = $A.get("e.c:ApexCallbackError");
                    appEvent.setParams({"className" : "LoanUnderwritingController",
                                        "methodName" : "emailCreditDecline",
                                        "errors" : resp.getError()});
                    appEvent.fire();
                }                
            });
            $A.enqueueAction(action);
        }
    },

    emailCoAppCreditDecline : function(component, event, helper) {
        var lead = component.get("v.lead");
        if (!lead.Personal_Credit_Report_Co_Applicant__r.Adverse_Credit_Notice_1__c) {
            alert("ADVERSE CREDIT NOTICE NOT SENT - " +
                  "PLEASE PROVIDE CONTENT FOR THE ADVERSE CREDIT NOTICE IN THE CO-APPLICANT PERSONAL CREDIT REPORT");
        } else if(!lead.Personal_Credit_Report_Co_Applicant__r.LASERCA__Code__c) {
            alert("ADVERSE CREDIT NOTICE NOT SENT - " +
                  "PLEASE MANUALLY ENTER CREDIT DENIAL CODES FROM PDF ATTACHMENT ON CO-APPLICANT CREDIT REPORT");
        } else { 
            var action = component.get("c.updateManualCreditDecline");
            action.setParams({"lead": lead,
                             "coApplicant": true});
            action.setCallback(this, function(resp) {
                if (resp.getState() == "SUCCESS") {
                    alert("Adverse Credit Notice has been sent to the Co-Applicant.");
                    helper.getLead(component);
                    component.set("v.declineCoAppButtonLabel", "Co-Applicant Adverse Notice Sent");
                } else {
                    var appEvent = $A.get("e.c:ApexCallbackError");
                    appEvent.setParams({"className" : "LoanUnderwritingController",
                                        "methodName" : "emailCoAppCreditDecline",
                                        "errors" : resp.getError()});
                    appEvent.fire();
                }                
            });
            $A.enqueueAction(action);
        }
    },
    
    handleIncomeAdjustment : function(component, event, helper) {
        var adjustedIncome = event.getParam("adjustedIncome");
        var pcrId = event.getParam("pcrId");
        var lead = component.get("v.lead");

        if (pcrId === lead.Personal_Credit_Report__r.Id) {
            lead.Personal_Credit_Report__r.Adjusted_Income__c = adjustedIncome;
        } else {
            lead.Personal_Credit_Report_Co_Applicant__r.Adjusted_Income__c = adjustedIncome;
        }
        helper.calculateApplicationIncome(component);
        helper.calculateApplicationDTI(component);
    },

    handleDebtAdjustment : function(component, event, helper) {
        var adjustedDebt = event.getParam("adjustedDebt");
        var pcrId = event.getParam("pcrId");
        var lead = component.get("v.lead");

        if (pcrId === lead.Personal_Credit_Report__r.Id) {
            lead.Personal_Credit_Report__r.Adjusted_Monthly_Personal_Debt__c = adjustedDebt;
        } else {
            lead.Personal_Credit_Report_Co_Applicant__r.Adjusted_Monthly_Personal_Debt__c = adjustedDebt;
        }
        helper.calculateApplicationIncome(component);
        helper.calculateApplicationDTI(component);
    }


})
