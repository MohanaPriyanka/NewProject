({
    doInit : function(component, event, helper) {
        var record = component.get('v.objectRecord');
        var fieldName = component.get('v.fieldName');
        var conditionalField = component.get("v.conditionalColorField");
        if (fieldName != 'Action') {
        	helper.setFieldType(component, fieldName);        
        	helper.setRowValues(component, record, fieldName);
            if (conditionalField != null) {
                helper.setColorAttributeConditionalField(component, conditionalField, fieldName, "colorCode", "conditionalColorMap", "columnColorMap");
            } else {
                helper.setColorAttributeColumn(component, fieldName);
            }
        } else {
			helper.setButtonAttribute(component, conditionalField, "buttonLabel", "buttonConditionalLabelMap", "allButtonLabels");       
            helper.setButtonAttribute(component, conditionalField, "buttonEventId", "buttonConditionalEventMap", "allButtonEvents")    	
        }
    },

    recordChange: function(component, event, helper) {
    	helper.setButtonAttribute(component, "buttonLabel", "buttonConditionalLabelMap", "allButtonLabels");                     
        helper.setButtonAttribute(component, "buttonEventId", "buttonConditionalEventMap", "allButtonEvents")     
    },    

    executeAction: function(component, event, helper) {
        var record = component.get('v.objectRecord');
        var buttonEventId = component.get("v.buttonEventId");
        var buttonEventEvt = component.getEvent("buttonEvent");
        buttonEventEvt.setParams({ buttonEventId: buttonEventId, 
                                   record: record}); 
        buttonEventEvt.fire();   
    },      
     
})