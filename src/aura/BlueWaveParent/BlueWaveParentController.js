({
    handleSystemError : function(component, event) {
        console.log('System Error Received: ' + event.getParam("message"));
        helper.logError('BlueWaveParentHelper', 'handleSystemError', event.getParam("message"));
    },
})
