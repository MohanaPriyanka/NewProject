({
    openCustomerWindow: function(component, record) {
        $A.util.addClass(component.find("BWDataTableAllCustomers"), 'noDisplayBar');        
        var evtCustomerWindow = $A.get("e.c:SLPAllCustomersEvent");
        evtCustomerWindow.setParams({"customerLoanId": record.Id});
        evtCustomerWindow.fire();
    },  

    continueApplication: function(component, record) {

    },   

    selectTab: function(component, selectedTab) {
        $A.util.removeClass(component.find('customersInProcess'), 'slds-is-active');   
        $A.util.removeClass(component.find('applications'), 'slds-is-active');   
        $A.util.removeClass(component.find('declinedApplicants'), 'slds-is-active');   
        $A.util.removeClass(component.find('completedCustomers'), 'slds-is-active');   
        $A.util.addClass(component.find(selectedTab), 'slds-is-active');   
        component.set("v.selectedTable", selectedTab);
    },   
})