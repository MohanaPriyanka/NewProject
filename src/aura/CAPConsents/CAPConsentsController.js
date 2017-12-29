({
    handleNavEvent : function(component, event, helper) {
        const lead = event.getParam('lead');
        if (lead && lead.LASERCA__Home_State__c === 'MA') {
            helper.handleNavEvent(component, event, helper, 'SREC');
        } else {
            helper.handleNavEvent(component, event, helper, 'Disbursal');
        }
    },

    saveSRECAskDisbursal : function(component, event, helper) {
        component.set('v.page', 'Disbursal');
    },

    saveDisbursal : function(component, event, helper) {
        const lead = component.get('v.lead');
        var leadToSave = {
            sobjectType: 'Lead',
            Id: lead.Id,
            Electronic_Disbursal_Authorized__c: lead.Electronic_Disbursal_Authorized__c
        };
        var leadPromise = helper.saveSObject(component, lead.Id, 'Lead', null, null, leadToSave);
        leadPromise.then($A.getCallback(function resolve(retVal) {
            helper.finishStage(component, event, helper);
        }));
    },
})