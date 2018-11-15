({
    doInit : function(component, event, helper) {
        component.set("v.loadingSpinner", true);
        helper.getLicenseType(component);
        var actionGetLoans = component.get("c.getAllCustomers");
        actionGetLoans.setCallback(this,function(resp){ 
            if(resp.getState() == 'SUCCESS') {
                component.set("v.loansInProcess", resp.getReturnValue().loansInProcess);
                component.set("v.completedLoans", resp.getReturnValue().completedLoans);
                component.set("v.expiredApplicants", resp.getReturnValue().expiredApplicants);
            }
            else {
                $A.log("Errors", resp.getError());
            }

        });
        $A.enqueueAction(actionGetLoans);

        var actionGetLeads = component.get("c.getLeads");
        actionGetLeads.setCallback(this,function(resp){ 
            if(resp.getState() == 'SUCCESS') {
                component.set("v.pendingApplications", resp.getReturnValue().pendingApplications);
                component.set("v.declinedApplicants", resp.getReturnValue().declinedApplicants);
                helper.selectTab(component, 'applications');
                helper.clearSearchSelections(component);
                component.set("v.loadingSpinner", false);
            }
            else {
                $A.log("Errors", resp.getError());
            }

        });
        $A.enqueueAction(actionGetLeads);
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

    setSearchableExpiredApplicants : function(component, event, helper) {
        helper.setSearchableValues(component, event, helper, "expiredApplicants", "originalExpiredApplicants", "expiredApplicantsSearchableValues", component.get("v.runSetSearchableExpiredApplicants"));
        // set the runSetSearchable to false here so that the list doesn't get set twice. If it doesn't get set to false, the execute search updates the record list and thus runs the setSearchable method again.
        component.set("v.runSetSearchableExpiredApplicants", false);
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
            if(helper.executeSearch(component, event, helper, searchText, "expiredApplicants", "originalExpiredApplicants", "expiredApplicantsSearchableValues")) {
                searchSuccess = helper.handleSearchResultDisplay(component, "expiredApplicantsSearchSelected", "expiredApplicants", selectedTabs, doNotClearSelectionList);
            }            
            if (!searchSuccess) {
                alert("No records found");
                return;
            } else {
                helper.selectTabs(component, selectedTabs);
                helper.clearSearchSelections(component, doNotClearSelectionList);
            }
        } else {
            helper.changeTable(component, "applications", "pendingApplications", "originalPendingApplications");
        }
    },    

    executeTableButtonActions : function(component, event, helper) {
        var buttonEventId = event.getParam("buttonEventId");
        var record = event.getParam("record");
        switch (buttonEventId) {
            case 'openCustomerWindow':
                sessionStorage.setItem('loanId', record.Id);
                var urlEvent = $A.get("e.force:navigateToURL");
                urlEvent.setParams({
                    "url": '/slpcustomer'
                });
                urlEvent.fire(); 
                break;
            case 'continueApplication':
                sessionStorage.setItem('leadId', record.Id);
                sessionStorage.setItem('leadName', record.FirstName + ' ' + record.LastName);
                var urlEvent = $A.get("e.force:navigateToURL");
                urlEvent.setParams({
                    "url": '/slpcreditstatus'
                });
                urlEvent.fire(); 
                break;
            case 'addCoSigner':
               $A.createComponent(
                  "c:SLPAddCoApplicant", 
                   {"mainApplicant" : record}, 
                    function(newButton, status, errorMessage){
                        if (status === "SUCCESS") {
                            var body = component.get("v.body");
                            body.push(newButton);
                            component.set("v.body", body);
                        } else {
                            helper.logError("SLPCreditStatusController", "openAddCoApplicant", resp.getError());
                        }
                    }
                );
            case 'resendApplication':
                var action = component.get('c.sendApplication');
                action.setParams({lead: record});
                action.setCallback(this,function(resp) {
                    if (resp.getState() === 'SUCCESS') {
                        var title = 'Resent Application';
                        var message = 'Application link has been resent to ' + resp.getReturnValue();
                        helper.showToast(component, title, message);
                    } else {
                        helper.logError('SLPAllCustomersController', 'resendApplication', resp.getError(), record);
                    }
                });
                $A.enqueueAction(action);
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

    changeTableToExpiredApplicants : function(component, event, helper) {
        helper.changeTable(component, "expiredApplicants", "expiredApplicants", "originalExpiredApplicants");
    },
})