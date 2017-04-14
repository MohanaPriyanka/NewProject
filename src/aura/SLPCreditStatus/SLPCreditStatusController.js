({
    doInit : function(component, event, helper) {
        var actionViewPreQualifiedRecords = component.get("c.viewPreQualifiedRecords");        
        actionViewPreQualifiedRecords.setCallback(this,function(resp){
            if(resp.getState() == 'SUCCESS') {     
                var evt = $A.get("e.c:SLPNavigationBarAlertEvent");
                evt.setParams({"pendingCustomersAlert": "false"});
                evt.fire();                           
            } else {
                $A.log("Errors", resp.getError());   
                var appEvent = $A.get("e.c:ApexCallbackError");
                appEvent.setParams({"className" : "SLPCreditStatus",
                    "methodName" : "viewPreQualifiedRecords",
                    "errors" : resp.getError()});
                appEvent.fire();
                $A.log("Errors", resp.getError());                               
            }
        });    
        $A.enqueueAction(actionViewPreQualifiedRecords);          

        var getUrlParameter = function getUrlParameter(sParam) {
            var sPageURL = decodeURIComponent(window.location.search.substring(1)),
            sURLVariables = sPageURL.split('&'),
            sParameterName,
            i;

            for (i = 0; i < sURLVariables.length; i++) {
                sParameterName = sURLVariables[i].split('=');
                if (sParameterName[0] === sParam) {
                    return sParameterName[1] === undefined ? true : sParameterName[1];
                }
            }
        };
        var leadId = getUrlParameter('leadId');
        if ($A.util.isUndefinedOrNull(leadId)) {
            var action = component.get("c.getLeads");        
            action.setCallback(this,function(resp){ 
                    if(resp.getState() == 'SUCCESS') {
                        component.set("v.allCustomers", resp.getReturnValue());
                    }
                    else {
                        $A.log("Errors", resp.getError());
                    }
                });        
            $A.enqueueAction(action);     
        } else {
            // Lead ID is set from the AddCustomer Component, so we want to lead
            // this component with just that lead. We also want to disable the back button
            component.set("v.leadId", leadId);
            helper.getProductsHelper(component, event, helper);
            $A.util.addClass(component.find("creditStatusBackButton"),"noDisplay");
        }
              
    },
    
    searchCustomers : function(component, event, helper) {            
        var input = component.find("customerSearch");
        var customerName = input.get("v.value");           
        var action = component.get("c.searchLeads");     
        
        action.setParams({searchValue : customerName});
        
        action.setCallback(this,function(resp){
            if(resp.getState() == 'SUCCESS') {
                component.set("v.allCustomers", resp.getReturnValue());
            }
            else {
                $A.log("Errors", resp.getError());
            }
        });        
        $A.enqueueAction(action);        
    },

    getProducts : function(component, event, helper) { 
        helper.getProductsHelper(component, event, helper);
    },        

    updateProductSelection : function(component, event, helper) { 
        var actionGetProduct = component.get("c.getSelectedProduct"); 
        var source = event.getSource();
        var productId = source.get("v.class"); 
        var productTerm = source.get("v.name");
        var productValue = source.get("v.value");

        actionGetProduct.setParams({productId : productId});

        actionGetProduct.setCallback(this,function(resp){ 
            if(resp.getState() == 'SUCCESS') {
                component.set("v.product", resp.getReturnValue());
            }
            else {
                $A.log("Errors", resp.getError());
            }
        });        
        $A.enqueueAction(actionGetProduct);    

        var customerEmailButton = component.find("customerEmailButton");
        var incomeFormButton = component.find("incomeFormButton");

        if(productValue == true) {
        component.set("v.productId", productId); 
        component.set("v.loanTerm", productTerm);

        $A.util.removeClass(customerEmailButton, 'noDisplay');
        $A.util.removeClass(incomeFormButton, 'noDisplay');     

        }else {
        component.set("v.productId", null); 
        component.set("v.loanTerm", 0);   

        $A.util.addClass(customerEmailButton, 'noDisplay');
        $A.util.addClass(incomeFormButton, 'noDisplay');     

        }                 
    },       

    navigate : function(component, event, helper) {
        var leadId = component.get("v.leadId");
        var productId = component.get("v.product.Id");
        var loanTerm = component.get("v.product.Loan_Term__c");

        var action = component.get("c.getLeads");         
        action.setParams({leadId : leadId});
        if(loanTerm > 0 && loanTerm != null) {
            action.setCallback(this,function(resp){ 
                if(resp.getState() == 'SUCCESS') {
                    if (resp.getReturnValue()[0].DOER_Solar_Loan__c == false) {
                        component.set("v.selectedCustomer", resp.getReturnValue(0));
                        var lead = resp.getReturnValue()[0];
                        var address = lead.LASERCA__Home_Address__c;
                        var city = lead.LASERCA__Home_City__c;
                        var state = lead.LASERCA__Home_State__c;
                        var zip = lead.LASERCA__Home_Zip__c;
                        var income = lead.Annual_Income_Currency__c;
                        var systemCost = lead.System_Cost__c;
                        var updateDummy = lead.Update_Dummy;
                        var firstName = lead.FirstName;
                        var lastName = lead.LastName;     

                        if(updateDummy == true){
                            updateDummy = false;
                        }else{
                            updateDummy = true;
                        }
                        var leadId = lead.Id;                         
                        var urlEvent = $A.get("e.force:navigateToURL");
                        urlEvent.setParams({
                          "url": 'https://forms.bluewaverenewables.com/' + '381610' + '?tfa_1311=' + address 
                            + '&' + 'tfa_154=' + state 
                            + '&' + 'tfa_526=' + leadId 
                            + '&' + 'tfa_1180=' + updateDummy
                            + '&' + 'tfa_390=' + income 
                            + '&' + 'tfa_1312=' + city 
                            + '&' + 'tfa_1179=' + productId 
                            + '&' + 'tfa_1313=' + zip     
                            + '&' + 'tfa_1287=' + loanTerm     
                            + '&' + 'tfa_1372=' + firstName     
                            + '&' + 'tfa_1373=' + lastName                                                                 
                        });
                        urlEvent.fire();  
                    }
                    if (resp.getReturnValue()[0].DOER_Solar_Loan__c == true) {
                        //component.set("v.selectedCustomer", resp.getReturnValue(0));
                        var lead = resp.getReturnValue()[0];
                        var address = lead.LASERCA__Home_Address__c;
                        var city = lead.LASERCA__Home_City__c;
                        var state = lead.LASERCA__Home_State__c;
                        var formId = component.get("v.formId");   
                        var zip = lead.LASERCA__Home_Zip__c;
                        var income = lead.Annual_Income_Currency__c;
                        var systemCost = lead.System_Cost__c;
                        var updateDummy = lead.Update_Dummy;
                        var firstName = lead.FirstName;
                        var lastName = lead.LastName;                    
                        if(updateDummy == true){
                            updateDummy = false;
                        }else{
                            updateDummy = true;
                        }
                        var leadId = lead.Id;                         
                        var urlEvent = $A.get("e.force:navigateToURL");
                        urlEvent.setParams({
                          "url": 'https://forms.bluewaverenewables.com/' + '381604' + '?tfa_572=Individually'  
                            + '&' + 'tfa_154=Massachusetts&tfa_526=' + leadId 
                            + '&' + 'tfa_1180=' + updateDummy
                            + '&' + 'tfa_63=' + city 
                            + '&' + 'tfa_1179=' + productId 
                            + '&' + 'tfa_81=' + zip     
                            + '&' + 'tfa_1287=' + loanTerm   
                            + '&' + 'tfa_94=' + address 
                            + '&' + 'tfa_390=' + income   
                            + '&' + 'tfa_1181=true'  
                        });
                        urlEvent.fire();  
                    }              
                }
                else {
                    $A.log("Errors", resp.getError());
                }
            });        
            $A.enqueueAction(action);                              
        }else {
            alert("Please select a product");
        }        
        //Find the text value of the component with aura:id set to "address"
    },

     sendCustomerApplication : function(component, event, helper) {
        var leadId = component.get("v.leadId");
        var product = component.get("v.product");
        var loanTerm = component.get("v.product.Loan_Term__c");        

        var actionSendApp = component.get("c.sendApplication"); 

        actionSendApp.setParams({leadId : leadId,
                          product : product,
                          loanTerm : loanTerm});        
        if (loanTerm > 0 ){
            actionSendApp.setCallback(this,function(resp){ 
                if (resp.getState() == 'SUCCESS') {
                    alert('The email to continue this application has been sent to ' + resp.getReturnValue());
                } else {
                    var appEvent = $A.get("e.c:ApexCallbackError");
                    appEvent.setParams({"className" : "SLPCreditStatus",
                                        "methodName" : "sendApplication",
                                        "errors" : resp.getError()});
                    appEvent.fire();
                    $A.log("Errors", resp.getError());                      
                }
            });                                                   
        $A.enqueueAction(actionSendApp); 
        var btn = event.getSource();
        btn.set("v.disabled",true);
        btn.set("v.label",'Email Sent!')            
        } else {
            alert('Please select a product');
        }        
    },

    exitProductSelection : function(component, event, helper) { 
        $A.get('e.force:refreshView').fire();
    },    

})