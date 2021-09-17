/**
 * Created by PeterYao on 8/27/2019.
 */

({
    returnPayment : function(component) {
        component.set('v.loading', true);
        component.set('v.confirm', false);
        let action = component.get('c.reverseReturnedPayment');
        action.setParams({"paymentId": component.get("v.recordId")});
        action.setCallback(this, function(resp) {
            component.set('v.loading', false);
            let result = resp.getReturnValue();
            component.set('v.result', result);
            if (result.success) {
                component.set('v.successMessage', result.message);
            }
        });
        $A.enqueueAction(action);
    },

    cancel : function() {
        $A.get("e.force:closeQuickAction").fire();
    }
});