({
    getProductsHelper : function(component, event, helper) {
        if (!$A.util.isUndefinedOrNull(component.get("v.leadId"))) {
            var leadId = component.get("v.leadId");
        } else {
            var source = event.getSource();
            var leadId = source.get("v.class").Id;
            component.set("v.customerName", source.get("v.class").Name);
            if (source.get("v.class").LASERCA__Home_State__c === 'MA') {
                component.set("v.srecCustomer", true);
            } else {
                component.set("v.srecCustomer", false);
            }
        }
        var action = component.get("c.getCustomerProducts"); 

        component.set("v.leadId", leadId);
        component.set("v.customerName", source.get("v.class").Name);
        if (source.get("v.class").LASERCA__Home_State__c === 'MA') {
            component.set("v.srecCustomer", true);
        } else {
            component.set("v.srecCustomer", false);
        }

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
