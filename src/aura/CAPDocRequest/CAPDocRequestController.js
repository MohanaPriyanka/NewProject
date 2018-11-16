({
    handleNavEvent : function(component, event, helper) {
        if (event.getParam("eventType") === "INITIATED" &&
            event.getParam("stageName") === component.get("v.STAGENAME")) {
            let lead = event.getParam("lead");
            component.set("v.lead", lead);
            if (lead && lead.Docs_Requested__c) {
                helper.handleNavEvent(component, event, helper, 'CAPDocRequest');
                helper.parseAttachments(component, helper, lead);
            } else if (lead && !lead.Docs_Requested__c) {
                helper.handleNavEvent(component, event, helper, 'finishDocRequest');
            }
        }
    },

    uploadMissingDocument : function(component, event, helper) {
        const lead = component.get('v.lead');
        let docType = component.get('v.informationType');
        if (docType === 'Other') {
            docType = 'Requested ' + component.get('v.informationTypeOther');
        }
        helper.handleAttachment(component, event, helper, docType);
    },

    finishUploadDoc : function(component, event, helper) {
        const lead = component.get('v.lead');
        var action = component.get("c.finishDocRequestAndNotifyOps");
        action.setParams({"leadId" : lead.Id});
        action.setCallback(this,function(resp) {
            if (resp.getState() === 'SUCCESS') {
                component.set('v.page', 'finishDocRequest');
            } else {
                console.log(resp.getError());
            }
        });
        $A.enqueueAction(action);
    },
})