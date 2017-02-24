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
        //hide the task table on the dashboard
        //var customerWindowToggle = component.get("v.eventToggle");
        var allCustomers = component.find("allCustomers");   
        $A.util.addClass(allCustomers, 'noDisplayBar');
        
        //if(customerWindowToggle == true){
        //send the id of the selected customer to the customer component and bring it to display
        //the view click of customer record.
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