({
    doInit : function(component, event, helper) {
       var actionGetScheduleZs = component.get("c.getScheduleZs");
       var compParentId = component.get("v.transfer");

       actionGetScheduleZs.setParams({
           "transferId" : compParentId
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
        var compParentId = component.get("v.transfer");
        var selectedScheduleZ = component.get("v.selectedScheduleZ");

        actionGetUASList.setParams({
            "parentId" : compParentId,
            "isTransfer" : true,
            "scheduleZId" : selectedScheduleZ
        });

        actionGetUASList.setCallback(this,function(resp){
            if (resp.getState() === 'SUCCESS') {
                component.set("v.nonCancelledBills", resp.getReturnValue());
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

    switchToNewCredits : function (component, event, helper) {
        $A.util.addClass(component.find("tab-default-1"), 'slds-show');
        $A.util.removeClass(component.find("tab-default-1"), 'slds-hide');
        $A.util.removeClass(component.find("tab-default-2"), 'slds-show');
        $A.util.addClass(component.find("tab-default-2"), 'slds-hide');
    },

    switchToZeroBills : function (component, event, helper) {
        if (!component.get("v.selectedScheduleZ")){
            alert('Select an Allocation Schedule before viewing $0 bills');
            return;
        }
        helper.getCancelledBills(component);
        $A.util.removeClass(component.find("tab-default-1"), 'slds-show');
        $A.util.addClass(component.find("tab-default-1"), 'slds-hide');
        $A.util.addClass(component.find("tab-default-2"), 'slds-show');
        $A.util.removeClass(component.find("tab-default-2"), 'slds-hide');
    },


    saveToTransfer : function (component, event, helper) {
        var actionSaveProdUpdate = component.get("c.saveAllocationScheduleToTransfer");
        var transfer = component.get("v.transfer");
        var selectedScheduleZ = component.get("v.selectedScheduleZ");

        actionSaveProdUpdate.setParams({
           "scheduleZId" : selectedScheduleZ,
           "transferId" : transfer
        });

        actionSaveProdUpdate.setCallback(this,function(resp){
            if (resp.getState() === 'SUCCESS') {
                alert("Saved Successfully!");
            } else {
                var appEvent = $A.get("e.c:ApexCallbackError");
                appEvent.setParams({"className" : "PreviewProductionUpdateResults",
                    "methodName" : "saveAllocationScheduleToTransfer",
                    "errors" : "Save Failed"});
                appEvent.fire();
            }
        });
        $A.enqueueAction(actionSaveProdUpdate);
    },

    downloadAllData : function(component,event,helper){
        var allBillsList = component.get("v.nonCancelledBills");
        var additionalUASB = component.get("v.cancelledBills");
        additionalUASB.push(...allBillsList);

        var allHavePremise = true;
        var allDoNotHavePremise = true;
        var i;
        for (i = 0; i < additionalUASB.length; i++) {
            if (additionalUASB[i].PreGen_Additional_Id__c != null) {
                allDoNotHavePremise = false;
            } else {
                allHavePremise = false;
            }
        }

        var keys;

        if (allDoNotHavePremise) {
            keys = ['PreGen_Name_on_Account__c','PreGen_IsPreGen__c', 'PreGen_Discounted_Bill__c', 'PreGen_NMCs_Allocated__c',
                'PreGen_Production_Update__c', 'PreGen_Schedule_Z_Status__c', 'PreGen_System_Share__c', 'PreGen_Utility_Acct__c'];
        } else if (allHavePremise) {
            keys = ['PreGen_Name_on_Account__c','PreGen_IsPreGen__c', 'PreGen_Discounted_Bill__c', 'PreGen_NMCs_Allocated__c',
                'PreGen_Production_Update__c', 'PreGen_Additional_Id__c', 'PreGen_Schedule_Z_Status__c', 'PreGen_System_Share__c'];
        } else {
            keys = ['PreGen_Name_on_Account__c','PreGen_IsPreGen__c', 'PreGen_Discounted_Bill__c', 'PreGen_NMCs_Allocated__c',
                'PreGen_Production_Update__c', 'PreGen_Additional_Id__c', 'PreGen_Schedule_Z_Status__c', 'PreGen_System_Share__c', 'PreGen_Utility_Acct__c'];
        }

        var csvFile, counter, columnDivider, lineDivider;

        if (additionalUASB == null || !additionalUASB.length) {
            return null;
        }

        columnDivider = ',';
        lineDivider =  '\n';

        csvFile = '';
        csvFile += keys.join(columnDivider);
        csvFile += lineDivider;

        for (var i=0; i < additionalUASB.length; i++){
            counter = 0;

            for (var sTempkey in keys) {
                var skey = keys[sTempkey] ;
                // add , [comma] after every String value,. [except first]
                if (counter > 0){
                    csvFile += columnDivider;
                }
                csvFile += '"'+ additionalUASB[i][skey]+'"';
                counter++;
            }
            csvFile += lineDivider;
        }

        var hiddenElement = document.createElement('a');
        hiddenElement.href = 'data:text/csv;charset=utf-8,' + encodeURI(csvFile);
        hiddenElement.target = '_self'; //
        hiddenElement.download = 'PreviewBills.csv';
        document.body.appendChild(hiddenElement);
        hiddenElement.click();
    },
})