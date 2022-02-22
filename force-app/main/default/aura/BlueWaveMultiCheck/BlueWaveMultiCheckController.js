({
    doInit : function(component, event, helper) {
        helper.setAttributeWithPicklistOptions(component, component.get('v.sObject'), component.get('v.field'), component, 'v.picklistOptions');
        const valueString = component.get('v.valueString');
        if (valueString) {
            component.set('v.valueArray', valueString.split(';'));
        }
    },

    setValueString : function(component, event, helper) {
        const valueArray = component.get('v.valueArray');
        component.set('v.valueString', valueArray.join(';'));
    }
})