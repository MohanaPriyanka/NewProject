({
	doInit : function(component, event, helper) {
		helper.getClientId(component, helper);
		helper.getClientReportData(component, helper);
	}, 

	setReportId : function(component, event, helper) {
		var selectedReportName = component.get('v.selectedReportName');
		component.set('v.selectedReportId', component.get('v.reports')[selectedReportName]);
	}, 

})