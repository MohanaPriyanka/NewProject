/*
 * Created by mstackhouse on 8/20/2018.
 */
({
    getAsyncReportGroupRows : function(component, helper, asyncReportId, groupKey) {
        var action = component.get('c.getAsyncSummaryReportGroup');
        action.setStorable();
        action.setParams({
            'asyncReportId': asyncReportId,
            'groupKey': groupKey
        });
        action.setCallback(this, function(resp) {
            if (resp.getState() === 'SUCCESS') {
                var groupFieldData = resp.getReturnValue();
                groupFieldData.visibleChild = true;
                var componentValue = 'v.reportObject.sumResp.groupMap[' + groupKey + ']';
                component.set(componentValue, groupFieldData);

                var reportObject = component.get('v.reportObject');
                var groupList = Object.values(reportObject.sumResp.groupMap);
                component.set('v.groupList', groupList);
                component.set('v.loading', false);
            } else {
                helper.logError('LightningReportGroupComponentHelper', 'getAsyncReportGroupRows', resp.getError(), component.get('v.reportObject'));
            }
        });
        $A.enqueueAction(action);
    }
})