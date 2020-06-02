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
                helper.getDataQueryResult(component, helper, dataQueryId, 0);
            } else {
                component.set("v.errorMessage", 'An error has occurred. BlueWave has been notified. Please check back later');
                component.set("v.showError", true);
            }
        });

        $A.enqueueAction(actionStartOutstandingItemsQuery);
    },

    getDataQueryResult : function(component, helper, dataQueryId, numberOfQueries) {
        var actionGetQueryResult = component.get("c.getQueryResult");
        actionGetQueryResult.setParams({
            "dataQueryId" : dataQueryId
        });
        actionGetQueryResult.setCallback(this, function(resp) {
            if (resp.getState() === 'SUCCESS') {
                if (resp.getReturnValue()) {
                    component.set("v.outstandingItemsByDate", JSON.parse(resp.getReturnValue()));
                    console.log(component.get('v.outstandingItemsByDate'));
                } else {
                    if (numberOfQueries < 30) {
                        window.setTimeout(
                            $A.getCallback(function() {
                                helper.getDataQueryResult(component, helper, dataQueryId, numberOfQueries++);
                            }), 1000);
                    }
                }
            }
        });
        $A.enqueueAction(actionGetQueryResult);
    }
});