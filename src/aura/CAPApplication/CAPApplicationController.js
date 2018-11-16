({
    doInit: function(component, event, helper) {
        var email = component.get('v.email');
        if (email) {
            component.set('v.email', decodeURIComponent(email));
        }
    },
})