({
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

    finishIncomeDocs : function(component, event, helper) {
        const lead = component.get('v.lead');
        let leadToSave;
        if (lead.Status === 'Awaiting Info Requested from Customer') {
            leadToSave = {
                sobjectType: 'Lead',
                Status: 'Under BlueWave Review',
                Id: lead.Id,
                Unfinished_Lead__c: false
            };
        } else {
            leadToSave = {
                sobjectType: 'Lead',
                Id: lead.Id,
                Unfinished_Lead__c: false
            };
        }
        helper.saveSObject(component, lead.Id, 'Lead', null, null, leadToSave)
        .then($A.getCallback(function resolve() {
            return helper.insertPartnerTaskFunction(component, event, helper);
        }))
        .then($A.getCallback(function resolve() {
            helper.finishStage(component, event, helper);
        }));
    },

    incomeSourceProvided : function(lead) {
        return (lead &&
                (lead.Employed__c ||
                 lead.Self_Employed__c ||
                 lead.Retired__c ||
                 lead.Veteran_Disability__c ||
                 lead.Other_Income__c));
    },
})