({
    handleSelect : function (component, event, helper) {
        var stepName = event.getParam("detail").value;
        component.set("v.selectedStage", stepName);
        component.set("v.showSave", true);
    },

    updateSSSStage : function (component, event, helper) {
        let actionUpdateStage = component.get("c.updateStage");

        actionUpdateStage.setParams({
            "sssToUpdate" : component.get("v.recordFromVF"),
            "newStage" : component.get("v.selectedStage")
        });

        actionUpdateStage.setCallback(this,function(resp) {
            if (resp.getState() === 'SUCCESS') {
                let responseVar = resp.getReturnValue();
                if (responseVar === 'Success'){
                    component.set("v.showSave", false);
                    component.set("v.successfulUpdate", true);
                } else {
                    component.set("v.showSave", false);
                    component.set("v.errorMessage", responseVar);
                }
            } else {
                component.set("v.errorMessage", 'An error occurred while updating the SSS Stage. Please contact Biz Apps');
            }
        });
        $A.enqueueAction(actionUpdateStage);
    },
})