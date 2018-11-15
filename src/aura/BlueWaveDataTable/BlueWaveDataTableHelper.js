({
    handleFieldSecurity : function(component) {
        var licenseType = component.get("v.licenseType");
        this.removeItemsFromTable(component, "recordFieldNames", licenseType);
        this.removeItemsFromTable(component, "headerLabels", licenseType);
    },

    removeItemsFromTable : function(component, attribute, licenseType) {
        var profileSecurityMap = component.get("v.profileSecurityMap");
        var list = component.get("v." + attribute);
        var updatedList = list.slice();
        var removedList = [];
        var i;
        if (profileSecurityMap != null) {
            if (profileSecurityMap[licenseType] != null) {
                var privateFields = profileSecurityMap[licenseType];
                for (i=0; i<list.length; i++) {
                    var index = updatedList.indexOf(list[i]);
                    if (privateFields.includes(list[i])) {
                        this.removeItemFromList(index, updatedList, removedList);
                    }
                }
                component.set("v." + attribute, updatedList);
            }
        }
    },

    setRecordCount : function(component, recordList) {
        var recordCount = component.get("v.numberOfRecordsPerPage");
        var trimmedRecordList = recordList.slice(0, recordCount);
        component.set("v.tableRecords", trimmedRecordList);
    },

    setHeaderMap : function(component) {
        var headerMap = {};
        var headerLabels = component.get("v.headerLabels");
        var fieldNames = component.get("v.recordFieldNames");
        var i;

        for (i=0; i < headerLabels.length; i++) {
            var label = headerLabels[i];
            headerMap[label] = fieldNames[i];
        }
        component.set("v.headerMap", headerMap);
    },

    handleNullValuesInSort : function(component, recordList, removedList, sortField) {
        var updatedList = recordList.slice();
        var i;
        for (i=0; i < recordList.length; i++) {
            var record = recordList[i];
            var index = updatedList.indexOf(record);
            if (sortField.includes("__r.")) {
                var crossRelationalField = sortField.split(".");
                var objectRecord = crossRelationalField[0].replace("__r", "__c");
                if (record[objectRecord] == null) {
                    this.removeItemFromList(index, updatedList, removedList)
                }
            } else if (sortField.includes("__r[0]")) {
                var childObjectList = sortField.split("[0].");
                if (record[childObjectList[0]] == null || record[childObjectList[0]]["0"][childObjectList[1]] == null) {
                    this.removeItemFromList(index, updatedList, removedList);
                }
            } else {
                if (record[sortField] == null) {
                    this.removeItemFromList(index, updatedList, removedList);
                }
            }
        }
        return [removedList, updatedList];
    },

    removeItemFromList : function(index, updatedList, removedList) {
	var currentRemovedList = updatedList.splice(index, 1);
        var j;
	if (currentRemovedList.length > 0) {
	    for (j=0; j < currentRemovedList.length; j++) {
		removedList.push(currentRemovedList[j]);
	    }
	}
    },

    sortRecords : function(component, recordList, currentOrder, sortField) {
        recordList.sort(function(a,b) {
            if (sortField.includes("__r.")) {
                var crossRelationalField = sortField.split(".");
                var objectRecord = crossRelationalField[0].replace("__r", "__c");
                var sortValueA = a[objectRecord];
                var sortValueB = b[objectRecord];
            } else if (sortField.includes("__r[0]")) {
                var childObjectList = sortField.split("[0].");
                var sortValueA = a[childObjectList[0]]["0"][childObjectList[1]]
                var sortValueB = b[childObjectList[0]]["0"][childObjectList[1]]
            } else {
                var sortValueA = a[sortField];
                var sortValueB = b[sortField];
            }
            if (sortValueA == null) {
        	return -1;
            } else {
            	var t1 = sortValueA == sortValueB, t2 = sortValueA < sortValueB;
            	return t1? 0: (currentOrder?-1:1)*(t2?1:-1);
            }
        });
    },

    addNullValuesToRecordList : function(component, recordList, removedList, currentOrder) {
        var i;
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
        component.set("v.sortedRecords", recordList);
        component.set("v.sortField", sortField);
    },

    returnToPageOne : function(component) {
        var recordList = component.get("v.sortedRecords");
        var recordsPerPage = component.get("v.numberOfRecordsPerPage");
        var trimmedRecordList = recordList.slice(0, recordsPerPage);
        $A.util.addClass(component.find('previousPageButton'), 'noDisplay');
        $A.util.removeClass(component.find('nextPageButton'), 'noDisplay');
        $A.util.removeClass(component.find('tableNavCenterGridclass'), 'center');
        $A.util.addClass(component.find('tableNavCenterGridclass'), 'centerWithoutPreviousPage');
        component.set("v.currentPage", 1);
        component.set("v.tableRecords", trimmedRecordList);
    },
})