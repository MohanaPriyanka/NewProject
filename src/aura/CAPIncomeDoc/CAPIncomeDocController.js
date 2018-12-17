({
    handleNavEvent : function(component, event, helper) {
        const lead = event.getParam('lead');
        if (lead) {
            component.set('v.docsRequested', lead.Docs_Requested__c);
        }
        if (lead && lead.Product_Program__c === "MSLP") {
            helper.handleNavEvent(component, event, helper, 'MSLPTechnicalConfirm');
            if (event.getParam("eventType") === "INITIATED" &&
                event.getParam("stageName") === component.get("v.STAGENAME")) {
                helper.parseAttachments(component, helper, lead);
            }
        } else {
            if (lead && helper.incomeSourceProvided(lead)) {
                helper.handleNavEvent(component, event, helper, 'GetAllPrimaryDocs');
            } else {
                helper.handleNavEvent(component, event, helper, 'GetPrimaryIncomeSources');
            }
        }

        var now = new Date();
        // getMonth starts at 0, and we need to collect W-2s through April (per Mickey at Avidia)
        if (now.getMonth() <= 3) {
            component.set('v.inFirstQuarter', true);
            component.set('v.lastYear', now.getFullYear() - 1);
        } else {
            component.set('v.inFirstQuarter', false);
        }
    },

    handleTC : function(component, event, helper) {
        helper.handleAttachment(component, event, helper, helper.TC_DOC);
    },

    saveTCAskEmployed : function(component, event, helper) {
        if (helper.checkProjectIDErrors(component)) {
            helper.logError("CAPIncomeDocController", "saveTCAskEmployed", helper.checkProjectIDErrors(component));
            return;
        }
        if (!component.get('v.tcDocs') ||
            component.get('v.tcDocs').length === 0) {
            alert('Please upload your technical confirmation before continuing');
            return;
        }

        const lead = component.get('v.lead');
        var leadToSave = {
            sobjectType: 'Lead',
            Id: lead.Id,
            Project_Identification_Number__c: lead.Project_Identification_Number__c
        };
        var leadPromise = helper.saveSObject(component, lead.Id, 'Lead', null, null, leadToSave);
        leadPromise.then($A.getCallback(function resolve(retVal) {
            if (helper.incomeSourceProvided(lead)) {
                component.set('v.page', 'GetAllPrimaryDocs');
            } else {
                component.set('v.page', 'GetPrimaryIncomeSources');
            }
        }));
    },

    finishPrimaryDocs : function(component, event, helper) {
        let lead = component.get('v.lead');
        let incomeDocCollectionCmp = component.find('primaryIncomeDocCollectionCmp');
        if (!incomeDocCollectionCmp.allDocsCollected()) {
            component.find('notifLib').showNotice({
                "variant": "error",
                "header": 'Missing Documents',
                "message": incomeDocCollectionCmp.docsToBeCollected()});
            return;
        }

        if (lead.Application_Type__c === 'Joint') {
            let contact = component.get('v.lead.CoApplicant_Contact__r');
            if (contact.Employed__c ||
                contact.Self_Employed__c ||
                contact.Retired__c ||
                contact.Veteran_Disability__c ||
                contact.Other_Income__c) {
                component.set('v.page', 'GetAllJointDocs');
                return;
            }
        }
        helper.finishIncomeDocs(component, event, helper);
    },

    checkJointDocsAndfinishStage : function(component, event, helper) {
        let incomeDocCollectionCmp = component.find('jointIncomeDocCollectionCmp');
        if (incomeDocCollectionCmp.allDocsCollected()) {
            helper.finishIncomeDocs(component, event, helper);
        } else {
            component.find('notifLib').showNotice({
                "variant": "error",
                "header": 'Missing Documents',
                "message": incomeDocCollectionCmp.docsToBeCollected()});
        }
    },

    goBack : function(component, event, helper) {
        var pageMap = new Map();
        pageMap.set('EmployedQuestion', 'MSLPTechnicalConfirm');
        pageMap.set('GetPayStubs', 'EmployedQuestion');
        pageMap.set('SelfEmployedQuestion', 'EmployedQuestion');
        pageMap.set('GetTaxReturns', 'SelfEmployedQuestion');
        pageMap.set('RetirementQuestion', 'SelfEmployedQuestion');
        pageMap.set('GetRetirementIncome', 'RetirementQuestion');
        pageMap.set('VeteranQuestion', 'RetirementQuestion');
        pageMap.set('GetVeteranIncome', 'VeteranQuestion');
        pageMap.set('AlimonyQuestion', 'VeteranQuestion');
        pageMap.set('GetAlimonyIncome', 'AlimonyQuestion');
        pageMap.set('OtherIncome', 'AlimonyQuestion');
        component.set('v.page', pageMap.get(event.getSource().get('v.name')));
    },

    callSaveIncomeType : function(component, event, helper) {
        let lead = component.get('v.lead');
        if (lead.Application_Type__c === 'Joint') {
            helper.saveIncomeType(component, event, helper, 'GetJointIncomeSources');
        } else {
            helper.saveIncomeType(component, event, helper, 'GetAllPrimaryDocs');
        }
    },

    callSaveCoAppIncomeType : function(component, event, helper) {
        helper.saveCoAppIncomeType(component, event, helper, 'GetAllPrimaryDocs');
    },
})