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
        var srcElement = event.getSource();
        var savePromise = helper.saveSObject(component,
                                             srcElement.get("v.name"),
                                             'LASERCA__Trade_Accounts__c',
                                             'Exclude_From_Rollup__c',
                                             srcElement.get("v.checked"));
        savePromise.then(
            $A.getCallback(function(result) {
                return(helper.initHelper(component, event));
            })
        ).then(
            $A.getCallback(function(result) {
                var debtEvent = $A.get("e.c:LoanUnderwritingDebtAdjustment");
                debtEvent.setParams({"pcrId": component.get("v.pcr.Id")});
                debtEvent.fire();
            })
        )
    },
    updatePayment : function(component, event, helper) {
        var srcElement = event.getSource();
        var savePromise = helper.saveSObject(component,
                                             srcElement.get("v.class"),
                                             'LASERCA__Trade_Accounts__c',
                                             'LASERCA__Monthly_Payment__c',
                                             srcElement.elements[0].value);
        savePromise.then(
            $A.getCallback(function(result) {
                return(helper.initHelper(component, event));
            })
        ).then(
            $A.getCallback(function(result) {
                var debtEvent = $A.get("e.c:LoanUnderwritingDebtAdjustment");
                debtEvent.setParams({"pcrId": component.get("v.pcr.Id")});
                debtEvent.fire();
            })
        )
    }

})
