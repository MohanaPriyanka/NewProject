({
    loadChart : function(component, event, helper) {
	helper.loadChart(component);
    },

    removeDisplay : function(component, event, helper) {
    	var chartToggle = component.find("stageChart");	
        $A.util.addClass(chartToggle, 'noDisplayBar');
	},
    
    showDisplay : function(component, event, helper) {
    	var chartToggle = component.find("stageChart");	
        $A.util.removeClass(chartToggle, 'noDisplayBar');
	},    
})