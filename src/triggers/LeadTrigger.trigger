/*************************************************************************************
 * Test: LeadTriggerHandlerTest,UtilityAccountLogConvertTestClass,ReferralCodeHandlerTest,CSApplicationStatusEvaluatorTest
 *************************************************************************************/

trigger LeadTrigger on Lead (before insert, after insert, before update, after update ) {
    if (Util.isDisabled('Disable_LeadTrigger__c')) {
        return;
    }
    //Make call to LeadHandler to determine if Switch or CSAP/Web/Loan Lead
    LeadDispatcher leadDispatcher = new LeadDispatcher();

    switch on Trigger.operationType {
        when AFTER_UPDATE {
            leadDispatcher.onAfterUpdate(Trigger.new, Trigger.oldMap);
            CSApplicationStatusEventPublisher.publishEvent(Trigger.oldMap, Trigger.new);
        }
        when BEFORE_UPDATE {
            leadDispatcher.onBeforeUpdate(Trigger.new, Trigger.oldMap);
        }
        when BEFORE_INSERT {
            leadDispatcher.onBeforeInsert(Trigger.new);
        }
        when AFTER_INSERT {
            leadDispatcher.checkForDuplicates(Trigger.new);
            CSApplicationStatusEventPublisher.publishEvent(null, Trigger.new);
        }
    }
}