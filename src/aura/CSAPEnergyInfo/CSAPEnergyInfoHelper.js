({
    addUAL : function (component, event, helper) {
        var lead = component.get("v.lead");
        var ual = {
            sobjectType: "Utility_Account_Log__c"
        };
        ual.Same_Address__c = false;
        ual.Service_Zip_Code__c = lead.Parcel_Zip__c;

        var ualList = component.get("v.ualList");
        ualList.push(ual);
        helper.setDefaultUsageAmounts(component, event, helper);
    },

    setDefaultUsageAmounts : function (component, event, helper) {
        var lead = component.get("v.lead");
        var product = component.get("v.selectedProduct");
        var partnerApp = component.get("v.partnerApp");
        var ualList = component.get("v.ualList");

        if (partnerApp){

            var defaultAnnualkWh;
            var defaultAnnualCostofElectricity;
            if (product.Customer_Subscription_Type__c == "kWh"){
                if(lead.Application_Type__c == 'Non-Residential' && product.Default_Business_Usage__c != null){
                    defaultAnnualkWh = product.Default_Business_Usage__c;
                } else if(lead.Application_Type__c == 'Residential' && product.Default_Residential_Usage__c != null){
                    defaultAnnualkWh = product.Default_Residential_Usage__c;
                }
            } else if (product.Customer_Subscription_Type__c == "Electricity Cost ($)"){
                if(lead.Application_Type__c == 'Non-Residential' && product.Default_Business_Usage__c != null){
                    defaultAnnualCostofElectricity = product.Default_Business_Usage__c;
                } else if(lead.Application_Type__c == 'Residential' && product.Default_Residential_Usage__c != null){
                    defaultAnnualCostofElectricity = product.Default_Residential_Usage__c;
                }
            }
            for(var i = 0; i < ualList.length; i++) {
                var ualItem = ualList[i];
                if (ualItem.Annual_kWh__c == null && defaultAnnualkWh != null) {
                    ualItem.Annual_kWh__c = defaultAnnualkWh;
                }
                if (ualItem.Annual_Cost_of_Electricity__c == null && defaultAnnualCostofElectricity != null) {
                    ualItem.Annual_Cost_of_Electricity__c = defaultAnnualCostofElectricity;
                }
                component.set("v.ualList", ualList);
            }
        }
    }
})