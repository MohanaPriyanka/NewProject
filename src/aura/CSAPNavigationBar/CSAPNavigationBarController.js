({
    doInit: function(component, event, helper) {
        var leadId = component.get("v.leadId");
        // hides nav bar if the customer needs to log in
        if (leadId != null && leadId != '' && leadId != undefined) {
            component.set("v.showNavBar", false);
        }
    },

    handleNavEvent : function(component, event, helper) {
        component.set("v.showNavBar", true);
        if (event.getParam("lead")) {
            component.set("v.lead", event.getParam("lead"));
        }

        if (event.getParam("eventType") === "INITIATED") {
            //Get current stage to set current index
            var currentStage = event.getParam("stageName");
            var currentIndex = helper.getStage(currentStage);
            component.set("v.stageIndex", currentIndex);
        }


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
        const lead = component.get("v.lead");
        if (lead) {
            var stage = event.currentTarget.dataset.stage;
            var stageIndex = helper.getStage(stage);
            var maxIndex = helper.getStage(lead.CSAP_Stage__c);
            if (stageIndex <= maxIndex+1) {
                helper.raiseNavEvent("INITIATED", {"stageName": stage, "lead": lead});
            }
        }
    },
})