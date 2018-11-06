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
        if(component.get("v.StaticTotalDue") === 0){
            component.set("v.chOrder.Autopay_Only__c", true);
        }

        let thisYear = new Date().getFullYear();
        let years = [];
        for (let i=0; i<8; i++) {
            years.push(''+(thisYear + i));
        }
        component.set('v.expirationYears', years);
    },

    returnToMyAccount : function(component, event, helper) {
        $A.get('e.force:refreshView').fire();
    },

    boxIsChecked : function(component, event, helper) {
        var isChecked = component.get("v.chOrder.Autopay_Only__c");
        if (isChecked){
            component.set("v.DynamicTotalDue", 0);
        } else {
            component.set("v.DynamicTotalDue", component.get("v.StaticTotalDue"));
        }
    },

    makePaymentOrder : function(component, event, helper) {
        if (component.get("v.SelectedPaymentMethod") === 'ACH') {
            component.set("v.chOrder.ChargentOrders__Payment_Method__c", 'Check');
        } else {
            component.set("v.chOrder.ChargentOrders__Payment_Method__c", component.get("v.SelectedPaymentMethod"));
        }
        var chOrFields = component.get("v.chOrder");
        var errors = helper.checkInputs(component, chOrFields);
        if (!errors){
            var insertOrderPromise = helper.insertOrders(component, chOrFields, helper);
            insertOrderPromise.then(
                $A.getCallback(function(result) {
                    if(component.get("v.chOrder.Autopay_Only__c") === false){
                        component.set("v.transactionsCreated", []);
                        var ordersToInsert = component.get("v.readyToChargeOrders");
                        helper.submitPayments(component, ordersToInsert, helper, true);
                    } else{
                        component.set("v.Spinner", false);
                        helper.showOrderCreated(component);
                    }
                })
            );
        }
    },

    clearFields : function(component, event, helper) {
        let chOrder = component.get('v.chOrder');
        component.set('v.chOrder', { 'sobjectType': 'ChargentOrders__ChargentOrder__c',
            'ChargentOrders__Payment_Method__c' : '',
            'ChargentOrders__Bank_Name__c' : '',
            'ChargentOrders__Bank_Routing_Number__c' : '',
            'ChargentOrders__Bank_Account_Type__c' : '',
            'ChargentOrders__Bank_Account_Number__c' : '',
            'ChargentOrders__Bank_Account_Name__c' : '',
            'ChargentOrders__Billing_Email__c' : 'compliance@bluewavesolar.com',
            'ChargentOrders__Card_Type__c' : '',
            'ChargentOrders__Card_Number__c' : '',
            'ChargentOrders__Card_Expiration_Month__c' : '',
            'ChargentOrders__Card_Expiration_Year__c' : '',
            'ChargentOrders__Billing_Address__c' : '',
            'ChargentOrders__Billing_City__c' : '',
            'ChargentOrders__Billing_State__c' : '',
            'ChargentOrders__Billing_Zip_Postal__c' : '',
            'ChargentOrders__Billing_First_Name__c' : '',
            'ChargentOrders__Billing_Last_Name__c' : '',
            'Autopay_Only__c': chOrder.Autopay_Only__c});
    }
})