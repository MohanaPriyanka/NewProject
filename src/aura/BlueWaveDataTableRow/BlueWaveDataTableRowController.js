({
    doInit : function(component, event, helper) {
        var record = component.get('v.objectRecord');
        var fieldName = component.get('v.fieldName');
        var conditionalColorField = component.get("v.conditionalColorField");
        var conditionalButtonField = component.get("v.buttonConditionalField");

        if (fieldName != 'Action') {
        	helper.setFieldType(component, fieldName);        
        	helper.setRowValues(component, record, fieldName);
            if (conditionalColorField != null) {
                helper.setColorAttributeConditionalField(component, conditionalColorField, fieldName, "colorCode", "conditionalColorMap", "columnColorMap");
            } else {
                helper.setColorAttributeColumn(component, fieldName);
            }
        } else {
			helper.setButtonAttribute(component, conditionalButtonField, "buttonLabel", "buttonConditionalLabelMap", "allButtonLabels");       
            helper.setButtonAttribute(component, conditionalButtonField, "buttonEventId", "buttonConditionalEventMap", "allButtonEvents")    	
        }
    },

    recordChange: function(component, event, helper) {
        var conditionalButtonField = component.get("v.buttonConditionalField");
    	helper.setButtonAttribute(component, conditionalButtonField, "buttonLabel", "buttonConditionalLabelMap", "allButtonLabels");                     
        helper.setButtonAttribute(component, conditionalButtonField, "buttonEventId", "buttonConditionalEventMap", "allButtonEvents")     
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