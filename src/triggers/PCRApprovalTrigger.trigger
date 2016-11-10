trigger PCRApprovalTrigger on LASERCA__Personal_Credit_Report__c (before update) {
    PCRApprovalHandler handler = new PCRApprovalHandler(Trigger.isExecuting, Trigger.size);

         if(Trigger.isUpdate && Trigger.isBefore){
                handler.OnBeforeUpdate (Trigger.new);
            }
            
}