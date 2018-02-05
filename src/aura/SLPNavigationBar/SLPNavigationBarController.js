({
    doInit : function(component, event, helper) {
        //The following block of code retrieves the user's license type to determine what to display on the UI
        var actionLicenseType = component.get("c.getLicenseType");        
        actionLicenseType.setCallback(this,function(resp){
            if(resp.getState() === 'SUCCESS') {
                const partnerProfile = resp.getReturnValue();
                const listParams = partnerProfile.split("/",3);
                const licenseType = listParams[0];
                const referralCode = listParams[1];
                const disableCS = listParams[2];
                if (licenseType === 'Executive'){
                    component.set("v.licenseType", true);
                    $A.util.removeClass(component.find("disbursalsMenuItem"), 'noDisplay');
                }
                if (disableCS === 'true'){
                    component.set("v.referralCode", referralCode);
                    component.set("v.showCSTab", true);
                } 
            }    
            else {
                $A.log("Errors", resp.getError());
            }
        });    
        $A.enqueueAction(actionLicenseType);                      
    },

    openCSWindow : function(component, event, helper) {
        component.set("v.CSWindow", true);  
        component.set("v.emailSuccess", false);    
    },

    closeCSWindow : function(component, event, helper) {
        component.set("v.CSWindow", false);   
    },

    sendCSApplication : function(component, event, helper) {
        var actionSendEmail = component.get("c.sendAnEmail");        
        const toEmail = component.get("v.emailInput");
        const salesCode = component.get("v.referralCode");

        actionSendEmail.setParams({
            "emailTemplateName": 'SLP_Community_Solar_Application',
            "orgWideEmail": 'customercare@bluewavesolar.com',
            "subjectLine": 'Start Your Community Solar Application Here',
            "addressList": toEmail,
            "templateField" : '{!ReferralCode}',
            "replaceText" : salesCode,
        }); 

        actionSendEmail.setCallback(this,function(resp){
            if(resp.getState() === 'SUCCESS' && resp.getReturnValue() === true) {
                component.set("v.emailSuccess", true);   
            } else {
                alert('Please enter a valid email address');
            }
        });    

        $A.enqueueAction(actionSendEmail);   
    },

    hideDisplay : function(component, event, helper) {
        var headerDisplay = component.find("header");
        $A.util.addClass(headerDisplay, 'noDisplayBar');   
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
})