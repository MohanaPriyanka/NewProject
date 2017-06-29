({
    openModal: function(component, event, helper) {
        component.set("v.isOpen", true);
        helper.getPicklistOptions(component, 
                                  'LASERCA__Personal_Credit_Report__c', 
                                  'Adverse_Credit_Notice_1__c', 
                                  component.find("AdverseCreditNotice"));
        var objectName = event.target.dataset.objectname;
        var fieldName = event.target.dataset.fieldname;
        var lead = component.get("v.lead");
        component.set("v.adverseObject", objectName);
        component.set("v.adverseField", fieldName);
        component.set("v.adverseValue", lead[objectName][fieldName]);
    },

    closeModal: function(component, event, helper) {
        component.set("v.isOpen", false);
    },
    
    closeAndSaveModal: function(component, event, helper) {
        var lead = component.get("v.lead");
        var objectName = component.get("v.adverseObject");
        var fieldName = component.get("v.adverseField");
        var adverseValue = component.get("v.adverseValue");
        helper.saveSObject(component,
                           lead[objectName].Id,
                           'LASERCA__Personal_Credit_Report__c',
                           fieldName,
                           adverseValue);
        lead[objectName][fieldName]=adverseValue;
        component.set("v.lead", lead);
        component.set("v.isOpen", false);
    },    
})