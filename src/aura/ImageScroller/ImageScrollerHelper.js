({
	getImages : function(cmp, event, helper) {
        var action = cmp.get("c.getImages");
        action.setParams({objectSource : cmp.get("v.objectSource"), titleSource : cmp.get("v.titleSource"), descriptionSource : cmp.get("v.descriptionSource")});
         action.setCallback(this, function(response) {
            var state = response.getState();
            if (cmp.isValid() && state === "SUCCESS") {
                cmp.set("v.images", response.getReturnValue());
                this.loadSlider(cmp, event, helper);
            }
            else if (cmp.isValid() && state === "ERROR") {
                var errors = response.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        console.log("Error message: " +
                                 errors[0].message);
                    }
                } else {
                    console.log("Unknown error");
                }
            }
        });
        $A.enqueueAction(action);
	},
    loadSlider: function(cmp, event, helper) {
     	cmp.set("v.imagesLoaded", true); 
	}
})