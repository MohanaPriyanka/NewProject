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
        var termsType;
        if (component.get("v.partnerApp")) {
            termsConditions = component.get("v.partnerTermsConditions");
            termsType = 'BW Applicant Terms with Partner';
        } else {
            termsConditions = component.get("v.termsConditions");
            termsType = 'BW Applicant Terms without Partner';
        }

        var action = component.get("c.saveTerms");
        action.setParams({
            "terms" : termsConditions,
            "lead" : lead,
            "termsType" : termsType
        });
        action.setCallback(this, function(resp){
            if (resp.getState() !== "SUCCESS") {
                this.logError("CSAPCapacityCheckHelper", "storeTermsConditions", resp.getError(), 'No task created to store Terms Consent for Lead: ' + lead.Id);
            }
        });
        $A.enqueueAction(action);
    },

    clearAttachments : function(component, event, helper){
        component.set("v.electricBill1", "");
        component.set('v.isLargeFile', false);
    },
})