({
    doInit : function(component, event, helper) {
        helper.getLead(component);
        helper.getReviewStatusOptions(component);
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
    
    openModel: function(component, event, helper) {
        component.set("v.isOpen", true);
        helper.getCreditNoticeOptions(component);
        var objectName = event.target.dataset.objectname;
        var fieldName = event.target.dataset.fieldname;
        var lead = component.get("v.lead");
        component.set("v.adverseObject", objectName);
        component.set("v.adverseField", fieldName);
        component.set("v.adverseValue", lead[objectName][fieldName]);
    },

    closeModel: function(component, event, helper) {
        component.set("v.isOpen", false);
    },
    
    closeAndSaveModel: function(component, event, helper) {
        var lead = component.get("v.lead");
        var objectName = component.get("v.adverseObject");
        var fieldName = component.get("v.adverseField");
        var adverseValue = component.get("v.adverseValue");
        helper.savePCR(component,
                       lead[objectName].Id,
                       fieldName,
                       adverseValue);
        lead[objectName][fieldName]=adverseValue;
        component.set("v.lead", lead);
        component.set("v.isOpen", false);
    },    
})
