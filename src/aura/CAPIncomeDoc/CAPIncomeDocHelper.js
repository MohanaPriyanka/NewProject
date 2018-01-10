({
    PAYSTUB: 'Paystub',
    TAX_PREV_YEAR: 'Tax Return (Previous Year)',
    TAX_TWO_YEARS_PRIOR: 'Tax Return (Two Years Previous)',
    SSN: 'SSN Award Letter',
    PENSION: ' Pension Award Letter',
    BANK: 'Bank Statement (SSN Income)',
    VETERAN: 'Veteran Income Documentation',
    OTHER_INCOME: 'Income: Other',

    getLead : function(component, helper) {
        var action = component.get('c.getLead');
        action.setParams({'leadId' : component.get('v.lead.Id'),
                          'email': component.get('v.lead.Email')});
        action.setCallback(this,function(resp) {
            if (resp.getState() === 'SUCCESS') {
                component.set('v.lead', resp.getReturnValue());
                helper.parseAttachments(component, helper);
            } else {
                this.logError('CAPIncomeDocHelper', 'getLead', resp.getError(), component.get('v.lead'));
            }
        });
        $A.enqueueAction(action);
    },

    parseAttachments : function(component, helper) {
        const lead = component.get('v.lead');
        if (lead.Attachments) {
            const paystubs = [];
            const taxreturns = [];
            const retirement = [];
            const veteran = [];
            const otherIncome = [];
            lead.Attachments.forEach(function(attachment) {
                const desc = attachment.Description;
                if (desc === helper.PAYSTUB) {
                    paystubs.push(attachment.Name);
                } else if (
                    desc === helper.TAX_PREV_YEAR ||
                    desc === helper.TAX_TWO_YEARS_PRIOR
                ) {
                    taxreturns.push(attachment.Name);
                } else if (
                    desc === helper.SSN ||
                    desc === helper.PENSION ||
                    desc === helper.BANK
                ) {
                    retirement.push(attachment.Name);
                } else if (desc === helper.VETERAN) {
                    veteran.push(attachment.Name);
                } else if (desc === helper.OTHER_INCOME) {
                    otherIncome.push(attachment.Name);
                }
            });
            component.set('v.paystubs', paystubs);
            component.set('v.taxreturns', taxreturns);
            component.set('v.retirementIncome', retirement);
            component.set('v.veteranIncome', veteran);
            component.set('v.otherIncome', otherIncome);
        }
    },

    handleAttachment : function(component, event, helper, description) {
        var files = event.getSource().get("v.files")
        var parentId = component.get("v.lead.Id");
        helper.uploadFiles(component, files, parentId, helper.getLead, description, helper);
    }
})