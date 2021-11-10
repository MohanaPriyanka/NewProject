/**
 * @description Trigger on LASERCA__Credit_Report_Log__c
 * Tested By: CSQualificationTestclass
 */
trigger CreditReportLogTrigger on LASERCA__Credit_Report_Log__c (after insert, after update) {
    if (Util.isDisabled('Disable_CreditReportLogTrigger__c')) {
        return;
    }
    CSQualificationService csQualificationService = new CSQualificationService();
    if (Trigger.isAfter) {
        MapPCRtoLeadHandler.mapPCRtoLead(Trigger.newMap, Trigger.oldMap);
        csQualificationService.checkCreditReportLog(Trigger.newMap);
    }
}