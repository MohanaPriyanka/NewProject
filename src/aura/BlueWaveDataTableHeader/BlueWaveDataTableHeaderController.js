({
    doInit : function(component, helper) {
    	var map = component.get("v.headerMap");
    	var label = component.get("v.label");
    	var fieldName = map[label];
    	component.set("v.fieldName", fieldName);
    },

    sortTable: function(component, event, helper) {
    	$A.util.removeClass(component.find("sortArrow"), 'noDisplay'); 

    	var order = component.get("v.sortAsc");
    	var newOrder = !order;
    	component.set("v.sortAsc", newOrder);

        var sortField = event.currentTarget.name;
        var sortTableEvt = component.getEvent("sortTable");
        sortTableEvt.setParams({ sortField: sortField }); 
        sortTableEvt.fire();       
    },
})