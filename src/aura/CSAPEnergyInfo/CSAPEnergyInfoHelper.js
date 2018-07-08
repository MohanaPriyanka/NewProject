({
    ELECTRIC_BILL_1: "Electric Bill",
    ELECTRIC_BILL_2: "Electric Bill 2",
    ANNUAL_ELECTRIC_HISTORY: "Annual Electric History",
    showUploadSuccess : function(component, helper) {
        var action = component.get("c.getAttachments");
        action.setParams({
            "parentId" : component.get("v.ual.Id")
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
            const electricBill2 = [];
            const annualElectricHistory = [];
            attachments.forEach(function(attachment) {
                const desc = attachment.Description;
                if (desc === helper.ELECTRIC_BILL_1) {
                    electricBill1.push(attachment.Name);
                } 
            });
            component.set("v.electricBill1", electricBill1);
            component.set("v.electricBill2", electricBill2);
            component.set("v.annualElectricHistory", annualElectricHistory);
        }
    },

    handleAttachment : function(component, event, helper, description) {
        var files = event.getSource().get("v.files")
        var parentId = component.get("v.ual.Id");
        helper.uploadFiles(component, files, parentId, helper.showUploadSuccess, description, helper);
    },
    addNewLead : function(component, event, helper, applicationType) {
        var oldLead = component.get("v.lead");
        var newLead = {
            sobjectType: "Lead",
            Personal_Credit_Report__c: oldLead.Personal_Credit_Report__c,
            Parent_Account__c: oldLead.Parent_Account__c,
            Partner_lookup__c : oldLead.Partner_lookup__c,
            Bs_Sales_ID__c : oldLead.Bs_Sales_ID__c,
            Email : oldLead.Email,
            FirstName: oldLead.FirstName,
            LastName: oldLead.LastName,
            MobilePhone: oldLead.MobilePhone,
            Phone: oldLead.Phone,
            LASERCA__Birthdate__c: oldLead.LASERCA__Birthdate__c,
            LASERCA__SSN__c : oldLead.LASERCA__SSN__c,
            Application_Type__c : applicationType
        };

        component.set("v.lead", newLead);

        var stageChangeEvent = $A.get("e.c:CSAPNavigationEvent");
        stageChangeEvent.setParams({"stageName": "NAV_Personal_Information"});
        stageChangeEvent.setParams({"options": {"pageName": "AddressForm"}});
        stageChangeEvent.setParams({"eventType": "INITIATED"});
        stageChangeEvent.setParams({"lead": newLead});
        stageChangeEvent.fire();
    },
})