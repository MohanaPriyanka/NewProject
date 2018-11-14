({
    handleNavEvent : function(component, event, helper) {
        if (event.getParam('lead')) {
            component.set("v.lead", event.getParam("lead"));
        }
        if (event.getParam('options') && event.getParam('options').hasOwnProperty("contractSent")) {
            component.set('v.contractSent', event.getParam('options').contractSent);
        }
        if (event.getParam('options') && event.getParam('options').hasOwnProperty("systemInfoComplete")) {
            component.set('v.systemInfoComplete', event.getParam('options').systemInfoComplete);
        }
        if (event.getParam("eventType") === "COMPLETED") {
            var nextStageIndex = helper.getNextStageIndex(event.getParam("stageName"), helper);
            var nextStageName = helper.getStage(nextStageIndex);
            var currentStageIndex = component.get("v.stageIndex");
            if (currentStageIndex < nextStageIndex) {
                component.set("v.stageIndex", nextStageIndex);
            }
            let eventOptions = {};
            eventOptions.stageName = nextStageName;
            eventOptions.lead = component.get('v.lead');
            if (event.getParam('options') && event.getParam('options').hasOwnProperty("contractSent")) {
                eventOptions.contractSent = component.get('v.contractSent');
            }
            if (event.getParam('options') && event.getParam('options').hasOwnProperty("systemInfoComplete")) {
                eventOptions.systemInfoComplete = component.get('v.systemInfoComplete');
            }
            helper.raiseNavEvent("INITIATED", eventOptions);
        }
    },

    onStageClicked : function(component, event, helper) {
        const lead = component.get('v.lead');
        if (lead && lead.CAP_Stage__c !== 'NAV_Complete') {
            var stage = event.currentTarget.dataset.stage;
            var stageIndex = helper.getStage(stage);
            var maxIndex = helper.getStage(lead.CAP_Stage__c);
            if (stageIndex <= maxIndex+1) {
                helper.raiseNavEvent("INITIATED", {
                    "stageName": stage,
                    "lead": lead,
                    "contractSent": component.get('v.contractSent'),
                    "systemInfoComplete": component.get('v.systemInfoComplete')
                });
            }
        }
    },
})
