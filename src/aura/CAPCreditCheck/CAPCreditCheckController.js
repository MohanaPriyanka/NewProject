({
    handleNavEvent : function(component, event, helper) {
        if (!component.get('v.creditStatusTimeout')) {
            var actionGetTimeout = component.get("c.getCreditCheckTimeout");
            actionGetTimeout.setCallback(this,function(resp) {
                if(resp.getState() == 'SUCCESS') {
                    component.set("v.creditStatusTimeout", resp.getReturnValue());
                } else {
                    component.set("v.creditStatusTimeout", 60000);
                }
            });
            $A.enqueueAction(actionGetTimeout);
        }
        
        helper.handleNavEvent(component, event, helper, 'ConfirmBeforePull');
        const lead = component.get('v.lead');
        if (lead && lead.LASERCA__SSN__c) {
            component.set('v.primarySSN', '***-**-'+lead.LASERCA__SSN__c.substr(5,4));
        }
        if (lead && lead.CoApplicant_Contact__r && lead.CoApplicant_Contact__r.LASERCA__Social_Security_Number__c) {
            component.set('v.coAppSSN', '***-**-'+lead.CoApplicant_Contact__r.LASERCA__Social_Security_Number__c.substr(5,4));
        }
        if (lead && lead.Personal_Credit_Report__c) {
            component.set('v.primaryChecked', true);
        }
        if (lead && lead.Personal_Credit_Report_Co_Applicant__c) {
            component.set('v.coAppChecked', true);
        }
    },

    checkCredit : function(component, event, helper) {
        $A.util.addClass(component.find("confirmSubmit"), 'noDisplay');
        helper.startSpinner(component, 'creditSpinner');
        const lead = helper.cleanLead(component);
        var action = component.get("c.pullCreditStatus");
        action.setParams({"lead" : lead});
        action.setCallback(this, function(resp) {
            if (lead.Application_Type__c === 'Joint') {
                helper.raiseNavEvent('LOCKJOINT');
            } else {
                helper.raiseNavEvent('LOCKPI');
            }
            if(resp.getState() == "SUCCESS") {
                window.setTimeout(function() {
                    $A.util.removeClass(component.find("creditStatus"), 'noDisplay');
                    component.set("v.creditStatusText", "Sending request to TransUnion");
                }, 3000);
                window.setTimeout(function() {
                    component.set("v.creditStatusText", "Waiting for TransUnion to process...");
                }, 6000);
                window.setTimeout(function() {
                    component.set("v.creditStatusText", "Checking for results...");
                }, 9000);
                window.setTimeout(function() {
                    var creditPollerInterval = window.setInterval($A.getCallback(helper.checkCreditStatus), 
                                                                  2000, component, helper);
                    component.set("v.creditStatusPoller", creditPollerInterval);
                }, 10000);

                // checkCreditStatus should clearInterval if it finds a Credit Report Log or
                // a Credit Report on the Lead, but just in case, stop checking after a minute
                const timeoutInterval = window.setTimeout(function() {
                    component.set("v.creditStatusText",
                                  "Credit request timed out, please wait a minute, refresh the page, and log in again");
                    helper.stopSpinner(component, 'creditSpinner');
                    window.clearInterval(component.get("v.creditStatusPoller"));
                }, component.get("v.creditStatusTimeout"));
                component.set("v.creditStatusTimeoutID", timeoutInterval);
            } else {
                helper.stopSpinner(component, 'creditSpinner');
                $A.util.removeClass(component.find("SubmitButton"), 'noDisplay');

                helper.logError("CAPCreditCheckController", "checkCredit",
                                "There was an issue running credit, but has been logged. Please call Customer Care at the number below for assistance.",
                                resp.getError());
                $A.util.addClass(component.find("pullCreditButtons"), 'noDisplay');
                component.set("v.newLead", lead);
            }
        });
        $A.enqueueAction(action);
    },

    addCoSigner : function(component, event, helper) {
        const lead = component.get('v.lead');
        lead.Application_Type__c = 'Joint';
        let leadPromise = helper.saveSObject(component, lead.Id, 'Lead', 'Application_Type__c', 'Joint');
        leadPromise.then($A.getCallback(function resolve(value) {
            component.set('v.page', 'Done');
            var stageChangeEvent = $A.get("e.c:CAPNavigationEvent");
            stageChangeEvent.setParams({"stageName": "NAV_Personal_Information"});
            stageChangeEvent.setParams({"options": {"pageName": "CoAppPI", "coSigner": true}});
            stageChangeEvent.setParams({"eventType": "INITIATED"});
            stageChangeEvent.setParams({"lead": lead});
            stageChangeEvent.fire();
        }));
    },

    selectProduct : function(component, event, helper) {
        var action = component.get("c.getCustomerProducts");
        action.setParams({"leadid" : component.get("v.lead").Id});
        action.setCallback(this, function(resp) {
            if(resp.getState() == "SUCCESS") {
                component.set("v.allProducts", resp.getReturnValue());
                component.set('v.page', 'SelectProduct');
            } else {
                helper.logError("CAPCreditCheckController", "selectProduct",
                                "There was an issue getting your qualified products. Please call Customer Care at the number below for assistance.",
                                resp.getError());
            }
        });
        $A.enqueueAction(action);
    },

    updateProductSelection : function(component, event, helper) { 
        helper.updateProductSelection(component, event, helper);
    },       

    finishStage : function(component, event, helper) {
        helper.finishStage(component, event, helper);
    },
    
})
