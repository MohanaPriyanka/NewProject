// CS Template assignment and email sending is only triggered off the conga conductor because it is where users
// are currently generating conga pdf records.

trigger CongaConductorTrigger on APXT_BPM__Conductor__c (after update) {
    if (Trigger.isUpdate && Trigger.isAfter){      
        OverpaymentApplication.triggerApplication(Trigger.oldMap, Trigger.new);
        BatchCSBillEmailHandler emailSend = new BatchCSBillEmailHandler(Trigger.oldMap, Trigger.new);
        CongaTemplateAssigner templateAssigner = new CongaTemplateAssigner(Trigger.oldMap, Trigger.new);
        templateAssigner.executeBatch();
    }
}