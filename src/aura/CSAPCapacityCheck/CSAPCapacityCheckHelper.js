/**
 * Created by mstackhouse on 2/19/2019.
 */
({
    ELECTRIC_BILL_1: "Electric Bill",
    showUploadSuccess : function(component, helper) {
        var action = component.get("c.getAttachments");
        action.setParams({
            "parentId" : component.get("v.lead.Id")
        });
        action.setCallback(this,function(resp) {
            if (resp.getState() === "SUCCESS") {
                component.set("v.attachments", resp.getReturnValue());
                helper.parseAttachments(component, helper);
            } else {
                this.logError("CAPIncomeDocHelper", "getLead", resp.getError(), component.get("v.lead"));
            }
        });
        $A.enqueueAction(action);

        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            "title": "Success!",
            "message": "Upload successful."
        });
        toastEvent.fire();
    },
    parseAttachments : function(component, helper) {
        const attachments = component.get("v.attachments");
        if (attachments) {
            const electricBill1 = [];
            attachments.forEach(function(attachment) {
                const desc = attachment.Description;
                if (desc === helper.ELECTRIC_BILL_1) {
                    electricBill1.push(attachment.Name);
                }
            });
            component.set("v.electricBill1", electricBill1);
        }
    },

    handleAttachment : function(component, event, helper, description) {
        var files = event.getSource().get("v.files")
        var parentId = component.get("v.lead.Id");
        helper.uploadFiles(component, files, parentId, helper.showUploadSuccess, description, helper);
    },

    storeTermsConditions : function(component, event, helper) {
        var lead = component.get('v.lead');
        var termsConditions;
        if (component.get("v.partnerApp")) {
            termsConditions = component.get("v.partnerTermsConditions");
        } else {
            termsConditions = component.get("v.termsConditions");
        }
        console.log("are we updating the lead: " + component.get("v.initials"));
        var today = new Date();
        lead.Acknowledged_Customer_Initials__c = component.get("v.initials");
        lead.Terms_Conditions_Acknowledged__c = new Date();
        lead.Terms_Conditions__c = termsConditions;

    },

    clearAttachments : function(component, event, helper){
        component.set("v.electricBill1", "");
        component.set('v.isLargeFile', false);
    },
})