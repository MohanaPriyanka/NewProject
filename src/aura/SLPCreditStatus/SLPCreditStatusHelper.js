({
    getProductsHelper : function(component, event, helper) {
        return new Promise(function(resolve, reject) {
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
                    resolve(helper);
                }
                else {
                    $A.log("Errors", resp.getError());
                }
            });        
            $A.enqueueAction(action);
        });
    },

    updateProductSelection : function(component, event, helper) { 
        var source = event.getSource();
        var productId = source.get("v.class"); 
        var productTerm = source.get("v.name");
        // The value of the toggle before it was checked, e.g. if toggle is turned off,
        // this will be true
        var valueBeforeToggle = source.get("v.value");

        helper.toggleProductSelection(component, helper, productId, productTerm, !valueBeforeToggle);
    },

    toggleProductSelection : function(component, helper, prodId, term, selected) { 
        var customerEmailButton = component.find("customerEmailButton");
        var incomeFormButton = component.find("incomeFormButton");

        if (selected) {
            component.set("v.productId", prodId); 
            component.set("v.loanTerm", term);
            if (prodId !== component.get("v.allCustomers[0].Product__c")) {
                helper.saveSObject(component, 
                                   component.get("v.allCustomers[0].Id"),
                                   'Lead',
                                   'Product__c',
                                   prodId);
                component.set("v.allCustomers[0].Product__c", prodId);
            }

            $A.util.removeClass(customerEmailButton, 'noDisplay');
            $A.util.removeClass(incomeFormButton, 'noDisplay');     
        } else {
            component.set("v.productId", null); 
            component.set("v.loanTerm", 0);
            component.set("v.allCustomers[0].Product__c", null);

            $A.util.addClass(customerEmailButton, 'noDisplay');
            $A.util.addClass(incomeFormButton, 'noDisplay');     
        }
    },

    qualifyingProductSelected : function(component, productId) {
        var products = component.get("v.allProducts");
        for (var p in products) {
            if (products[p].Id === productId) {
                return true;
            }
        }
        return false;
    }
})