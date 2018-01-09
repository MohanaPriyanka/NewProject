({
    handleNavEvent : function(component, event, helper) {
        const lead = event.getParam('lead');
        if (lead && lead.LASERCA__Home_State__c === 'MA') {
            if (lead.Product_Program__c === 'MSLP') {
                helper.handleNavEvent(component, event, helper, 'MSLPTechnicalConfirm');
                if (event.getParam("eventType") === "INITIATED" &&
                    event.getParam("stageName") === component.get("v.STAGENAME")) {
                    helper.parseAttachments(component, helper, lead);
                }
            } else {
                helper.handleNavEvent(component, event, helper, 'SREC');
            }
            helper.getSRECProducts(component, event, helper, lead);
        } else {
            helper.handleNavEvent(component, event, helper, 'Disbursal');
        }
    },

    handleTC : function(component, event, helper) {
        helper.handleAttachment(component, event, helper, helper.TC_DOC);
    },

    saveTCAskSREC : function(component, event, helper) {
        if (helper.checkProjectIDErrors(component)) {
            helper.logError("CAPConsentsController", "saveTCAskSREC", helper.checkProjectIDErrors(component));
            return;
        }

        const lead = component.get('v.lead');
        var leadToSave = {
            sobjectType: 'Lead',
            Id: lead.Id,
            Project_Identification_Number__c: lead.Project_Identification_Number__c
        };
        helper.saveSObject(component, lead.Id, 'Lead', null, null, leadToSave);
        component.set('v.page', 'SREC');
    },

    saveSRECAskDisbursal : function(component, event, helper) {
        const lead = component.get('v.lead');
        var leadToSave = {
            sobjectType: 'Lead',
            Id: lead.Id,
            SREC_Product__c: lead.SREC_Product__c
        };
        helper.saveSObject(component, lead.Id, 'Lead', null, null, leadToSave);
        component.set('v.page', 'Disbursal');
    },

    saveDisbursal : function(component, event, helper) {
        const lead = component.get('v.lead');
        var leadToSave = {
            sobjectType: 'Lead',
            Id: lead.Id,
            Electronic_Disbursal_Authorized__c: lead.Electronic_Disbursal_Authorized__c,
            Unfinished_Lead__c: false
        };
        var leadPromise = helper.saveSObject(component, lead.Id, 'Lead', null, null, leadToSave);
        leadPromise.then($A.getCallback(function resolve(retVal) {
            helper.finishStage(component, event, helper);
        }));
    },
})