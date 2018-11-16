({
    getLead : function(component, helper) {
        var action = component.get('c.getLead');
        action.setParams({'leadId' : component.get('v.lead.Id'),
            'email': component.get('v.lead.Email')});
        action.setCallback(this,function(resp) {
            if (resp.getState() !== 'SUCCESS') {
                this.logError('CAPConsentsHelper', 'getLead', resp.getError(), component.get('v.lead'));
            }
        });
        $A.enqueueAction(action);
    },

    sendLoanDocs : function(component, event, helper) {
        return new Promise(function(resolve) {
            let action = component.get('c.sendLoanDocs');
            action.setParams({
                'leadId': component.get('v.lead.Id'),
                'email': component.get('v.lead.Email')
            });
            action.setCallback(this, function(resp) {
                if (resp.getState() === 'SUCCESS') {
                    helper.raiseNavEvent("CONTRACTSENT", {"lead": component.get('v.lead'), "contractSent": true});
                    resolve();
                } else {
                    helper.raiseError(
                        'CAPConsentsHelper',
                        'sendLoanDocs',
                        'DocuSign could not be sent, please contact Customer Care',
                        'For leadId ' + component.get('v.lead.Id') + ': ' + resp.getError()[0].message
                    );
                }
            });
            $A.enqueueAction(action);
        });
    },
})