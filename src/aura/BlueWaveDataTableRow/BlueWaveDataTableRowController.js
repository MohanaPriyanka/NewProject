({
    doInit : function(component, event, helper) {
        var record = component.get('v.objectRecord');
        var fieldName = component.get('v.fieldName');
        if (fieldName != 'Action') {
        	helper.setFieldType(component, fieldName);        
        	helper.setRowValues(component, record, fieldName);
        	helper.setColor(component, fieldName);
        } else {
			helper.setButtonLabels(component);       
            helper.setButtonEvents(component);   	
        }
    },

    recordChange: function(component, event, helper) {
    	helper.setButtonLabels(component);                        
        helper.setButtonEvents(component);      
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