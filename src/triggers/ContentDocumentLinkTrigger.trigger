trigger ContentDocumentLinkTrigger on ContentDocumentLink (after insert) {
    if (Util.isDisabled('Disable_ContentDocumentLinkTrigger__c')) {
        return;
    }
    if(Trigger.isInsert && Trigger.isAfter){
          FileDeliveryHandler.findRelatedObject(Trigger.new);   
    }
}