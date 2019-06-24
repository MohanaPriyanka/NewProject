({
    handleNavEvent : function(component, event, helper) {
        if (event.getParam('options') && event.getParam('options').pageName) {
            helper.handleNavEvent(component, event, helper, event.getParam('options').pageName);
        } else {
            helper.handleNavEvent(component, event, helper, "UtilityAccountInformation");
        }
        if (component.get('v.STAGENAME') === 'NAV_Energy_Information' && component.get('v.page') === 'UtilityAccountInformation' && event.getParam("eventType")=== "INITIATED") {

            component.set("v.loading", true);
            component.set("v.loadingText", "Loading...");
            var lead = component.get('v.lead');
            var action = component.get("c.getProduct");
            var ual = component.get("v.ual");
            var productId = lead.Product__c;

            action.setParams({"productId" : productId});
            action.setCallback(this, function(resp) {
                if (resp.getState() === "SUCCESS") {
                    component.set("v.selectedProduct", resp.getReturnValue());
                    helper.addUAL(component, event, helper);
                    component.set("v.loading", false);
                    component.set("v.loadingText", "");
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
            var rateClassesAction = component.get("c.getRateClassesForUtility");
            rateClassesAction.setParams({"utilityId" : utilId});
            rateClassesAction.setCallback(this, function(resp) {
                if (resp.getState() === "SUCCESS") {
                    component.set('v.rateClasses', resp.getReturnValue());
                } else {
                    helper.logError("CSAPEnergyInfoController", "getRateClass", resp.getError(), lead);
                }
            });
            if (lead.Utility_relationship__c) {
                $A.enqueueAction(utilityAction);
                $A.enqueueAction(rateClassesAction);
            }

            ual.Service_Zip_Code__c = lead.Parcel_Zip__c;

            if (component.get("v.abbrevStates") && component.get("v.abbrevStates").length === 0) {
                helper.getUSStates(component, "v.abbrevStates", true);
            }
        }
    },

    goToUtilityAccountInformation : function(component, event, helper) {
        component.set("v.page", "UtilityAccountInformation");
    },

    cancelAddUAL : function(component, event, helper) {
        if(confirm("Are you sure you want to cancel adding another Utility Account Log?")){
            helper.finishStage(component, event, helper);
        }
    },

    addUAL : function(component, event, helper) {
        helper.addUAL(component, event, helper);
    },
    removePreviousUAL : function(component, event, helper) {
        var ualList = component.get("v.ualList");
        ualList.pop();
        component.set("v.ualList", ualList);
    },
    submitEnergyInfo :  function(component, event, helper) {
        if(helper.validatePageFields(component)){
            var ual = component.get("v.ual");
            var lead = component.get("v.lead");
            var partnerApp = component.get("v.partnerApp");

            var ualList = component.get("v.ualList");
            for(var i = 0; i < ualList.length; i++) {
                var ualItem = ualList[i];
                if(ualItem.Lead__c == null){
                    ualItem.Lead__c = lead.Id;
                }
                var utility = component.get('v.utility');
                ualItem.Utility__c = utility.Id;
                if (ualItem.Same_Address__c){
                    ualItem.Service_Address__c = lead.LASERCA__Home_Address__c;
                    ualItem.Service_City__c = lead.LASERCA__Home_City__c;
                    ualItem.Service_State__c = lead.LASERCA__Home_State__c;
                    ualItem.Service_Zip_Code__c = lead.Parcel_Zip__c;
                }
            }

            var saveUALList = component.get("c.saveUtilityAccountLogList");
            saveUALList.setParams({'ualList' : ualList});
            saveUALList.setCallback(this, function(resp) {
                if (resp.getState() === "SUCCESS") {
                    component.set("v.loading", false);
                    component.set("v.loadingText", "");

                    component.set('v.ualList', resp.getReturnValue());
                    if (partnerApp){
                        component.set("v.page", "UtilityAccountUpload");
                    } else {
                        var action = component.get('c.sendEmailForPaymentInfo');
                        action.setParams({
                            "lead": lead
                        });
                        action.setCallback(this, function(resp) {
                            if (resp.getState() === "SUCCESS") {
                                component.set("v.loading", false);
                                component.set('v.page', 'CompletedUtilityInfo');
                            } else {
                                helper.logError("CSAPEnergyInfoController", "finishStage",
                                    "There was an issue saving this information. We have recorded this error and will review it.",
                                    resp.getError());
                            }
                        })
                        $A.enqueueAction(action);
                    }

                } else if (resp.getState() !== 'SUCCESS') {
                    helper.logError("CSAPEnergyInfoController", "saveUtilityAccountLogList", resp.getError(), lead);
                }
            });

            if(ual.Rate_Class__c === 'Rate Class Not in List') {
                alert('Only rate classes in the list are eligible for this product. Please close this window and mark the lead as unqualified.');
            } else {
                component.set("v.loading", true);
                component.set("v.loadingText", "Saving utility account information...");
                $A.enqueueAction(saveUALList);
            }
        }
    },
    finishStage :  function(component, event, helper) {
        component.set("v.loading", true);
        component.set("v.loadingText", "Processing...");
        helper.finishStage(component, event, helper);
    },

    handleChange : function (component, event, helper) {
        var checkCmp = component.find("checkbox");
        var result = checkCmp.get("v.value");
        component.set("v.sameAddress", result );
    },
    handleUploadFinished : function (component, event, helper) {
        var uploadedFiles = event.getParam("files");
        event.getSource().set("v.label", uploadedFiles.length + " file(s) uploaded.");
    }
})