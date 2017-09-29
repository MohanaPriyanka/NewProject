trigger addUtilityLogCost on Opportunity (before insert, before update){

    //Decimal totalULCost;
    //Decimal totalSubCostStatic;
    //Decimal totalSubCostDynamic;

    //Set<String> oppIdSet = new Set<String>();

    //for(Opportunity opp : Trigger.new){
    //    if(Trigger.isInsert || Trigger.isUpdate){
    //        oppIdSet.add(opp.Id);
    //    }
    //}

    //if(oppIdSet.size() > 0) {
    //    try{
    //        Aggregateresult utilityLogCosts = [ SELECT Sum(subscribed_annual_cost_of_electricity__c) sumUlCosts, 
    //                                                   Sum(Customer_Subscription_kW_DC_STATIC__c)sumULsubsStatic, 
    //                                                   Sum(Customer_Subscription_kW_DC__c)sumULsubsDynamic
    //                                            FROM utility_account_subscription__c 
    //                                            WHERE Opportunity__c IN : oppIdSet AND Opportunity__c != null];
    //        totalULCost = (Decimal)utilityLogCosts.get('sumUlCosts');
    //        totalSubCostStatic = (Decimal)utilityLogCosts.get('sumUlSubsStatic');
    //        totalSubCostDynamic = (Decimal)utilityLogCosts.get('sumUlSubsDynamic');}

    //    catch(system.queryexception e ){
    //        return;
    //    }
    //}
    //if( totalULCost > 0) {
    //    for(Opportunity opp : Trigger.new){
    //        if(opp.Annual_Electricity_cost_method__c == null || opp.Annual_Electricity_cost_method__c == 'Utility Log Calculator'){
    //            if(Trigger.isInsert || Trigger.isUpdate){
    //                if(opp.stageName == 'Complete'){
    //                    opp.Annual_Electricity_Cost__c = totalULCost;
    //                    opp.CS_Capacity_Allocated__c = totalSubCostStatic;
    //                }
    //                if(opp.stageName != 'Complete'){
    //                    opp.Annual_Electricity_Cost__c = totalULCost;
    //                    opp.CS_Capacity_Allocated__c = totalSubCostDynamic;
    //                }
    //            }
    //            else{
    //                opp.Annual_Electricity_Cost__c  = null;
    //                opp.CS_Capacity_Allocated__c = null;
    //            }
    //        }
    //    }
    //}
}