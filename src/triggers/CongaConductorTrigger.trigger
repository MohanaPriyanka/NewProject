trigger CongaConductorTrigger on APXT_BPM__Conductor__c (after update) {    
    if (Trigger.isUpdate && Trigger.isAfter){       
        List <APXT_BPM__Conductor__c> triggeredConductorList = new List <APXT_BPM__Conductor__c> ();
        
        for (APXT_BPM__Conductor__c conductor : Trigger.new) {  
            if (conductor.Emails_Sent__c) {
                Id newvalueID = conductor.Id;
                Boolean newBox = conductor.Emails_Sent__c;
                Boolean oldBox = Trigger.OldMap.get(newvalueID).Emails_Sent__c;
                    if (newBox && !oldBox) { 
                        triggeredConductorList.add(conductor);
                    } 
            }
        } 

        if (triggeredConductorList.size() > 0) {
            BatchCSBillEmailHandler sendCSEmails = new BatchCSBillEmailHandler (); 
            Id batchId = Database.executeBatch(sendCSEmails, 10);   
        }
    }
}