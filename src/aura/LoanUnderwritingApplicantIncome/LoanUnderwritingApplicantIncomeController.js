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
                incomeEvent.setParams({"adjustedIncome":component.get("v.pcr.Adjusted_Income__c")});
                incomeEvent.setParams({"pcrId":component.get("v.pcr.Id")});
                incomeEvent.fire();
            }),
            $A.getCallback(function(error){
                alert('An error occurred getting the account : ' + error.message);
            })
        );
    }
})