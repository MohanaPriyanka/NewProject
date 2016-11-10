Trigger updateLZUL on Lead (before insert, before update) {

    set <string> ZipCodes = new Set <string>( ); 

    for ( Lead l : trigger.new) {
    
        If ( l.Parcel_Zip__c != null) {
    
            ZipCodes.add (l.Parcel_Zip__C);}
    }

    if ( ZipCodes.size( ) > 0 ) {
    
        map <string, Load_u__c> validLZU = new map <string, Load_u__c> ( );
        
        for (Load_u__c obj : [SELECT Id, name, Load_Zone__C, LZ__c, utility__c FROM Load_u__C WHERE name IN : ZipCodes] ) {

            validLZU.put (obj.name, obj); 
        }

    for ( Lead l : trigger.new) {

        if ( trigger.isInsert || trigger.oldMap.get(l.Id). Parcel_Zip__c != l.Parcel_Zip__C){
         
            if(validLZU.containsKey (l.Parcel_Zip__c)){

                l.LZU__c = validLZU.get (l.Parcel_Zip__C).Load_Zone__C;
                l.Load_Zone__c = validLZU.get (l.Parcel_Zip__c).LZ__C;
                l.Utility_1__c = validLZU.get(l.Parcel_Zip__C).Utility__c;
            
            }
        }

        else if(trigger.oldMap.get(l.iD).Parcel_Zip__c != l.Parcel_Zip__C && !validLZU.containsKey(l.Parcel_Zip__C)) {

            l.LZU__C = null;
            l.Load_Zone__C = null;
            l.Utility_1__C = null;
    }
}
}
}