({
    PAYSTUB: 'PayStub',
    TAX_PREV_YEAR: 'Tax Return (Previous Year)',
    TAX_TWO_YEARS_PRIOR: 'Tax Return (Two Years Previous)',
    SSN: 'SSN Award Letter',
    PENSION: 'Pension Award Letter',
    BANK: 'Bank Statement (SSN Income)',
    VETERAN: 'Veteran Income Documentation',
    OTHER_INCOME: 'Income: Other',
    TC_DOC: 'MSLP Technical Confirmation',

    getLead : function(component, helper) {
        var action = component.get('c.getLeadWrapper');
        action.setParams({'leadId' : component.get('v.lead.Id'),
                          'email': component.get('v.lead.Email')});
        action.setCallback(this,function(resp) {
            if (resp.getState() === 'SUCCESS') {
                // We call getLead after docs are uploaded to refresh the attachment list.
                // We lose data if fields are set before uploading and not yet saved.
                component.set('v.lead.Attachments', resp.getReturnValue().attachments);
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
            const lastYearReturns = [];
            const twoYearReturns = [];
            const retirement = [];
            const veteran = [];
            const otherIncome = [];
            const tcDocs = [];
            lead.Attachments.forEach(function(attachment) {
                const desc = attachment.Description;
                if (desc === helper.PAYSTUB) {
                    paystubs.push(attachment.Name);
                } else if (desc === helper.TAX_PREV_YEAR) {
                    taxreturns.push(attachment.Name);
                    lastYearReturns.push(attachment.Name);
                } else if (desc === helper.TAX_TWO_YEARS_PRIOR) {
                    taxreturns.push(attachment.Name);
                    twoYearReturns.push(attachment.Name);
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
                } else if (desc === helper.TC_DOC) {
                    tcDocs.push(attachment.Name);
                }
            });
            component.set('v.paystubs', paystubs);
            component.set('v.taxreturns', taxreturns);
            component.set('v.lastYearReturns', lastYearReturns);
            component.set('v.twoYearReturns', twoYearReturns);
            component.set('v.retirementIncome', retirement);
            component.set('v.veteranIncome', veteran);
            component.set('v.otherIncome', otherIncome);
            component.set('v.tcDocs', tcDocs);
        }
    },

    handleAttachment : function(component, event, helper, description) {
        var files = event.getSource().get("v.files");
        if (component.get('v.lead.ConvertedContactId')) {
            helper.uploadFiles(component, files, component.get('v.lead.ConvertedContactId'), helper.getLead, description, helper);
        } else {
            helper.uploadFiles(component, files, component.get('v.lead.Id'), helper.getLead, description, helper);
        }
    },

    checkProjectIDErrors : function(component) {
        var errorMessage = "";
        var lead = component.get("v.lead");
        errorMessage += this.getFieldError(component, {
            'fieldValue': lead.Project_Identification_Number__c,
            'fieldId': "tcProjectId",
            'allowSpecialChars': true,
            'errorMessage': "Enter your MassCEC Project ID Number"
        });
        if (!component.get('v.tcDocs')) {
            errorMessage += 'Please upload your Technical Confirmation';
        }
        return errorMessage;
    },

    insertPartnerTaskFunction : function(component, event, helper) {
        let lead = component.get('v.lead');
        return new Promise(function(resolve) {
            let upsertPartnerTaskAction = component.get("c.insertPartnerTasks");
            upsertPartnerTaskAction.setParams({
                leadId : lead.Id,
                email : lead.Email
            });
            upsertPartnerTaskAction.setCallback(this,function(resp) {
                if (resp.getState() === 'SUCCESS') {
                    resolve();
                } else {
                    helper.raiseError('CAPIncomeDocHelper', 'upsertPartnerTaskFunction', 'Couldn\'t upsert partner tasks', resp,  {suppressAlert: true});
                    resolve();
                }
            });
            $A.enqueueAction(upsertPartnerTaskAction);
        });
    },

})