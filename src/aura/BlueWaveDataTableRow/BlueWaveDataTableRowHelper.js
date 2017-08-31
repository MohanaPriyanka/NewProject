({
    setRowValues : function(component, record, fieldName) {
        var outputValue = this.setOutputValueId(component);
        if (fieldName != null) {
        	this.handleNullChildAndCrossRelationalFields(component, outputValue, record, fieldName);
        }
    },          

    setOutputValueId : function(component, record, fieldName) {
        var fieldType = component.get("v.fieldType");
        if (fieldType === "Currency") {
            var outputValue = component.find("outputCurrencyId");
        } else {
            var outputValue = component.find("outputTextId");           
        }
        return outputValue;
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

    setButtonAttribute : function(component, attribute, conditionalMapAttribute, allAttribute) {
        var record = component.get("v.objectRecord");
        var conditionalField = component.get("v.buttonConditionalField");
        var conditionalMap = component.get("v." + conditionalMapAttribute);
        var allButtonAttribute = component.get("v." + allAttribute);  

        if (conditionalField != null) {
            if (conditionalField.includes("__r.")) {
                var crossRelationalField = conditionalField.split(".");
                if (record[crossRelationalField[0]] != null) {
                    if (record[crossRelationalField[0]][crossRelationalField[1]] != null) {
                        if (conditionalMap[record[crossRelationalField[0]][crossRelationalField[1]]] != null) {
                            component.set("v." + attribute, conditionalMap[record[crossRelationalField[0]][crossRelationalField[1]]]);                         
                        } else {
                            this.setNonConditionalButtonAttribute(component, attribute,allButtonAttribute);
                        }  
                    } else {
                        this.setNonConditionalButtonAttribute(component, attribute,allButtonAttribute);     
                    }
                } else {
                    this.setNonConditionalButtonAttribute(component, attribute,allButtonAttribute); 
                }
            } else if (conditionalField.includes("__r[0]")) {
                var childObjectList = conditionalField.split("[0]."); 
                if (record[childObjectList[0]] != null ) {
                    if (record[childObjectList[0]]["0"][childObjectList[1]]!= null) {
                        if (conditionalMap[record[childObjectList[0]]["0"][childObjectList[1]]]) {
                            component.set("v." + attribute, conditionalMap[record[childObjectList[0]]["0"][childObjectList[1]]]);
                        } else {
                            this.setNonConditionalButtonAttribute(component, attribute,allButtonAttribute);   
                        }
                    } else {
                        this.setNonConditionalButtonAttribute(component, attribute,allButtonAttribute);
                    }
                } else {
                    this.setNonConditionalButtonAttribute(component, attribute,allButtonAttribute);
                } 
            } else if (conditionalMap[record[conditionalField]] != null) {
                component.set("v." + attribute, conditionalMap[record[conditionalField]]);  
            } else {
                this.setNonConditionalButtonAttribute(component, attribute,allButtonAttribute);
            }
        } else {
            this.setNonConditionalButtonAttribute(component, attribute,allButtonAttribute);
        }
    },  

    setNonConditionalButtonAttribute : function(component, attribute, allAttribute) {
        if (allAttribute != null) {
            component.set("v." + attribute, allAttribute);
        } else {
            component.set("v." + attribute, null); 
        } 
    },           


})


