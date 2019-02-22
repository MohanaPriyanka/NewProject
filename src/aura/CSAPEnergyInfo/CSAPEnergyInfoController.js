({
    handleNavEvent : function(component, event, helper) {
        if (event.getParam('options') && event.getParam('options').pageName) {
            helper.handleNavEvent(component, event, helper, event.getParam('options').pageName);
        } else {
            helper.handleNavEvent(component, event, helper, "UtilityAccountInformation");
        }
        if (component.get('v.STAGENAME') === 'NAV_Energy_Information' && component.get('v.page') === 'UtilityAccountInformation') {
            var lead = component.get('v.lead');
            var action = component.get("c.getProduct");
            var productId = lead.Product__c;
            action.setParams({"productId" : productId});
            action.setCallback(this, function(resp) {
                if (resp.getState() === "SUCCESS") {
                    component.set('v.selectedProduct', resp.getReturnValue());
                } else {
                    helper.logError("CSAPEnergyInfoController", "getProduct", resp.getError(), lead);
                }
            });
            if (lead.Product__c) {
                $A.enqueueAction(action);
            }
            var utilityAction = component.get("c.getUtility");
            var utilId = lead.Utility_relationship__c;
            utilityAction.setParams({"utilityId" : utilId});
            utilityAction.setCallback(this, function(resp) {
                if (resp.getState() === "SUCCESS") {
                    component.set('v.utility', resp.getReturnValue());
                } else {
                    helper.logError("CSAPEnergyInfoController", "getUtility", resp.getError(), lead);
                }
            });
            if (lead.Utility_relationship__c) {
                $A.enqueueAction(utilityAction);
            }
        }
        if (component.get("v.abbrevStates") && component.get("v.abbrevStates").length === 0) {
            helper.getUSStates(component, "v.abbrevStates", true);
        }
        helper.clearAttachments(component, event, helper);
    },

    goToUtilityAccountInformation : function(component, event, helper) {
        component.set("v.page", "UtilityAccountInformation");
    },
    goToAddMore : function(component, event, helper) {
        //Upsert UAL record
        if(helper.validatePageFields(component)){
            var ual = component.get("v.ual");
            var lead = component.get("v.lead");

            component.set("v.loading", true);
            component.set("v.loadingText", "Saving utility account information...");

            if(ual.Lead__c == null){
                ual.Lead__c = lead.Id;
            }
            var utility = component.get('v.utility');
            ual.Name = utility.Name;
            var saveUAL = component.get('c.saveUtilityAccountLog');
            saveUAL.setParams({'ual' : ual});
            saveUAL.setCallback(this, function(resp) {
                if (resp.getState() === 'SUCCESS') {
                    component.set("v.page", "AddMoreUAL");
                    component.set("v.loading", false);
                } else {
                    helper.logError("CSAPEnergyInfoController", "goToAddMore", resp.getError(), lead);
                }
            });
            $A.enqueueAction(saveUAL);
        }
    },
    cancelAddUAL : function(component, event, helper) {
        if(confirm("Are you sure you want to cancel adding another Utility Account Log?")){
            helper.finishStage(component, event, helper);
        }
    },

    addUAL : function(component, event, helper) {
        var ual = {
            sobjectType: "Utility_Account_Log__c"
        };
        //Go back to the Utility Account Information Page
        var ualList = component.get("v.ualList");
        ualList.push(ual);
        component.set("v.ual", ual);
        component.set("v.ualList", ualList);
        component.set("v.page", "UtilityAccountInformation");
        helper.clearAttachments(component, event, helper);
    },

    finishStage : function(component, event, helper) {
        var lead = component.get("v.lead");
        var action = component.get('c.sendEmailForPaymentInfo');
        action.setParams({
            "lead": lead
        });
        action.setCallback(this, function(resp) {
            if (resp.getState() === "SUCCESS") {
                component.set('v.page', 'CompletedUtilityInfo');
            } else {
                helper.logError("CSAPEnergyInfoController", "finishStage",
                    "There was an issue saving this information. We have recorded this error and will review it.",
                    resp.getError());
            }
        })
        $A.enqueueAction(action);
    },
})