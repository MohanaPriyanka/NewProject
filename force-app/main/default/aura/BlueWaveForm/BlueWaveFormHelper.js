({
    // options:
    // var options = {
    //     'fieldValue' : null, (required)
    //     'fieldId' : null, (required)
    //     'animation' : null:,
    //     'expectedLength' : null,
    //     'allowLetters' : true,
    //     'allowSpecialChars' : false,
    //     'allowSpaces' : true,
    //     'errorMessage' : null,
    //     'fieldType' : 'standard',
    //     'optional' : false
    // }
    getFieldError : function(component, options) {
        return this.checkFieldValidity(
            component,
            options.fieldValue,
            options.fieldId,
            options.hasOwnProperty('animation')?options.animation:'shake',
            options.hasOwnProperty('expectedLength')?options.expectedLength:null,
            options.hasOwnProperty('maxLength')?options.maxLength:null,
            options.hasOwnProperty('allowLetters')?options.allowLetters:true,
            options.hasOwnProperty('allowSpecialChars')?options.allowSpecialChars:false,
            options.hasOwnProperty('allowSpaces')?options.allowSpaces:true,
            options.hasOwnProperty('errorMessage')?options.errorMessage:'Error with ' + options.fieldId,
            options.hasOwnProperty('optional')?options.optional:false,
            options.hasOwnProperty('fieldType')?options.fieldType:'standard');
    },

    checkFieldValidity : function(component, fieldValue, fieldId, animation, expectedLength, maxLength, allowLetters, allowSpecialChars, allowSpaces, errorMessage, optional, fieldType) {
        if (this.invalidField(component, fieldValue, expectedLength, allowLetters, allowSpecialChars, allowSpaces, maxLength, optional, fieldType)) {
    	    this.setInputToError(component, fieldId, animation);
    	    return errorMessage + "\n" + "\n";
    	} else {
    	    this.setInputToCorrect(component, fieldId);
    	    return "";
    	}
    },

    invalidField : function(component, fieldValue, expectedLength, allowLetters, allowSpecialChars, allowSpaces, maxLength, optional, fieldType) {
        var error;
    	var format;
    	if (fieldType === 'standard') {
            if (!optional && (fieldValue === '' || fieldValue === null || !fieldValue)) {
                return true;
            } else {
                if (fieldValue && expectedLength > 0 && fieldValue.length != expectedLength) {
                    return true;
                }
                if (!allowLetters && !/^[0-9]+$/.test(fieldValue)) {
                    return true;
                }
                if (!allowSpecialChars && allowSpaces && !/^[a-zA-Z0-9- .\b]+$/.test(fieldValue)) {
                    return true;
                }
                if (!allowSpecialChars && !allowSpaces && !/^[a-zA-Z0-9-]*$/.test(fieldValue)) {
                    return true;
                }
                if (fieldValue && maxLength > 0 && fieldValue.length > maxLength) {
                    return true;
                }
            }
    	} else if (fieldType === 'email') {
    	    format = /^(([^<>()\[\]\\.,;:\s@"]+(\.[^<>()\[\]\\.,;:\s@"]+)*)|(".+"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$/;
                return !format.test(fieldValue);
    	} else if (fieldType === 'date') {
            format = /^\d{2}\/\d{2}\/\d{4}$/;
            if (!format.test(fieldValue)) {
                return true;
            }

            // Parse the date parts to integers
            var parts = fieldValue.split("/");
            var day = parseInt(parts[1], 10);
            var month = parseInt(parts[0], 10);
            var year = parseInt(parts[2], 10);

            // Check the ranges of month and year
            if(year < 1000 || year > 3000 || month === 0 || month > 12) {
                return true;
            }

            var monthLength = [ 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31 ];

            // Adjust for leap years
            if (year % 400 === 0 || (year % 100 !== 0 && year % 4 === 0)) {
                monthLength[1] = 29;
            }

            // Check the range of the day
            return day < 0 || day > monthLength[month - 1];
    	} else if (fieldType === 'phone') {
                format = /^[\+]?[(]?[0-9]{3}[)]?[-\s\.]?[0-9]{3}[-\s\.]?[0-9]{4,6}$/;
                return !format.test(fieldValue);
    	} else if (fieldType === 'ssn') {
                format = /^\d{3}[-]?\d{2}[-]?\d{4}$/;
                return !format.test(fieldValue);
    	} else if (fieldType === 'currency') {
                // Assumes a ui:inputCurrency field, so just check for a value, but could be 0
    	    return (fieldValue === '' || fieldValue === null);
    	} else if (fieldType === 'uncheckedCheckbox') {
    	    return (!fieldValue);
            }
    	return false;
    },

    setInputToError : function(component, fieldId, animation) {
        $A.util.addClass(component.find(fieldId), 'slds-has-error'); 
        if (animation != null) {
            $A.util.addClass(component.find(fieldId), animation);
        }
    },     

    setInputToCorrect : function(component, fieldId) {
        $A.util.removeClass(component.find(fieldId), 'slds-has-error'); 
    },     
})