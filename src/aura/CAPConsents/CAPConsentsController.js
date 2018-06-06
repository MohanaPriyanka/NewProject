({
    handleNavEvent : function(component, event, helper) {
        const lead = event.getParam('lead');
        if (lead && lead.LASERCA__Home_State__c === 'MA') {
            helper.handleNavEvent(component, event, helper, 'SREC');
            helper.getSRECProducts(component, event, helper, lead);
        } else {
            helper.handleNavEvent(component, event, helper, 'Disbursal');
        }
    },

    saveSRECAskDisbursal : function(component, event, helper) {
        const lead = component.get('v.lead');
        var leadToSave = {
            sobjectType: 'Lead',
            Id: lead.Id,
            SREC_Product__c: lead.SREC_Product__c
        };
        var leadPromise = helper.saveSObject(component, lead.Id, 'Lead', null, null, leadToSave);
        leadPromise.then($A.getCallback(function resolve(retVal) {
            component.set('v.page', 'Disbursal');
        }));
    },

    saveDisbursal : function(component, event, helper) {
        const lead = component.get('v.lead');
        var leadToSave = {
            sobjectType: 'Lead',
            Id: lead.Id,
            Electronic_Disbursal_Authorized__c: lead.Electronic_Disbursal_Authorized__c,
        };
        helper.saveSObject(component, lead.Id, 'Lead', null, null, leadToSave).then(
            $A.getCallback(function resolve(retVal) {
                helper.sendLoanDocs(component, event, helper);
            })).then(
            $A.getCallback(function resolve(retVal) {
                component.set('v.page', 'ContingentConfirmation');
            }));
    },

    finishConfirmations : function(component, event, helper) {
        helper.finishStage(component, event, helper);
    },
})