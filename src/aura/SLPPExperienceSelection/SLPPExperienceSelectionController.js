({
	doInit : function(component, event, helper) {
        var evtHideHeader = $A.get("e.c:SLPLandingPageEvent");
        evtHideHeader.setParams({"dashboardDisplay": "true"});
        evtHideHeader.fire(); 		
	}
})