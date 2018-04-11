({
    doInit : function(component, event, helper) {
        var actionGetUASList = component.get("c.getUASes"); 
        var compParentId = component.get("v.parentId");
        var isProductionUpdate = component.get("v.IsProdUpdate");
        
        actionGetUASList.setParams({
            "parentId" : compParentId,
            "isProdUpdate" : isProductionUpdate,
        });
        
        actionGetUASList.setCallback(this,function(resp){
            if (resp.getState() === 'SUCCESS') {
                component.set("v.SchZBillList", resp.getReturnValue());  
            } else {
                var appEvent = $A.get("e.c:ApexCallbackError");
				appEvent.setParams({"className" : "PreviewProductionUpdateResults",
				"methodName" : "getUASes",
				"errors" : "No Active UASes Found"});
				appEvent.fire();
            }
        });   
        $A.enqueueAction(actionGetUASList);
    }, 
    
    downloadCsv : function(component,event,helper){
        
        var stockData = component.get("v.SchZBillList");

        var keys = ['Name','PreGen_IsPreGen__c', 'PreGen_Discounted_Bill__c', 'PreGen_NMCs_Allocated__c', 'PreGen_Name_on_Account__c', 
               'PreGen_Production_Update__c', 'PreGen_Schedule_Z_Status__c', 'PreGen_System_Share__c', 'PreGen_Utility_Acct__c'];
        
        var csv = helper.convertArrayOfObjectsToCSV(component,stockData,keys);   
         if (csv == null){return;} 

	     var hiddenElement = document.createElement('a');
          hiddenElement.href = 'data:text/csv;charset=utf-8,' + encodeURI(csv);
          hiddenElement.target = '_self'; // 
          hiddenElement.download = 'PreviewBills.csv';   
          document.body.appendChild(hiddenElement); 
    	  hiddenElement.click(); 
    },   

    downloadTransferSheet : function(component,event,helper){  
        var stockData = component.get("v.SchZBillList");
        var keys = ['PreGen_Utility_Acct__c', 'PreGen_System_Share__c', 'PreGen_NMCs_Allocated__c'];
        
        var csv = helper.convertArrayOfObjectsToCSV(component,stockData,keys);   
         if (csv == null){return;} 
         var hiddenElement = document.createElement('a');
          hiddenElement.href = 'data:text/csv;charset=utf-8,' + encodeURI(csv);
          hiddenElement.target = '_self'; 
          hiddenElement.download = 'TransferSheetQC.csv';   
          document.body.appendChild(hiddenElement); 
          hiddenElement.click(); 
    },       
})