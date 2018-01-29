({
    checkLoanNum : function(component, event, helper) {
    	const oppID = component.get("v.OppId");
        const emailInput = component.get("v.emailInput");

    	var IDPromise = helper.insertRecord(component, oppID, emailInput, helper);
        IDPromise.then($A.getCallback(function resolve(retVal) {
			var docInterval = window.setInterval($A.getCallback(function() {
	            helper.checkForLink(component,retVal, helper);
	        }), 2000);
	       	window.setTimeout(function() {clearInterval(docInterval)},8000)
	    }));
    },
})