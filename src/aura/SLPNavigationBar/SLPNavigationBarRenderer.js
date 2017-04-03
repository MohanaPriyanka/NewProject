({
    afterRender : function(component, helper) {
        this.superAfterRender();

        // For some reason, SLDS adds slds-button--neutral to lighting:button classes.
        // We want to use a buttons on the nav bar to use window.location.href instead of a href
        // because a href seems to retain parameters from previous uses of e:navigateToURL (which
        // is used to get from SLPAddCustomer to SLPCreditStatus
        // We need to do this after the component is rendered:
        // http://salesforce.stackexchange.com/questions/158237/a-util-removeclass-not-working-in-some-cases
        $A.util.removeClass(component.find("slpcreditstatus"),"slds-button--neutral");
        $A.util.removeClass(component.find("slpdashboard"),"slds-button--neutral");
        $A.util.removeClass(component.find("slpcustomer"),"slds-button--neutral");
        $A.util.removeClass(component.find("slpdisbursals"),"slds-button--neutral");
        $A.util.removeClass(component.find("slpalerts"),"slds-button--neutral");
    }
})