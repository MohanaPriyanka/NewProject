({
    getLead : function(component, helper) {
        var action = component.get('c.getLead');
        action.setParams({'leadId' : component.get('v.lead.Id'),
                          'email': component.get('v.lead.Email')});
        action.setCallback(this,function(resp) {
            if (resp.getState() === 'SUCCESS') {
                component.set('v.lead', resp.getReturnValue());
                helper.parseAttachments(component);
            } else {
                this.logError('CAPIncomeDocHelper', 'getLead', resp.getError(), component.get('v.lead'));
            }
        });
        $A.enqueueAction(action);
    },

    parseAttachments : function(component) {
        const lead = component.get('v.lead');
        if (lead.Attachments) {
            const paystubs = [];
            lead.Attachments.forEach(function(attachment) {
                if (attachment.Description === 'Paystub') {
                    paystubs.push(attachment.Name);
                }
            });
            component.set('v.paystubs', paystubs);
        }
    },
})
