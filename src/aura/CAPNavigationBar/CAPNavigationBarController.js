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
            helper.raiseNavEvent("INITIATED", {"stageName": nextStageName, "lead": component.get("v.lead")});
        }
    },

    onStageClicked : function(component, event, helper) {
        const lead = component.get('v.lead');
        if (lead) {
            var stage = event.currentTarget.dataset.stage;
            var stageIndex = helper.getStage(stage);
            var maxIndex = helper.getStage(lead.CAP_Stage__c);
            if (stageIndex <= maxIndex+1) {
                helper.raiseNavEvent("INITIATED", {"stageName": stage, "lead": lead});
            }
        }
    },
})
