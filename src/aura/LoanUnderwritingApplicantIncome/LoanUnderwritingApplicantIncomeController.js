({
    saveAdjustedIncome : function(component, event, helper) {
        console.log('foo');
        console.log('saving adjusted income: ' + component.get("v.pcr.Adjusted_Income__c"));
        var pcr = component.get("v.pcr");
        helper.saveSObject(component,
                           pcr.Id,
                           'LASERCA__Personal_Credit_Report__c',
                           'Adjusted_Income__c',
                           component.get("v.pcr.Adjusted_Income__c"));
    }
})