({
    getStage : function(stageName) {
        var stageMap = new Map();
        stageMap.set('NAV_Getting_Started', 0);
        stageMap.set('NAV_Personal_Information', 1);
        stageMap.set('NAV_Credit_Check', 2);
        stageMap.set('NAV_Income_Documentation', 3);
        stageMap.set('NAV_SREC_and_Disbursals', 4);
        stageMap.set('NAV_Complete', 5);
        stageMap.set(0, 'NAV_Getting_Started');
        stageMap.set(1, 'NAV_Personal_Information');
        stageMap.set(2, 'NAV_Credit_Check');
        stageMap.set(3, 'NAV_Income_Documentation');
        stageMap.set(4, 'NAV_SREC_and_Disbursals');
        stageMap.set(5, 'NAV_Complete');
        if (stageMap.get(stageName) != undefined) {
            return stageMap.get(stageName);
        } else {
            return -1;;
        }
    },

    getNextStageIndex : function(stageName, helper) {
        return helper.getStage(stageName) + 1;
      },

    getNextStageName : function(stageName, helper) {
        return helper.getStage(helper.getNextStageIndex(stageName));
      },

    finishStage : function(component, event, helper) {
        var lead = component.get('v.leadRecord');
        var stageName = component.get("v.STAGENAME");
        var currentMaxStage = lead.CAP_Stage__c;
        if (currentMaxStage == null ||
            helper.getStage(stageName) > helper.getStage(currentMaxStage)) {
            lead.CAP_Stage__c = stageName;
            var promise = helper.saveSObject(component, lead.Id, 'Lead', 'CAP_Stage__c', stageName);
            promise.then($A.getCallback(function resolve(value) {
                helper.closePageFireComplete(component, helper, stageName, lead);
            }));
        } else {
            helper.closePageFireComplete(component, helper, stageName, lead);
        }
    },

    closePageFireComplete : function(component, helper, stageName, lead) {
        component.set('v.page', 'Done');
        var stageChangeEvent = $A.get("e.c:CAPNavigationEvent");
        stageChangeEvent.setParams({"stageName": stageName});
        stageChangeEvent.setParams({"eventType": "COMPLETED"});
        stageChangeEvent.setParams({"lead": lead});
        stageChangeEvent.fire();
    }
})
