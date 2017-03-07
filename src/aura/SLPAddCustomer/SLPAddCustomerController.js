({ 
    doInit : function(component, event, helper) {

        var actionLogo = component.get("c.getPartnerLogo");        
        actionLogo.setCallback(this,function(resp){
            if(resp.getState() == 'SUCCESS') {
                component.set("v.partnerLogo", resp.getReturnValue());
            }
            else {
                $A.log("Errors", resp.getError());
            }
        });    
        $A.enqueueAction(actionLogo);

        var actionCustomId = component.get("c.getPartnerCustomId");        
        actionCustomId.setCallback(this,function(resp){
            if(resp.getState() == 'SUCCESS') {
                component.set("v.partnerLogo", resp.getReturnValue());
            }
            else {
                $A.log("Errors", resp.getError());
            }
        });    
        $A.enqueueAction(actionCustomId);
    },    

    addCustomer : function(component, event, helper) {
        var lead = component.get("v.newLead");
        if (lead.LASERCA__Home_Address__c != null 
            && lead.LASERCA__Home_City__c != null
            && lead.FirstName != null
            && lead.LastName != null
            && lead.Email != null
            && lead.LASERCA__Social_Security_Number__c != null
            && lead.System_Cost__c != null
            && lead.Annual_Income_Currency__c != null
            && lead.Credit_Check_Acknowledged__c == true
            && lead.Privacy_Policy_Acknowledged__c == true
            && lead.Utility_Bill_Access_Acknowledged__c == true) {
           var Action = component.get("c.addNewLeadRecord");
            Action.setParams({
                "newLead" : lead,          
            });
            
            Action.setCallback(this, function(resp) {
                if(resp.getState() == "SUCCESS") {
                    var inputForm = component.find("inputForm");
                    var addAnotherCustomer = component.find("addAnotherCustomer");
                    var mslpButton = component.find("mslpbutton");
                    var applicationNotification = component.find("applicationNotification");

                    $A.util.addClass(inputForm, 'noDisplayBar');
                    $A.util.addClass(mslpButton, 'noDisplayBar');                    
                    $A.util.removeClass(addAnotherCustomer, 'noDisplayBar');
                    $A.util.removeClass(applicationNotification, 'noDisplayBar');


                    //alert("This customer has been added. Please check the credit status tab to see their qualification status. This may take a minute or two.");
                }else {
                    $A.log("Errors", resp.getError());                
                }
            }); 
    		$A.enqueueAction(Action);
        }
        else {
            alert("Please acknowledge our privacy policy, give BlueWave permission to access credit history, energy history and fill out all of the fields on this form.");            
        }
    },
    
    navigateAddAnotherCustomer : function(component, event, helper) {

        var urlEvent = $A.get("e.force:navigateToURL");
        urlEvent.setParams({
          "url": '/slpaddcustomer'

        });
        urlEvent.fire();                
    },

    navigateCreditStatus : function(component, event, helper) {

        var urlEvent = $A.get("e.force:navigateToURL");
        urlEvent.setParams({
          "url": '/slpcreditstatus'

        });
        urlEvent.fire();                
    }, 

    navigateToMSLP : function(component, event, helper) {

        var urlEvent = $A.get("e.force:navigateToURL");
        urlEvent.setParams({
          "url": 'https://forms.bluewaverenewables.com/381458?'

        });
        urlEvent.fire();                
    },          


    
})