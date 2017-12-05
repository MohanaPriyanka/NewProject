trigger CongaConductorTrigger on APXT_BPM__Conductor__c (after update) {    
    if (Trigger.isUpdate && Trigger.isAfter){      
        OverpaymentApplication.triggerApplication(Trigger.oldMap, Trigger.new);
        BatchCSBillEmailHandler emailSend = new BatchCSBillEmailHandler(Trigger.oldMap, Trigger.new);
    }
}