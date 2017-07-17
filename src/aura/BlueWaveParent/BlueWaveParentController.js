({
    handleSystemError : function(component, event) {
        console.log('System Error Received: ' + event.getParam("message"));
        var appEvent = $A.get("e.c:ApexCallbackError");
        appEvent.setParams({"className" : "BlueWaveParentHelper",
                            "methodName" : "handleSystemError",
                            "errors" : event.getParam("message")});
        appEvent.fire();
    },
})
