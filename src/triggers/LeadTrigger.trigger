/*************************************************************************************
 * Test: LeadTriggerHandlerTest,assignServiceTerritoryTest,UtilityAccountLogConvertTestClass,mapAvailableCapacityTest,ReferralCodeHandlerTest
 *************************************************************************************/

trigger LeadTrigger on Lead (before insert, after insert, before update, after update ) {
    LeadTriggerHandler leadTriggerHandler = new LeadTriggerHandler();
    AssignServiceTerritoryHandler assignServiceTerritoryHandler = new AssignServiceTerritoryHandler(Trigger.isExecuting, Trigger.size);
    UtilityAccountLogConversionHandler utilityAccountLogConversionHandler = new UtilityAccountLogConversionHandler(Trigger.isExecuting, Trigger.size);
    ReferralCodeHandler referralCodeHandler  = new ReferralCodeHandler();
    LoanHandler loanHandler = new LoanHandler (Trigger.isExecuting, Trigger.size);

    if(Trigger.isUpdate && Trigger.isAfter){
        leadTriggerHandler.onAfterUpdate(Trigger.old, Trigger.new, Trigger.oldMap);
        loanHandler.OnAfterLeadUpdate(Trigger.new, Trigger.old, Trigger.newMap, Trigger.oldMap);
    }
    else if(Trigger.isUpdate && Trigger.isBefore){
        leadTriggerHandler.onBeforeUpdate(Trigger.old, Trigger.new, Trigger.oldMap, Trigger.newMap);
        assignServiceTerritoryHandler.OnBeforeUpdate(Trigger.new);
        utilityAccountLogConversionHandler.OnBeforeUpdate(Trigger.new);
        referralCodeHandler.OnBeforeUpdate(Trigger.oldMap, Trigger.newMap);
        loanHandler.OnBeforeLeadUpdate(Trigger.newMap, Trigger.oldMap);
    }  
    else if(Trigger.isInsert && Trigger.isBefore){
        leadTriggerHandler.onBeforeInsert(Trigger.new);
        assignServiceTerritoryHandler.OnBeforeInsert(Trigger.new);
        referralCodeHandler.OnBeforeInsert(Trigger.new);
    }
}