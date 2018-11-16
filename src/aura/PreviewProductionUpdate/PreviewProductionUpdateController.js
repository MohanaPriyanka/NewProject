({
    doInit : function(component, event, helper) {
        var actionGetScheduleZs = component.get("c.getScheduleZs");
        var compParentId = component.get("v.prodUpdate");

        actionGetScheduleZs.setParams({
            "productionUpdateId" : compParentId
        });

        actionGetScheduleZs.setCallback(this,function(resp){
            if (resp.getState() === 'SUCCESS') {
                var scheduleZs = [];
                var scheduleZrecords = resp.getReturnValue();
                for (var index in scheduleZrecords) {
                    var scheduleZ = scheduleZrecords[index];
                    var label = scheduleZ.Name + ' - ' + scheduleZ.Status__c;
                    scheduleZs.push({'label': label, 'value': scheduleZ.Id});
                }
                component.set("v.scheduleZs", scheduleZs);
            } else {
                var appEvent = $A.get("e.c:ApexCallbackError");
                appEvent.setParams({"className" : "PreviewProductionUpdateResults",
                    "methodName" : "scheduleZs",
                    "errors" : "No Schedule Zs Found"});
                appEvent.fire();
            }
        });
        $A.enqueueAction(actionGetScheduleZs);
    },

    getBills : function(component, event, helper) {
        var actionGetUASList = component.get("c.getUASes");
        var compParentId = component.get("v.prodUpdate");
        var selectedScheduleZ = component.get("v.selectedScheduleZ");

        actionGetUASList.setParams({
            "parentId" : compParentId,
            "isProdUpdate" : true,
            "scheduleZId" : selectedScheduleZ
        });

        actionGetUASList.setCallback(this,function(resp){
            if (resp.getState() === 'SUCCESS') {
                component.set("v.SchZBillList", resp.getReturnValue());
            } else {
                var appEvent = $A.get("e.c:ApexCallbackError");
                appEvent.setParams({"className" : "PreviewProductionUpdateResults",
                    "methodName" : "getUASes",
                    "errors" : "No Active UASes Found"});
                appEvent.fire();
            }
        });
        $A.enqueueAction(actionGetUASList);
    },

    saveToProdUpdate : function (component, event, helper) {
        var actionSaveProdUpdate = component.get("c.saveSchedZToProdUpdate");
        var prodUpdate = component.get("v.prodUpdate");
        var selectedScheduleZ = component.get("v.selectedScheduleZ");

        actionSaveProdUpdate.setParams({
           "scheduleZId" : selectedScheduleZ,
           "prodUpdateId" : prodUpdate
        });

        actionSaveProdUpdate.setCallback(this,function(resp){
            if (resp.getState() === 'SUCCESS') {
                alert("Saved Successfully!");
            } else {
                var appEvent = $A.get("e.c:ApexCallbackError");
                appEvent.setParams({"className" : "PreviewProductionUpdateResults",
                    "methodName" : "saveSchedZToProdUpdate",
                    "errors" : "Save Failed"});
                appEvent.fire();
            }
        });
        $A.enqueueAction(actionSaveProdUpdate);
    }
})