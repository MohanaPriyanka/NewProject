// Tested by JournalEntryServiceTest

trigger JournalEntryTrigger on Journal_Entry__c (before insert, before update, before delete) {
    if (Util.isDisabled('Disable_Journal_Entry_Trigger__c')) {
        return;
    }
    JournalEntryService service = new JournalEntryService();
    switch on Trigger.operationType {
        when BEFORE_INSERT {
            service.populateLookups(Trigger.new);
            service.markReadyForProductionDetail(Trigger.new);
        } when BEFORE_UPDATE {
            service.populateLookups(Trigger.new);
        } when BEFORE_DELETE {
            service.deleteProductionDetailsBeforeJEDeletion(Trigger.old);
        }
    }

}