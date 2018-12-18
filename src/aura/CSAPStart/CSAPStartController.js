({
    doInit: function(component, event, helper) {
        component.set("v.STAGENAME", "NAV_Getting_Started");
        component.set("v.page", "ApplicationPrep");
    },

    handleNavEvent : function(component, event, helper) {

    },

    beginApplication : function(component, event, helper) {
        var lead = component.get("v.lead");
        component.set("v.page", "AboutYourself");
        helper.raiseNavEvent("INITIATED", {"stageName": "NAV_Personal_Information", "lead": lead, "page": "AboutYourself"});
    },

    checkForEnter : function(component, event, helper) {
        if (event.getParams().keyCode == 13) {
            helper.login(component, event, helper);
        }
    },
    login : function(component, event, helper) {
        if(helper.validatePageFields(component)){
            helper.login(component, event, helper);
        }
    },
})