({
    doInit : function(component, event, helper) {
        var actionDetail = component.get("c.getFifthDetail");
        actionDetail.setParams({"tuScoreFactor" : component.get("v.pcr.LASERCA__TransUnion_Score_Factor__c")});
        actionDetail.setCallback(this, function(resp) {
            if (resp.getState() === 'SUCCESS') {
                component.set("v.detailFive", resp.getReturnValue());
            } else {
                var appEvent = $A.get("e.c:ApexCallbackError");
                appEvent.setParams({"className" : "LoanUnderwritingApplicantCreditController",
                                    "methodName" : "doInitDetail",
                                    "errors" : resp.getError()});
                appEvent.fire();
            }
        });

        var actionCode = component.get("c.getFifthCode");
        actionCode.setParams({"tuScoreFactor" : component.get("v.pcr.LASERCA__TransUnion_Score_Factor__c")});
        actionCode.setCallback(this, function(resp) {
            if (resp.getState() === 'SUCCESS') {
                component.set("v.codeFive", resp.getReturnValue());
            } else {
                var appEvent = $A.get("e.c:ApexCallbackError");
                appEvent.setParams({"className" : "LoanUnderwritingApplicantCreditController",
                                    "methodName" : "doInitCode",
                                    "errors" : resp.getError()});
                appEvent.fire();
            }
        });

        $A.enqueueAction(actionDetail);
        $A.enqueueAction(actionCode);
    },

    openModal: function(component, event, helper) {
        component.set("v.isOpen", true);
        helper.getPicklistOptions(component, 
                                  'LASERCA__Personal_Credit_Report__c', 
                                  'Adverse_Credit_Notice_1__c', 
                                  component.find("AdverseCreditNotice"));
        var objectName = event.target.dataset.objectname;
        var fieldName = event.target.dataset.fieldname;
        var lead = component.get("v.lead");
        component.set("v.adverseObject", objectName);
        component.set("v.adverseField", fieldName);
        component.set("v.adverseValue", lead[objectName][fieldName]);
    },

    closeModal: function(component, event, helper) {
        component.set("v.isOpen", false);
    },
    
    closeAndSaveModal: function(component, event, helper) {
        var lead = component.get("v.lead");
        var objectName = component.get("v.adverseObject");
        var fieldName = component.get("v.adverseField");
        var adverseValue = component.get("v.adverseValue");
        helper.saveSObject(component,
                           lead[objectName].Id,
                           'LASERCA__Personal_Credit_Report__c',
                           fieldName,
                           adverseValue);
        lead[objectName][fieldName]=adverseValue;
        component.set("v.lead", lead);
        component.set("v.isOpen", false);
    },

    updateCreditDecline : function(component, event, helper) {
        var srcElement = event.srcElement;
        var lead = component.get("v.lead");
        helper.saveSObject(component,
                           lead.Id,
                           'Lead',
                           srcElement.name,
                           srcElement.checked);
        
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
                    alert("Adverse Credit Notice has been sent to the Main Applicant.");
                    component.set("v.lead.Manual_Credit_Decline__c", "true");
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
                    component.set("v.lead.Co_App_Manual_Credit_Decline__c", "true");
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
})