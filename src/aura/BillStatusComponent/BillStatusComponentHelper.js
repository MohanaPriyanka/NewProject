({
    getAccountBillSummary : function(component, helper) {
        var actionGetAccountBillSummary = component.get("c.getAccountBillSummary");
        if (actionGetAccountBillSummary){
            actionGetAccountBillSummary.setCallback(this,function(resp){
                if (resp.getState() === 'SUCCESS') {
                    var responseRaw = resp.getReturnValue();
                    var listQualities = responseRaw.split("/",5);
                    component.set("v.abSummary", listQualities);
                } else {
                    helper.logError('BillGenerationConsoleController',
                        'getAccountBillSummary',
                        'error getting AB Summary','');
                }
            });
            $A.enqueueAction(actionGetAccountBillSummary);
        }
    },
})