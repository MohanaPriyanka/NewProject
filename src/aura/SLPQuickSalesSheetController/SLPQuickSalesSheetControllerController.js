({   
    clickCreateQSS : function(component, event, helper) {
        $A.util.removeClass(component.find("spinnerandtext"), 'noDisplay');
        var newSheet = component.get("v.quicksalessheet");
        var btnClicked = event.getSource().get("v.name");
        var genDoc = false;
        if (btnClicked == 'submitUpfront') {
            genDoc = true;
            $A.util.addClass(component.find("submitQSSbutton"), 'noDisplay');
            $A.util.addClass(component.find("viewLoanData"), 'noDisplay');
            $A.util.addClass(component.find("inputTable"), 'noDisplay');
        } else if (btnClicked == 'refreshbutton'){
            $A.util.addClass(component.find("loaninfocard"), 'noDisplay');
        }
        var actionAddNewQss = component.get("c.addNewQSS");
        
        actionAddNewQss.setParams({
            "newQSS": newSheet, 
            "generateDoc": genDoc
        });
        
        actionAddNewQss.setCallback(this,function(resp) {
            if(resp.getState() == "SUCCESS" && genDoc) {
                $A.util.addClass(component.find("submitQSSbutton"), 'noDisplay');
                $A.util.addClass(component.find("viewLoanData"), 'noDisplay');

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
            else if(resp.getState() == "SUCCESS" && !genDoc) {
                var qssIdVar = resp.getReturnValue().Id;
                helper.getQSS(component,qssIdVar);
                helper.refreshTable(component);
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
        $A.util.addClass(component.find("loaninfocard"), 'noDisplay');
    },    
    
    clickCreateDocument : function(component, event, helper) {
        $A.util.removeClass(component.find("spinnerandtext"), 'noDisplay');
        var qssToUpdate = component.get("v.calculatedQSS");
        var qssIdVarible = component.get("v.calculatedQSS.Id");
        var modified = component.get("v.modifiedTaxIncentive");
        var actionCreateDocQss = component.get("c.updateQSS");
        component.set("v.calculatedQSS.Generate_Doc__c", true);

        actionCreateDocQss.setParams({
            "updatedQSS" : qssToUpdate,
            "generateDoc" : true, 
            "modifiedTax" : modified
        });
        
        actionCreateDocQss.setCallback(this,function(resp) {
            $A.util.addClass(component.find("documentCreatebutton"), 'noDisplay');
            $A.util.addClass(component.find("loaninfocard"), 'noDisplay');
       
            window.setTimeout(function() {
                    $A.util.removeClass(component.find("docStatus"), 'noDisplay');    
                    component.set("v.docStatusText", "Creating the Document...");
                    }, 6000);
               
            window.setTimeout(function() {
                    component.set("v.docStatusText", "Generating a download link...");
                    }, 8000);
               
            window.setTimeout(function() {
                    var docInterval = window.setInterval($A.getCallback(function() {helper.getQSS(component,qssIdVarible);}), 2000);
                       component.set("v.docStatusPoller", docInterval);
                    }, 12000);  
               
            window.setTimeout(function() {
                    window.clearInterval(component.get("v.docStatusPoller"));
                    var successLink = component.get("v.qssLinkToFile");
                    if (successLink == "notgeneratedinportal") {
                        component.set("v.docStatusText", "An Error Occurred While Creating Your Document, Please Contact BlueWave at partnersupport@bluewavesolar.com");
                        $A.util.addClass(component.find("qssSpinner"), 'noDisplay');
                    }
            }, 30000);
        });
        
        $A.enqueueAction(actionCreateDocQss);
    },   

    refreshTaxCredits : function(component, event, helper) {
        component.set("v.calculatedQSS.Modified_State_Tax_Credit__c", component.get("v.calculatedQSS.State_Tax_Incentive__c"));
        component.set("v.calculatedQSS.Modified_ITC__c", component.get("v.calculatedQSS.ITC_Estimated__c"));
        $A.util.addClass(component.find("loaninfocard"), 'noDisplay')
        const updatedQSS = component.get("v.calculatedQSS");
        helper.updateQSS(component, updatedQSS);
    },

    refreshTable : function(component, event, helper) {
         $A.util.removeClass(component.find("qssSpinner"), 'noDisplay');
         $A.util.addClass(component.find("loaninfocard"), 'noDisplay')
         var qssToUpdate = component.get("v.calculatedQSS");
         component.set("v.modifiedTaxIncentive", false);
         helper.updateQSS(component, qssToUpdate);
    },
    
    eraseZeros : function(component, event, helper) {
        var source = event.getSource();
        if (source.get("v.value")=="0" || source.get("v.value")=="$0.00") {
           source.set("v.value","");
        }
    },
    
    checkTaxCredit : function(component, event, helper) {
        var source = event.getSource();
        if (source.get("v.value") > source.get("v.placeholder")) {
           source.set("v.value", "v.placeholder");
            return;
        } else {
            $A.util.addClass(component.find("loaninfocard"), 'noDisplay')
            var qssToUpdate = component.get("v.calculatedQSS");
            helper.updateQSS(component, qssToUpdate);
        }
    },
})