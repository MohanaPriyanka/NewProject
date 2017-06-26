({
    doInit : function(component, event, helper) {
        helper.getLead(component);
        helper.getReviewStatusOptions(component);
        helper.getSolarLoanStatusOptions(component);
        helper.getCreditNoticeOptions(component);
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
        console.log("event.srcElement.fieldname: " + event.target.dataset.fieldname);
        component.set("v.adverseField", event.target.dataset.fieldname);
    },
    
    closeModel: function(component, event, helper) {
        alert(component.get("v.adverseField"));
        component.set("v.isOpen", false);
    },    
})
