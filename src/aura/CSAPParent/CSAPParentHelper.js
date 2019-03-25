({
    getStage : function(stageName) {
        var stageMap = new Map();
        stageMap.set("NAV_Personal_Information", 0);
        stageMap.set("NAV_Capacity_Check", 1);
        stageMap.set("NAV_Credit_Check", 2);
        stageMap.set("NAV_Energy_Information", 3);
        stageMap.set("NAV_Payment_Information", 4);
        stageMap.set("NAV_Complete", 5);
        stageMap.set(0, "NAV_Personal_Information");
        stageMap.set(1, "NAV_Capacity_Check");
        stageMap.set(2, "NAV_Credit_Check");
        stageMap.set(3, "NAV_Energy_Information");
        stageMap.set(4, "NAV_Payment_Information");
        stageMap.set(5, "NAV_Complete");
        if (stageMap.get(stageName) != undefined) {
            return stageMap.get(stageName);
        } else {
            return -1;;
        }
    },

    raiseNavEvent : function(eventType, options) {
        var stageChangeEvent = $A.get("e.c:CSAPNavigationEvent");
        stageChangeEvent.setParams({"eventType": eventType});
        if(options){
            if (options.hasOwnProperty("stageName")) {
                stageChangeEvent.setParams({"stageName": options.stageName});
            }
            if (options.hasOwnProperty("lead")) {
                stageChangeEvent.setParams({"lead": options.lead});
            }
            if (options.hasOwnProperty("page")) {
                stageChangeEvent.setParams({"page": options.page});
            }
        }
        stageChangeEvent.fire();
    },

    handleNavEvent : function(component, event, helper, defaultPage) {
        if (event.getParam("eventType") === "INITIATED" &&
            event.getParam("stageName") === component.get("v.STAGENAME")) {
            component.set("v.lead", event.getParam("lead"));
            component.set("v.page", defaultPage);
            component.set("v.supressWaiting", false);
        } else if ((event.getParam("eventType") === "INITIATED" && event.getParam("stageName") !== component.get("v.STAGENAME"))) {
            component.set("v.page", "");
            component.set("v.supressWaiting", true);
        }
    },

    getNextStageIndex : function(stageName, helper) {
        return helper.getStage(stageName) + 1;
    },

    getNextStageName : function(stageName, helper) {
        return helper.getStage(helper.getNextStageIndex(stageName));
    },
    finishStage : function(component, event, helper) {
        var lead = component.get("v.lead");
        var stageName = component.get("v.STAGENAME");
        var currentMaxStage = lead.CSAP_Stage__c;
        if (currentMaxStage == null ||
            helper.getStage(stageName) > helper.getStage(currentMaxStage)) {
            lead.CSAP_Stage__c = stageName;
            var promise = helper.saveSObject(component, lead.Id, "Lead", "CSAP_Stage__c", stageName);
            promise.then($A.getCallback(function resolve(value) {
                helper.closePageFireComplete(component, helper, stageName, lead);
                component.set("v.loading", false);
            }));
        } else {
            helper.closePageFireComplete(component, helper, stageName, lead);
            component.set("v.loading", false);
        }
    },
    closePageFireComplete : function(component, helper, stageName, lead) {
        component.set("v.page", "Done");
        var stageChangeEvent = $A.get("e.c:CSAPNavigationEvent");
        stageChangeEvent.setParams({"stageName": stageName});
        stageChangeEvent.setParams({"eventType": "COMPLETED"});
        stageChangeEvent.setParams({"lead": lead});
        stageChangeEvent.fire();
    },

})