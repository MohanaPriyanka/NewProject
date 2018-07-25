({
    doInit: function(component, event, helper) {
        var email = component.get("v.email");
        if (email) {
            component.set("v.email", decodeURIComponent(email));
        }
        var partnerId = component.get("v.partnerId");
        if (partnerId) {
            component.set("v.partnerId", decodeURIComponent(partnerId));
        }
        var salesRepId = component.get("v.salesRepId");
        if (salesRepId) {
            component.set("v.salesRepId", decodeURIComponent(salesRepId));
        }
        var referralCode = component.get("v.referralCode");
        if(referralCode) {
            component.set("v.referralCode", decodeURIComponent(referralCode));
        }
    },
})