// consider putting a query attribure into the component that allows the user to chooose if they want to query in the table or outside the table
({
    doInit : function(component, helper) {
        var headerMap = {};
        var headerLabels = component.get("v.headerLabels");
        var fieldNames = component.get("v.recordFieldNames");
        var records = component.get("v.tableRecords");
        console.log(fieldNames);
        console.log(headerLabels);
        console.log(records);

        for (i=0; i < headerLabels.length; i++) {
            var label = headerLabels[i];
            headerMap[label] = fieldNames[i];
        }  
        component.set("v.headerMap", headerMap);        

        var conditionalField = component.get("v.buttonConditionalField");
        var conditionalFieldMap = component.get("v.buttonConditionalsMap");
        var buttonLabelsMap = component.get("v.buttonLabelsMap");        

        for (i=0; i < fieldNames.length; i++) {     
            if (conditionalField === null) {
                if (buttonLabelsMap["All"] != null) {
                    component.set("v.buttonLabel", buttonLabelsMap["All"]);
                }                      
            } else {
                if (conditionalFieldMap[fieldNames[i] != null]) {
                    component.set("v.buttonLabel", conditionalFieldMap[fieldNames[i]]);                                          
                } else {
                    return;
                } 
            }
        }     
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

    setButton: function(component, event, helper) {
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



// // consider putting a query attribure into the component that allows the user to chooose if they want to query in the table or outside the table
// ({
//     doInit : function(component, helper) {
//         var headerMap = {};
//         var headerLabels = component.get("v.headerLabels");
//         var fieldNames = component.get("v.recordFieldNames");

//         for (i=0; i < headerLabels.length; i++) {
//             var label = headerLabels[i];
//             headerMap[label] = fieldNames[i];
//         }  
//         component.set("v.headerMap", headerMap);        
       
//         var records = component.get("v.tableRecords");
//         var conditionalField = component.get("v.buttonConditionalField");
//         var conditionalFieldMap = component.get("v.buttonConditionalsMap");
//         var buttonLabelsMap = component.get("v.buttonLabelsMap");        
//         if (records.length > 0 ) {
//             for (i=0; i < records.length; i++) {     
//                 if (conditionalField === null) {
//                     if (buttonLabelsMap["All"] != null) {
//                         component.set("v.buttonLabel", buttonLabelsMap["All"]);
//                     }                      
//                 } else {
//                     if (conditionalFieldMap[record[i][conditionalField]] != null) {
//                         component.set("v.buttonLabel", conditionalFieldMap[record[i][conditionalField]]);                                          
//                     } else {
//                         return;
//                     } 
//                 }
//             } 
//         }    
//     },

//     sortTable: function(component, event, helper) {
//         var removedList = [];
//         var sortField = event.getParam("sortField");        
//         var currentOrder = !component.get("v.sortAsc"),
//             recordList = component.get("v.tableRecords");
//         var returnLists = helper.handleNullValuesInSort(component, recordList, removedList, sortField);
//         recordList = [];
//         removedList = returnLists[0];
//         recordList = returnLists[1];

//         helper.sortRecords(component, recordList, currentOrder, sortField);
//         helper.addNullValuesTorecordList(component, recordList, removedList, currentOrder);
//         helper.setComponentSortAttributes(component, recordList, currentOrder, sortField);
//     },

//     setButton: function(component, event, helper) {
//         var removedList = [];
//         var sortField = event.getParam("sortField");        
//         var currentOrder = !component.get("v.sortAsc"),
//             recordList = component.get("v.tableRecords");
//         var returnLists = helper.handleNullValuesInSort(component, recordList, removedList, sortField);
//         recordList = [];
//         removedList = returnLists[0];
//         recordList = returnLists[1];

//         helper.sortRecords(component, recordList, currentOrder, sortField);
//         helper.addNullValuesTorecordList(component, recordList, removedList, currentOrder);
//         helper.setComponentSortAttributes(component, recordList, currentOrder, sortField);
//     },    
// })