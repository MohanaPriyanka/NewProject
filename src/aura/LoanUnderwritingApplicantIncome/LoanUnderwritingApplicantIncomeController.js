({
    saveAdjustedIncome : function(component, event, helper) {
        var pcr = component.get("v.pcr");
        var savePromise = helper.saveSObject(component,
                                             pcr.Id,
                                             'LASERCA__Personal_Credit_Report__c',
                                             'Adjusted_Income__c',
                                             component.get("v.pcr.Adjusted_Income__c"));
        savePromise.then(
            $A.getCallback(function resolve(value) {
                var incomeEvent = $A.get("e.c:LoanUnderwritingIncomeAdjustment");
                incomeEvent.setParams({"pcrId":component.get("v.pcr.Id")});
                incomeEvent.fire();
            }),
            $A.getCallback(function(error){
                alert('An error occurred getting the account : ' + error.message);
            })
        );
    },
    
    saveIncomeNotes : function(component, event, helper) {
        var pcr = component.get("v.pcr");
        helper.saveSObject(component,
                           pcr.Id,
                           'LASERCA__Personal_Credit_Report__c',
                           'Adjustments_Comments__c',
                           component.get("v.pcr.Adjustments_Comments__c"));
    }
})