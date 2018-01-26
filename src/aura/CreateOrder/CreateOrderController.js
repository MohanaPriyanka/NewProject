({
    checkLoanNum : function(component, event, helper) {
    	const oppID = component.get("v.OppId");
        const emailInput = component.get("v.emailInput");

    	const IDPromise = helper.checkID(component, oppID, emailInput);
        IDPromise.then($A.getCallback(function resolve(retVal) {
    		console.log(retVal);
	        const opportunity = component.get("v.OppId");
	        const PaymentRequestPromise = helper.insertRecord(component, opportunity);    
	        PaymentRequestPromise.then($A.getCallback(function resolve(retVal) {
	           var docInterval = window.setInterval($A.getCallback(function() {
	               helper.checkForLink(component,retVal.Id);}), 2000);
	       }));    	
	    }));
    },
})