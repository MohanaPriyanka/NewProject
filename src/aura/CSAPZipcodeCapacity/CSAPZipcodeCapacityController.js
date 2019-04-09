/**
 * Created by AlyssaCooper on 1/29/2019.
 */
({
    onSubmit : function (component, event, helper) {
        var action = component.get("c.hasCapacity"); //call the method instead
        var zipcode = component.get("v.zipcode");
        action.setParams({'zipcode':zipcode});
        action.setCallback(this, function(resp) {
            var response = resp.getReturnValue();
            if(resp.getState() === "SUCCESS") {
                component.set("v.hasCapacity", response);

                if (component.get("v.hasCapacity")) {
                    helper.sendCSApplication(component, helper);
                } else {
                    component.set("v.page", "NoProject");
                }
            }
            else {
                helper.logError("CSAPZipcodeCapacityController", "hasCapacity",
                    "There was an issue checking your zipcode, but has been logged. Please call Customer Care at the number below for assistance.",
                    resp.getError());
            }
        });
        $A.enqueueAction(action);
    },

    keyCheck : function(component, event, helper) {
        var zipcode = component.get('v.zipcode');
        if (event.which === 13) {
            event.preventDefault();
            if (zipcode.length === 5) {
                var action = component.get("c.onSubmit");
                $A.enqueueAction(action);
            }
        }
    }
});