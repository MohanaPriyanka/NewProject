({
    doInit : function(component, event, helper) { 
        var InputtedbrandKey = component.get("v.bk");
        
        if (InputtedbrandKey != null){
            if (InputtedbrandKey.length < 2) {
                component.set("v.showBW", true);
            } else {
                component.set("v.showBW", false);
            }
        } else {
            component.set("v.showBW", true);
        }
    },
})