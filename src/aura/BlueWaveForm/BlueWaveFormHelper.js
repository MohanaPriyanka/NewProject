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


    convertStateToAbbreviation: function(stringName) {
        String abbreviation;
        switch (stateName) {
            case 'Alabama ':
                abbreviation = 'AL';            
            case 'Alaska ':
                abbreviation = 'AK';            
            case 'Arizona ':
                abbreviation = 'AZ';            
            case 'Arkansas ':
                abbreviation = 'AR';            
            case 'California ':
                abbreviation = 'CA';            
            case 'Colorado ':
                abbreviation = 'CO';            
            case 'Connecticut ':
                abbreviation = 'CT';            
            case 'Delaware ':
                abbreviation = 'DE';            
            case 'Florida ':
                abbreviation = 'FL';            
            case 'Georgia ':
                abbreviation = 'GA';            
            case 'Hawaii ':
                abbreviation = 'HI';            
            case 'Idaho ':
                abbreviation = 'ID';            
            case 'Illinois':
                abbreviation = 'IL';            
            case 'Indiana ':
                abbreviation = 'IN';            
            case 'Iowa ':
                abbreviation = 'IA';            
            case 'Kansas ':
                abbreviation = 'KS';            
            case 'Kentucky ':
                abbreviation = 'KY';            
            case 'Louisiana ':
                abbreviation = 'LA';            
            case 'Maine ':
                abbreviation = 'ME';            
            case 'Maryland ':
                abbreviation = 'MD';            
            case 'Massachusetts ':
                abbreviation = 'MA';            
            case 'Michigan ':
                abbreviation = 'MI';            
            case 'Minnesota ':
                abbreviation = 'MN';            
            case 'Mississippi ':
                abbreviation = 'MS';            
            case 'Missouri ':
                abbreviation = 'MO';            
            case 'Montana':
                abbreviation = 'MT';            
            case 'Nebraska ':
                abbreviation = 'NE';            
            case 'Nevada ':
                abbreviation = 'NV';            
            case 'New Hampshire ':
                abbreviation = 'NH';            
            case 'New Jersey ':
                abbreviation = 'NJ';            
            case 'New Mexico ':
                abbreviation = 'NM';            
            case 'New York ':
                abbreviation = 'NY';            
            case 'North Carolina ':
                abbreviation = 'NC';            
            case 'North Dakota ':
                abbreviation = 'ND';            
            case 'Ohio ':
                abbreviation = 'OH';            
            case 'Oklahoma ':
                abbreviation = 'OK';            
            case 'Oregon ':
                abbreviation = 'OR';            
            case 'Pennsylvania':
                abbreviation = 'PA';            
            case 'RhodeIsland ':
                abbreviation = 'RI';            
            case 'South Carolina ':
                abbreviation = 'SC';            
            case 'South Dakota ':
                abbreviation = 'SD';            
            case 'Tennessee ':
                abbreviation = 'TN';            
            case 'Texas ':
                abbreviation = 'TX';            
            case 'Utah ':
                abbreviation = 'UT';            
            case 'Vermont ':
                abbreviation = 'VT';            
            case 'Virginia ':
                abbreviation = 'VA';            
            case 'Washington ':
                abbreviation = 'WA';            
            case 'West Virginia ':
                abbreviation = 'WV';            
            case 'Wisconsin ':
                abbreviation = 'WI';            
            case 'Wyoming':
                abbreviation = 'WY';            
            default:
                abbreviation = stateName;  
        }
        return abbreviation;   
    }    
})