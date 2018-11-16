({
    doInit : function(component, event, helper) {
        var leadPromise = helper.getLead(component);
        leadPromise.then(
            $A.getCallback(function resolve(helper) {
                if (component.get("v.lead.Personal_Credit_Report__r")) {
                    helper.calculateApplicationIncome(component);
                    helper.calculateApplicationDTI(component);
                }
                helper.getPicklistOptions(component,
                                          'LASERCA__Personal_Credit_Report__c', 
                                          'Avidia_Review_Status__c',
                                          component.find("AvidiaReviewStatus"));
                if (component.get('v.lead.Change_Order_Status__c') != null) {
                    helper.getPicklistOptions(component,
                        'Lead',
                        'Change_Order_Status__c',
                        component.find("ChangeOrderStatus"));
                }
            }));
    },

    updateReviewStatus : function(component, event, helper) {
        var lead = component.get("v.lead");
        helper.saveSObject(component,
                           lead.Personal_Credit_Report__r.Id,
                           'LASERCA__Personal_Credit_Report__c',
                           'Avidia_Review_Status__c',
                           event.getSource().get("v.value"));
        if (component.get("v.hasCoApp")) {
            helper.saveSObject(component,
                               lead.Personal_Credit_Report_Co_Applicant__r.Id,
                               'LASERCA__Personal_Credit_Report__c',
                               'Avidia_Review_Status__c',
                               event.getSource().get("v.value"));
        }
        if (event.getSource().get("v.value") === 'Reviewed - Approved') {
            let action = component.get('c.approveLead');
            action.setParams({'leadId': lead.Id});
            action.setCallback(this, function(resp) {
                if (resp.getState() !== 'SUCCESS') {
                    helper.logError('LoanUnderwritingController', 'updateReviewStatus', 'Could not approve lead', resp);
                }
            });
            $A.enqueueAction(action);
        }
    },

    updateChangeOrderStatus : function(component, event, helper) {
        var lead = component.get("v.lead");
        if (lead.Change_Order_Status__c === 'Reviewed - Accepted' ||
            lead.Change_Order_Status__c === 'Reviewed - Rejected') {
            helper.saveSObject(component,
                lead.Id,
                'Lead',
                'Change_Order_Status__c',
                event.getSource().get("v.value"));
        } else {
            alert('Not saved: only used Reviewed - Accepted or Reviewed - Rejected');
            component.set('v.lead.Change_Order_Status__c', 'Customer Authorized');
        }
    },

    handleEvent : function(component, event, helper) {
        var leadPromise = helper.getLead(component);
        leadPromise.then(
            $A.getCallback(function resolve(helper) {
                helper.calculateApplicationIncome(component);
                helper.calculateApplicationDTI(component);
            }));
    },

    updateAdjustedDTI : function(component, event, helper) {
        var lead = component.get("v.lead");
        var savePromise = helper.saveSObject(component,
                                             lead.Personal_Credit_Report__r.Id,
                                             'LASERCA__Personal_Credit_Report__c',
                                             'Adjusted_DTI__c',
                                             lead.Personal_Credit_Report__r.Adjusted_DTI__c);
        savePromise.then(
            $A.getCallback(function resolve(value) {
                var debtEvent = $A.get("e.c:LoanUnderwritingDebtAdjustment");
                debtEvent.setParams({"pcrId" : lead.Personal_Credit_Report__r.Id});
                debtEvent.fire();
            })
        );
        if (component.get("v.hasCoApp")) {
            helper.saveSObject(component,
                               lead.Personal_Credit_Report_Co_Applicant__r.Id,
                               'LASERCA__Personal_Credit_Report__c',
                               'Adjusted_DTI__c',
                               lead.Personal_Credit_Report__r.Adjusted_DTI__c);
        }
    },

    saveDTINotes : function(component, event, helper) {
        var lead = component.get("v.lead");
        helper.saveSObject(component,
                           lead.Personal_Credit_Report__r.Id,
                           'LASERCA__Personal_Credit_Report__c',
                           'Adjusted_DTI_Notes__c',
                           lead.Personal_Credit_Report__r.Adjusted_DTI_Notes__c);
    },

    waiting : function(component, event, helper) {
        component.set("v.waiting", true);
    },

    doneWaiting : function(component, event, helper) {
        component.set("v.waiting", false);
    },

    handleFilesChange : function(component, event, helper) {
        var files = event.getSource().get("v.files")
        var parentId = component.get('v.lead.ConvertedContactId')?component.get('v.lead.ConvertedContactId'):component.get("v.lead.Id");
        helper.uploadFiles(component, files, parentId, helper.getLead);
    },
       
    takeSnapshot : function(component, event, helper) {
        var action = component.get("c.renderPDFAndAttach");
        action.setParams({"leadId" : component.get("v.leadId")});
        action.setCallback(this,function(resp) {
            if (resp.getState() === 'SUCCESS') {
                helper.getLead(component);
            } else {
                console.log(resp.getError());
            }
        });
        $A.enqueueAction(action);
    },

    openInfoRequestModal : function(component, event, helper) {
        component.set("v.showInfoRequestModal", true);
    },

})
