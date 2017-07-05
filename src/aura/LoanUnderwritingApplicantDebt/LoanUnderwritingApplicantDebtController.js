({
    doInit : function(component, event, helper) {
        helper.initHelper(component, event, helper);
    },

    display : function(component, event, helper) {
        helper.toggleHelper(component, event);
    },

    displayOut : function(component, event, helper) {
        helper.toggleHelper(component, event);
    },

    updateExclude : function(component, event, helper) {
        var srcElement = event.srcElement;
        var savePromise = helper.saveSObject(component,
                                             srcElement.name,
                                             'LASERCA__Trade_Accounts__c',
                                             'Exclude_From_Rollup__c',
                                             srcElement.checked);
        savePromise.then(
            $A.getCallback(function resolve(value) {
                helper.initHelper(component, event);
            }),
            $A.getCallback(function(error){
                alert('An error occurred getting the account : ' + error.message);
            })
        ).then(
            $A.getCallback(function resolve(value) {
                var debtEvent = $A.get("e.c:LoanUnderwritingDebtAdjustment");
                incomeEvent.setParams({"adjustedDebt":component.get("v.adjustedDebt")});
                incomeEvent.setParams({"pcrId":component.get("v.pcr.Id")});
                incomeEvent.fire();
            }),
            $A.getCallback(function(error){
                alert('An error occurred getting the account : ' + error.message);
            })
        )
    }
})
