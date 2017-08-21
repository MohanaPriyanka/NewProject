({
	doInit : function(component, event, helper) {
        //The following block of code retrieves the user's license type to determine what to display on the UI
        var actionLicenseType = component.get("c.getLicenseType");        
        actionLicenseType.setCallback(this,function(resp){
            if(resp.getState() == 'SUCCESS') {
                if(resp.getReturnValue().length > 0){
                    if(resp.getReturnValue() == 'Executive')
                    component.set("v.licenseType", true);
                }
            }    
            else {
                $A.log("Errors", resp.getError());
            }
        });    
        $A.enqueueAction(actionLicenseType);   
                
        var action = component.get("c.getAllCustomers");        
        action.setCallback(this,function(resp){ 
            if(resp.getState() == 'SUCCESS') {
                component.set("v.allCustomers", resp.getReturnValue());
            }
            else {
                $A.log("Errors", resp.getError());
            }
        });        
        $A.enqueueAction(action);  
        component.set("v.sortAsc", true);   
        component.set("v.sortField", "Name");   
	},
    
    searchCustomers : function(component, event, helper) {            
        var input = component.find("customerSearch");
        var customerName = input.get("v.value");           
        var action = component.get("c.getAllCustomers");     
        
        action.setParams({searchValue : customerName});
        
        action.setCallback(this,function(resp){
            if(resp.getState() == 'SUCCESS') {
                component.set("v.allCustomers", resp.getReturnValue());
            }
            else {
                $A.log("Errors", resp.getError());
            }
        });        
        $A.enqueueAction(action);        
    },
    
    searchCustomers : function(component, event, helper) {            
        var input = component.find("customerSearch");
        var customerName = input.get("v.value");           
        var action = component.get("c.getAllCustomers");     
        
        action.setParams({searchValue : customerName});
        
        action.setCallback(this,function(resp){
            if(resp.getState() == 'SUCCESS') {
                component.set("v.allCustomers", resp.getReturnValue());
            }
            else {
                $A.log("Errors", resp.getError());
            }
        });        
        $A.enqueueAction(action);        
    },

    sortTable: function(component, event, helper) {
        var fieldName = event.currentTarget.name;
        var currentOrder = component.get("v.sortAsc"),
            currentList = component.get("v.allCustomers");
        currentOrder = !currentOrder;
        currentList.sort(function(a,b) {
            var t1 = a[fieldName] == b[fieldName], t2 = a[fieldName] < b[fieldName];
            return t1? 0: (currentOrder?-1:1)*(t2?1:-1);
        });
        component.set("v.sortAsc", currentOrder);
        component.set("v.allCustomers", currentList);
        component.set("v.sortField", fieldName);
    },

    openCustomerWindow : function(component, event, helper) {          
        var allCustomers = component.find("allCustomers");   
        $A.util.addClass(allCustomers, 'noDisplayBar');
        
        var source = event.getSource();
        var customerLoanId = source.get("v.class");
        var evtCustomerWindow = $A.get("e.c:SLPAllCustomersEvent");
        evtCustomerWindow.setParams({"customerLoanId": customerLoanId});
        evtCustomerWindow.fire(); 
	    //}   
    },
    

    closeCustomerWindow : function(component, event, helper) {             
        var allCustomers = component.find("allCustomers");   
        $A.util.removeClass(allCustomers, 'noDisplayBar');           
    },     

})