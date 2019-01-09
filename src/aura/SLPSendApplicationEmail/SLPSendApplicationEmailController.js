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
                if (partner.Accounts__r[0] &&
                    partner.Accounts__r[0].Enable_Storage_Application_in_Portal__c) {
                    component.set("v.enableStorage", true);
                }
            } else {
                helper.logError("SLPSendApplicationEmailController", "doInit", resp.getError());
            }
        });    
        $A.enqueueAction(action);

        helper.callApexMethod(component, "getActiveStates", ["activeStates"]);
        helper.setListAttributeWithPicklistOptions(component, 'Residential_Equipment__c', 'Storage_Manufacturer__c', "v.availableStorageManufacturers");
        helper.setListAttributeWithPicklistOptions(component, 'Residential_Equipment__c', 'Storage_Inverter_Manufacturer__c', "v.availableStorageInverterManufacturers");

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
        component.set('v.newLead.System_Size_kW_DC__c', component.get('v.systemInfoObj.generator_nameplate_capacity__c'));
        helper.startApplication(component, event, helper, {'email':true, 'open':false});
    },

    getAvailableProducts : function(component, event, helper) {
        helper.getAvailableLoanProducts(component, event, helper);
    },

    setProductProgram : function(component, event, helper) {
        var productProgramMap = component.get("v.productProgramMap");
        var selectedProgram = component.get("v.newLead.Product_Program__c");

        if (selectedProgram === 'MSLP') {
            component.set('v.newLead.DOER_Solar_Loan__c', true);
            component.set("v.availableLoanProducts", null);
        } else {
            component.set('v.newLead.DOER_Solar_Loan__c', false);
            component.set("v.availableLoanProducts", productProgramMap[selectedProgram]);
        }
    },
})