/*************************************************************************************
 * Description: Personal Credit Check Approval Status
 * Tested By: TestPCRapproval, mapPCRTestClass
 *************************************************************************************/

trigger PCRApprovalTrigger on LASERCA__Personal_Credit_Report__c (before update, before insert, after insert, after update) {
    if (Trigger.isUpdate && Trigger.isBefore) {
        // Whenever a PCR is updated calculate DTI if the PCR isn't in the insert process (if it's old)
        PCRApprovalHandler.calcDTIAndEmailOnlyOld(Trigger.new);
    }
}