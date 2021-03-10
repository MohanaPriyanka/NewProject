/*************************************************************************************
 * Tested By: CSAPControllerTest
 *************************************************************************************/

trigger CreditReportLogTrigger on LASERCA__Credit_Report_Log__c (after insert, after update) {
    switch on Trigger.operationType {
        when AFTER_UPDATE {
            MapPCRtoLeadHandler.mapPCRtoLead(Trigger.newMap, Trigger.oldMap);
            CSQualificationService.checkCreditReportLog(Trigger.newMap, Trigger.oldMap);
        } when AFTER_INSERT {
            MapPCRtoLeadHandler.mapPCRtoLead(Trigger.newMap, null);
            CSQualificationService.checkCreditReportLog(Trigger.newMap, null);
        }
    }
}