/**
 * @description Tested by CaseEscalationHandlerTest, CSApplicationStatusEvaluatorTest, roundRobinTests, TestCaseRoundRobin
 */
trigger CaseTrigger on Case ( before insert, after insert, after update, after delete, before delete ) {
    
    List<Case> records = Trigger.isDelete ? Trigger.old : Trigger.new;

    switch on Trigger.operationType {
        when AFTER_UPDATE, AFTER_INSERT {
            List<Case_Round_Robin_Queue_Ids__c> caseRRQIds = Case_Round_Robin_Queue_Ids__c.getAll().values();
            RoundRobinHandler rrh = new RoundRobinHandler(records,Trigger.oldMap,'Case',caseRRQIds);
            rrh.handleRoundRobinAssignments();
            if (Trigger.isInsert) {
                CaseEscalationHandler.linkTaskToCase(Trigger.new);
            }
            CSApplicationStatusEventPublisher.publishEvent(Trigger.oldMap, Trigger.new);
        } when BEFORE_INSERT {
            CaseEscalationHandler.findContactFromVM(Trigger.new);
        }
    }
}