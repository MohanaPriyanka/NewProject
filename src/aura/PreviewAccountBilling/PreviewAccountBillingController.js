({
    doInit : function(component, event, helper) {
        var actionGetProperties = component.get("c.getProperties"); 
        var acctParentId = component.get("v.accountID");
        var isParent = component.get("v.isParentAcct");
        
        actionGetProperties.setParams({
            "parentAcctId" : acctParentId,
            "isParentAcct" : isParent,
        });
        
        actionGetProperties.setCallback(this,function(resp){
            if (resp.getState() === 'SUCCESS') {
                component.set("v.propAccountList", resp.getReturnValue());  
            } else {
                var appEvent = $A.get("e.c:ApexCallbackError");
				appEvent.setParams({"className" : "PreviewProductionUpdateResults",
				"methodName" : "getProperties",
				"errors" : "Can't Find Properties"});
				appEvent.fire();
            }
        });   
        $A.enqueueAction(actionGetProperties);
        
        if (isParent === "TRUE"){
            $A.util.addClass(component.find("secondaryHeader"), 'slds-hide');
        } else {
            $A.util.addClass(component.find("propertyTree"), 'slds-hide');
            $A.util.removeClass(component.find("propertyTree"), 'slds-show');
            var billTable = helper.generateBillTable(component,acctParentId);   
        }
    }, 
    
    updateAccountId : function(component, event, helper) {  
       var newId = event.getSource().get('v.title');
       component.set("v.accountID", newId);
       var newTable = helper.generateBillTable(component,newId);  
       $A.util.removeClass(component.find("tabtwo"), 'slds-is-active'); 
       $A.util.addClass(component.find("tabone"), 'slds-is-active'); 
    },
      
    switchToTransactions : function(component, event, helper) {  
       var propertyList = component.get("v.propAccountList");
       var newTransTable = helper.generateTransactionTable(component,propertyList);   
       $A.util.addClass(component.find("tabtwo"), 'slds-is-active'); 
       $A.util.removeClass(component.find("tabone"), 'slds-is-active'); 
    },
    
    switchToNMCs : function(component, event, helper) {   
       var acctId = component.get("v.accountID");
       var billTable = helper.generateBillTable(component,acctId);
       $A.util.removeClass(component.find("tabtwo"), 'slds-is-active'); 
       $A.util.addClass(component.find("tabone"), 'slds-is-active'); 
    },
})