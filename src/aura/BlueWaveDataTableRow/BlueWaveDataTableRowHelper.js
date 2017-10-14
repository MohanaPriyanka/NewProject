({
    setRowValues : function(component, record, fieldName, nullValueMap) {
        var outputValue = this.setOutputValueId(component);
        if (fieldName != null) {
        	this.handleNullChildAndCrossRelationalFields(component, outputValue, record, fieldName, nullValueMap);
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

    handleNullChildAndCrossRelationalFields : function(component, outputValue, record, fieldName, nullValueMap) {
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
                // set a key value of the record object to complete so that the user can search for the assign complete value.
                var objectRecord = component.get("v.objectRecord");
                objectRecord["objectRecordNullValue"] = nullValueMap[fieldName];
                console.log(objectRecord);
                component.set["v.objectRecord", objectRecord];
                outputValue.set("v.value", nullValueMap[fieldName]); 
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

    setColorAttributeColumn : function(component, fieldName) {
        var columnColorMap = component.get("v.columnColorMap");
        if (columnColorMap != null && fieldName != null) {
            if (columnColorMap[fieldName] == null) {
                return;
            } else {
                var color = columnColorMap[fieldName];    
                component.set("v.colorCode", color);            
            }
        }
    },   

    setColorAttributeConditionalField : function(component, conditionalField, fieldName, attribute, conditionalMapAttribute, defaultAttribute) {
        var record = component.get("v.objectRecord");
        var conditionalMap = component.get("v." + conditionalMapAttribute);
        var defaultValue = component.get("v." + defaultAttribute);  
        if (conditionalField === fieldName && conditionalField != null) {
            this.setConditionalOrDefaultAttribute(component, attribute, record, conditionalField, conditionalMap, defaultValue);
        }
    },      

    setButtonAttribute : function(component, conditionalField, attribute, conditionalMapAttribute, defaultAttribute) {
        var record = component.get("v.objectRecord");
        var conditionalMap = component.get("v." + conditionalMapAttribute);
        var defaultValue = component.get("v." + defaultAttribute);  
        this.setConditionalOrDefaultAttribute(component, attribute, record, conditionalField, conditionalMap, defaultValue);
    },  

    setConditionalOrDefaultAttribute : function(component, attribute, record, conditionalField, conditionalMap, defaultValue) {
        if (record != null) {
            if (conditionalField != null) {
                if (conditionalField.includes("__r.")) {
                    var crossRelationalField = conditionalField.split(".");
                    if (record[crossRelationalField[0]] != null) {
                        if (record[crossRelationalField[0]][crossRelationalField[1]] != null) {
                            if (conditionalMap != null && conditionalMap[record[crossRelationalField[0]][crossRelationalField[1]]] != null) {
                                component.set("v." + attribute, conditionalMap[record[crossRelationalField[0]][crossRelationalField[1]]]);                         
                            } else {
                                this.setAttributeToDefaultValue(component, attribute, defaultValue);
                            }  
                        } else {
                            this.setAttributeToDefaultValue(component, attribute, defaultValue);     
                        }
                    } else {
                        this.setAttributeToDefaultValue(component, attribute, defaultValue); 
                    }
                } else if (conditionalField.includes("__r[0]")) {
                    var childObjectList = conditionalField.split("[0]."); 
                    if (record[childObjectList[0]] != null ) {
                        if (record[childObjectList[0]]["0"][childObjectList[1]]!= null) {
                            if (conditionalMap != null && conditionalMap[record[childObjectList[0]]["0"][childObjectList[1]]]) {
                                component.set("v." + attribute, conditionalMap[record[childObjectList[0]]["0"][childObjectList[1]]]);
                            } else {
                                this.setAttributeToDefaultValue(component, attribute, defaultValue);   
                            }
                        } else {
                            this.setAttributeToDefaultValue(component, attribute, defaultValue);
                        }
                    } else {
                        this.setAttributeToDefaultValue(component, attribute, defaultValue);
                    } 
                } else if (conditionalMap[record[conditionalField]] != null) {
                    component.set("v." + attribute, conditionalMap[record[conditionalField]]);  
                } else {
                    this.setAttributeToDefaultValue(component, attribute, defaultValue);
                }
            } else {
                this.setAttributeToDefaultValue(component, attribute, defaultValue);
            }
        }
    },           

    setAttributeToDefaultValue : function(component, attribute, defaultValue) {
        if (defaultValue != null) {
            component.set("v." + attribute, defaultValue);
        } else {
            component.set("v." + attribute, null); 
        } 
    },           
})


