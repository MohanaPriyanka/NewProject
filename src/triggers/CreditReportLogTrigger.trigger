/*************************************************************************************
 * Description: Calculates DTI and Emails applicant after PCR is inserted
 * Tested By: PCRApprovalHandlerTest
 *************************************************************************************/

trigger CreditReportLogTrigger on LASERCA__Credit_Report_Log__c (after insert, after update) {
    System.debug(LoggingLevel.ERROR, 'CreditReportLogTrigger Update: ' + Trigger.isUpdate + ' Before: ' + Trigger.isBefore);
    if (Trigger.isAfter && Trigger.isUpdate) {
        PCRApprovalHandler.calcDTIAndEmailIfComplete(Trigger.newMap, Trigger.oldMap);
    } else if (Trigger.isAfter && Trigger.isInsert) {
        PCRApprovalHandler.calcDTIAndEmailIfComplete(Trigger.newMap, null);
    }
}