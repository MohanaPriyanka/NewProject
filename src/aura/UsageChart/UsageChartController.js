({
	loadChart : function(component, event, helper) {
		helper.loadChart(component);
	},
    
    onRangeChange : function(component, event, helper) {
    	var selected = component.find("rangeselect").get("v.value");
        helper.drawChart(component, selected);
	}
})