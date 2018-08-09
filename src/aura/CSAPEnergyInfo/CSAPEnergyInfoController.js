({
    handleNavEvent : function(component, event, helper) {
        if (event.getParam('options') && event.getParam('options').pageName) {
            helper.handleNavEvent(component, event, helper, event.getParam('options').pageName);
        } else {
            helper.handleNavEvent(component, event, helper, "UtilityAccountInformation");
        }
        if (component.get('v.STAGENAME') === 'NAV_Energy_Information' && component.get('v.page') === 'UtilityAccountInformation') {
            var action = component.get("c.getProduct");
            var productId = event.getParam("lead").Product__c;
            action.setParams({"productId" : productId});
            action.setCallback(this, function(resp) {
                if (resp.getState() === "SUCCESS") {
                    component.set('v.selectedProduct', resp.getReturnValue());
                } else {
                    helper.logError("CSAPEnergyInfoController", "getProduct", resp.getError(), lead);
                }
            });
            $A.enqueueAction(action);
        }
        if (component.get("v.abbrevStates") && component.get("v.abbrevStates").length === 0) {
            helper.getUSStates(component, "v.abbrevStates", true);
        }
        helper.clearAttachments(component, event, helper);
    },

    goToUtilityAccountInformation : function(component, event, helper) {
        component.set("v.page", "UtilityAccountInformation");
    },
    goToGridUsageHistory : function(component, event, helper) {
        //Upsert UAL record
        if(helper.validatePageFields(component)){
            var ual = component.get("v.ual");
            var lead = component.get("v.lead");

            //TODO - Add the Electricty_Provider__c on the ual
            //Save the lead record for the Utility
            //lead.Electricty_Provider__c = ual.Electricty_Provider__c;
            helper.saveSObject(component, lead.Id, "Lead", null, null, lead);

            if(ual.Lead__c == null){
                ual.Lead__c = lead.Id;
            }
            if(ual.Id){
                var ualPromise = helper.saveSObject(component, ual.Id, "Utility_Account_Log__c", null, null, ual);
                ualPromise.then($A.getCallback(function resolve(retVal) {
                    component.set("v.ual", retVal);
                    component.set("v.page", "GridUsageHistory");
                }));
            }else{
                var ualPromise = helper.insertSObject(component, ual);
                ualPromise.then($A.getCallback(function resolve(retVal) {
                    component.set("v.ual", retVal);
                    component.set("v.page", "GridUsageHistory");
                }));
            }
        }
    },
    goToUAServiceAddress : function(component, event, helper) {
        if (!component.get("v.electricBill1")) {
            alert("Please upload your recent electric bill");
            return;
        }

        if(helper.validatePageFields(component)){
            var ual = component.get("v.ual");
            var ualPromise = helper.saveSObject(component, ual.Id, "Utility_Account_Log__c", null, null, ual);
            ualPromise.then($A.getCallback(function resolve(retVal) {
                component.set("v.page", "UAServiceAddress");
            }));
        }
    },
    goToAddMore : function(component, event, helper) {
        if(helper.validatePageFields(component)){
            var ual = component.get("v.ual");
            if(ual.Id){
                var ualPromise = helper.saveSObject(component, ual.Id, "Utility_Account_Log__c", null, null, ual);
                ualPromise.then($A.getCallback(function resolve(retVal) {
                    component.set("v.page", "AddMore");
                    component.set("v.ual", {
                        sobjectType: "Utility_Account_Log__c"
                    });
                }));
            }
        }
    },
    addResidence : function(component, event, helper) {
        helper.addNewLead(component, event, helper,"Residential");
    },
    addBusiness : function(component, event, helper) {
        helper.addNewLead(component, event, helper,"Non-Residential");
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
    handleEBill1 : function(component, event, helper) {
        helper.handleAttachment(component, event, helper, helper.ELECTRIC_BILL_1);
    },

    handleEBill2 : function(component, event, helper) {
        helper.handleAttachment(component, event, helper, helper.ELECTRIC_BILL_2);
    },

    handleAnnualElectricHistory : function(component, event, helper) {
        helper.handleAttachment(component, event, helper, helper.ANNUAL_ELECTRIC_HISTORY);
    },
    
    finishStage : function(component, event, helper) {
        component.set('v.loading', true);
        component.set('v.loadingText', 'Submitting your application...');
        helper.convertLeadFunction(component, event, helper);
        helper.finishStage(component, event, helper);
    },
})