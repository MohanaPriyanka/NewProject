({
    doInit : function(cmp) {  
       var acctID = cmp.get("v.accountID");
                
       $A.createComponent(
	    	"c:PregeneratedBillsTable", 
        	{"parentId": cmp.get("v.accountID") ,
             "IsProdUpdate" : "FALSE"}, 

        	function(newButton, status, errorMessage){
                if (status === "SUCCESS") {
                    var body = cmp.get("v.body");
                    body.push(newButton);
                    cmp.set("v.body", body);
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
    
    switchToTransactions : function(cmp, event) {  
    	 cmp.set("v.body", []);

         $A.createComponent(
	    	"c:TableofTransactions", 
        	{"accountLookupId": cmp.get("v.accountID")}, 
           
              function(newButton, status, errorMessage){
                if (status === "SUCCESS") {
                    var body = cmp.get("v.body");
                    body.push(newButton);
                    cmp.set("v.body", body);
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
    
    switchToNMCs : function(cmp, event) {          
        var acctID = cmp.get("v.accountID");
        cmp.set("v.body", []); 
        
        $A.createComponent(
	    	"c:PregeneratedBillsTable", 
        	{"parentId": cmp.get("v.accountID") ,
             "IsProdUpdate" : "FALSE"}, 

        	function(newButton, status, errorMessage){
                if (status === "SUCCESS") {
                    var body = cmp.get("v.body");
                    body.push(newButton);
                    cmp.set("v.body", body);
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