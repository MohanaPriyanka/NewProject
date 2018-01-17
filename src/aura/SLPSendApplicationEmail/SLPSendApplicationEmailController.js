({
    doInit: function(component, event, helper) {
        var action = component.get("c.getPartnerRecord");
        action.setCallback(this,function(resp){
            if (resp.getState() === 'SUCCESS') {
                var partner = resp.getReturnValue();
                component.set("v.partnerRecord", partner);
                if (partner.Accounts__r[0] &&
                    partner.Accounts__r[0].Disable_New_Loan_Applications_in_Portal__c) {
                    component.set("v.disableOrigination", true);
                }
            } else {
                helper.logError("SLPSendApplicationEmailController", "doInit", resp.getError());
            }
        });    
        $A.enqueueAction(action);    

        helper.callApexMethod(component, "getActiveStates", ["activeStates"]);

        //reset the modal so that the email confirmation gets removed and the form gets displayed
        $A.util.addClass(component.find('emailConfirmation'), 'noDisplay');
        $A.util.removeClass(component.find('emailForm'), 'noDisplay');

        var modalToggle = event.getParam("openModal");
        if (modalToggle === "openModal") {
            helper.openModal(component, "emailCustomerModal");
        }

        var promise = helper.getSLPSettings(component, event, helper);
        promise.then($A.getCallback(function resolve(settings) {
            component.set('v.iblsRequired', settings[0].Require_IBLS_for_MSL_Loans__c);
        }));
    },

    closeEmailCustomerModal: function(component, event, helper) {
        helper.closeModal(component, 'emailCustomerModal'); 
        helper.enableButton(component, 'sendEmailButton', 'Send');
        component.set("v.newLead.Email", null);
        component.set("v.newLead.LASERCA__Home_State__c", null);
        component.set("v.newLead.System_Cost__c", null);
        helper.setInputToCorrect(component, 'systemCostElement');
        helper.setInputToCorrect(component, 'emailAddressElement');
  
        if (!component.get("v.disableOrigination")) {
            helper.enableButton(component, 'sendEmailButton', 'Send');
        }

        var evtCustomerWindow = $A.get("e.c:SLPSendApplicationEmailEvent");
        evtCustomerWindow.setParams({"closeModal": "closeModal"});
        evtCustomerWindow.fire();
    },

    createLeadAndSendApplication : function(component, event, helper) {
        helper.startApplication(component, event, helper, {'email':true, 'open':false});
    },

    getAvailableProducts : function(component, event, helper) {
        helper.getAvailableLoanProducts(component, event, helper);
        helper.getAvailableSRECProducts(component, event, helper);
    },

    setProductProgram : function(component, event, helper) {
        const newLead = component.get('v.newLead');
        const availableLoanProducts = component.get("v.availableLoanProducts");
        var productProgram = helper.getProductProgram(availableLoanProducts, newLead.Product__c)

        if (newLead.Product__c) {
            component.set('v.productProgram', productProgram);
            if (productProgram === 'MSLP') {
                component.set('v.newLead.DOER_Solar_Loan__c', true);
            } else {
                component.set('v.newLead.DOER_Solar_Loan__c', false);
            }
        } else {
            component.set('v.productProgram', '');
        }
    },
})
