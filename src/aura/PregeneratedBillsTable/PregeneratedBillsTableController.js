({
    doInit : function(component, event, helper) {
        //TODO
        var actionGetUASList = component.get("c.getUASes"); 
        var compParentId = component.get("v.parentId");
        var isTransfer = component.get("v.IsTransfer");

        if (!isTransfer) {
            actionGetUASList.setParams({
                "parentId" : compParentId,
                "isTransfer" : isTransfer,
                "scheduleZName" : ''
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
        }
    },
    
    downloadCsv : function(component,event,helper){
        
        var stockData = component.get("v.SchZBillList");

        var allHavePremise = true;
        var allDoNotHavePremise = true;
        var i;
        for (i = 0; i < stockData.length; i++) {
            if (stockData[i].PreGen_Additional_Id__c != null) {
                allDoNotHavePremise = false;
            } else {
                allHavePremise = false;
            }
        }

        var keys;

        if (allDoNotHavePremise) {
            keys = ['Name','PreGen_IsPreGen__c', 'PreGen_Discounted_Bill__c', 'PreGen_NMCs_Allocated__c', 'PreGen_Name_on_Account__c',
                'PreGen_Production_Update__c', 'PreGen_Schedule_Z_Status__c', 'PreGen_System_Share__c', 'PreGen_Utility_Acct__c'];
        } else if (allHavePremise) {
            keys = ['Name','PreGen_IsPreGen__c', 'PreGen_Discounted_Bill__c', 'PreGen_NMCs_Allocated__c', 'PreGen_Name_on_Account__c',
                'PreGen_Production_Update__c', 'PreGen_Additional_Id__c', 'PreGen_Schedule_Z_Status__c', 'PreGen_System_Share__c'];
        } else {
            keys = ['Name','PreGen_IsPreGen__c', 'PreGen_Discounted_Bill__c', 'PreGen_NMCs_Allocated__c', 'PreGen_Name_on_Account__c',
                'PreGen_Production_Update__c', 'PreGen_Additional_Id__c', 'PreGen_Schedule_Z_Status__c', 'PreGen_System_Share__c', 'PreGen_Utility_Acct__c'];
        }

        
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

        var allHavePremise = true;
        var allDoNotHavePremise = true;
        for (var i = 0; i < stockData.length; i++) {
            if (stockData[i].PreGen_Additional_Id__c != null) {
                allDoNotHavePremise = false;
            } else {
                allHavePremise = false;
            }
        }

        var keys;

        if (allDoNotHavePremise) {
            keys = ['PreGen_Utility_Acct__c', 'PreGen_System_Share__c', 'PreGen_NMCs_Allocated__c'];
        } else if (allHavePremise) {
            keys = ['PreGen_Additional_Id__c', 'PreGen_System_Share__c', 'PreGen_NMCs_Allocated__c'];
        } else {
            keys = ['PreGen_Utility_Acct__c', 'PreGen_System_Share__c', 'PreGen_Additional_Id__c', 'PreGen_NMCs_Allocated__c'];
        }

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