({    
    getQSS : function(component, qssIdVar) {
        var actionGetUrl = component.get("c.getQuickSalesSheet");
        
        actionGetUrl.setParams({
            "newlycreatedQSSid": qssIdVar
        }); 
        
        actionGetUrl.setCallback(this,function(response) {
            if(response.getState() === "SUCCESS") {
                var qss = response.getReturnValue();
                component.set("v.calculatedQSS", qss);
                component.set("v.isAdjustable", (qss.Product__r.Index_Rate_for_Adjustment__c?true:false));
                if(qss.Link_to_File__c != "notgenerated"){
                    component.set("v.qssLinkToFile", qss.Link_to_File__c);
                    component.set("v.calculatedQSS", qss);
                    $A.util.addClass(component.find("spinnerandtext"), 'noDisplay');
                    $A.util.removeClass(component.find("downloadQSSbutton"), 'noDisplay');   
                    $A.util.removeClass(component.find("downloadQSStext"), 'noDisplay');
                    $A.util.addClass(component.find("downloadQSSbutton"), 'bounce');   
                } 
            } 
        });                                 
        $A.enqueueAction(actionGetUrl);
    },
    
    refreshTable : function(component){
       $A.util.addClass(component.find("submitQSSbutton"), 'noDisplay');
       $A.util.addClass(component.find("viewLoanData"), 'noDisplay');
       $A.util.addClass(component.find("inputTable"), 'noDisplay');
       $A.util.removeClass(component.find("loaninfocard"), 'noDisplay');
       $A.util.removeClass(component.find("documentCreatebutton"), 'noDisplay');
    },
    
    updateQSS : function(component, qssToUpdate){
        var modified = component.get("v.modifiedTaxIncentive");
        var actionUpdateQss = component.get("c.updateQSS");
        
        actionUpdateQss.setParams({
           "updatedQSS" : qssToUpdate,
           "generateDoc" : false,
           "modifiedTax" : modified
        });
       
        actionUpdateQss.setCallback(this,function(response) {
            if(response.getState() == "SUCCESS") { 
                var qssIdVar = response.getReturnValue().Id;
                this.getQSS(component,qssIdVar);
                this.refreshTable(component);
            }
        });
        
        $A.enqueueAction(actionUpdateQss);
    },

})