({
    doInit : function(component, helper) {
        var record = component.get('v.objectRecord');
        var fieldName = component.get('v.fieldName');
        var outputText = component.find("outputTextId");
        if (fieldName != null) {
        	if (fieldName.includes("__r.")) {
                var crossRelationalField = fieldName.split(".");                
        		var objectRecord = crossRelationalField[0].replace("__r", "__c");
        		if (record[objectRecord] == null) {
        			outputText.set("v.value", "");     			        			
        		} else {
        			if (record[crossRelationalField[0]][crossRelationalField[1]] == null) {
        				outputText.set("v.value", "");
        			} else {
        				outputText.set("v.value", record[crossRelationalField[0]][crossRelationalField[1]]);     			        				
        			}
        		}
        	} else if (fieldName.includes("__r[0]")) {
                var childObjectList = fieldName.split("[0].");  
                if (record[childObjectList[0]] == null) {
                    outputText.set("v.value", "Complete");       
                } else {
                    outputText.set("v.value", record[childObjectList[0]]["0"][childObjectList[1]]);
                }
            }else {
        		if (record[fieldName] == null) {
        			outputText.set("v.value", "");          			
        		} else {
        			outputText.set("v.value", record[fieldName]);	        			        			
        		}
        	}
        }
    }
})