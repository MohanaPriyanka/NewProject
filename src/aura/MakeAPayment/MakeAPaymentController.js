({ 
   
 navigateToStatement : function(component, event, helper) {
    // Prevent the form from getting submitted
    //event.preventDefault();
    // Get the value from the field that's in the form
    //var accountBillId = event.target.getElementsByClassName('account-form')[0].value;
    var source = event.getSource();
    var statementId = source.get("v.class"); 
    var actionGetStatement = component.get("c.getStatement");
    var urlEvent = $A.get("e.force:navigateToURL");
     actionGetStatement.setParams({parentId : statementId});
     actionGetStatement.setCallback(this,function(resp){ //sets the menu selection to a field on the portal
         if(resp.getState() == 'SUCCESS') {
              component.set("v.statementId", resp.getReturnValue());
              var statementReturnId = resp.getReturnValue();
              urlEvent.setParams({
      		  "url": 'https://c.na16.content.force.com/servlet/servlet.FileDownload?file=' + statementReturnId  });
                  urlEvent.fire();
         }
         else {
              $A.log("Errors", resp.getError());
         }
     });      
     $A.enqueueAction(actionGetStatement);

}
 ,  
   navigate : function(component, event, helper) {
    //Find the text value of the component with aura:id set to "address"
	var source = event.getSource();
    var statementMap = source.get("v.statementIdMap");
    var accountBillId = source.get("v.label");  
        
    var urlEvent = $A.get("e.force:navigateToURL");
        for(accountBillId in statementMap){
            urlEvent.setParams({
      		"url": 'https://c.na16.content.force.com/servlet/servlet.FileDownload?file=' + statementMap.get[accountBillId]});
        }    

    urlEvent.fire();
}
,
    accountMenuOutput : function(component, event) {    
        var source = event.getSource();
        var label = source.get("v.label"); 
       	
        var actionMenuSelection = component.get("c.getMenuAccountBillItem"); //sets the menu selection to a field on the portal
        var actionMyAccountBill = component.get("c.getMyBill"); //shows the total due for the property account selected
        var actionMyAccountId = component.get("c.getMyParentAccountId");
        var actionMyParentAccountId = component.get("c.getMyParentAccountId")
        var actionSystemBills = component.get("c.getSystemBills"); //loads the system bill's total due into the form for payment 
		var actionStatements = component.get("c.getAccountBills"); //loads Account Bills into the tabels for the customer
		var actionPaymentLogs = component.get("c.getTransactions"); //loads Chargent Transactions into the tabels for the customer 
        
        actionMenuSelection.setParams({menuInput : label});
        actionMyAccountBill.setParams({propertyAccountId : label});
        actionMyAccountId.setParams({propertyAccountId : label});
        actionMyParentAccountId.setParams({propertyAccountId : "All"});
        actionSystemBills.setParams({propertyAccountId : label});
        actionStatements.setParams({propertyAccountId : label});  
        actionPaymentLogs.setParams({propertyAccountId : label});
		        
        
        actionMenuSelection.setCallback(this,function(resp){ //sets the menu selection to a field on the portal
            if(resp.getState() == 'SUCCESS') {
                component.set("v.menuOutputMessage", resp.getReturnValue());
            }
            else {
                $A.log("Errors", resp.getError());
            }
        });                                        
        
        actionMyAccountBill.setCallback(this,function(resp){ //shows the total due for the property account selected
            if(resp.getState() == 'SUCCESS') {
                component.set("v.myBill", resp.getReturnValue());
            }
            else {
                $A.log("Errors", resp.getError());
            }
        });
        actionMyAccountId.setCallback(this,function(resp){ //shows the total due for the property account selected
            if(resp.getState() == 'SUCCESS') {
                component.set("v.accountId", resp.getReturnValue());
            }
            else {
                $A.log("Errors", resp.getError());
            }
        });
        actionMyParentAccountId.setCallback(this,function(resp){ //shows the total due for the property account selected
            if(resp.getState() == 'SUCCESS') {
                component.set("v.parentAccountId", resp.getReturnValue());
            }
            else {
                $A.log("Errors", resp.getError());
            }
        });         
        actionSystemBills.setCallback(this,function(resp){ //loads the system bills into the form for payment   
            if(resp.getState() == 'SUCCESS') {
                component.set("v.SystemBills", resp.getReturnValue());
            }
            else {
                $A.log("Errors", resp.getError());
            }
        });

        actionStatements.setCallback(this,function(resp){ //loads Account Bills into the customer's statement tables   
            if(resp.getState() == 'SUCCESS') {
                component.set("v.AccountBills", resp.getReturnValue());
            }
            else {
                $A.log("Errors", resp.getError());
            }
        });
        actionPaymentLogs.setCallback(this,function(resp){ //loads Account Bills into the customer's statement tables   
            if(resp.getState() == 'SUCCESS') {
                component.set("v.PaymentLogs", resp.getReturnValue());
            }
            else {
                $A.log("Errors", resp.getError());
            }
        });
           
        $A.enqueueAction(actionMenuSelection);
        $A.enqueueAction(actionMyAccountBill);
        $A.enqueueAction(actionMyAccountId);
        $A.enqueueAction(actionMyParentAccountId);
        $A.enqueueAction(actionSystemBills);
        $A.enqueueAction(actionStatements);
        $A.enqueueAction(actionPaymentLogs);
    }
,    
    doInit : function(component, event, helper) {
		
        var actionGetOpportunitys = component.get("c.getOpportunityIds");
        var actionPaymentFormToggle = component.get("c.getPaymentFormCheck");
        var actiongetMyAccountId = component.get("c.getMyParentAccountId");
        var actiongetMyParentAccountId = component.get("c.getMyParentAccountId");  
        var action12 = component.get("c.getSystemBills");
		var actionPaymentLogs2 = component.get("c.getTransactions"); //loads Chargent Transactions into the tabels for the customer        
        
        actionPaymentFormToggle.setCallback(this,function(resp){
            if(resp.getState() == 'SUCCESS') {
			    var paymentButtonToggle = component.find("paymentButton");  
                var autoPaymentFormButtonToggle = component.find("autoPaymentFormButton");                
                if(resp.getReturnValue() == true){
                    $A.util.removeClass(autoPaymentFormButtonToggle, 'noDisplay');                                                                        
                    $A.util.addClass(paymentButtonToggle, 'noDisplay');            
                }
            }
        })
        $A.enqueueAction(actionPaymentFormToggle);   
       
        actionGetOpportunitys.setCallback(this,function(resp){
            if(resp.getState() == 'SUCCESS') {
                component.set("v.Opportunitys", resp.getReturnValue());
            }
            else {
                $A.log("Errors", resp.getError());
            }
        }); 
        $A.enqueueAction(actionGetOpportunitys);    
        
        action12.setCallback(this,function(resp){
            if(resp.getState() == 'SUCCESS') {
                component.set("v.SystemBills", resp.getReturnValue());
            }
            else {
                $A.log("Errors", resp.getError());
            }
        }); 
        $A.enqueueAction(action12);
       
        actionPaymentLogs2.setCallback(this,function(resp){
            if(resp.getState() == 'SUCCESS') {
                component.set("v.PaymentLogs", resp.getReturnValue());
            }
            else {
                $A.log("Errors", resp.getError());
            }
        }); 
        $A.enqueueAction(actionPaymentLogs2); 
        
        actiongetMyAccountId.setCallback(this,function(resp){
            if(resp.getState() == 'SUCCESS') {
                component.set("v.accountId", resp.getReturnValue());
            }
            else {
                $A.log("Errors", resp.getError());
            }
        }); 
        $A.enqueueAction(actiongetMyAccountId);
       
        actiongetMyParentAccountId.setCallback(this,function(resp){
            if(resp.getState() == 'SUCCESS') {
                component.set("v.accountId", resp.getReturnValue());
            }
            else {
                $A.log("Errors", resp.getError());
            }
        }); 
        $A.enqueueAction(actiongetMyParentAccountId);         
         
        var action14 = component.get("c.getMenuLabelList");        
        action14.setCallback(this,function(resp){
            if(resp.getState() == 'SUCCESS') {
                component.set("v.menuLabels", resp.getReturnValue());
            }
            else {
                $A.log("Errors", resp.getError());
            }
        });    
       $A.enqueueAction(action14);
        
        var action = component.get("c.getMyBill");                                        
        action.setCallback(this,function(resp){
            if(resp.getState() == 'SUCCESS') {
                component.set("v.myBill", resp.getReturnValue());
            }
            else {
                $A.log("Errors", resp.getError());
            }
        });
        $A.enqueueAction(action);
        
        var action15 = component.get("c.getTransactions");
        action15.setCallback(this,function(resp){
            if(resp.getState() == 'SUCCESS') {
                component.set("v.paymentLogs", resp.getReturnValue());
            }
            else {
                $A.log("Errors", resp.getError());
            }
        }); 
                
        
        var action10 = component.get("c.getAccountBills");
        action10.setCallback(this,function(resp){
            if(resp.getState() == 'SUCCESS') {
                component.set("v.AccountBills", resp.getReturnValue());
            }
            else {
                $A.log("Errors", resp.getError());
            }
        });        
        
        $A.enqueueAction(action10);
        $A.enqueueAction(action15);
        

    }
})