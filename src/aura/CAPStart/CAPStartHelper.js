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
                if (lead.Product__c) {
                    if (lead.Product__r.Lender_of_Record__c !== 'BlueWave') {
                        helper.raiseNavEvent("LORCHANGE", {"lenderOfRecord": lead.Product__r.Lender_of_Record__c});
                    }
                } else {
                    var lorAction = component.get('c.getLenderOfRecord');
                    lorAction.setParams({'state': lead.LASERCA__Home_State__c});
                    lorAction.setCallback(this, function(result) {
                        var lor = result.getReturnValue();
                        if (lor !== 'BlueWave') {
                            helper.raiseNavEvent("LORCHANGE", {"lenderOfRecord": lor});
                        }
                    });
                    $A.enqueueAction(lorAction);
                }
                if (lead.LASERCA__Personal_Credit_Report__c) {
                    helper.raiseNavEvent('LOCKPI');
                }
                if (lead.Personal_Credit_Report_Co_Applicant__c) {
                    helper.raiseNavEvent('LOCKJOINT');
                }
                if (lead.CAP_Stage__c !== '') {
                    component.set('v.page', '');
                    helper.raiseNavEvent("COMPLETED", {"stageName": lead.CAP_Stage__c, "lead": lead});
                } else {
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