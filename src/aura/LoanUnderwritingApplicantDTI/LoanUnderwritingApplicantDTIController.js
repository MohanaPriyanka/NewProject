({
    handleIncomeAdjustment : function(component, event, helper) {
        var adjustedIncome = event.getParam("adjustedIncome");
        var pcrId = event.getParam("pcrId");
        var pcr = component.get("v.pcr");
        console.log(pcrId, pcr.Id);
        if (pcrId === pcr.Id) {
            pcr.Adjusted_Income__c = adjustedIncome;
            helper.updateAdjustedDTI(component, adjustedIncome, pcr.LASERCA__Sum_of_monthly_Personal_Debt__c, null);
        }
    }
})