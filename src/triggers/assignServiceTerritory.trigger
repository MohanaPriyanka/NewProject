Trigger assignServiceTerritory on Lead (before insert, before update) {

  /*  set <string> leadIds = new Set <string>( ); 

    for ( lead l : trigger.new) {
    
        If ( trigger.isInsert || trigger.isUpdate) {
    
            leadIds.add (l.parcel_zip__c);}
    }

    if ( leadIds.size( ) > 0 ) {
    
        map <string, service_territory__c> mapServiceTerritory = new map <string, service_territory__c> ( );
        
        for (service_territory__c obj : [SELECT Id, name, city__c, service_territory__c FROM service_territory__c WHERE name IN : leadIds] ) {

            mapServiceTerritory.put (obj.name, obj); 
        }

    for ( lead l : trigger.new) {

        if ( trigger.isInsert || trigger.isUpdate ){
         
            if(mapServiceTerritory.containsKey (l.parcel_zip__c)){

               l.service_territory__c = mapServiceTerritory.get (l.parcel_zip__c).service_territory__c;
            
            }
        }

        else  {

            l.service_territory__c = null;
    }
}
} */
}