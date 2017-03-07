({
	
    dashboardMenuOutput : function(component, event, helper) {    
        
        var source = event.getSource();
        var num1 = source.get("v.label");
        var evt = $A.get("e.c:DashboardMenu");
        evt.setParams({"propertyAccountId": num1});
        evt.fire();
    }
,    
    doInit : function(component, event, helper) {
        
        var actionGetMenuLabels = component.get("c.getMenuLabelList");              
        
        actionGetMenuLabels.setCallback(this,function(resp){
            if(resp.getState() == 'SUCCESS') {
                component.set("v.menuLabels", resp.getReturnValue());
            }
            else {
                $A.log("Errors", resp.getError());
            }
        });     
        
       $A.enqueueAction(actionGetMenuLabels);
		/*var action = component.get("c.hasBill");
    	action.setCallback(this,function(resp){
            if(resp.getState() == 'SUCCESS') {
        		component.set("v.isViewable", resp.getReturnValue());
            }
            else {
                $A.log("Errors", resp.getError());
            }
    	});
	    $A.enqueueAction(action);*/
        var action2 = component.get("c.getName");
    	action2.setCallback(this,function(resp){
            if(resp.getState() == 'SUCCESS') {
        		component.set("v.name", resp.getReturnValue());
            }
            else {
                $A.log("Errors", resp.getError());
            }
    	});
	    $A.enqueueAction(action2);
	}
})