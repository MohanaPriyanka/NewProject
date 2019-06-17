/*************************************************************************************
 * Test: LeadTriggerHandlerTest,assignServiceTerritoryTest,UtilityAccountLogConvertTestClass,mapAvailableCapacityTest,ReferralCodeHandlerTest
 *************************************************************************************/

trigger LeadTrigger on Lead (before insert, after insert, before update, after update ) {
    if (Util.isDisabled('Disable_LeadTrigger__c')) {
        return;
    }
    //Make call to LeadHandler to determine if Switch or CSAP/Web/Loan Lead
    LeadDispatcher leadHandler = new LeadDispatcher();
    LoanHandler loanHandler = new LoanHandler (Trigger.isExecuting, Trigger.size);

    if(Trigger.isUpdate && Trigger.isAfter){
        leadHandler.onAfterUpdate(Trigger.new, Trigger.oldMap);
        loanHandler.OnAfterLeadUpdate(Trigger.new, Trigger.old, Trigger.newMap, Trigger.oldMap);
    }
    else if(Trigger.isUpdate && Trigger.isBefore){
        leadHandler.onBeforeUpdate(Trigger.new, Trigger.oldMap);
        loanHandler.OnBeforeLeadUpdate(Trigger.newMap, Trigger.oldMap);

    }  

    else if(Trigger.isInsert && Trigger.isBefore){
        leadHandler.onBeforeInsert(Trigger.new);
    }
}