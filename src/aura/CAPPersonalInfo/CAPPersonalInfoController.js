({
    handleNavEvent : function(component, event, helper) {
        const options = event.getParam('options');
        var eventType = event.getParam('eventType');
        if(eventType !== 'LOCKPI' && eventType !== 'LOCKJOINT') {
            const leadVar =  event.getParam("lead");
            if (options) {
                if (options.pageName) {
                    helper.handleNavEvent(component, event, helper, options.pageName);
                } else if (leadVar.Product_Program__c == 'MSLP') {
                    helper.handleNavEvent(component, event, helper, 'iblsQualification');
                } else {
                    helper.handleNavEvent(component, event, helper, 'IndividualOrJoint');
                }
                if (options.coSigner) {
                    component.set('v.coSigner', true);
                }
            } else if (leadVar.Product_Program__c === 'MSLP') {
                helper.handleNavEvent(component, event, helper, 'iblsQualification');
            } else {
                helper.handleNavEvent(component, event, helper, 'IndividualOrJoint');
            }
        }
        const lead =  component.get('v.lead');
        if (eventType === 'LOCKPI' ||
            eventType === 'LOCKJOINT' ||
            (lead && lead.Personal_Credit_Report__c)) {
            component.set('v.piLocked', true);
        }
        if (eventType === 'LOCKJOINT' ||
            (lead && lead.Personal_Credit_Report_Co_Applicant__c)) {
            component.set('v.coAppLocked', true);
        }

        if (component.get('v.states') && component.get('v.states').length === 0) {
            helper.getUSStates(component, 'v.states');
        }
    },

    setAppType : function(component, event, helper) {
        var lead = component.get("v.lead");
        if (component.get('v.coAppLocked') || lead.Application_Type__c === 'Individual') {
            component.set('v.page', 'PrimaryPI');
            return;
        }
            
        // If it's an individual application, save the whole lead in case the applicant
        // was switching from joint (we need to remove the CoApp Contact Info).
        // Otherwise, we can just save the application type. We can't use saveLead since
        // it assumes there's already coapp contact information which might not be set yet
        if (lead.Application_Type__c === 'Individual') {
            helper.saveLead(component, event, helper, {finish: false, nextPage: 'PrimaryPI'});
        } else {
            const promise = helper.saveSObject(component,
                                               lead.Id,
                                               'Lead',
                                               'Application_Type__c',
                                               lead.Application_Type__c);
            promise.then($A.getCallback(function resolve(value) {
                component.set('v.page', 'PrimaryPI');
            }));
        }
    },

    handleShowModal : function(component, event, helper) {
        var newComponents = [];
        newComponents.push(["ui:outputURL", {
            "value": "http://bluewavesolar.com/about-us/privacy-policy/",
            "label": "BlueWave's Privacy Policy",
            "target": "_blank"
        }]);
        newComponents.push(["aura:html", {
            "tag": "br"
        }]);
        if (component.get('v.lenderOfRecord') === 'Avidia') {
            newComponents.push(["ui:outputURL", {
                        "value": "https://www.avidiabank.com/discls/general/privacy.html",
                            "label": "Avidia's Privacy Policy",
                            "target": "_blank"
                            }]);
        }

        var modalBody;
        $A.createComponents(newComponents,
                            function(content, status) {
                                if (status === "SUCCESS") {
                                    modalBody = content;
                                    var overlay = component.find('overlayLib');
                                    overlay.showCustomModal({
                                        cssClass: 'slds-modal__header_empty, slds-backdrop',
                                        body: modalBody,
                                        showCloseButton: true
                                    })
                                    
                                }
                                
                            });
    },

    savePI : function(component, event, helper) {
        if (helper.checkPIErrors(component)) {
            helper.logError("CAPPersonalInfoController", "savePI", helper.checkPIErrors(component));
            return;
        }

        // PI is locked if credit has already been run
        if (component.get('v.piLocked')) {
            component.set('v.page', 'PrimarySSN');
        } else {
            helper.saveLead(component, event, helper, {finish: false, nextPage: 'PrimarySSN'});
        }
    },

    saveSSN : function(component, event, helper) {
        if (helper.checkSSNErrors(component)) {
            helper.logError("CAPPersonalInfoController", "saveSSN", helper.checkSSNErrors(component));
            return;
        }

        if (component.get("v.lead").Application_Type__c === "Joint") {
            if (component.get('v.piLocked')) {
                component.set('v.page', 'CoAppPI');
            } else {
                helper.saveLead(component, event, helper, {finish: false, nextPage: 'CoAppPI'});
            }
        } else {
            if (component.get('v.piLocked')) {
                helper.finishStage(component, event, helper);
            } else {
                helper.saveLead(component, event, helper, {finish: true});
            }
        }
    },

    saveCoAppPI : function(component, event, helper) {
        if (helper.checkCoAppPIErrors(component)) {
            helper.logError("CAPPersonalInfoController", "saveCoAppPI", helper.checkCoAppPIErrors(component));
            return;
        }

        helper.saveLead(component, event, helper, {finish: false, nextPage: 'CoAppSSN'});
    },

    saveCoAppSSN : function(component, event, helper) {
        if (helper.checkCoAppSSNErrors(component)) {
            helper.logError("CAPPersonalInfoController", "saveCoAppSSN", helper.checkCoAppSSNErrors(component));
            return;
        }

        helper.saveLead(component, event, helper, {finish: true});
    },

    finishStage : function(component, event, helper) {
        helper.finishStage(component, event, helper);
    },

    changeApplicationToBWSL : function(component, event, helper) {
        alert('You are being redirected to apply for a standard BlueWave Solar Loan');
        helper.toggleMSLP(component, event, helper, false);
        component.set('v.page', 'IndividualOrJoint');
    },

    setToMSLPEligible : function(component, event, helper) {
        helper.toggleMSLP(component, event, helper, true);
        component.set('v.page', 'IndividualOrJoint');
    },
})