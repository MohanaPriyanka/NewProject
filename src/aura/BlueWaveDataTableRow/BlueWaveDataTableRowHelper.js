({
    setRowValues : function(component, record, fieldName) {
    	var fieldType = component.get("v.fieldType");
    	if (fieldType === "Currency") {
    		var outputValue = component.find("outputCurrencyId");
    	} else {
    		var outputValue = component.find("outputTextId");    		
    	}
    	
        if (fieldName != null) {
        	this.handleNullChildAndCrossRelationalFields(component, outputValue, record, fieldName);
        }
    },  

    handleNullChildAndCrossRelationalFields : function(component, outputValue, record, fieldName) {
    	if (fieldName.includes("__r.")) {
            var crossRelationalField = fieldName.split(".");                
    		var objectRecord = crossRelationalField[0].replace("__r", "__c");
    		if (record[objectRecord] == null) {
    			outputValue.set("v.value", "");     			        			
    		} else {
    			if (record[crossRelationalField[0]][crossRelationalField[1]] == null) {
    				outputValue.set("v.value", "");
    			} else {
    				outputValue.set("v.value", record[crossRelationalField[0]][crossRelationalField[1]]);     			        				
    			}
    		}
    	} else if (fieldName.includes("__r[0]")) {
            var childObjectList = fieldName.split("[0].");  
            if (record[childObjectList[0]] == null) {
                outputValue.set("v.value", "Complete"); 
            } else {
                outputValue.set("v.value", record[childObjectList[0]]["0"][childObjectList[1]]);
            }
        }else {
    		if (record[fieldName] == null) {
    			outputValue.set("v.value", "");          			
    		} else {
    			outputValue.set("v.value", record[fieldName]);	        			        			
    		}
    	}
    },        

    setFieldType : function(component, fieldName) {
        var fieldTypeMap = component.get("v.fieldTypeMap");
        if (fieldTypeMap != null && fieldName != null) {
            if (fieldTypeMap[fieldName] == null) {
                component.set("v.fieldType", "String");
            } else {
                var fieldType = fieldTypeMap[fieldName];    
                component.set("v.fieldType", fieldType);            
            }
        }
    },     

    setColor : function(component, fieldName) {
        var colorMap = component.get("v.colorMap");
        if (colorMap != null && fieldName != null) {
            if (colorMap[fieldName] == null) {
                return;
            } else {
                var color = colorMap[fieldName];    
                component.set("v.colorCode", color);            
            }
        }
    },   

    setButtonLabels : function(component) {
        var record = component.get("v.objectRecord");
        var conditionalField = component.get("v.buttonConditionalField");
        var conditionalFieldMap = component.get("v.buttonConditionalsLabelMap");
        var allButtonLabels = component.get("v.allButtonLabels");  

        if (allButtonLabels != null) {
            component.set("v.buttonLabel", allButtonLabels);
        } else {
            if (conditionalField != null) {
                if (conditionalFieldMap[record[conditionalField]] != null) {
                    component.set("v.buttonLabel", conditionalFieldMap[record[conditionalField]]);  
                } else {
                    component.set("v.buttonLabel", null);  
                }
            } 
        }  
    }, 

    setButtonEvents : function(component) {
        var record = component.get("v.objectRecord");
        var conditionalField = component.get("v.buttonConditionalField");
        var conditionalFieldMap = component.get("v.buttonConditionalsEventMap");
        var allButtonEvents = component.get("v.allButtonEvents");  

        if (allButtonEvents != null) {
            component.set("v.buttonEventId", allButtonEvents);
        } else {
            if (conditionalField != null) {
                if (conditionalFieldMap[record[conditionalField]] != null) {
                    component.set("v.buttonEventId", conditionalFieldMap[record[conditionalField]]);  
                } else {
                    component.set("v.buttonEventId", null);  
                }
            } 
        }  
    },                  
})
