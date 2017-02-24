({
	doInit : function(component, event, helper) {
        var actionIncompleteDisbursals = component.get("c.getIncompleteLoanDisbursals");        
        actionIncompleteDisbursals.setCallback(this,function(resp){ 
            if(resp.getState() == 'SUCCESS') {
                component.set("v.allIncompleteDisbursals", resp.getReturnValue());
            }
            else {
                $A.log("Errors", resp.getError());
            }
        });        
        $A.enqueueAction(actionIncompleteDisbursals);   
        
        var actionCompleteDisbursals = component.get("c.getCompleteLoanDisbursals");        
        actionCompleteDisbursals.setCallback(this,function(resp){ 
            if(resp.getState() == 'SUCCESS') {
                component.set("v.allCompleteDisbursals", resp.getReturnValue());
            }
            else {
                $A.log("Errors", resp.getError());
            }
        });        
        $A.enqueueAction(actionCompleteDisbursals);
        
      
              
	},
    
    searchDisbursals : function(component, event, helper) {            
        var input = component.find("disbursalSearch");
        var customerName = input.get("v.value");           
        var actionCompleteDisbursals = component.get("c.getCompleteLoanDisbursals");
        
        actionCompleteDisbursals.setParams({searchValue : customerName});        
        actionCompleteDisbursals.setCallback(this,function(resp){
            if(resp.getState() == 'SUCCESS') {
                component.set("v.allCompleteDisbursals", resp.getReturnValue());
            }
            else {
                $A.log("Errors", resp.getError());
            }
        });        
        $A.enqueueAction(actionCompleteDisbursals);

        var actionIncompleteDisbursals = component.get("c.getIncompleteLoanDisbursals");
        
        actionIncompleteDisbursals.setParams({searchValue : customerName});        
        actionIncompleteDisbursals.setCallback(this,function(resp){
            if(resp.getState() == 'SUCCESS') {
                component.set("v.allIncompleteDisbursals", resp.getReturnValue());
            }
            else {
                $A.log("Errors", resp.getError());
            }
        });        
        $A.enqueueAction(actionIncompleteDisbursals);         
    },
    
    updateDisbursal : function(component, event, helper) { 
        var source = event.getSource();
        var disbursalId = source.get("v.name");
        var disbursalVal = source.get("v.value");
        var actionUpdateDisbursals = component.get("c.updateDisbursals");
        
        actionUpdateDisbursals.setParams({disbursalId : disbursalId,
                                          disbursalValue : disbursalVal});
        $A.enqueueAction(actionUpdateDisbursals); 
    }
})