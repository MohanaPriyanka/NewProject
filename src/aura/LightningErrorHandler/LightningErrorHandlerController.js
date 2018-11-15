({
    log : function(component, event) {
        var defaultOptions = {
            suppressAlert: false,
            suppressDBSave: false
        };
        var errors = event.getParam("errors");
        var options = event.getParam('options');
        if (!options) {
            options = defaultOptions;
        }
        if (errors) {
            if (errors[0]) {
                var messageText;
                if (errors[0] && errors[0].message) {
                    messageText = errors[0].message;
                } else if (errors[0] && errors[0].pageErrors && errors[0].pageErrors.length > 0) {
                    messageText = errors[0].pageErrors[0].message;
                } else if (errors[0] && errors[0].fieldErrors && errors[0].fieldErrors.length > 0) {
                    // There might be more than one field error for different fields. Just get the first field which has
                    // a status code, column, and message.

                    const fieldWithError = errors[0].fieldErrors[Object.keys(errors[0].fieldErrors)[0]][0];
                    messageText = fieldWithError.columnApiName + ': ' + fieldWithError.message;
                } else {
                    messageText = errors;
                }
                if (!options.suppressAlert) {
                    alert("Sorry, we encountered an error! Please try again or contact us with this error message:\n\n" +
                          messageText);
                }

                if (!options.suppressDBSave) {
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
    }
})