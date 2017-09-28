({
	doInit : function(component, event, helper) {
        var actionDashboardWidgets = component.get("c.getDashboardWidgets");        
        actionDashboardWidgets.setCallback(this,function(resp){
            if(resp.getState() == 'SUCCESS') {
                var widgets = resp.getReturnValue();
                component.set("v.widgets", resp.getReturnValue());
            }
            else {
                $A.log("Errors", resp.getError());
            }
        });    
        $A.enqueueAction(actionDashboardWidgets);          

        //The following block of code retrieves the user's license type to determine what to display on the UI
        var actionLicenseType = component.get("c.getLicenseType");        
        actionLicenseType.setCallback(this,function(resp){
            if(resp.getState() == 'SUCCESS') {
                if (resp.getReturnValue() != null) {
                    if(resp.getReturnValue().length > 0){
                        if(resp.getReturnValue() == 'Executive')
                        component.set("v.licenseType", true);
                    }
                }
            }    
            else {
                $A.log("Errors", resp.getError());
            }
        });    
        $A.enqueueAction(actionLicenseType);                         
        
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