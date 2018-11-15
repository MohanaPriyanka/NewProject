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
	},      
    
    removeDisplay : function(component, event, helper) {
    	var widgetsToggle = component.find("disbursalWidgets");
        var partnerLogo = component.find("partnerLogo");	
        $A.util.addClass(widgetsToggle, 'noDisplayBar');
        $A.util.addClass(partnerLogo, 'noDisplayBar');
	},    
    
    showDisplay : function(component, event, helper) {
    	var widgetsToggle = component.find("disbursalWidgets");
        var partnerLogo = component.find("partnerLogo");	
        $A.util.removeClass(widgetsToggle, 'noDisplayBar');
        $A.util.removeClass(partnerLogo, 'noDisplayBar');
	},    
})