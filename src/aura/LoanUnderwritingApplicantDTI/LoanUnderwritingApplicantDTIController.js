({
    handleIncomeAdjustment : function(component, event, helper) {
        var adjustedIncome = event.getParam("adjustedIncome");
        var pcrId = event.getParam("pcrId");
        var pcr = component.get("v.pcr");

        if (pcrId === pcr.Id) {
            pcr.Adjusted_Income__c = adjustedIncome;
            helper.updateAdjustedDTI(component, adjustedIncome, pcr.Adjusted_Monthly_Personal_Debt__c);
        }
    },
        
    handleDebtAdjustment : function(component, event, helper) {
        var adjustedDebt = event.getParam("adjustedDebt");
        var pcrId = event.getParam("pcrId");
        var pcr = component.get("v.pcr");

        if (pcrId === pcr.Id) {
            pcr.Adjusted_Monthly_Personal_Debt__c = adjustedDebt;
            component.set("v.pcr.DTI_Before__c", event.getParam("dtiBefore"));
            component.set("v.pcr.DTI_After__c", event.getParam("dtiAfter"));
        }
    }
})
