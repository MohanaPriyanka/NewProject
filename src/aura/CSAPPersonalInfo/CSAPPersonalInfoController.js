({
    doInit: function(component, event, helper) {
        var leadId = component.get("v.leadId");
        if(!leadId){
            var lead = {"sobjectType": "Lead"};
            helper.raiseNavEvent("COMPLETED", {"stageName": "NAV_Getting_Started", "lead": lead});
            lead.Partner_Lookup__c = component.get("v.partnerId");
            lead.bs_Sales_Id__c = component.get("v.salesRepId");
            component.set("v.lead", lead);
            component.set("v.STAGENAME", "NAV_Personal_Information");
            component.set("v.page", "AboutYourself");
        }

        if (component.get("v.abbrevStates") && component.get("v.abbrevStates").length === 0) {
            helper.getUSStates(component, "v.abbrevStates", true);
        }
    },
    handleNavEvent : function(component, event, helper) {
        helper.handleNavEvent(component, event, helper, "AboutYourself");
    },
    goToAboutYourself : function(component, event, helper) {
        component.set("v.page", "AboutYourself");
    },
    goToApplyingFor : function(component, event, helper) {
        if(event.getSource().get("v.label") == "Next" && helper.validatePageFields(component)){
            component.set("v.page", "ApplyingFor");
        }else{
            component.set("v.page", "ApplyingFor");
        }
    },
    goToAddressForm : function(component, event, helper) {
        if(component.get("v.lead.Application_Type__c") != null) {
            component.set("v.page", "AddressForm");
        } else {
            var toastEvent = $A.get("e.force:showToast");
            toastEvent.setParams({
                "title": "You forgot something!",
                "message": 'Please select whether you are applying for Community Solar for your home or for your business.'
            });
            toastEvent.fire();
        }
    },
    setCSApplicationResidential : function(component, event, helper) {
        component.set("v.lead.Application_Type__c", "Residential");
        component.set("v.Residential", true);
        component.set("v.NonResidential", false);
    },
    setCSApplicationNonResidential : function(component, event, helper) {
        component.set("v.lead.Application_Type__c", "Non-Residential");
        component.set("v.Residential", false);
        component.set("v.NonResidential", true);
    },
    goToCheckCapacity : function(component, event, helper) {
        if(helper.validatePageFields(component)){
            component.set('v.loading', true);
            component.set("v.loadingText", "Saving your information...");
            window.setTimeout(function() {
                helper.processLead(component, event, helper);
                helper.upsertRecords(component, event, helper);
                component.set("v.loadingText", "Locating your address...");
            }, 2000);
        }
    },
})


