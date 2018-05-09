({
    doInit : function(component, event, helper) {
        //The following block of code retrieves the user's license type to determine what to display on the UI
        var actionLicenseType = component.get("c.getLicenseTypeandReferralCode");
        actionLicenseType.setCallback(this,function(resp){
            if(resp.getState() === 'SUCCESS') {
                const partnerProfile = resp.getReturnValue();
                const listParams = partnerProfile.split("/",3);
                const licenseType = listParams[0];
                const referralCode = listParams[1];
                const disableCS = listParams[2];
                if (disableCS === 'true'){
                    component.set("v.referralCode", referralCode);
                    component.set("v.showCSTab", true);
                } else {
                    component.set("v.showCSTab", false);
                }
                if (licenseType === 'Executive'){
                    component.set("v.licenseType", true);
                    $A.util.removeClass(component.find("disbursalsMenuItem"), 'noDisplay');
                }
            }    
            else {
                $A.log("Errors", resp.getError());
            }
        });    
        $A.enqueueAction(actionLicenseType);
    },

    navigateToTab : function(component, event, helper) {
        var btnClicked = event.getSource().get("v.name");
        helper.activateTab(component, event, helper, btnClicked);

        var btnClickedWithSlash = '/' + btnClicked;
        var urlEvent = $A.get("e.force:navigateToURL");
        urlEvent.setParams({
            "url": btnClickedWithSlash
        });
        urlEvent.fire();
    },

    navigateToCommunitySolarApplication : function(component, event, helper) {
        var action = component.get("c.getCommunitySolarApplicationURL");
        action.setCallback(this,function(resp){
            if(resp.getState() === 'SUCCESS') {
                var urlEvent = $A.get("e.force:navigateToURL");
                urlEvent.setParams({
                    "url": resp.getReturnValue()
                });
                urlEvent.fire();
            }
            else {
                $A.log("Errors", resp.getError());
            }
        });
        $A.enqueueAction(action);
        component.set("v.CSWindow", false);
        component.set("v.emailInput", "");
        helper.deactivateTab(component, event, helper, 'slpcommunitySolar');
        helper.activateTab(component, event, helper, component.get("v.currentTab"));    },

    openCSWindow : function(component, event, helper) {
        component.set("v.CSWindow", true);
        component.set("v.emailSuccess", false);
        helper.activateTab(component, event, helper, 'slpcommunitySolar');
    },

    closeCSWindow : function(component, event, helper) {
        component.set("v.CSWindow", false);
        component.set("v.emailInput", "");
        helper.deactivateTab(component, event, helper, 'slpcommunitySolar');
        helper.activateTab(component, event, helper, component.get("v.currentTab"));
    },

    sendCSApplication : function(component, event, helper) {
        var emailAddressList = [];
        emailAddressList.push(component.get("v.emailInput"));
        var actionSendEmail = component.get("c.sendCommunitySolarApplication");

        actionSendEmail.setParams({
            "emailAddress": emailAddressList
        }); 

        actionSendEmail.setCallback(this,function(resp){
            if(resp.getState() === 'SUCCESS' && resp.getReturnValue()) {
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