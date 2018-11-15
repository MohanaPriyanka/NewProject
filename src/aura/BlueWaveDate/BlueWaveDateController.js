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
        var newVal = currVal;
        //To accommodate for backspacing, we detect which key was pressed - if backspace (keycode 8), do nothing:
        if (event.getParams().keyCode !== 8) {
            // user entered a /, fix formatting or suppress if necessary
            if (event.getParams().keyCode === 111 || event.getParams().keyCode === 191) {
                if (currVal.endsWith('/') && numChars === 2) {
                    // e.g. 1/ turns into 01/
                    newVal = '0' + currVal;
                } else if (currVal.endsWith('/') && numChars === 5) {
                    // e.g. 01/1/ turns into 01/01
                    newVal = currVal.substring(0, 3) + '0' + currVal.substring(3, 5);
                } else {
                    // in case there's something like this: 10//
                    newVal = currVal.replace('//', '/');
                }
            }
            // Now, newVal should be well formatted, but we need to find strings like 001/00 or 01/001/
            var parts = newVal.split('/');
            var carryover = '';
            if (parts[0]) {
                newVal = parts[0].substring(0,2);
                carryover = parts[0].substring(2);
            }
            if (parts[1] || (carryover !== '' && carryover !== null)) {
                var day = carryover + (parts[1]?parts[1]:'');
                newVal += '/' + day.substring(0,2);
                carryover = day.substring(2);
            }
            if (parts[2] || (carryover !== '' && carryover !== null)) {
                var year = carryover + (parts[2]?parts[2]:'');
                newVal += '/' + year.substring(0,4);
            }
            if (!newVal.endsWith('/') && (newVal.length === 2 || newVal.length === 5)) {
                newVal += '/';
            }
            if (newVal !== currVal) {
                component.set("v.value", newVal);
            }
        }
    }
})