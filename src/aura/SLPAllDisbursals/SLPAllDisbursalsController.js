({
    doInit : function(component, event, helper) {
        //The following block of code retrieves the user's license type to determine what to display on the UI
        var actionLicenseType = component.get("c.getLicenseType");
        actionLicenseType.setCallback(this,function(resp){
            if(resp.getState() == 'SUCCESS') {
                if(resp.getReturnValue().length > 0){
                    if(resp.getReturnValue() == 'Executive')
                    component.set("v.licenseType", true);
                }
            }
            else {
                $A.log("Errors", resp.getError());
            }
        });
        $A.enqueueAction(actionLicenseType);

        var actionIncompleteDisbursals = component.get("c.getIncompleteLoanDisbursals");
        actionIncompleteDisbursals.setCallback(this,function(resp){
            if(resp.getState() == 'SUCCESS') {
                component.set("v.allIncompleteDisbursals", resp.getReturnValue());
            }
            else {
                $A.log("Errors", resp.getError());
            }
        });
        $A.enqueueAction(actionIncompleteDisbursals);

        var actionCompleteDisbursals = component.get("c.getCompleteLoanDisbursals");
        actionCompleteDisbursals.setCallback(this,function(resp){
            if(resp.getState() == 'SUCCESS') {
                component.set("v.allCompleteDisbursals", resp.getReturnValue());
            }
            else {
                $A.log("Errors", resp.getError());
            }
        });
        $A.enqueueAction(actionCompleteDisbursals);

        var actionGetDisbursalToggle = component.get("c.getSLPortalSettings");
        actionGetDisbursalToggle.setCallback(this,function(resp) {
            if (resp.getState() == 'SUCCESS') {
                var slpSettings = resp.getReturnValue();
                console.log(slpSettings);
                var customSetting = slpSettings.Show_Disbursal_Method__c; 
                component.set("v.showDisbursalMethod", customSetting);
            } else {
                $A.log("Errors", resp.getError());
            }
        });
        $A.enqueueAction(actionGetDisbursalToggle);
    },

    searchDisbursals : function(component, event, helper) {
        var input = component.find("disbursalSearch");
        var customerName = input.get("v.value");
        var actionCompleteDisbursals = component.get("c.getCompleteLoanDisbursals");

        actionCompleteDisbursals.setParams({searchValue : customerName});
        actionCompleteDisbursals.setCallback(this,function(resp){
            if(resp.getState() == 'SUCCESS') {
                component.set("v.allCompleteDisbursals", resp.getReturnValue());
            }
            else {
                $A.log("Errors", resp.getError());
            }
        });
        $A.enqueueAction(actionCompleteDisbursals);

        var actionIncompleteDisbursals = component.get("c.getIncompleteLoanDisbursals");

        actionIncompleteDisbursals.setParams({searchValue : customerName});
        actionIncompleteDisbursals.setCallback(this,function(resp){
            if(resp.getState() == 'SUCCESS') {
                component.set("v.allIncompleteDisbursals", resp.getReturnValue());
            }
            else {
                $A.log("Errors", resp.getError());
            }
        });
        $A.enqueueAction(actionIncompleteDisbursals);
    },

    updateDisbursal : function(component, event, helper) {
        var source = event.getSource();
        var disbursalId = source.get("v.name");
        var disbursalVal = source.get("v.value");
        var actionUpdateDisbursals = component.get("c.updateDisbursals");

        actionUpdateDisbursals.setParams({disbursalId : disbursalId,
                                          disbursalValue : disbursalVal});
        $A.enqueueAction(actionUpdateDisbursals);
    }
})