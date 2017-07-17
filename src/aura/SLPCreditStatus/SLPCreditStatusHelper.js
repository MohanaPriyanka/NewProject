({
    getProductsHelper : function(component, event, helper) {
        var source = event.getSource();
        var leadId = source.get("v.class");
        if (!$A.util.isUndefinedOrNull(component.get("v.leadId"))) {
            leadId = component.get("v.leadId");
        }
        var action = component.get("c.getCustomerProducts"); 

        component.set("v.leadId", leadId);

        action.setParams({leadId : leadId});

        action.setCallback(this,function(resp){ 
            if(resp.getState() == 'SUCCESS') {
                if (resp.getReturnValue().length == 0) {
                    component.set("v.noAvailableProducts", true);                    
                }
                component.set("v.allProducts", resp.getReturnValue());
                $A.util.addClass(component.find("customerTable"), 'noDisplay');
                $A.util.addClass(component.find("customerSearchButton"), 'noDisplay');
                $A.util.addClass(component.find("customerSearchBar"), 'noDisplay');
                $A.util.removeClass(component.find("productTable"), 'noDisplay');
            }
            else {
                $A.log("Errors", resp.getError());
            }
        });        
        $A.enqueueAction(action);        
    }
})