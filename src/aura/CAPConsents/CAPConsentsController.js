({
    handleNavEvent : function(component, event, helper) {
        const lead = event.getParam('lead');
        helper.handleNavEvent(component, event, helper, 'Disbursal');
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
                if	(lead.Status !== "Awaiting Info Requested from Customer") {
                    helper.sendLoanDocs(component, event, helper);
                }
            })).then(
            $A.getCallback(function resolve(retVal) {
                component.set('v.page', 'ContingentConfirmation');
            }));
    },

    finishConfirmations : function(component, event, helper) {
        helper.finishStage(component, event, helper);
    },
})