trigger ContentVersionTrigger on ContentVersion ( after insert ) {
    if(Trigger.isInsert && Trigger.isAfter){
        FileDeliveryHandler.createDistribution(Trigger.new);   
    }
}