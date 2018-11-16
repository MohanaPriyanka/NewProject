({
    selectTab: function(component, selectedTab) {
        $A.util.removeClass(component.find('customersInProcess'), 'slds-is-active');
        $A.util.removeClass(component.find('applications'), 'slds-is-active');
        $A.util.removeClass(component.find('declinedApplicants'), 'slds-is-active');
        $A.util.removeClass(component.find('completedCustomers'), 'slds-is-active');
        $A.util.removeClass(component.find('expiredApplicants'), 'slds-is-active');
        $A.util.addClass(component.find(selectedTab), 'slds-is-active');
        component.set("v.selectedTable", selectedTab);
    },

    selectTabs: function(component, selectedTabs) {
        var k;
        $A.util.removeClass(component.find('customersInProcess'), 'slds-is-active');
        $A.util.removeClass(component.find('applications'), 'slds-is-active');
        $A.util.removeClass(component.find('declinedApplicants'), 'slds-is-active');
        $A.util.removeClass(component.find('completedCustomers'), 'slds-is-active');
        $A.util.removeClass(component.find('expiredApplicants'), 'slds-is-active');
        for (k=0; k<selectedTabs.length; k++) {
        	$A.util.addClass(component.find(selectedTabs[k]), 'slds-is-active');
        }
    },

    clearSearchSelections: function(component, selectionsToNotClear) {
        var j;
        component.set("v.completedLoansSearchSelected", false);
        component.set("v.loansInProcessSearchSelected", false);
        component.set("v.pendingApplicationsSearchSelected", false);
        component.set("v.declinedApplicantsSearchSelected", false);
        component.set("v.expiredApplicantsSearchSelected", false);
        if (selectionsToNotClear != null && selectionsToNotClear.length > 0) {
        	for (j=0; j<selectionsToNotClear.length; j++) {
        		component.set("v." + selectionsToNotClear[j], true);
        	}
        }
    },

    handleSearchResultDisplay : function(component, searchSelectedId, tabId, selectedTabs, doNotClearSelectionList) {
        component.set("v." + searchSelectedId , true);
        this.selectTab(component, tabId);
        selectedTabs.push(tabId);
        doNotClearSelectionList.push(searchSelectedId);
        return true;
    },

    changeTable : function(component, tabId, recordsId, originalRecordsId) {
        if (component.get("v." + recordsId).length != component.get("v." + originalRecordsId).length) {
            component.set("v." + recordsId, component.get("v." + originalRecordsId));
        }
        this.selectTab(component, tabId);
        this.clearSearchSelections(component);
    },

})