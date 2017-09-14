({
    //make it so the users tab defaults to where they left off.
    doInit : function(component, event, helper) {
        helper.getLicenseType(component);
        var action = component.get("c.getAllCustomers");        
        action.setCallback(this,function(resp){ 
            if(resp.getState() == 'SUCCESS') {
                component.set("v.loansInProcess", resp.getReturnValue().loansInProcess);
                component.set("v.completedLoans", resp.getReturnValue().completedLoans);
                component.set("v.allCustomers", resp.getReturnValue().allLoans);
                component.set("v.originalAllCustomers", resp.getReturnValue().allLoans);
            }
            else {
                $A.log("Errors", resp.getError());
            }

        });        
        $A.enqueueAction(action);         
    },

    setSearchableValues : function(component, event, helper) {   
        helper.setSearchableValues(component, event, helper, "allCustomers", "originalAllCustomers", "allCustomersSearchableValues");
        // set the runSetSearchable to false here to that the list doesn't get set twice. If it doesn't get set to false, the execute search updates the record list and thus runs the setSearchable method again.
        component.set("v.runSetSearchable", false);
    },
    
    executeSearch : function(component, event, helper) {   
        helper.executeSearch(component, event, helper, "allCustomers", "originalAllCustomers", "allCustomersSearchableValues");
    }, 

    executeTableButtonActions : function(component, event, helper) {        
       var buttonEventId = event.getParam("buttonEventId");
       var record = event.getParam("record");
        switch (buttonEventId) {
            case 'openCustomerWindow':
                var urlEvent = $A.get("e.force:navigateToURL");
                urlEvent.setParams({
                    "url": '/slpcustomer?loanId=' + record.Id
                });
                urlEvent.fire(); 
                break;
            case 'continueApplication':
                var urlEvent = $A.get("e.force:navigateToURL");
                urlEvent.setParams({
                    "url": '/slpcreditstatus?leadId=' + record.Id +
                    '&leadName=' + encodeURIComponent(record.FirstName + ' ' + record.LastName)
                });
                urlEvent.fire(); 
                break;                    
        }  
    },    

    changeTableToCompletedCustomers : function(component, event, helper) {   
        helper.selectTab(component, 'completedCustomers');       
    },    

    changeTableToCustomersInProcess : function(component, event, helper) {   
        helper.selectTab(component, 'customersInProcess'); 
    },      

    changeTableToApplications : function(component, event, helper) {   
        var action = component.get("c.getLeads");        
        action.setCallback(this,function(resp){ 
            if(resp.getState() == 'SUCCESS') {
                component.set("v.allLeads", resp.getReturnValue().allLeads);
                component.set("v.pendingApplications", resp.getReturnValue().pendingApplications);
                component.set("v.declinedApplicants", resp.getReturnValue().declinedApplicants);
                helper.selectTab(component, 'applications');   
            }
            else {
                $A.log("Errors", resp.getError());
            }

        });        
        $A.enqueueAction(action);                    
        action.setStorable();                    
    },        

    changeTableToDeclinedApplicants : function(component, event, helper) {   
        var action = component.get("c.getLeads");        
        action.setCallback(this,function(resp){ 
            if(resp.getState() == 'SUCCESS') {
                component.set("v.allLeads", resp.getReturnValue().allLeads);
                component.set("v.pendingApplications", resp.getReturnValue().pendingApplications);
                component.set("v.declinedApplicants", resp.getReturnValue().declinedApplicants);
                helper.selectTab(component, 'declinedApplicants');   
            }
            else {
                $A.log("Errors", resp.getError());
            }

        });        
        $A.enqueueAction(action);                    
        action.setStorable();                    
    },      
})


