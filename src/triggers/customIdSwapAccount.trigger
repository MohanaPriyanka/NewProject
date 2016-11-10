Trigger customIdSwapAccount on Account (before insert, before update) {

    set <string> customIds = new Set <string>( ); 

    for ( Account l : trigger.new) {
    
        If ( l.Custom_Id__c!= null) {
    
            customIds.add (l.Custom_Id__c);}
    }

    if ( customIds.size( ) > 0 ) {
    
        map <string, BSST__c > salesIdMap = new map <string, BSST__c > ( );
        
        try{
        
        for (BSST__c obj : [SELECT id, custom_id__C, partner__r.id FROM BSST__C WHERE custom_id__c IN : customIds] ) {

            salesIdMap.put (obj.custom_id__c, obj); 
        
        }}
        
          Catch(System.queryException e){
        
            return;}
        
        
    for ( account l : trigger.new) {

        if ( trigger.isInsert || trigger.isUpdate) {
try{
            l.sales_representative__c = salesIdMap.get (l.custom_id__C).id;
            
}

        Catch(System.NullPointerException e){
        
        return;
        }
        
            l.partner__c = salesIdMap.get (l.custom_id__c).partner__r.id;
            }
        

        else {
       
            l.sales_representative__c = null;
            l.partner__c = null;
    }
}
}
}