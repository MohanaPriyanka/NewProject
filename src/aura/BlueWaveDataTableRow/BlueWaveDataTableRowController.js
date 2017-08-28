({
    doInit : function(component, event, helper) {
        var record = component.get('v.objectRecord');
        var fieldName = component.get('v.fieldName');
        helper.setFieldType(component, fieldName);        
        helper.setRowValues(component, record, fieldName);
        helper.setColor(component, fieldName);
    },
     
})