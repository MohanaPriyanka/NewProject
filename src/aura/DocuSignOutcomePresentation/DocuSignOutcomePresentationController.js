({
    doInit: function(component, event, helper) {
        var parsedUrl = new URL(window.location.href);
        component.set('v.docuSignEventType', parsedUrl.searchParams.get("event"));
    }
})