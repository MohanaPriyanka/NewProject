({
    doInit : function(component, event, helper) {
        // Retrieve report rows during component initialization }
        helper.startAsyncReport(component, helper);
    },

    exportToCSV : function(component, event, helper) {
        var action = component.get('c.sendCSVReport');
        var reportId = component.get('v.reportId');
        var reportName = component.get('v.selectedReport');
        action.setParams({
            'reportId': reportId,
            'reportName': reportName
        });
        action.setCallback(this,function(resp) {
            var message;
            if (resp.getState() === 'SUCCESS' && resp.getReturnValue()) {
                var title = 'Report Sent';
                message = reportName + ' report has been sent to the email associated with this account.';
                helper.showToast(component, title, message);
            } else {
                message = 'Report ID: ' + reportId;
                message += ' Client ID: ' + clientId;
                helper.logError('LightningReportController', 'exportToCSV', resp.getError(), message);
            }
        });
        $A.enqueueAction(action);
    },
})