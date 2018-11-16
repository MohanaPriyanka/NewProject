({
    startAsyncReport : function(component, helper) {
        component.set('v.loading', true);
        var action = component.get('c.getAsyncReport');
        action.setParams({
            "reportId" : component.get('v.reportId')
        });
        action.setCallback(this,function(resp) {
            if (resp.getState() === 'SUCCESS') {
                var asyncReportId = resp.getReturnValue();
                component.set('v.asyncReportId', asyncReportId);
                helper.checkAsyncReport(component, helper, asyncReportId);
            } else {
                helper.logError('LightningReportHelper', 'startAsyncReport', resp.getError(), component.get('v.reportObject'));
            }
        });
        $A.enqueueAction(action);
    },

    checkAsyncReport : function(component, helper, asyncReportId) {
        var action = component.get('c.checkAsyncReport');
        action.setParams({"asyncReportId" : asyncReportId});
        action.setCallback(this, function(resp) {
            if (resp.getState() === 'SUCCESS') {
                if (resp.getReturnValue()) {
                    helper.getAsyncReport(component, helper, asyncReportId);
                } else {
                    helper.checkAsyncReport(component, helper, asyncReportId);
                }
            } else {
                helper.logError('LightningReportHelper', 'checkAsyncReport', resp.getError(), component.get('v.reportObject'));
            }
        })
        $A.enqueueAction(action);
    },

    getAsyncReport : function(component, helper, asyncReportId) {
        var action = component.get('c.getAsyncReportResponseWithoutRows');
        action.setStorable();
        action.setParams({"asyncReportId" : asyncReportId});
        action.setCallback(this, function(resp) {
            if (resp.getState() === 'SUCCESS') {
                var reportObject = resp.getReturnValue();
                component.set('v.reportObject', reportObject);
                component.set('v.loading', false);
            } else {
                helper.logError('LightningReportHelper', 'getAsyncReport', resp.getError(), component.get('v.reportObject'));
            }
        })
        $A.enqueueAction(action);
    },
})