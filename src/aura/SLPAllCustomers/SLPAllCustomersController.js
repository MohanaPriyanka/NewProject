({
    doInit : function(component, event, helper) {
        helper.getLicenseType(component);
        helper.getDataFromServer(component, "getAllCustomers", ["allCustomers", "originalAllCustomers"]);
    },

    executeTableButtonActions : function(component, event, helper) {        
       var buttonEventId = event.getParam("buttonEventId");
       var record = event.getParam("record");
        switch (buttonEventId) {
            case 'openCustomerWindow':
                helper.openCustomerWindow(component, record); 
        }  
    },    

    setSearchableValues : function(component, event, helper) {   
        helper.setSearchableValues(component, event, helper, "allCustomers", "originalAllCustomers", "allCustomersSearchableValues");
        // set the runSetSearchable to false here to that the list doesn't get set twice. If it doesn't get set to false, the execute search updates the record list and thus runs the setSearchable method again.
        component.set("v.runSetSearchable", false);
    },
    
    executeSearch : function(component, event, helper) {   
        helper.executeSearch(component, event, helper, "allCustomers", "originalAllCustomers", "allCustomersSearchableValues");
    },
})
