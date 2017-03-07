({
	doInit : function(component, event, helper) {
        
		var actionLogo = component.get("c.getPartnerLogo");        
        actionLogo.setCallback(this,function(resp){
            if(resp.getState() == 'SUCCESS') {
                component.set("v.partnerLogo", resp.getReturnValue());
            }
            else {
                $A.log("Errors", resp.getError());
            }
        });    
        $A.enqueueAction(actionLogo);
	}


})