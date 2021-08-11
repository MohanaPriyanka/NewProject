/*************************************************************************************
 * Tested By: CSAPControllerTest
 *************************************************************************************/

trigger CreditReportLogTrigger on LASERCA__Credit_Report_Log__c(
  after insert,
  after update
) {
  CSQualificationService csQualificationService = new CSQualificationService();
  if (Trigger.isAfter) {
    MapPCRtoLeadHandler.mapPCRtoLead(Trigger.newMap, Trigger.oldMap);
    csQualificationService.checkCreditReportLog(Trigger.newMap, Trigger.oldMap);
  }
}