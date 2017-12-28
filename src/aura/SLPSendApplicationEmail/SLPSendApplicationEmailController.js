({
    openEmailCustomerModal: function(component, event, helper) {
        var action = component.get("c.getPartnerRecord");
        action.setCallback(this,function(resp){
            if (resp.getState() == 'SUCCESS') {
                var partner = resp.getReturnValue();
                component.set("v.partnerRecord", partner);
                if (partner.Accounts__r[0] &&
                    partner.Accounts__r[0].Disable_New_Loan_Applications_in_Portal__c) {
                    component.set("v.disableOrigination", true);
                }
            } else {
                helper.logError("SLPSendApplicationEmailController", "openEmailCustomerModal", resp.getError());
            }
        });    
        $A.enqueueAction(action);    

        helper.callApexMethod(component, "getActiveStates", ["activeStates"]);

        //reset the modal so that the email confirmation gets removed and the form gets displayed
        $A.util.addClass(component.find('emailConfirmation'), 'noDisplay');
        $A.util.removeClass(component.find('emailForm'), 'noDisplay');

        var modalToggle = event.getParam("openModal");
        if (modalToggle == "openModal") {
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
        var newLead = component.get("v.newLead");
        var downPayment = component.get("v.downPayment");
        newLead.Requested_Loan_Amount__c = newLead.System_Cost__c - downPayment;
        var availableProducts = component.get("v.availableProducts");
        var errors = helper.errorsInForm(component, helper, newLead);
        if (errors == null) {
            newLead.Product_Program__c = helper.getProductProgram(availableProducts, newLead.Product__c);
            // We don't want to set a product for MA loans - just MSLP vs non-MSLP
            if (newLead.Product__c === 'MSLP' || newLead.Product__c === 'BlueWave Solar Loan') {
                delete newLead.Product__c;
            }
            helper.createLead(component, event, helper, downPayment, newLead);
            $A.util.removeClass(component.find('sendEmailModalButtons'), 'noDisplay');
        } else {
            helper.logError("SLPSendApplicationEmailController", "createLeadAndSendApplication", errors, newLead);
            return;
        }
    },

    getAvailableProducts : function(component, event, helper) {
        helper.getAvailableProducts(component, event, helper);
    },

    setProductProgram : function(component, event, helper) {
        const newLead = component.get('v.newLead');
        const availableProducts = component.get("v.availableProducts");
        var productProgram = helper.getProductProgram(availableProducts, newLead.Product__c)

        if (newLead.Product__c) {
            component.set('v.productProgram', productProgram);
            if (productProgram == 'MSLP') {
                component.set('v.newLead.DOER_Solar_Loan__c', true);
            }
        } else {
            component.set('v.productProgram', '');
        }
    },
})
