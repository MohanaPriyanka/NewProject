/**
 * Created by peteryao on 5/28/20.
 */

({
    getOutstandingItems : function(component, helper, zuoraAccountId) {
        var actionStartOutstandingItemsQuery = component.get("c.startOutstandingItemsQuery");

        actionStartOutstandingItemsQuery.setParams({
            "zuoraAcctId" : zuoraAccountId
        });

        actionStartOutstandingItemsQuery.setCallback(this, function(resp) {
            if (resp.getState() === 'SUCCESS') {
                var dataQueryId = resp.getReturnValue();
                let millisToWaitForDataQuery = 60*1000;
                component.set("v.outstandingItemsQueryTimeout", Date.now() + millisToWaitForDataQuery);
                helper.getDataQueryResult(component, helper, dataQueryId);
            } else {
                component.set("v.errorMessage", 'An error has occurred. BlueWave has been notified. Please check back later');
                component.set("v.showError", true);
            }
        });

        $A.enqueueAction(actionStartOutstandingItemsQuery);
    },

    getDataQueryResult : function(component, helper, dataQueryId) {
        var actionGetQueryResult = component.get("c.getQueryResult");
        actionGetQueryResult.setParams({
            "dataQueryId" : dataQueryId
        });
        actionGetQueryResult.setCallback(this, function(resp) {
            if (resp.getState() === 'SUCCESS') {
                if (resp.getReturnValue()) {
                    component.set("v.outstandingItemsByDate", JSON.parse(resp.getReturnValue()));
                } else {
                    if (Date.now() <= component.get('v.outstandingItemsQueryTimeout')) {
                        window.setTimeout(
                            $A.getCallback(function() {
                                helper.getDataQueryResult(component, helper, dataQueryId);
                            }), 1000);
                    } else {
                        component.set("v.errorMessage", 'We could not retrieve details about your balance to allocate by gateway. Please contact customer care.');
                        component.set("v.showError", true);
                    }
                }
            }
        });
        $A.enqueueAction(actionGetQueryResult);
    }
});