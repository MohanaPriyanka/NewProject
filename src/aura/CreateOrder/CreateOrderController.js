({
    doInit : function(component, event, helper) {
        const opportunity = component.get("v.OppId");
        const PaymentRequestPromise = helper.insertRecord(component, opportunity);
        PaymentRequestPromise.then($A.getCallback(function resolve(retVal) {
           var docInterval = window.setInterval($A.getCallback(function() {
               helper.checkForLink(component,retVal.Id);}), 2000);
       }));
    },
})