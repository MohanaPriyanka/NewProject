({
    doInit : function(component, event, helper) {
        var actionGetUASList = component.get("c.getUASes"); 
        var compParentId = component.get("v.parentId");
        var isProductionUpdate = component.get("v.IsProdUpdate");
        
        switch (component.get("v.IsProdUpdate")) {
           case "FALSE":
        	// $A.util.addClass(component.find('switchDisplay'), 'noDisplay');
        	// $A.util.addClass(component.find('switchDisplayTwo'), 'noDisplay');
             break;
           case "TRUE":
             break;
        }
        actionGetUASList.setParams({
            "parentId" : compParentId,
            "isProdUpdate" : isProductionUpdate,
        });
        
        actionGetUASList.setCallback(this,function(resp){
            if (resp.getState() == 'SUCCESS') {
                component.set("v.SchZBillList", resp.getReturnValue());  
            } else {
            }
        });   
        $A.enqueueAction(actionGetUASList);
    }, 
    
    downloadCsv : function(component,event,helper){
        
        var stockData = component.get("v.SchZBillList");
        
        var csv = helper.convertArrayOfObjectsToCSV(component,stockData);   
         if (csv == null){return;} 
        
	     var hiddenElement = document.createElement('a');
          hiddenElement.href = 'data:text/csv;charset=utf-8,' + encodeURI(csv);
          hiddenElement.target = '_self'; // 
          hiddenElement.download = 'PreviewBills.csv';   
          document.body.appendChild(hiddenElement); 
    	  hiddenElement.click(); 
        }, 
    
})