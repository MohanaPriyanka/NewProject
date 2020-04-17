/**
 * Created by AlyssaCooper on 1/29/2019.
 */
({
    sendCSApplication : function(component, helper) {
        console.log('Made it to sendCSApplication');
        //need to generate a URL with the partnerId = CS Self-Originations
        var action = component.get("c.getCSApplicationURL");
        action.setCallback(this, function(resp){
            if (resp.getState() === "SUCCESS") {
                var appURL = resp.getReturnValue();
                window.open(appURL, '_top');
            } else {
                component.set("v.page", "FailedURL");
                helper.logError("CSAPZipcodeCapacityHelper", "sendCSApplication", resp.getError(), "Failed to generate CSAP URL");
            }
        });
        $A.enqueueAction(action);

        //window.parent.location.replace(url);

    },



});