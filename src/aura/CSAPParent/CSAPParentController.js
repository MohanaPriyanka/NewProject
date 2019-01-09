({
    waiting : function(component, event, helper) {
        component.set("v.waiting", true);
    },

    doneWaiting : function(component, event, helper) {
        component.set("v.waiting", false);
    },
})