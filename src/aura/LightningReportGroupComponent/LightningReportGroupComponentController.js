({
	openChildRecords : function(component, event, helper) {
		var reportObject = component.get('v.reportObject');
		for (i=0; i<reportObject.sumResp.groupList.length;i++) {
			if (reportObject.sumResp.groupList[i].groupKey == event.currentTarget.dataset.groupkey) {
				if (reportObject.sumResp.groupList[i].visibleChild) {
					reportObject.sumResp.groupList[i].visibleChild = false;
				} else {
					reportObject.sumResp.groupList[i].visibleChild = true;
				}
			}
		} 
		component.set('v.reportObject', reportObject);
	},

	expandAllChilds : function(component, event, helper) {
		var reportObject = component.get('v.reportObject');
		for (i=0; i<reportObject.sumResp.groupList.length;i++) {
			console.log(reportObject.sumResp.groupList[i].visibleChild);
			reportObject.sumResp.groupList[i].visibleChild = true;
		}
		component.set('v.reportObject', reportObject);
		component.set('v.expandAll', true);
	},

	closeAllChilds : function(component, event, helper) {
		var reportObject = component.get('v.reportObject');
		for (i=0; i<reportObject.sumResp.groupList.length;i++) {
			reportObject.sumResp.groupList[i].visibleChild = false;
		}
		component.set('v.reportObject', reportObject);
		component.set('v.expandAll', false);
	}
})