({
    handleNavEvent : function(component, event, helper) {
        helper.handleNavEvent(component, event, helper, 'EmployedQuestion');
        if (event.getParam("eventType") === "INITIATED" &&
            event.getParam("stageName") === component.get("v.STAGENAME")) {
            helper.parseAttachments(component);
        }
    },

    getPayStubs : function(component, event, helper) {
        if (component.get('v.employed')) {
            component.set('v.page', 'GetPayStubs');
        } else {
            component.set('v.page', 'SelfEmployedQuestion');
        }
    },

    askPayStubs : function(component, event, helper) {
        component.set('v.page', 'SelfEmployedQuestion');
    },

    handleFilesChange : function(component, event, helper) {
        var files = event.getSource().get("v.files")
        var parentId = component.get("v.lead.Id");
        helper.uploadFiles(component, files, parentId, helper.getLead, 'Paystub', helper);
    },
})
