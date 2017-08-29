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

    executeTableButtonActions : function(component, event, helper) {        
       var buttonEventId = event.getParam("buttonEventId");
       var record = event.getParam("record");
        switch (buttonEventId) {
            case 'openCustomerWindow':
                helper.openCustomerWindow(component, record);   
        }  
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
    
    openCustomerWindow : function(component, event, helper) {          
        var allCustomers = component.find("allCustomers");   
        $A.util.addClass(allCustomers, 'noDisplayBar');
        
        var source = event.getSource();
        var customerLoanId = source.get("v.class");
        var evtCustomerWindow = $A.get("e.c:SLPAllCustomersEvent");
        evtCustomerWindow.setParams({"customerLoanId": customerLoanId});
        evtCustomerWindow.fire(); 
    },
    

    closeCustomerWindow : function(component, event, helper) {             
        var allCustomers = component.find("allCustomers");   
        $A.util.removeClass(allCustomers, 'noDisplayBar');           
    },     

})