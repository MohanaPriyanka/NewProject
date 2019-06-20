/*************************************************************************************
 * Description: Calculates DTI and Emails applicant after PCR is inserted
 * Tested By: PCRApprovalHandlerTest
 *************************************************************************************/

trigger CreditReportLogTrigger on LASERCA__Credit_Report_Log__c (after insert, after update) {
    if (Trigger.isAfter && Trigger.isUpdate) {
        MapPCRtoLeadHandler.mapPCRtoLead(Trigger.newMap, Trigger.oldMap);
        CSQualificationService.checkCSQualification(Trigger.newMap, Trigger.oldMap);
            //only want to update if status has changed to complete or a PCR has been returned
        PCRApprovalHandler.calcDTIAndEmailIfComplete(Trigger.newMap, Trigger.oldMap);
    } else if (Trigger.isAfter && Trigger.isInsert) {
        MapPCRtoLeadHandler.mapPCRtoLead(Trigger.newMap, null);
        CSQualificationService.checkCSQualification(Trigger.newMap, null);
        PCRApprovalHandler.calcDTIAndEmailIfComplete(Trigger.newMap, null);
        PCRApprovalHandler.addMortgage(Trigger.newMap, null);
    }
}