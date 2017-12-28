({
   login : function(component, event, helper) {
        var action = component.get('c.getLead');
        action.setParams({
            "leadId": component.get('v.leadId'),
            "email" : component.get('v.leadEmail')
        });
        action.setCallback(this, function(actionResult) {
            if (actionResult.getReturnValue() != null) {
                var lead = actionResult.getReturnValue();
                if (lead.Product__c &&
                    lead.Product__r.Lender_of_Record__c !== 'BlueWave') {
                    console.log('Check1')
                    helper.raiseNavEvent("LORCHANGE", {"lenderOfRecord": lead.Product__r.Lender_of_Record__c});
                }
                if (lead.CAP_Stage__c !== '') {
                    console.log('Check2')
                    component.set('v.page', '');
                    helper.raiseNavEvent("COMPLETED", {"stageName": lead.CAP_Stage__c, "lead": lead});
                } else {
                    console.log('Check3')
                    component.set('v.page', 'LoanConfirmation');
                    component.set('v.lead', lead);
                }
            } else {
                alert('Incorrect email address. Please verify your email address.');
            }
        });

        $A.enqueueAction(action);
    },
})