({
    doInit : function(component, event, helper) {
        helper.initHelper(component, event, helper);
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
                                             srcElement.get("v.value"));
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

    openModal: function(component, event, helper) {
        component.set("v.isModalOpen", true);
    },

    closeModal: function(component, event, helper) {
        component.set("v.isModalOpen", false);
    },
    
    closeAndSaveModal: function(component, event, helper) {
        var sobj = {'sobjectType' : 'LASERCA__Trade_Accounts__c',
                    'Name' : component.get("v.tradeAccountName"),
                    'LASERCA__Personal_Credit_Report__c' : component.get("v.pcr.Id"),
                    'LASERCA__Monthly_Payment__c' : component.get("v.tradeAccountMonthlyPayment")};
        var insertPromise = helper.insertSObject(component, sobj);
        insertPromise.then(
            $A.getCallback(function(result) {
                return(helper.initHelper(component, event));
            })
        ).then(
            $A.getCallback(function(result) {
                var debtEvent = $A.get("e.c:LoanUnderwritingDebtAdjustment");
                debtEvent.setParams({"pcrId": component.get("v.pcr.Id")});
                debtEvent.fire();
            })
        ).then(
            $A.getCallback(function(result) {
                component.set("v.isModalOpen", false);
            }));
    }
})
