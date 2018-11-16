({
    setDefaultValue : function(component, event, helper) {
    	component.set('v.value', component.get('v.default'));
    },

    setValue : function(component, event, helper) {
    	component.set('v.value', event.currentTarget.value);
    },
})