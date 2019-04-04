({
    getSSSWithoutProdUpdate : function(component, event, helper, productionUpdates) {
        var actionGetSharedSolarSystems = component.get("c.getSSSWithoutProductionUpdates");

        actionGetSharedSolarSystems.setParams({
            "prodUpdateList" : productionUpdates
        });

        actionGetSharedSolarSystems.setCallback(this,function(resp){
            if (resp.getState() === 'SUCCESS') {
                component.set("v.sssWithoutProdList", resp.getReturnValue());
            } else {
                helper.logError('BillGenerationConsoleController',
                    'getSSSWithoutProductionUpdates',
                    'error refreshing sss table','');
            }
        });
        $A.enqueueAction(actionGetSharedSolarSystems);
    },

    refreshTable : function(component, event, helper, refreshSSSTable) {
        var actionGetProdUpdates = component.get("c.getThisMonthsProductionUpdates");
        if (actionGetProdUpdates) {
            actionGetProdUpdates.setCallback(this, function (resp) {
                if (resp.getState() === 'SUCCESS') {
                    var prodUpdateList = resp.getReturnValue();
                    component.set("v.ProdUpdateList", prodUpdateList);
                    var proUpStep;
                    var countGenerated = 0;
                    for (proUpStep = 0; proUpStep < prodUpdateList.length; proUpStep++) {
                        if (prodUpdateList[proUpStep].Generate_Bills__c){
                            countGenerated += 1;
                        }
                    }
                    if (countGenerated === prodUpdateList.length){
                        component.set("v.doneGenerating", true);
                        component.set("v.generating", false);
                    }
                    if (refreshSSSTable) {
                        this.getSSSWithoutProdUpdate(component, event, helper, prodUpdateList);
                    }
                } else {
                    helper.logError('BillGenerationConsoleController',
                        'getThisMonthsProductionUpdates',
                        'error refreshing prod update table','');
                }
            });
            $A.enqueueAction(actionGetProdUpdates);
        }
    },
})