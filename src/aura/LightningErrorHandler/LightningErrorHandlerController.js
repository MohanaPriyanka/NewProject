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
                } else {
                    messageText = errors;
                }
                alert("Sorry, we encountered an error! Please try again or contact us with this error message:\n\n" +
                      messageText);

                var action = component.get("c.logNow");
                var devInfo = JSON.stringify(event.getParam("developerInfo"),
                                             function replacer(key, value) {
                                                 var blacklist = ['LASERCA__SSN__c']
                                                 return blacklist.indexOf(key) === -1 ? value : undefined
                                             },
                                             2);
                action.setParams({className : event.getParam("className"),
                            methodName : event.getParam("methodName"),
                            message : messageText + "\n\n" + (devInfo?devInfo:'')});
                action.setCallback(this, function(resp){});
                $A.enqueueAction(action);                
            }
        }
    }
})
