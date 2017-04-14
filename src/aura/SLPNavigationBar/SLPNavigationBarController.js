({
    doInit : function(component, event, helper) {
        //The following block of code retrieves the user's license type to determine what to display on the UI
        var actionLicenseType = component.get("c.getLicenseType");        
        actionLicenseType.setCallback(this,function(resp){
            if(resp.getState() == 'SUCCESS') {
                if(resp.getReturnValue().length > 0){
                    if(resp.getReturnValue() == 'Executive') {
                        component.set("v.licenseType", true);
                        $A.util.removeClass(component.find("disbursalsMenuItem"), 'noDisplay');
                    }
                }
            }    
            else {
                $A.log("Errors", resp.getError());
            }
        });    
        $A.enqueueAction(actionLicenseType);

        var actionGetUnseenPreQualRecords = component.get("c.getUnseenLeads");        
        actionGetUnseenPreQualRecords.setCallback(this,function(resp){
            if(resp.getState() == 'SUCCESS') {
                if (resp.getReturnValue() == true) {
                    var pendingCustomersButton = component.find("slpcreditstatus");   
                    pendingCustomersButton.set("v.iconName","utility:record");
                    $A.util.addClass(pendingCustomersButton, "animated shake");                        
                    pendingCustomersButton.set("v.iconPosition","right");

                } else {
                    var pendingCustomersButton = component.find("slpcreditstatus");                       
                    pendingCustomersButton.set("v.iconName",null);
                    pendingCustomersButton.set("v.iconPosition",null);                    
                }
            }    
            else {
                $A.log("Errors", resp.getError());
            }
        });    
        $A.enqueueAction(actionGetUnseenPreQualRecords);                  
    },

    hideDisplay : function(component, event, helper) {
        var headerDisplay = component.find("header");
        $A.util.addClass(headerDisplay, 'noDisplayBar');   
    },

    navigate : function(component, event, helper) {
        window.location.href = "/slportal/s/" + event.getSource().getLocalId();
    },
    
    openSendCustomerEmail: function(component, event, helper) {
        var modalBackground = component.find('emailCustomerModalBackground');
        $A.util.removeClass(modalBackground, 'slds-backdrop--hide');
        $A.util.addClass(modalBackground, 'slds-backdrop--open');          
        var evtCustomerWindow = $A.get("e.c:SLPSendApplicationEmailEvent");
        evtCustomerWindow.setParams({"openModal": "openModal"});
        evtCustomerWindow.fire();                
    },

    closeEmailCustomerModal: function(component, event, helper) {
        var modalToggle = event.getParam("closeModal");    
        if (modalToggle == "closeModal") {
            var modalBackground = component.find('emailCustomerModalBackground');
            $A.util.removeClass(modalBackground, 'slds-backdrop--open');
            $A.util.addClass(modalBackground, 'slds-backdrop--hide');    
        }
    },  
         
    setPendingCustomersAlert: function(component, event, helper) {
        var pendingCustomersButton = component.find("slpcreditstatus");      
        pendingCustomersButton.set("v.iconName", null);
        pendingCustomersButton.set("v.iconPosition", null)                 
    },    
})