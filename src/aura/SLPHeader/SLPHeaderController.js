({
	doInit : function(component, event, helper) {
        var action = component.get("c.getUserName");
    	action.setCallback(this,function(resp){
            if(resp.getState() == 'SUCCESS') {
        		component.set("v.userName", resp.getReturnValue());
            }
            else {
                $A.log("Errors", resp.getError());
            }
    	});
	    $A.enqueueAction(action);
	} , 

    hideDisplay : function(component, event, helper) {
        var headerDisplay = component.find("header");
        $A.util.addClass(headerDisplay, 'noDisplayBar');   
    } , 
})