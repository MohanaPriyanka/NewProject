({
    doInit : function(component, event, helper) {
        const orderToInsert = { 'sobjectType' : 'ChargentOrders__ChargentOrder__c',
                                'Comments__c' : 'Created For Payment Request',
                                'ChargentOrders__Subtotal__c' : 0.01,
                                'ChargentOrders__Charge_Amount__c' : 0.01,
                                'ChargentOrders__Gateway__c' : 'a1w210000007hd7',
                                'Opportunity__c' : component.get("v.OppId")};
        
        const ChargentOrderPromise = helper.insertSObject(component, orderToInsert);

        ChargentOrderPromise.then($A.getCallback(function resolve(returnValue) {
            const payRequest = { 'sobjectType' : 'ChargentOrders__Payment_Request__c',
                                'Status' : 'Created',
                                'Send_Payment_Request_Email__c' : false,
                                'ChargentOrders__ChargentOrder__c' : returnValue.Id};
            const PaymentRequestPromise = helper.insertSObject(component, payRequest);
            PaymentRequestPromise.then($A.getCallback(function resolve(retVal) {
                var docInterval = window.setInterval($A.getCallback(function() {
                    helper.checkForLink(component,retVal.Id);}), 2000);
            }));
        }));
    },
})