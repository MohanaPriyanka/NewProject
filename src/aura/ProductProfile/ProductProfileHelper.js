({
	getPds : function() {
        var action = cmp.get("c.getProfiles");
        	action.setCallback(this, function(response) {
	            var state = response.getState();
	            if (cmp.isValid() && state === "SUCCESS") {
	                cmp.set("v.profiles", response.getReturnValue());
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
    	}
	}
})