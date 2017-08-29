({
    openCustomerWindow: function(component, record) {
        $A.util.addClass(component.find("BWDataTableAllCustomers"), 'noDisplayBar');        
        var evtCustomerWindow = $A.get("e.c:SLPAllCustomersEvent");
        evtCustomerWindow.setParams({"customerLoanId": record.Id});
        evtCustomerWindow.fire();
    },    
})