Trigger customIdSwapLead on Lead (before insert, before update) {

    /*set <string> customIds = new Set <string>( ); 

    for ( lead l : trigger.new) {
    
        If ( l.custom_id__C != null) {
    
            customIds.add (l.custom_id__C);}
    }

    if ( customIds.size( ) > 0 ) {
    
        map <string, BSST__c> salesIdMap = new map <string, BSST__c> ( );
        
        try{
        
        for (BSST__c obj : [SELECT id, custom_id__C, partner__r.id, email__c FROM BSST__C WHERE custom_id__c IN : customIds] ) {

            salesIdMap.put (obj.custom_id__c, obj); 
        
        }}
        
          Catch(System.queryException e){
        
            return;}
        
        
    for ( lead l : trigger.new) {

        if ( trigger.isInsert || trigger.isUpdate) {
try{
            l.bs_sales_id__c = salesIdMap.get (l.custom_id__C).id;
            l.partner_email__c = salesIdMap.get(l.custom_id__c).email__c;
}

        Catch(System.NullPointerException e){
        
        return;
        }
        
            l.Partner_Lookup__c = salesIdMap.get (l.custom_id__c).partner__r.id;
            }
        

        else {
       
            l.bs_sales_id__c = null;
            l.partner_email__c = null;
    }
}
}*/
}