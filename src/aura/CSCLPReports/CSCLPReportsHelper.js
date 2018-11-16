({
	getClientId : function(component, helper) {
		var action = component.get('c.getClientId');
		action.setCallback(this,function(resp) {
			if (resp.getState() === 'SUCCESS') {
				var clientId15Digits = resp.getReturnValue().slice(0,15);
				component.set('v.clientId', clientId15Digits);
			} else {
				helper.logError('CSCLPReportsHelper', 'getClientReportData', resp.getError(), component.get('v.clientId'));
			}
		});
		$A.enqueueAction(action);
	},

	getClientReportData : function(component, helper) {
		var action = component.get('c.getClientReportData');
		action.setCallback(this,function(resp) {
			if (resp.getState() === 'SUCCESS') {
				var reports = resp.getReturnValue().reports;
				var sssList = resp.getReturnValue().sssList;
				var sssNames = [];
				for (i=0; i<sssList.length; i++) {
					sssNames.push(sssList[i]['Name']);
				}
				this.setReportAttributes(component, reports, sssNames);
			} else {
				helper.logError('CSCLPReportsHelper', 'getClientReportData', resp.getError(), null);
			}
		});
		$A.enqueueAction(action);
	},

	setReportAttributes : function(component, reports, sssNames) {
		component.set('v.reports', reports);
		component.set('v.selectedReportName', Object.keys(reports)[0]);
		component.set('v.reportIds', Object.values(reports));
		component.set('v.reportNames', Object.keys(reports));
		component.set('v.sssNames', sssNames);
	},
})