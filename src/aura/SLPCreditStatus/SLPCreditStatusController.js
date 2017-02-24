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
        var action = component.get("c.getAllCustomers");     
        
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

    navigate : function(component, event, helper) {
        var action = component.get("c.getLeads"); 
        var source = event.getSource();
        var leadId = source.get("v.class");
        
        action.setParams({leadId : leadId});
        
        action.setCallback(this,function(resp){ 
            if(resp.getState() == 'SUCCESS') {
                component.set("v.selectedCustomer", resp.getReturnValue(0));
                var lead = resp.getReturnValue()[0];
                var address = lead.LASERCA__Home_Address__c;
                var city = lead.LASERCA__Home_City__c;
                var state = lead.LASERCA__Home_State__c;
                var zip = lead.LASERCA__Home_Zip__c;
                var income = lead.Annual_Income_Currency__c;
                var systemCost = lead.System_Cost__c;
                var updateDummy = lead.Update_Dummy;
                if(updateDummy == true){
                    updateDummy = false;
                }else{
                    updateDummy = true;
                }
                var leadId = lead.Id;                         
                var urlEvent = $A.get("e.force:navigateToURL");
                urlEvent.setParams({
                  "url": 'https://forms.bluewaverenewables.com/381587?tfa_1299=' + address 
                    + '&' + 'tfa_154=' + state 
                    + '&' + 'tfa_526=' + leadId 
                    + '&' + 'tfa_1295=' + updateDummy
                    + '&' + 'tfa_1300=' + city 
                    + '&' + 'tfa_1301=' + zip                     
                });
                urlEvent.fire();                
            }
            else {
                $A.log("Errors", resp.getError());
            }
        });        
        $A.enqueueAction(action);     
             
        
        //Find the text value of the component with aura:id set to "address"

    },
})