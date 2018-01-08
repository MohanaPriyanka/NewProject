({
    doInit : function(component, event, helper) {
    	optionsMap = component.get('v.optionsMap');
    	var options = [];
    	for (var key in optionsMap) {
    		options.push({value:optionsMap[key], key:key});
    	}
    	component.set('v.options', options);
    },
})