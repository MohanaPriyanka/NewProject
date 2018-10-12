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