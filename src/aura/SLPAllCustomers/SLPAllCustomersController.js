({
	doInit : function(component, event, helper) {
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
	    //}   
    },
    

    closeCustomerWindow : function(component, event, helper) {             
        var allCustomers = component.find("allCustomers");   
        $A.util.removeClass(allCustomers, 'noDisplayBar');           
    },     

})