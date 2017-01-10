trigger PCRApprovalTrigger on LASERCA__Personal_Credit_Report__c (before update, before insert, after insert) {
    PCRApprovalHandler handler = new PCRApprovalHandler(Trigger.isExecuting, Trigger.size);
    MapPCRtoLeadHandler handler1 = new MapPCRtoLeadHandler(Trigger.isExecuting, Trigger.size);
    ProductAssignmentHandler handler2 = new ProductAssignmentHandler(Trigger.isExecuting, Trigger.size);    

         if(Trigger.isUpdate && Trigger.isBefore){
                handler2.OnBeforePCRUpdate (Trigger.new);
                handler.OnBeforeUpdate (Trigger.new);
                handler1.OnBeforeUpdate (Trigger.new);
            }
         if(Trigger.isInsert && Trigger.isAfter){
             handler2.OnBeforePCRUpdate (Trigger.new);
         }
}