({
    updateAdjustedDTI : function(component, annualIncome, adjustedMonthlyDebt) {
        var adjustedDTI;
        var pcr = component.get("v.pcr");
        if (annualIncome > 0) {
            var monthlyIncome = annualIncome/12;
            adjustedDTI = 100*(adjustedMonthlyDebt/monthlyIncome);
        } else {
            adjustedDTI = null;
        }
        var savePromise = this.saveSObject(component,
                                           pcr.Id,
                                           'LASERCA__Personal_Credit_Report__c',
                                           'Adjusted_DTI__c',
                                           adjustedDTI);
        savePromise.then(
            $A.getCallback(function resolve(value) {
                component.set("v.pcr.Adjusted_DTI__c", adjustedDTI);
            }),
            $A.getCallback(function(error){
                alert('An error occurred saving adjusted DTI : ' + error.message);
            })
        );
    }
})
