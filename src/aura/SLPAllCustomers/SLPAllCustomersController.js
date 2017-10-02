({
    //make it so the users tab defaults to where they left off.
    doInit : function(component, event, helper) {
        helper.getLicenseType(component);
        var actionGetLoans = component.get("c.getAllCustomers");        
        actionGetLoans.setCallback(this,function(resp){ 
            if(resp.getState() == 'SUCCESS') {
                component.set("v.loansInProcess", resp.getReturnValue().loansInProcess);
                component.set("v.completedLoans", resp.getReturnValue().completedLoans);
                component.set("v.allCustomers", resp.getReturnValue().allLoans);
                component.set("v.originalLoansInProcess", resp.getReturnValue().loansInProcess);
                component.set("v.originalCompletedLoans", resp.getReturnValue().completedLoans);
                component.set("v.originalAllCustomers", resp.getReturnValue().allLoans);
            }
            else {
                $A.log("Errors", resp.getError());
            }

        });        
        $A.enqueueAction(actionGetLoans);  
        actionGetLoans.setStorable();                  

        var actionGetLeads = component.get("c.getLeads");        
        actionGetLeads.setCallback(this,function(resp){ 
            if(resp.getState() == 'SUCCESS') {
                component.set("v.pendingApplications", resp.getReturnValue().pendingApplications);
                component.set("v.declinedApplicants", resp.getReturnValue().declinedApplicants);
                component.set("v.originalPendingApplications", resp.getReturnValue().pendingApplications);
                component.set("v.originalDeclinedApplicants", resp.getReturnValue().declinedApplicants);                
                helper.selectTab(component, 'applications'); 
                helper.clearSearchSelections(component);   
            }
            else {
                $A.log("Errors", resp.getError());
            }

        });        
        $A.enqueueAction(actionGetLeads);                    
        actionGetLeads.setStorable();                  
    },

    setSearchableCompletedLoans : function(component, event, helper) {   
        helper.setSearchableValues(component, event, helper, "completedLoans", "originalCompletedLoans", "completedLoansSearchableValues", component.get("v.runSetSearchableCompletedLoans"));
        // set the runSetSearchable to false here so that the list doesn't get set twice. If it doesn't get set to false, the execute search updates the record list and thus runs the setSearchable method again.
        component.set("v.runSetSearchableCompletedLoans", false);
    },

    setSearchableLoansInProcess : function(component, event, helper) {   
        helper.setSearchableValues(component, event, helper, "loansInProcess", "originalLoansInProcess", "loansInProcessSearchableValues", component.get("v.runSetSearchableLoansInProcess"));
        // set the runSetSearchable to false here so that the list doesn't get set twice. If it doesn't get set to false, the execute search updates the record list and thus runs the setSearchable method again.
        component.set("v.runSetSearchableLoansInProcess", false);
    
    },

    setSearchablePendingApplications : function(component, event, helper) {   
        helper.setSearchableValues(component, event, helper, "pendingApplications", "originalPendingApplications", "pendingApplicationsSearchableValues", component.get("v.runSetSearchablePendingApplications"));
        // set the runSetSearchable to false here so that the list doesn't get set twice. If it doesn't get set to false, the execute search updates the record list and thus runs the setSearchable method again.
        component.set("v.runSetSearchablePendingApplications", false);
    },

    setSearchableDeclinedApplicants : function(component, event, helper) {   
        helper.setSearchableValues(component, event, helper, "declinedApplicants", "originalDeclinedApplicants", "declinedSearchableValues", component.get("v.runSetSearchableDeclinedApplicants"));
        // set the runSetSearchable to false here so that the list doesn't get set twice. If it doesn't get set to false, the execute search updates the record list and thus runs the setSearchable method again.
        component.set("v.runSetSearchableDeclinedApplicants", false);
    },                 
    
    executeSearch : function(component, event, helper) {   
        var searchSuccess = false;
        var searchText = event.getParam("searchText");
        var doNotClearSelectionList = [];
        var selectedTabs = [];
        if (searchText != "") {
            if(helper.executeSearch(component, event, helper, searchText, "pendingApplications", "originalPendingApplications", "pendingApplicationsSearchableValues")) {
                searchSuccess = helper.handleSearchResultDisplay(component, "pendingApplicationsSearchSelected", "applications", selectedTabs, doNotClearSelectionList);          
            }

            if (helper.executeSearch(component, event, helper, searchText, "loansInProcess", "originalLoansInProcess", "loansInProcessSearchableValues")) {
                searchSuccess = helper.handleSearchResultDisplay(component, "loansInProcessSearchSelected", "customersInProcess", selectedTabs, doNotClearSelectionList);
            }

            if(helper.executeSearch(component, event, helper, searchText, "completedLoans", "originalCompletedLoans", "completedLoansSearchableValues")) {
                searchSuccess = helper.handleSearchResultDisplay(component, "completedLoansSearchSelected", "completedCustomers", selectedTabs, doNotClearSelectionList);
            } 

            if(helper.executeSearch(component, event, helper, searchText, "declinedApplicants", "originalDeclinedApplicants", "declinedSearchableValues")) {
                searchSuccess = helper.handleSearchResultDisplay(component, "declinedApplicantsSearchSelected", "declinedApplicants", selectedTabs, doNotClearSelectionList);
            }

            if (!searchSuccess) {
                alert("No records found");
                return;
            } else {
                helper.selectTabs(component, selectedTabs);
                helper.clearSearchSelections(component, doNotClearSelectionList);
            }
        } else {
            component.set("v." + recordsAttribute, originalRecords);
            helper.clearSearchSelections(component, null); 
            this.changeTableToApplications(component, event, helper); 
        }
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
            case 'addCoSigner':       
               $A.createComponent(
                  "c:SLPAddCoApplicant", 
                   {"mainApplicant" : record.Id}, 
                function(newButton, status, errorMessage){
                    if (status === "SUCCESS") {
                        var body = component.get("v.body");
                        body.push(newButton);
                        component.set("v.body", body);
                    } else  {
                        helper.logError("SLPCreditStatusController", "openAddCoApplicant", resp.getError());
                    }
                }   
            )                             
        }  
    },    
    changeTableToCompletedCustomers : function(component, event, helper) {   
        helper.changeTable(component, "completedCustomers", "completedLoans", "originalCompletedLoans");                  
    },    

    changeTableToCustomersInProcess : function(component, event, helper) {   
        helper.changeTable(component, "customersInProcess", "loansInProcess", "originalLoansInProcess");                  
    },      

    changeTableToApplications : function(component, event, helper) {   
        helper.changeTable(component, "applications", "pendingApplications", "originalPendingApplications");                  
    },        

    changeTableToDeclinedApplicants : function(component, event, helper) {  
        helper.changeTable(component, "declinedApplicants", "declinedApplicants", "originalDeclinedApplicants");                  
    },        
})


