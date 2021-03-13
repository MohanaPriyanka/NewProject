/*************************************************************************************
 * Tested By: CSAPControllerTest
 *************************************************************************************/

trigger CreditReportLogTrigger on LASERCA__Credit_Report_Log__c (after insert, after update) {
    if (Trigger.isAfter) {
        MapPCRtoLeadHandler.mapPCRtoLead(Trigger.newMap, Trigger.oldMap);
        CSQualificationService.checkCreditReportLog(Trigger.newMap, Trigger.oldMap);
    }
}