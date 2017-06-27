trigger ContentDocumentLinkTrigger on ContentDocumentLink (after insert) {
    if(Trigger.isInsert && Trigger.isAfter){
          FileDeliveryHandler.findRelatedObject(Trigger.new);   
    }
}