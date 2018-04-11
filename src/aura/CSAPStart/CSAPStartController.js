({
    doInit: function(component, event, helper) {
        var leadId = component.get("v.leadId");
        if(leadId){
            component.set("v.page", "Login");
        }
    },
    handleNavEvent : function(component, event, helper) {
        var leadId = component.get("v.leadId");
        if(leadId){
            helper.handleNavEvent(component, event, helper, "Login");
        }
    },
    login : function(component, event, helper) {
        if(helper.validatePageFields(component)){
            helper.login(component, event, helper);
        }
    },
})