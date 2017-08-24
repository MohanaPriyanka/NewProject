({
    doInit : function(component, helper) {
        var headerMap = {};
        var headerLabels = component.get("v.headerLabels");
        var fieldNames = component.get("v.recordFieldNames");

        for (i=0; i < headerLabels.length; i++) {
            var label = headerLabels[i];
            headerMap[label] = fieldNames[i];
        }  
        component.set("v.headerMap", headerMap);
    },

    sortTable: function(component, event, helper) {
    	var removedList = [];
        var sortField = event.getParam("sortField");        
        var currentOrder = component.get("v.sortAsc"),
            currentList = component.get("v.tableRecords");
        currentOrder = !currentOrder;
        console.log(currentList);        
        for (i=0; i < currentList.length; i++) {
            var record = currentList[i];
        	if (sortField.includes("__r.")) {
        		var crossRelationalField = sortField.split(".");
        		var objectRecord = crossRelationalField[0].replace("__r", "__c");
        		if (record[objectRecord] == null) {
        			removedList.push(record);        			
        			currentList.splice(i, 1);   			
        		}        		             		
        	} else if (sortField.includes("__r[0]")) {
                // console.log(record);
                var childObjectList = sortField.split("[0].");                
                if (record[childObjectList[0]] == null) {
                    removedList.push(record);                   
                    currentList.splice(i, 1);  
                    // console.log(currentList);
                    debugger;    
                    console.log(removedList);                 
                } else {
                    if (record[childObjectList[0]]["0"][childObjectList[1]] == null) {
                        console.log(record[childObjectList[0]]["0"][childObjectList[1]]);
                        removedList.push(record);                   
                        currentList.splice(i, 1);                    
                    }
                }                              
            } 
            else {
        		if (record[sortField] == null) {
        			removedList.push(record);        			
        			currentList.splice(i, 1);
        		}        		             		        		
        	}
        }
        currentList.sort(function(a,b) {
        	if (a[sortField] == null) {
        		return -1;
        	} else {
            	var t1 = a[sortField] == b[sortField], t2 = a[sortField] < b[sortField];
            	return t1? 0: (currentOrder?-1:1)*(t2?1:-1);
        	}
        });
        // console.log(removedList);
        if (removedList.length > 0) {
        	for (i=0; i < removedList.length; i++) {
        		if (currentOrder) {
        			currentList.unshift(removedList[i]);
        		} else {
        			currentList.push(removedList[i]);
        		}
        	}        	
        }
        component.set("v.sortAsc", currentOrder);
        component.set("v.tableRecords", currentList);
        component.set("v.sortField", sortField);
    },
})
