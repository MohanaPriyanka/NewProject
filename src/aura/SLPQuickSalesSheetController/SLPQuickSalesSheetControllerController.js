({   
    clickCreateQSS : function(component, event, helper) {
        var newSheet = component.get("v.quicksalessheet");        
        var actionAddNewQss = component.get("c.addNewQSS");
        
        actionAddNewQss.setParams({
            "newQSS": newSheet
        });
        
        actionAddNewQss.setCallback(this,function(resp) {		
            if(resp.getState() == "SUCCESS") {                
                $A.util.addClass(component.find("submitQSSbutton"), 'noDisplay');
                $A.util.removeClass(component.find("spinnerandtext"), 'noDisplay');
                                              
                    window.setTimeout(function() {
                        $A.util.removeClass(component.find("docStatus"), 'noDisplay');
                        component.set("v.docStatusText", "Calculating Your Loan Stats...");
                    	}, 3000);
                    window.setTimeout(function() {
                        component.set("v.docStatusText", "Creating the Document...");
                    	}, 8000);
                    window.setTimeout(function() {
                        component.set("v.docStatusText", "Generating a download link...");
                    	}, 12000);
                    window.setTimeout(function() {
                        var qssIdVar = resp.getReturnValue().Id;
                        var docInterval = window.setInterval($A.getCallback(function() {helper.getQSS(component,qssIdVar);}), 2000);
                        component.set("v.docStatusPoller", docInterval);
                        }, 15000);  
                    window.setTimeout(function() {
                        window.clearInterval(component.get("v.docStatusPoller"));
                        var successLink = component.get("v.qssLinkToFile");
                        if (successLink == "notgeneratedinportal") {
                            component.set("v.docStatusText", "An Error Occurred While Creating Your Document, Please Contact BlueWave");
                			$A.util.addClass(component.find("qssSpinner"), 'noDisplay');
                        }
                     	}, 30000);
            }
        });
        
        $A.enqueueAction(actionAddNewQss);
	},

    doInit : function(component, event, helper) {
        var actionProducts = component.get("c.getActiveProducts");        
        actionProducts.setCallback(this,function(resp){
            if (resp.getState() == 'SUCCESS') {
                component.set("v.ProductListAttribute", resp.getReturnValue());    
            } else {
            }
        });    
        $A.enqueueAction(actionProducts);
        $A.util.addClass(component.find("downloadQSSbutton"), 'noDisplay');
        $A.util.addClass(component.find("downloadQSStext"), 'noDisplay');
        $A.util.addClass(component.find("spinnerandtext"), 'noDisplay');
    },    

})