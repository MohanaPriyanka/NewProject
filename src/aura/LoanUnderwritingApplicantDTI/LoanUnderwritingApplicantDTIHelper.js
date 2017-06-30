({
    updateAdjustedDTI : function(component, annualIncome, monthlyDebt, adjustedMonthlyDebt) {
        console.log('in DTIHelper');
        var monthlyIncome = annualIncome/12;
        var adjustedDTI;
        var pcr = component.get("v.pcr");
        if (adjustedMonthlyDebt) {
            adjustedDTI = 100*(adjustedMonthlyDebt/monthlyIncome);
        } else {
            adjustedDTI = 100*(monthlyDebt/monthlyIncome);
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