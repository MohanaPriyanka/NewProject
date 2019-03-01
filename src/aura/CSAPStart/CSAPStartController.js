({
    doInit: function(component, event, helper) {
        component.set("v.STAGENAME", "NAV_Getting_Started");
        component.set("v.page", "ZipcodeChecker");
        var leadId = component.get("v.leadId");
        if (leadId != null && leadId != '' && leadId != undefined) {
            component.set("v.page","Login");
        }
    },

    handleNavEvent : function(component, event, helper) {
        const options = event.getParam("options");
        if (options && options.pageName) {
            helper.handleNavEvent(component, event, helper, options.pageName);
        }else{
            helper.handleNavEvent(component, event, helper, "ZipcodeChecker");
        }
    },

    capacityChecked : function(component, event, helper) {
        var hasCapacity = component.get('v.hasCapacity');
        if (hasCapacity) {
            var lead = component.get("v.lead");
            component.set("v.page", "AboutYourself");
            helper.raiseNavEvent("INITIATED", {"stageName": "NAV_Personal_Information", "lead": lead, "page": "AboutYourself"});
        } else {
            component.set("v.page", "NoProjects");
        }
    },

    beginApplication : function(component, event, helper) {
        component.set("v.page", "ZipcodeChecker");
    },

    checkForEnter : function(component, event, helper) {
        if (event.which === 13) {
            event.preventDefault();
            helper.login(component, event, helper);
        }
    },
    login : function(component, event, helper) {
        if(helper.validatePageFields(component)){
            helper.login(component, event, helper);
        }
    },
})