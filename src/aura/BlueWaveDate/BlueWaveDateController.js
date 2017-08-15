({
    onRender : function(component, event, helper) {
        var currVal = component.get("v.value");
        if (currVal && currVal.includes('-')) {
            component.set("v.value", helper.getFormattedDate(currVal));
        }
    },
    format : function(component, event) {
        var currVal = component.find("BlueWaveDate").get("v.value");
        var numChars = currVal.length;
        //To accomdate for backspacing, we detect which key was pressed - if backspace (keycode 8), do nothing:
        if (event.getParams().keyCode !== 8) {
            // user entered a /, fix formatting or supress if necessary
            if (event.getParams().keyCode === 111 || event.getParams().keyCode === 191) {
                if (currVal.endsWith('/') && numChars === 2) {
                    // e.g. 1/ turns into 01/
                    component.set("v.value", '0' + currVal);
                } else if (currVal.endsWith('/') && numChars === 5) {
                    // e.g. 01/1/ turns into 01/01
                    component.set("v.value", currVal.substring(0,3) + '0' + currVal.substring(3,5));
                } else {
                    // in case there's something like this: 10//
                    component.set("v.value", currVal.replace('//', '/'));
                }
            } else {
                if (!currVal.endsWith('/') && (numChars === 2 || numChars === 5)) {
                    component.set("v.value", currVal + '/');
                }
            }
        }
    }
})