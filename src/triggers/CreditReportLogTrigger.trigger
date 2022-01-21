/**
 * @description Trigger on LASERCA__Credit_Report_Log__c
 * Tested By: CSQualificationTestclass, LeadServiceTestclass
 */
trigger CreditReportLogTrigger on LASERCA__Credit_Report_Log__c (after insert, after update) {
    if (Util.isDisabled('Disable_CreditReportLogTrigger__c')) {
        return;
    }
    CSQualificationService csQualificationService = new CSQualificationService();
    try {
        switch on Trigger.operationType {
            when AFTER_INSERT {
                MapPCRtoLeadHandler.mapPCRtoLeadAfterInsert(Trigger.new);
                csQualificationService.checkCreditReportLog(Trigger.newMap);
            } when AFTER_UPDATE {
                MapPCRtoLeadHandler.mapPCRtoLeadAfterUpdate(Trigger.newMap, Trigger.oldMap);
                csQualificationService.checkCreditReportLog(Trigger.newMap);
            }
        }
    } catch (Exception e) {
        Logger.logNow('CreditReportLogTrigger', Trigger.operationType.name(), e.getMessage() + '\n' + e.getStackTraceString(), Logger.ERROR);
    }
}