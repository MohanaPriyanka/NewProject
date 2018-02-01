({
    checkEmail : function(component, event, helper) {
    	const oppID = component.get("v.OppId");
        const emailInput = component.get("v.emailInput");
    	helper.checkOppEmail(component, oppID, emailInput, helper);
    },

    submitOrder : function(component, event, helper) {
        const oppID = component.get("v.OppId");
        const emailInput = component.get("v.emailInput");
        const chOrderInput = component.get("v.chOrder");
        helper.insertRecord(component, oppID, emailInput, chOrderInput, helper);
    },
})