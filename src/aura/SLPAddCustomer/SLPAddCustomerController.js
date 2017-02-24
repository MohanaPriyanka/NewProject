({
    addCustomer : function(component, event, helper) {
        var lead = component.get("v.newLead");

        var Action = component.get("c.addNewLeadRecord");
        Action.setParams({
            "newLead" : lead,          
        });
        
        Action.setCallback(this, function(resp) {
            if(resp.getState() == "SUCCESS") {
                var inputForm = component.find("inputForm");
                var addAnotherCustomer = component.find("addAnotherCustomer");
                $A.util.addClass(inputForm, 'noDisplayBar');
                $A.util.removeClass(addAnotherCustomer, 'noDisplayBar');
                alert("This customer has been added. Please check the credit status tab to see their qualification status. This may take a minute or two.");
            }else {
                $A.log("Errors", resp.getError());                
            }
        }); 
		$A.enqueueAction(Action);
    },
    
    navigateAddAnotherCustomer : function(component, event, helper) {

        var urlEvent = $A.get("e.force:navigateToURL");
        urlEvent.setParams({
          "url": '/slpaddcustomer'

        });
        urlEvent.fire();                
    },    
    
})