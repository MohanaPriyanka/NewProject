({
    getCancelledBills: function (component, event, helper) {
        var actionGetCancelledBills = component.get("c.getCancelledBills");
        var prodUpdateId = component.get("v.prodUpdate");
        var uasbList = component.get("v.nonCancelledBills");
        var uasIdlist = [];
        var i;

        for (i = 0; i < uasbList.length; i++) {
            uasIdlist.push(uasbList[i].Utility_Account_Subscription__c);
        }

        actionGetCancelledBills.setParams({
            "productionUpdateId" : prodUpdateId,
            "alreadyGeneratedList" : uasIdlist,
            "scheduleZId" : component.get("v.selectedScheduleZ")
        });

        actionGetCancelledBills.setCallback(this,function(resp){
            if (resp.getState() === 'SUCCESS') {
                var response = resp.getReturnValue();
                component.set("v.cancelledBills", response);
            } else {

            }
        });
        $A.enqueueAction(actionGetCancelledBills);
    },
})