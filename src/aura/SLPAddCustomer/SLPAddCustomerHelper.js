({
    checkCreditStatus : function(component) {
        $A.util.addClass(component.find("creditStatus"), 'noDisplay');
        // $A.util.addClass(component.find("creditSpinner"), 'slds-hide'); 
        var spinner = component.find("creditSpinner");
        var evt = spinner.get("e.toggle");
        evt.setParams({ isVisible : false });
        evt.fire();
                                
        $A.util.removeClass(component.find("creditResultPass"), 'noDisplay');
        window.clearInterval(component.get("v.creditStatusPoller"));
    }
})