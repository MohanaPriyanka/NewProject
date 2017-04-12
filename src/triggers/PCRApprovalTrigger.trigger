/*************************************************************************************
 * Description: Personal Credit Check Approval Status
 * Tested By: TestPCRapproval, mapPCRTestClass, LoanProductAssignmentHandlerTestClass
 *************************************************************************************/

trigger PCRApprovalTrigger on LASERCA__Personal_Credit_Report__c (before update, before insert, after insert, after update) {
    PCRApprovalHandler pcrApprovalHandler = new PCRApprovalHandler();
    MapPCRtoLeadHandler mapPCRtoLeadHandler = new MapPCRtoLeadHandler(Trigger.isExecuting, Trigger.size);
    ProductAssignmentHandler productAssignmentHandler = new ProductAssignmentHandler(Trigger.isExecuting, Trigger.size);    

    if (Trigger.isUpdate && Trigger.isBefore) {
        productAssignmentHandler.OnBeforePCRUpdate (Trigger.new);
        mapPCRtoLeadHandler.OnBeforeUpdate (Trigger.new);
        pcrApprovalHandler.OnBeforeUpdate (Trigger.new);
    }

    if (Trigger.isInsert && Trigger.isBefore) {
        productAssignmentHandler.OnBeforePCRUpdate (Trigger.new);
    }
}