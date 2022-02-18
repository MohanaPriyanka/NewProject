({
	doInit : function(component, event, helper) {
		var action = component.get("c.getSolarSystem");
    	action.setCallback(this,function(resp){
            if(resp.getState() == 'SUCCESS') {
                component.set("v.farmName", resp.getReturnValue().Name);
                component.set("v.farmCOD", resp.getReturnValue().Estimated_COD_Date__c);
                component.set("v.farmShares", resp.getReturnValue().Capacity_Available_to_be_Reserved__c);
            }
            else {
                $A.log("Errors", resp.getError());
            }
    	});
	    $A.enqueueAction(action);
        var action2 = component.get("c.getUsers");
    	action2.setCallback(this,function(resp){
            if(resp.getState() == 'SUCCESS') {
        		component.set("v.users", resp.getReturnValue());
            }
            else {
                $A.log("Errors", resp.getError());
            }
    	});
        $A.enqueueAction(action2);
        var action3 = component.get("c.getProject");
    	action3.setCallback(this,function(resp){
            if(resp.getState() == 'SUCCESS') {
                component.set("v.project", resp.getReturnValue());
            }
            else {
                $A.log("Errors", resp.getError());
            }
    	});
	    $A.enqueueAction(action3);
	}
})