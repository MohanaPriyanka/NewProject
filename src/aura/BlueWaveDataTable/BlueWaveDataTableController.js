({
    sortTable: function(component, event, helper) {
    	var removedList = [];
        var sortField = event.getParam("sortField");        
        var currentOrder = component.get("v.sortAsc"),
            currentList = component.get("v.tableRecords");
        currentOrder = !currentOrder;

        for (i=0; i < currentList.length; i++) {
        	if (sortField.includes("__r.")) {
        		var crossRelationalField = sortField.split(".");
        		var objectRecord = crossRelationalField[0].replace("__r", "__c");
        		console.log(currentList[i][objectRecord]); 
        		if (currentList[i][objectRecord] == null) {
        			removedList.push(currentList[i]);        			
        			currentList.splice(i, 1);   			
        		}        		             		
        	} else {
        		if (currentList[i][sortField] == null) {
        			removedList.push(currentList[i]);        			
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
        console.log(removedList);
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