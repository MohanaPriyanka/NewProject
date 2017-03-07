trigger partnerAlertTrigger on Partner_Alert__c (before insert, before update, after insert, after update) {
    PartnerAlertHandler partnerAlertHandler = new PartnerAlertHandler();
    
    if(Trigger.isInsert && Trigger.isAfter){        
        partnerAlertHandler .OnAfterInsert(Trigger.new);
    }
}