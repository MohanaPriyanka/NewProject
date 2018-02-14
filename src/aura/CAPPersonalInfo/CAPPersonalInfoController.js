({
    handleNavEvent : function(component, event, helper) {
        const options = event.getParam('options');
        const lead =  component.get('v.lead');
        var eventType = event.getParam('eventType');
        if (eventType !== 'LOCKPI' && eventType !== 'LOCKJOINT' && eventType !== 'LORCHANGE') {
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
            if (leadVar.Other_Bank_Executive__c || leadVar.Avidia_Service_Provider__c) {
                component.set('v.bankAffiliation', true);
            }
            if (leadVar.CoApplicant_Contact__r &&
                (leadVar.CoApplicant_Contact__r.Other_Bank_Executive__c || leadVar.CoApplicant_Contact__r.Avidia_Service_Provider__c)) {
                component.set('v.coAppBankAffiliation', true);
            }
        }
        if (eventType === 'LORCHANGE') {
            helper.handleNavEvent(component, event, helper);
        }
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
            helper.getUSStates(component, 'v.states', false);
        }
        if (component.get('v.abbrevStates') && component.get('v.abbrevStates').length === 0) {
            helper.getUSStates(component, 'v.abbrevStates', true);
        }
    },

    setApplicationType : function(component, event, helper) {
        var lead = component.get("v.lead");
        if (component.get('v.coAppLocked') || lead.Status === 'Pre-Qualified') {
            component.set('v.page', 'PrimaryPI');
            return;
        }
            
        helper.setAppType(component, event, helper);
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

    openLicenseInformation : function(component, event, helper) {
        component.set('v.page', 'PrimaryLicenseInfo');
    },

    openAddressPI : function(component, event, helper) {
        if (helper.checkPIErrors(component)) {
            helper.raiseError("CAPPersonalInfoController", "savePI", helper.checkPIErrors(component), '', {suppressDBSave: true});
            return;
        }
        component.set('v.page', 'AddressPI');
    },

    setResidenceOwner: function(component, event, helper) {
        var lead = component.get('v.lead');
        var value = event.currentTarget.value;
        if (value == 'true') {
            component.set('v.lead.Residence_Owner__c', true);
            component.set('v.lead.Not_Residence_Owner__c', false);
        } else {
            component.set('v.lead.Residence_Owner__c', false);
            component.set('v.lead.Not_Residence_Owner__c', true);
        }
    },

    savePI : function(component, event, helper) {
        if (helper.checkAddressPIErrors(component)) {
            helper.raiseError("CAPPersonalInfoController", "savePI", helper.checkAddressPIErrors(component), '', {suppressDBSave: true});
            return;
        }

        // PI is locked if credit has already been run
        if (component.get('v.piLocked')) {
            if (component.get('v.lenderOfRecord') === 'Avidia') {
                component.set('v.page', 'PrimaryLicenseInfo');
            } else {
                component.set('v.page', 'PrimarySSN');
            }
        } else {
            if (component.get('v.lenderOfRecord') === 'Avidia') {
                helper.saveLead(component, event, helper, {finish: false, nextPage: 'PrimaryLicenseInfo'});
            } else {
                helper.saveLead(component, event, helper, {finish: false, nextPage: 'PrimarySSN'});
            }
        }
    },

    saveLicenseInfo : function(component, event, helper) {
        if (helper.checkLicenseErrors(component)) {
            helper.raiseError("CAPPersonalInfoController", "saveLicenseInfo", helper.checkLicenseErrors(component), '', {suppressDBSave: true});
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
            helper.raiseError("CAPPersonalInfoController", "saveSSN", helper.checkSSNErrors(component), '', {suppressDBSave: true});
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
            helper.raiseError("CAPPersonalInfoController", "saveCoAppPI", helper.checkCoAppPIErrors(component), '', {suppressDBSave: true});
            return;
        }

        helper.saveLead(component, event, helper, {finish: false, nextPage: 'CoAppSSN'});
    },

    saveCoAppSSN : function(component, event, helper) {
        if (helper.checkCoAppSSNErrors(component)) {
            helper.raiseError("CAPPersonalInfoController", "saveCoAppSSN", helper.checkCoAppSSNErrors(component), '', {suppressDBSave: true});
            return;
        }

        helper.saveLead(component, event, helper, {finish: true});
    },

    finishStage : function(component, event, helper) {
        helper.finishStage(component, event, helper);
    },

    openBWSLTransferAlert : function(component, event, helper) {
        component.set('v.bwslTransferAlert', true);
    },

    closeBWSLTransferAlert : function(component, event, helper) {
        component.set('v.bwslTransferAlert', false);
    },

    changeApplicationToBWSL : function(component, event, helper) {
        component.set('v.bwslTransferAlert', false);
        helper.toggleMSLP(component, event, helper, false);
        component.set('v.page', 'IndividualOrJoint');
    },

    setToMSLPEligible : function(component, event, helper) {
        helper.toggleMSLP(component, event, helper, true);
        component.set('v.page', 'IndividualOrJoint');
    },
})