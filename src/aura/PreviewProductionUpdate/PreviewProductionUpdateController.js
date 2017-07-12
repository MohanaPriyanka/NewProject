({
    doInit : function(cmp) {  
 		$A.createComponent(
	    	"c:PregeneratedBillsTable", 
        	{"parentId": cmp.get("v.prodUpdate") ,
             "IsProdUpdate" : "TRUE"}, 

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