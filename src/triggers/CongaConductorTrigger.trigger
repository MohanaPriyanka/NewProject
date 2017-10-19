trigger CongaConductorTrigger on APXT_BPM__Conductor__c (after update) {    
    if (Trigger.isUpdate && Trigger.isAfter){       
        List <APXT_BPM__Conductor__c> triggeredConductorList = new List <APXT_BPM__Conductor__c> ();
        
        for (APXT_BPM__Conductor__c conductor : Trigger.new) {  
            if (conductor.Emails_Sent__c && !Trigger.OldMap.get(conductor.Id).Emails_Sent__c ) {
                triggeredConductorList.add(conductor);
            }
        } 

        if (triggeredConductorList.size() > 0) {
            BatchCSBillEmailHandler sendCSEmails = new BatchCSBillEmailHandler (); 
            Id batchId = Database.executeBatch(sendCSEmails, 10);   
        }
    }
}