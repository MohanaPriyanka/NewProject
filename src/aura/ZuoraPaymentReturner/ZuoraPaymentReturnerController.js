/**
 * Created by PeterYao on 8/27/2019.
 */

({
    returnPayment : function(component, event, helper) {
        component.set('v.loading', true);
        component.set('v.confirm', false);
        var action = component.get('c.reverseReturnedPayment');
        action.setParams({"paymentId": component.get("v.recordId")});
        action.setCallback(this, function(resp) {
            component.set('v.loading', false);
            var result = resp.getReturnValue();
            component.set('v.result', result);
            if (result.success) {
                component.set('v.successMessage', result.debitMemos.length + ' debit memos created and posted successfully');
            }
        });
        $A.enqueueAction(action);
    }
});