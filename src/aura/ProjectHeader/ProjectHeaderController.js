/**
 * Created by SarahRenfro on 7/25/2019.
 */

({
    doInit : function(component, event, helper) {
        var action = component.get("c.getProject");
        // action.setParams({"projectId" : "a1J4B000002Rk8J"});
        action.setParams({"projectId": component.get("{!v.recordId}")});
        action.setCallback(this, function (resp) {
            if (resp.getState() == 'SUCCESS') {
                component.set("v.project", resp.getReturnValue());
            } else {
                $A.log("Errors", resp.getError());
            }
        });
        $A.enqueueAction(action);
    }
});