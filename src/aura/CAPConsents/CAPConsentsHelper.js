({
	getSRECProducts : function(component, event, helper, lead) {
		var i;
        var action = component.get("c.getProducts");
        action.setParams({state: component.get("v.lead.LASERCA__Home_State__c"),
                          productType: 'SREC'});
        action.setCallback(this,function(resp){
            if (resp.getState() == 'SUCCESS') {
                var srecOptions = resp.getReturnValue();
                for (i=0; i <= srecOptions.length; i++) {
                    if (srecOptions[i] != null) {
                        if (srecOptions[i]["Name"] === lead.SREC_Product__r.Name) {
                            var selectedIndex = i; 
                            var selectedSrec = srecOptions[i];
                        }
                    }
                }
                resp.getReturnValue().unshift(selectedSrec);
                resp.getReturnValue().splice(selectedIndex + 1, 1);
                component.set("v.availableSRECProducts", resp.getReturnValue());
            } else {
                helper.logError("SLPSendApplicationEmailController", "availableSRECProducts", resp.getError());
            }
        });
        $A.enqueueAction(action);
	}
})