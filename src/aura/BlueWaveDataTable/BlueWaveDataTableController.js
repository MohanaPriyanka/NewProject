// consider putting a query attribure into the component that allows the user to chooose if they want to query in the table or outside the table
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
        var currentOrder = !component.get("v.sortAsc"),
            recordList = component.get("v.tableRecords");
        var returnLists = helper.handleNullValuesInSort(component, recordList, removedList, sortField);
        recordList = [];
        removedList = returnLists[0];
        recordList = returnLists[1];

        helper.sortRecords(component, recordList, currentOrder, sortField);
        helper.addNullValuesTorecordList(component, recordList, removedList, currentOrder);
        helper.setComponentSortAttributes(component, recordList, currentOrder, sortField);
    },
})
