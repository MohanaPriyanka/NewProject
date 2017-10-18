({
    handleNavEvent : function(component, event, helper) {
        component.set("v.lead", event.getParam("lead"));
        if (event.getParam("eventType") === "COMPLETED") {
            var nextStageIndex = helper.getNextStageIndex(event.getParam("stageName"), helper);
            var nextStageName = helper.getStage(nextStageIndex);
            var currentStageIndex = component.get("v.stageIndex");
            if (currentStageIndex < nextStageIndex) {
                component.set("v.stageIndex", nextStageIndex);
            }
            var stageChangeEvent = $A.get("e.c:CAPNavigationEvent");
            stageChangeEvent.setParams({"stageName": nextStageName});
            stageChangeEvent.setParams({"eventType": "INITIATED"});
            stageChangeEvent.setParams({"lead": component.get("v.lead")});
            stageChangeEvent.fire();
        }
    },

    onStageClicked : function(component, event, helper) {
        var stage = event.currentTarget.dataset.stage;
        var stageIndex = helper.getStage(stage);
        var maxIndex = helper.getStage(component.get("v.lead").CAP_Stage__c);
        if (stageIndex <= maxIndex+1) {
            var stageChangeEvent = $A.get("e.c:CAPNavigationEvent");
            stageChangeEvent.setParams({"stageName": stage});
            stageChangeEvent.setParams({"eventType": "INITIATED"});
            stageChangeEvent.setParams({"lead": component.get("v.lead")});
            stageChangeEvent.fire();
        }
    },
})
