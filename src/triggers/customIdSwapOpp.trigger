Trigger customIdSwapOpp on Opportunity (before insert, before update) {

    set <string> customIds = new Set <string>( ); 

    for ( opportunity l : trigger.new) {
    
        If ( l.custom_id__C != null) {
    
            customIds.add (l.custom_id__C);}
    }

    if ( customIds.size( ) > 0 ) {
    
        map <string, BSST__c> salesIdMap = new map <string, BSST__c> ( );
        
        for (BSST__c obj : [SELECT id, custom_id__C FROM BSST__C WHERE custom_id__c IN : customIds] ) {

            salesIdMap.put (obj.custom_id__c, obj); 
        }

    for ( opportunity l : trigger.new) {

        if (( trigger.isInsert || trigger.oldMap.get(l.Id).custom_id__C != l.custom_id__C) && salesIdMap.containsKey (l.custom_id__C)) {

            l.bs_sales_id__c = salesIdMap.get (l.custom_id__C).id;
            }
        

        else if (
                Trigger.isUpdate &&
                Trigger.oldMap.get(l.Id).custom_id__c != l.custom_id__c &&
                !salesIdMap.containsKey(l.custom_id__c)){
 
        
            l.bs_sales_id__c = null;
    }
}
}
}