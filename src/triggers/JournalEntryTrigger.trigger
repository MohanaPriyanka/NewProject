// Tested by JournalEntryServiceTest

trigger JournalEntryTrigger on Journal_Entry__c (before insert, before update) {
    if (Util.isDisabled('Disable_Journal_Entry_Trigger__c')) {
        return;
    }
    JournalEntryService service = new JournalEntryService();
    service.populateLookups(Trigger.new);
}