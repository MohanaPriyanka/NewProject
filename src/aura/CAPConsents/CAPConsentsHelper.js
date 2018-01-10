({
    TC_DOC: 'MSLP Technical Confirmation',

    getLead : function(component, helper) {
        var action = component.get('c.getLead');
        action.setParams({'leadId' : component.get('v.lead.Id'),
            'email': component.get('v.lead.Email')});
        action.setCallback(this,function(resp) {
            if (resp.getState() === 'SUCCESS') {
                helper.parseAttachments(component, helper, resp.getReturnValue());
            } else {
                this.logError('CAPConsentsHelper', 'getLead', resp.getError(), component.get('v.lead'));
            }
        });
        $A.enqueueAction(action);
    },

    parseAttachments : function(component, helper, lead) {
        if (lead.Attachments) {
            const tcDocs = [];
            lead.Attachments.forEach(function(attachment) {
                const desc = attachment.Description;
                if (desc === helper.TC_DOC) {
                    tcDocs.push(attachment.Name);
                }
            });
            component.set('v.tcDocs', tcDocs);
        }
    },

    handleAttachment : function(component, event, helper, description) {
        var files = event.getSource().get("v.files")
        var parentId = component.get("v.lead.Id");
        helper.uploadFiles(component, files, parentId, helper.getLead, description, helper);
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

	getSRECProducts : function(component, event, helper, lead) {
		var i;
        var action = component.get("c.getProducts");
        action.setParams({state: component.get("v.lead.LASERCA__Home_State__c"),
                          productType: 'SREC'});
        action.setCallback(this,function(resp){
            if (resp.getState() === 'SUCCESS') {
                var srecOptions = resp.getReturnValue();
                var i = 0;
                for (; i < srecOptions.length; i++) {
                    if (srecOptions[i] && lead.SREC_Product__r) {
                        if (srecOptions[i]["Name"] === lead.SREC_Product__r.Name) {
                            var selectedIndex = i; 
                            var selectedSrec = srecOptions[i];
                        }
                    }
                }
                if (i > 0) {
                    resp.getReturnValue().unshift(selectedSrec);
                    resp.getReturnValue().splice(selectedIndex + 1, 1);
                }
                component.set("v.availableSRECProducts", resp.getReturnValue());
            } else {
                helper.logError("SLPSendApplicationEmailController", "availableSRECProducts", resp.getError());
            }
        });
        $A.enqueueAction(action);
	}
})