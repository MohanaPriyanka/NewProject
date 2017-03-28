({ 
    doInit : function(component, event, helper) {
        var actionPartnerRecord = component.get("c.getPartnerRecord");        
        actionPartnerRecord.setCallback(this,function(resp){
            if(resp.getState() == 'SUCCESS') {
                component.set("v.partnerRecord", resp.getReturnValue());
            }
            else {
                $A.log("Errors", resp.getError());
            }
        });    
        $A.enqueueAction(actionPartnerRecord);        
    },    

    addCustomer : function(component, event, helper) {
        var lead = component.get("v.newLead");
        if (lead.LASERCA__Home_Address__c != null 
            && lead.LASERCA__Home_City__c != ''
            && lead.FirstName != ''
            && lead.LastName != ''
            && lead.Email != ''
            && lead.LASERCA__Social_Security_Number__c != ''
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
                    var mslpButton = component.find("mslpAppbutton");
                    var applicationNotification = component.find("applicationNotification");

                    var bwslButton = component.find("bwslAppButton");
                    var avidiaLogo = component.find("avidiaLogo");
                    var mslpDisclaimer = component.find("mslpDisclaimer");                    
                    
                    $A.util.addClass(mslpButton, 'noDisplayBar'); 
                    $A.util.addClass(bwslButton, 'noDisplayBar');      
                    $A.util.addClass(inputForm, 'noDisplayBar'); 
                    $A.util.addClass(avidiaLogo, 'noDisplayBar');    
                    $A.util.addClass(mslpDisclaimer, 'noDisplayBar');                                                                             
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

    changeApplicationToMSLP : function(component, event, helper) {
        component.set("v.newLead.DOER_Solar_Loan__c",true);  
        component.set("v.newLead.Product_Program__c",'MSLP');
                 
        var bwslButton = component.find("bwslAppButton");
        var mslpButton = component.find("mslpAppButton");
        var inputFormBox = component.find("inputFormBox");
        var avidiaLogo = component.find("avidiaLogo");
        var mslpDisclaimer = component.find("mslpDisclaimer");

        $A.util.removeClass(bwslButton, 'noDisplayBar');      
        $A.util.addClass(mslpButton, 'noDisplayBar'); 
        $A.util.removeClass(avidiaLogo, 'noDisplay');  
        $A.util.removeClass(mslpDisclaimer, 'noDisplayBar');      

       // $A.util.addClass(inputFormBox, 'boxMSLP');      

                  
    }, 
    changeApplicationToBWSL : function(component, event, helper) {
        component.set("v.newLead.DOER_Solar_Loan__c",false);  
        component.set("v.newLead.Product_Program__c",'BlueWave Solar Loan');         

        var bwslButton = component.find("bwslAppButton");
        var mslpButton = component.find("mslpAppButton");
        var inputFormBox = component.find("inputFormBox");
        var avidiaLogo = component.find("avidiaLogo");
        var mslpDisclaimer = component.find("mslpDisclaimer");


        $A.util.addClass(bwslButton, 'noDisplayBar');      
        $A.util.removeClass(mslpButton, 'noDisplayBar');
        $A.util.addClass(avidiaLogo, 'noDisplay');   
        $A.util.addClass(mslpDisclaimer, 'noDisplayBar');      

        //$A.util.removeClass(inputFormBox, 'boxMSLP'); 
                     
           
    },         



    
})