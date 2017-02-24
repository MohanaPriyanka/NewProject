({
    dashboardMenuOutput : function(component, event) {            
        var label = event.getParam("propertyAccountId");
        //var source = event.getSource();
        //var label = source.get("v.label"); 
       
        var actionMyAccountBill = component.get("c.getDashboardBill"); //shows the total due for the property account selected
		var actionMySavings = component.get("c.getDashboardSavings"); //shows the total savings for the property account selected
		var actionMyProduction = component.get("c.getDashboardProduction"); //shows the total savings for the property account selected        
                        
        actionMyAccountBill.setParams({propertyAccountId : label});
 		actionMySavings.setParams({propertyAccountId : label});
 		actionMyProduction.setParams({propertyAccountId : label});         
                                               
        actionMyAccountBill.setCallback(this,function(resp){ //shows the total due for the property account selected
            if(resp.getState() == 'SUCCESS') {
                component.set("v.myBill", resp.getReturnValue());
            }
            else {
                $A.log("Errors", resp.getError());
            }
        });
        actionMySavings.setCallback(this,function(resp){ //shows the total due for the property account selected
            if(resp.getState() == 'SUCCESS') {
                component.set("v.mySavings", resp.getReturnValue());
            }
            else {
                $A.log("Errors", resp.getError());
            }
        });
        actionMyProduction.setCallback(this,function(resp){ //shows the total due for the property account selected
            if(resp.getState() == 'SUCCESS') {
                component.set("v.myProduction", resp.getReturnValue());
            }
            else {
                $A.log("Errors", resp.getError());
            }
        });         
        $A.enqueueAction(actionMyAccountBill);
        $A.enqueueAction(actionMySavings); 
        $A.enqueueAction(actionMyProduction);         
    }
,    
         
	doInit : function(component, event, helper) {
		//var action = component.get("c.getDashboardInfo");
		var actionBill = component.get("c.getDashboardBill"); 
		var actionSavings = component.get("c.getDashboardSavings");
        var actionProduction = component.get("c.getDashboardProduction");
        var actionGetMenuLabels = component.get("c.getMenuLabelList");        
        
        actionBill.setCallback(this,function(resp){
            if(resp.getState() == 'SUCCESS') {
                component.set("v.myBill", resp.getReturnValue());
            }
            else {
                $A.log("Errors", resp.getError());
            }
        });
        actionSavings.setCallback(this,function(resp){
            if(resp.getState() == 'SUCCESS') {
                component.set("v.mySavings", resp.getReturnValue());
            }
            else {
                $A.log("Errors", resp.getError());
            }
        });
        actionProduction.setCallback(this,function(resp){
            if(resp.getState() == 'SUCCESS') {
                component.set("v.myProduction", resp.getReturnValue());
            }
            else {
                $A.log("Errors", resp.getError());
            }
        });           
        
        actionGetMenuLabels.setCallback(this,function(resp){
            if(resp.getState() == 'SUCCESS') {
                component.set("v.menuLabels", resp.getReturnValue());
            }
            else {
                $A.log("Errors", resp.getError());
            }
        });          
               	$A.enqueueAction(actionGetMenuLabels); 
    	/*action.setCallback(this,function(resp){
            if(resp.getState() == 'SUCCESS') {
        		component.set("v.myBill", resp.getReturnValue().myBill);
                component.set("v.mySavings", resp.getReturnValue().mySavings);
                component.set("v.myConsumption", resp.getReturnValue().myConsumption);
                component.set("v.myProduction", resp.getReturnValue().myProduction);
            }
            else {
                $A.log("Errors", resp.getError());
            }
    	});*/
         
	    //$A.enqueueAction(action);
 		$A.enqueueAction(actionBill);
 		$A.enqueueAction(actionSavings);
 		$A.enqueueAction(actionProduction);         
        
	}
})