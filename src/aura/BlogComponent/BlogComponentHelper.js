({
    getBgs : function(cmp, event, helper) {
        var type = cmp.get("v.blogType");
        if(type != null && type != '') {
            var action = cmp.get("c.getBlogs");
        	action.setParams({ bType :cmp.get("v.blogType") });
        	action.setCallback(this, function(response) {
	            var state = response.getState();
	            if (cmp.isValid() && state === "SUCCESS") {
	                cmp.set("v.blogs", response.getReturnValue());
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
        else {
            var action = cmp.get("c.getRecordType");
        	//action.setParams({ recordId :cmp.get("v.recordId") });
        	//This doesn't work. F-U Salesforce
        	var parts = window.location.href.split('/');
            action.setParams({ recordId : parts[parts.length - 1]});
        	action.setCallback(this, function(response) {
	            var state = response.getState();
	            if (cmp.isValid() && state === "SUCCESS") {
	                cmp.set("v.blogType", response.getReturnValue());
	                this.getBgs(cmp, event, helper);
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