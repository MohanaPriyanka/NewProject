({    
    getQSS : function(component, qssIdVar) {
        var actionGetUrl = component.get("c.getQuickSalesSheet");
        
        actionGetUrl.setParams({
            "newlycreatedQSSid": qssIdVar
        }); 
        
        actionGetUrl.setCallback(this,function(response) {
            if(response.getState() == "SUCCESS") { 
                if(response.getReturnValue().Link_to_File__c != "notgenerated"){
                    component.set("v.qssLinkToFile", response.getReturnValue().Link_to_File__c);
                    $A.util.addClass(component.find("spinnerandtext"), 'noDisplay');
                   	$A.util.removeClass(component.find("downloadQSSbutton"), 'noDisplay');   
                    $A.util.removeClass(component.find("downloadQSStext"), 'noDisplay');
					$A.util.addClass(component.find("downloadQSSbutton"), 'bounce');   
                }
            } 
        });
                                 
        $A.enqueueAction(actionGetUrl);

    },
    
})