({
    getProductsHelper : function(component, event, helper) {
        var source = event.getSource();
        var leadId = source.get("v.class");
        if (!$A.util.isUndefinedOrNull(component.get("v.leadId"))) {
            leadId = component.get("v.leadId");
        }
        var action = component.get("c.getCustomerProducts"); 
        var customerTable = component.find("customerTable");
        var productTable = component.find("productTable");
        var searchBar = component.find("customerSearchBar");
        var searchButton = component.find("customerSearchButton");

        component.set("v.leadId", leadId);

        action.setParams({leadId : leadId});

        action.setCallback(this,function(resp){ 
            if(resp.getState() == 'SUCCESS') {
                component.set("v.allProducts", resp.getReturnValue());
                $A.util.addClass(customerTable, 'noDisplay');
                $A.util.addClass(searchButton, 'noDisplay');
                $A.util.addClass(searchBar, 'noDisplay');
                $A.util.removeClass(productTable, 'noDisplay');
            }
            else {
                $A.log("Errors", resp.getError());
            }
        });        
        $A.enqueueAction(action);        
    }
})