({
	doInit : function(component) {
		var reportObject = component.get('v.reportObject');
		if (reportObject !== null) {
			var groupList = Object.values(reportObject.sumResp.groupMap);
			component.set('v.groupList', groupList);
		}
	},

	openChildRecords : function(component, event, helper) {
		var groupList = component.get('v.groupList');
		var groupKey = event.currentTarget.dataset.groupkey;
		var asyncReportId = component.get('v.asyncReportId');
		if (+groupList[+groupKey].groupKey === +groupKey) {
			if (groupList[+groupKey].fieldDataList.length === 0) {
				component.set('v.loading', true);
				helper.getAsyncReportGroupRows(component, helper, asyncReportId, groupKey);
			} else {
				groupList[+groupKey].visibleChild = !groupList[+groupKey].visibleChild;
			}
		} else {
		    let message = 'group key' + groupKey + 'does not exist';
			helper.logError('LightningReportGroupComponentController', 'openChildRecords', message, component.get('v.reportObject'));
		}
		component.set('v.groupList', groupList);
	},
})