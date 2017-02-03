trigger PCRApprovalTrigger on LASERCA__Personal_Credit_Report__c (before update, before insert, after insert, after update) {
    PCRApprovalHandler handler = new PCRApprovalHandler(Trigger.isExecuting, Trigger.size);
    MapPCRtoLeadHandler handler1 = new MapPCRtoLeadHandler(Trigger.isExecuting, Trigger.size);
    ProductAssignmentHandler handler2 = new ProductAssignmentHandler(Trigger.isExecuting, Trigger.size);    

         if(Trigger.isUpdate && Trigger.isBefore){              
                handler2.OnBeforePCRUpdate (Trigger.new); //Assign Product    
                handler1.OnBeforeUpdate (Trigger.new); // Map the Report to the Lead 
                handler.OnBeforeUpdate (Trigger.new);               
         }           
         if(Trigger.isUpdate && Trigger.isAfter){
                               
         }             
         if(Trigger.isInsert && Trigger.isAfter){     
         }                
         if(Trigger.isInsert && Trigger.isBefore){
          handler2.OnBeforePCRUpdate (Trigger.new); //Assign Product                      
         }
}