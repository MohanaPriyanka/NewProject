trigger ContentVersionTrigger on ContentVersion ( after insert ) {
    if(Trigger.isInsert && Trigger.isAfter){
        ContentService.createDistribution(Trigger.new);   
    }
}