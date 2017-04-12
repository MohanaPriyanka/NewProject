({
    log : function(component, event) {
        var errors = event.getParam("errors");
        if (errors) {
            if (errors[0]) {
                var messageText;
                if (errors[0] && errors[0].message) {
                    messageText = errors[0].message;
                } else if (errors[0] && errors[0].pageErrors) {
                    messageText = errors[0].pageErrors[0].message;
                }
                alert("Sorry, we encountered an error! Please try again or contact us with this error message:\n\n " +
                      messageText);

                var action = component.get("c.logNow");
                action.setParams({className : event.getParam("className"),
                            methodName : event.getParam("methodName"),
                            message : messageText});
                action.setCallback(this, function(resp){});
                $A.enqueueAction(action);                
            }
        }
    }
})
