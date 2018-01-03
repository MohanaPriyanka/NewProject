({
    doInit : function(component, event, helper) {     
        var leadId = sessionStorage.getItem('leadId');
        var leadName = sessionStorage.getItem('leadName');
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
            // Lead ID is specified, getLeads returns a single lead
            var action = component.get("c.getLeads");
            action.setParams({leadId : leadId});
            action.setCallback(this,function(resp) {
                if (resp.getState() == 'SUCCESS') {
                    component.set("v.allCustomers", resp.getReturnValue());
                    var lead = resp.getReturnValue()[0];
                    // Lead ID is set from the AddCustomer Component, so we want to
                    // this component with just that lead. We also want to disable the back button
                    component.set("v.leadId", leadId);
                    component.set("v.customerName", leadName);
                    helper.getProductsHelper(component, event, helper).then(
                        $A.getCallback(function resolve(helper) {
                            var selected = helper.qualifyingProductSelected(component, lead.Product__c);
                            helper.toggleProductSelection(component, helper, lead.Product__c, lead.Product__r.Loan_Term__c, selected);
                        }));
                    $A.util.addClass(component.find("creditStatusBackButton"),"noDisplay");
                } else {
                    $A.log("Errors", resp.getError());
                }
            });        
            $A.enqueueAction(action);
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
        helper.getProducts(component, event, helper);
    },        

    updateProductSelection : function(component, event, helper) { 
        helper.updateProductSelection(component, event, helper);
    },       

    navigate : function(component, event, helper) {
        var leadId = component.get("v.leadId");
        var productId = component.get("v.productId");
        var loanTerm = component.get("v.loanTerm");

        var action = component.get("c.getLeads");         
        action.setParams({leadId : leadId});
        if(loanTerm > 0 && loanTerm != null) {
            action.setCallback(this,function(resp){ 
                if (resp.getState() === 'SUCCESS') {
                    var lead = resp.getReturnValue()[0];
                    window.open('/slportal/s/loan-application?leadId='+lead.Id+'&email='+lead.Email);
                } else {
                    $A.log("Errors", resp.getError());
                }
            });
            $A.enqueueAction(action);
        } else {
            alert("Please select a product");
        }
        //Find the text value of the component with aura:id set to "address"
    },

     sendCustomerApplication : function(component, event, helper) {
        var leadId = component.get("v.leadId");
        var loanTerm = component.get("v.loanTerm");        

        var actionSendApp = component.get("c.sendApplication"); 

        actionSendApp.setParams({leadId : leadId,
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
    
    openAddCoApplicant : function(component, event, helper) {            
       var source = event.getSource();
       var leadVar = source.get("v.class");        
       $A.createComponent(
          "c:SLPAddCoApplicant", 
           {"mainApplicant" : leadVar}, 
           
        function(newButton, status, errorMessage){
          if (status === "SUCCESS") {
               var body = component.get("v.body");
               body.push(newButton);
               component.set("v.body", body);
          } else  {
               helper.logError("SLPCreditStatusController", "openAddCoApplicant", resp.getError());
          }
         }
        );               
    }, 

})