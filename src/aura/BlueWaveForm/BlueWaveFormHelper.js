({
	checkFieldValidity : function(component, fieldValue, fieldId, animation, expectedLength, allowLetters, allowSpecialChars, allowSpaces, errorMessage, fieldType) {
		if (this.invalidField(component, fieldValue, expectedLength, allowLetters, allowSpecialChars, allowSpaces, fieldType)) {
			this.setInputToError(component, fieldId, animation);
			return errorMessage + "\n" + "\n";                      
		} else {
			this.setInputToCorrect(component, fieldId);
			return "";
		}     
	},       

    invalidField : function(component, fieldValue, expectedLength, allowLetters, allowSpecialChars, allowSpaces, fieldType) {
    	var error;
    	var format;
		if (fieldType === 'standard') {
			if (fieldValue === '' || fieldValue === null || !fieldValue) {
				error = true;
            } else {
                if (expectedLength > 0) {
                    if (fieldValue.length != expectedLength) {
                        error = true;
                    }
                }   	
                if (!allowLetters) {
                    if (!/^[0-9]+$/.test(fieldValue)) {
                        error = true;
                    }
                }
                if (!allowSpecialChars && allowSpaces) {
                    if (!/^[a-zA-Z0-9- .\b]+$/.test(fieldValue)) {
                        error = true;
                    }
                }
                if (!allowSpecialChars && !allowSpaces) {
                    if (!/^[a-zA-Z0-9-]*$/.test(fieldValue)) {
                        error = true;
                    }
                }
            }
		} else if (fieldType === 'email') {
	        format = /^(([^<>()\[\]\\.,;:\s@"]+(\.[^<>()\[\]\\.,;:\s@"]+)*)|(".+"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$/;
	        if (format.test(fieldValue)) {
	        	error = false;
	        } else {
	        	error = true;
	        }
		} else if (fieldType === 'date') {
	        format = /^\d{2}\/\d{2}\/\d{4}$/;
	        if (format.test(fieldValue)) {
	        	error = false;
	        } else {
	        	error = true;
	        }
		}
		if (error) {
			return true;
		} else {
			return false;
		}
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