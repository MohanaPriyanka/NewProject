({
	doInit : function(component, event, helper) {
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
              
	},
    
    searchCustomers : function(component, event, helper) {            
        var input = component.find("customerSearch");
        var customerName = input.get("v.value");           
        var action = component.get("c.searchleads");     
        
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
        var source = event.getSource();
        var leadId = source.get("v.class");               
        var action = component.get("c.getCustomerProducts"); 
        var customerTable = component.find("customerTable");
        var productTable = component.find("productTable");
        var searchBar = component.find("customerSearchBar");
        var searchButton = component.find("customerSearchButton");

        component.set("v.leadId", leadId);

        action.setParams({leadId : leadId});

        action.setCallback(this,function(resp){ 
            if(resp.getState() == 'SUCCESS') {
                component.set("v.allProducts", resp.getReturnValue());
                $A.util.addClass(customerTable, 'noDisplay');
                $A.util.addClass(searchButton, 'noDisplay');
                $A.util.addClass(searchBar, 'noDisplay');
                $A.util.removeClass(productTable, 'noDisplay');
            }
            else {
                $A.log("Errors", resp.getError());
            }
        });        
        $A.enqueueAction(action);        
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


        if(productValue == true) {
        component.set("v.productId", productId); 
        component.set("v.loanTerm", productTerm); 
        }else {
        component.set("v.productId", null); 
        component.set("v.loanTerm", 0);             
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
                          "url": 'https://forms.bluewaverenewables.com/' + '381603' + '?tfa_1299=' + address 
                            + '&' + 'tfa_154=' + state 
                            + '&' + 'tfa_526=' + leadId 
                            + '&' + 'tfa_1295=' + updateDummy
                            + '&' + 'tfa_1300=' + city 
                            + '&' + 'tfa_1302=' + productId 
                            + '&' + 'tfa_1301=' + zip     
                            + '&' + 'tfa_1303=' + loanTerm   
                            + '&' + 'tfa_1304=' + firstName     
                            + '&' + 'tfa_1305=' + lastName                                         
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
                          "url": 'https://forms.bluewaverenewables.com/' + '381605' + '?tfa_572=Individually'  
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

    exitProductSelection : function(component, event, helper) { 
        var customerTable = component.find("customerTable");
        var productTable = component.find("productTable");
        var searchBar = component.find("customerSearchBar");
        var searchButton = component.find("customerSearchButton");

        $A.util.removeClass(customerTable, 'noDisplay');
        $A.util.removeClass(searchButton, 'noDisplay');
        $A.util.removeClass(searchBar, 'noDisplay');
        $A.util.addClass(productTable, 'noDisplay');      
        $A.get('e.force:refreshView').fire();
    },    

})