({
    doInit : function(component, event, helper) {
        var actionStates = component.get("c.getStates");        
        actionStates.setCallback(this,function(resp){
            if (resp.getState() === 'SUCCESS') {
                component.set("v.States", resp.getReturnValue());    
            } else {
                component.set("v.States", "MA");
            }
        });   
        $A.enqueueAction(actionStates);

        component.set("v.DynamicTotalDue", component.get("v.StaticTotalDue"));
    },  

    returnToMyAccount : function(component, event, helper) {
        $A.get('e.force:refreshView').fire();
    },    

    makePaymentOrder : function(component, event, helper) {
        if (component.get("v.ACH") === 'true'){
            component.set("v.chOrder.ChargentOrders__Payment_Method__c", 'Check');
        } else {
            component.set("v.chOrder.ChargentOrders__Payment_Method__c", 'Credit Card');
        }
        var chOrFields = component.get("v.chOrder");
        var errors = helper.checkInputs(component, chOrFields);
        if (!errors){
            var insertOrderPromise = helper.insertOrders(component, chOrFields, helper);
            insertOrderPromise.then(
                $A.getCallback(function(result) {
                    component.set("v.transactionsCreated", []);
                    var ordersToInsert = component.get("v.readyToChargeOrders");
                    helper.submitPayments(component, ordersToInsert, helper);
                })
            );
        }
    },    
})


