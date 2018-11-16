/*************************************************************************************
 * Description: Calculates DTI and Emails applicant after PCR is inserted
 * Tested By: PCRApprovalHandlerTest
 *************************************************************************************/

trigger CreditReportLogTrigger on LASERCA__Credit_Report_Log__c (after insert, after update) {
    if (Trigger.isAfter && Trigger.isUpdate) {
        MapPCRtoLeadHandler.mapPCRtoLead(Trigger.newMap, Trigger.oldMap);
        PCRApprovalHandler.calcDTIAndEmailIfComplete(Trigger.newMap, Trigger.oldMap);
    } else if (Trigger.isAfter && Trigger.isInsert) {
        MapPCRtoLeadHandler.mapPCRtoLead(Trigger.newMap, null);
        PCRApprovalHandler.calcDTIAndEmailIfComplete(Trigger.newMap, null);
        PCRApprovalHandler.addMortgage(Trigger.newMap, null);
    }
}