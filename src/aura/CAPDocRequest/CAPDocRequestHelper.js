/**
 * Created by abarnes on 10/9/2018.
 */
({
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
                this.logError('CAPDocRequestHelper', 'getLead', resp.getError(), component.get('v.lead'));
            }
        });
        $A.enqueueAction(action);
    },

    handleAttachment : function(component, event, helper, description) {
        var files = event.getSource().get("v.files");
        if (component.get('v.lead.ConvertedContactId')) {
            helper.uploadFiles(component, files, component.get('v.lead.ConvertedContactId'), helper.getLead, description, helper);
        } else {
            helper.uploadFiles(component, files, component.get('v.lead.Id'), helper.getLead, description, helper);
        }
    },

    parseAttachments : function(component, helper) {
        const lead = component.get('v.lead');
        if (lead.Attachments) {
            const requestedDocs = [];
            lead.Attachments.forEach(function(attachment) {
                const desc = attachment.Description;
                 if (desc.substring(0,9) === 'Requested') {
                    requestedDocs.push(attachment.Name);
                }
            });
            component.set('v.requestedDocs', requestedDocs);
        }
    },

    showNotice : function(component, callback, header, message, callbackParams) {
        component.find('notifLib').showNotice({
            "variant": "error",
            "header": header,
            "message": message,
            closeCallback: function() {
                callback(callbackParams)
            }
        });
    },

})