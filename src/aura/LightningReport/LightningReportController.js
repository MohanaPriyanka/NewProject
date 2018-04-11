({
	doInit : function(component, event, helper) {
        // Retrieve report rows during component initialization }
        helper.getReportRows(component, helper);
    },

    exportToCSV : function(component, event, helper) {
    	var csv = helper.convertToCSV(component, component.get("v.reportObject"));
    	if (csv != null){
    		var hiddenElement = document.createElement('a');
    		hiddenElement.href = 'data:text/csv;charset=utf-8,' + encodeURI(csv);
			hiddenElement.target = '_self'; // 
			hiddenElement.download = component.get('v.selectedReport') + '.csv';
			document.body.appendChild(hiddenElement);
			hiddenElement.click(); 
		} 
	},
})