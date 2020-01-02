({
    getSSSWithoutTransfer : function(component, event, helper, transferList) {
        var actionGetSharedSolarSystems = component.get("c.getSSSWithoutTransfer");

        actionGetSharedSolarSystems.setParams({
            "transferList" : transferList
        });

        actionGetSharedSolarSystems.setCallback(this,function(resp){
            if (resp.getState() === 'SUCCESS') {
                component.set("v.sssWithoutTransferList", resp.getReturnValue());
            } else {
                helper.logError('BillGenerationConsoleController',
                    'getSSSWithoutTransfer',
                    'error refreshing sss table','');
            }
        });
        $A.enqueueAction(actionGetSharedSolarSystems);
    },

    refreshTable : function(component, event, helper, refreshSSSTable) {
        var actionGetTransfers = component.get("c.getThisMonthsTransfers");
        if (actionGetTransfers) {
            actionGetTransfers.setCallback(this, function (resp) {
                if (resp.getState() === 'SUCCESS') {
                    var transferList = resp.getReturnValue();
                    component.set("v.TransferList", transferList);
                    var transferStep;
                    var countGenerated = 0;
                    for (transferStep = 0; transferStep < transferList.length; transferStep++) {
                        if (transferList[transferStep].Generate_Bills__c){
                            countGenerated += 1;
                        }
                    }
                    if (countGenerated === transferList.length){
                        component.set("v.doneGenerating", true);
                        component.set("v.generating", false);
                    }
                    if (refreshSSSTable) {
                        this.getSSSWithoutTransfer(component, event, helper, transferList);
                    }
                } else {
                    helper.logError('BillGenerationConsoleController',
                        'getThisMonthsTransfers',
                        'error refreshing transfer table','');
                }
            });
            $A.enqueueAction(actionGetTransfers);
        }
    },
})