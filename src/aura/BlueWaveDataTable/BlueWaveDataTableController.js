({
    doInit : function(component, event, helper) {
        helper.setHeaderMap(component);     
        helper.getLicenseType(component); 
        var records = component.get("v.tableRecords"); 
        component.set("v.originalRecords", records);
        component.set("v.sortedRecords", records);
        if (component.get("v.recordsPerPage") < component.get("v.originalRecords").length) {
            helper.setRecordCount(component, records);
        }
        $A.util.addClass(component.find('previousPageButton'), 'noDisplay');   
        $A.util.removeClass(component.find('tableNavCenterGridclass'), 'center');               
        $A.util.addClass(component.find('tableNavCenterGridclass'), 'centerWithoutPreviousPage');      

        var recordList = component.get("v.originalRecords");
        var recordsPerPage = component.get("v.numberOfRecordsPerPage"); 
        var totalPages = Math.ceil(recordList.length/recordsPerPage);

        if (totalPages === 1) {
            $A.util.addClass(component.find('previousPageButton'), 'noDisplay');      
            $A.util.addClass(component.find('tableNavCenterGridclass'), 'noDisplay'); 
            $A.util.addClass(component.find('nextPageButton'), 'noDisplay'); 
        }
    },

    applySecurity : function(component, event, helper) {  
        helper.handleFieldSecurity(component);
    },                 

    sortTable: function(component, event, helper) {
        var removedList = [];
        var sortField = event.getParam("sortField");        
        var currentOrder = event.getParam("sortAsc"),
            recordList = component.get("v.sortedRecords");
        var returnLists = helper.handleNullValuesInSort(component, recordList, removedList, sortField);       
        recordList = [];
        removedList = returnLists[0];
        recordList = returnLists[1];
        helper.sortRecords(component, recordList, currentOrder, sortField);
        helper.addNullValuesToRecordList(component, recordList, removedList, currentOrder);
        helper.setComponentSortAttributes(component, recordList, currentOrder, sortField);
        helper.setRecordCount(component, recordList);  

        var currentPage = component.get("v.currentPage");
        if (currentPage != 1) {
            helper.returnToPageOne(component);
        }
    },    

    nextPage: function(component, event, helper) {
        var recordList = component.get("v.sortedRecords");
        var recordsPerPage = component.get("v.numberOfRecordsPerPage");  
        
        var currentPage = component.get("v.currentPage");
        var nextPage = currentPage + 1;
        var totalPages = Math.ceil(recordList.length/recordsPerPage);

        var recordsShown = currentPage * recordsPerPage;
        var trimmedRecordList = recordList.slice(recordsShown, recordsPerPage * nextPage);
        if (nextPage + 1 > totalPages) {
            $A.util.addClass(component.find('nextPageButton'), 'noDisplay');   
        }
        if (currentPage >= totalPages) {
            return;
        } else {
            $A.util.removeClass(component.find('previousPageButton'), 'noDisplay'); 
            $A.util.addClass(component.find('tableNavCenterGridclass'), 'center');               
            $A.util.removeClass(component.find('tableNavCenterGridclass'), 'centerWithoutPreviousPage');                       
            component.set("v.currentPage", nextPage);
            component.set("v.tableRecords", trimmedRecordList); 
        }       
    },    

    previousPage: function(component, event, helper) {
        var recordList = component.get("v.sortedRecords");
        var recordsPerPage = component.get("v.numberOfRecordsPerPage");  
        
        var currentPage = component.get("v.currentPage");
        var previousPage = currentPage - 1;

        var recordsShown = currentPage * recordsPerPage;
        var trimmedRecordList = recordList.slice(recordsShown  - recordsPerPage * 2, recordsShown - recordsPerPage);
  
        if (previousPage - 1 == 0) {
            $A.util.addClass(component.find('previousPageButton'), 'noDisplay');   
            $A.util.removeClass(component.find('tableNavCenterGridclass'), 'center');               
            $A.util.addClass(component.find('tableNavCenterGridclass'), 'centerWithoutPreviousPage');   
        }        
        if (currentPage == 1) {
            $A.util.addClass(component.find('previousPageButton'), 'noDisplay');   
            return;
        } else {
            $A.util.removeClass(component.find('nextPageButton'), 'noDisplay'); 
            component.set("v.currentPage", previousPage);
            component.set("v.tableRecords", trimmedRecordList); 
        }       
    },         

    showAllRecords: function(component, event, helper) {
        $A.util.addClass(component.find('nextPageButton'), 'noDisplay');   
        $A.util.addClass(component.find('previousPageButton'), 'noDisplay');   
        $A.util.addClass(component.find('showAllButton'), 'noDisplay');   

        var recordList = component.get("v.originalRecords");
        component.set("v.currentPage", 1);
        component.set("v.tableRecords", recordList); 
        }       
    },              
})
