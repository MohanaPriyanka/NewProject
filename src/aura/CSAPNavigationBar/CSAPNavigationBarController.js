({
    doInit: function(component, event, helper) {
        var leadId = component.get("v.leadId");
        // hides nav bar if the customer needs to log in
        if (leadId != null && leadId != '' && leadId != undefined) {
            component.set("v.showNavBar", false);
            component.set("v.loading", false);
        }

        var partnerId = component.get("v.partnerId");

        if (partnerId != null && partnerId != '' && partnerId != undefined) {
            var action = component.get("c.checkApplicationPartner");
            action.setParams({"partnerId": component.get("v.partnerId")});
            action.setCallback(this, function(resp) {
                if(resp.getState() === 'SUCCESS') {
                    component.set("v.partnerApp", resp.getReturnValue());
                    component.set("v.loading", false);
                } else {
                    this.logError('CSAPApplication', 'checkApplicationPartner', resp.getError(), component.get('v.partnerId'));
                }
            });
            $A.enqueueAction(action);

        }


    },

    handleNavEvent : function(component, event, helper) {
        component.set("v.showNavBar", true);
        var lead;
        if (event.getParam("lead")) {
            component.set("v.lead", event.getParam("lead"));
            lead = event.getParam("lead");
        }
        if (component.get("v.partnerApp") == undefined) {
            if ( lead.Application_Source_Phase_1__c == 'CSAP 2.1 with Partner'){
                component.set("v.partnerApp", true);
            } else {
                component.set("v.partnerApp", false);
            }
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