({  generateBillTable : function(component, accountRef) {  
       var body = component.get("v.body");  
       component.set("v.body", []);  
        
       $A.createComponent(
		  "c:PregeneratedBillsTable", 
          {"parentId": accountRef,
           "IsProdUpdate" : "FALSE"}, 
           
       function(newButton, status, errorMessage){
          if (status === "SUCCESS") {
           var body = component.get("v.body");
               body.push(newButton);
               component.set("v.body", body);
           $A.util.removeClass(component.find("secondaryHeader"), 'slds-hide');
          } else if (status === "INCOMPLETE") {
               console.log("No response from server or client is offline.")
          }
          else if (status === "ERROR") {
               console.log("Error: " + errorMessage);
          }
          }
          ); 
	},
     
    generateTransactionTable : function(component, propList) {  
       var body = component.get("v.body");  
       component.set("v.body", []);  
       
       $A.createComponent(
		  "c:TableofTransactions", 
          {"accountLookupId": propList}, 
           
       function(newButton, status, errorMessage){
          if (status === "SUCCESS") {
           var body = component.get("v.body");
               body.push(newButton);
               component.set("v.body", body);
          }
          else if (status === "INCOMPLETE") {
               console.log("No response from server or client is offline.")
          }
          else if (status === "ERROR") {
               console.log("Error: " + errorMessage);
          }
          }
          );   
	},
  
})