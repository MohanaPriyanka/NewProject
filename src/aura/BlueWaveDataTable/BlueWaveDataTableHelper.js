({
    setHeaderMap : function(component) {
        var headerMap = {};
        var headerLabels = component.get("v.headerLabels");
        var fieldNames = component.get("v.recordFieldNames");

        for (i=0; i < headerLabels.length; i++) {
            var label = headerLabels[i];
            headerMap[label] = fieldNames[i];
        }  
        component.set("v.headerMap", headerMap);
    },      

	handleNullValuesInSort : function(component, recordList, removedList, sortField) {
        var updatedList = recordList.slice();
        for (i=0; i < recordList.length; i++) {
            var record = recordList[i];
            var index = updatedList.indexOf(record);            
            if (sortField.includes("__r.")) {
                var crossRelationalField = sortField.split(".");
                var objectRecord = crossRelationalField[0].replace("__r", "__c");
                if (record[objectRecord] == null) {
                	this.removeNullRecordsFromList(index, updatedList, removedList)              
                }                                   
            } else if (sortField.includes("__r[0]")) {
                var childObjectList = sortField.split("[0]."); 
                if (record[childObjectList[0]] == null || record[childObjectList[0]]["0"][childObjectList[1]] == null) {
                	this.removeNullRecordsFromList(index, updatedList, removedList);
                }                           
            } else {
                if (record[sortField] == null) {
                	this.removeNullRecordsFromList(index, updatedList, removedList);
                }                                                   
            }
        }
        return [removedList, updatedList];
	}, 

	removeNullRecordsFromList : function(index, updatedList, removedList) {
		var currentRemovedList = updatedList.splice(index, 1);
		if (currentRemovedList.length > 0) {
			for (j=0; j < currentRemovedList.length; j++) {
				removedList.push(currentRemovedList[j]);
			}
		}
	},		

	sortRecords : function(component, recordList, currentOrder, sortField) {
        recordList.sort(function(a,b) {
        	if (a[sortField] == null) {
        		return -1;
        	} else {
            	var t1 = a[sortField] == b[sortField], t2 = a[sortField] < b[sortField];
            	return t1? 0: (currentOrder?-1:1)*(t2?1:-1);
        	}
        });
	},	

	addNullValuesToRecordList : function(component, recordList, removedList, currentOrder) {
        if (removedList.length > 0) {
        	for (i=0; i < removedList.length; i++) {
        		if (currentOrder) {
        			recordList.unshift(removedList[i]);
        		} else {
        			recordList.push(removedList[i]);
        		}
        	}
        }
	},	

	setComponentSortAttributes : function(component, recordList, currentOrder, sortField) {
        component.set("v.sortAsc", currentOrder);
        component.set("v.tableRecords", recordList);
        component.set("v.sortField", sortField);
	},	
})