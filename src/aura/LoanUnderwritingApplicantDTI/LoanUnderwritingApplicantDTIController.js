({
    handleIncomeAdjustment : function(component, event, helper) {
        var adjustedIncome = event.getParam("adjustedIncome");
        var pcrId = event.getParam("pcrId");
        var pcr = component.get("v.pcr");

        if (pcrId === pcr.Id) {
            pcr.Adjusted_Income__c = adjustedIncome;
            helper.updateAdjustedDTI(component, adjustedIncome, pcr.Adjusted_Monthly_Debt__c);
        }
    },
        
    handleDebtAdjustment : function(component, event, helper) {
        var adjustedIncome = event.getParam("adjustedDebt");
        var pcrId = event.getParam("pcrId");
        var pcr = component.get("v.pcr");

        if (pcrId === pcr.Id) {
            pcr.Adjusted_Monthly_Personal_Debt__c = adjustedDebt;
            helper.updateAdjustedDTI(component, pcr.Adjusted_Income__c, adjustedDebt);
        }
    }
})
