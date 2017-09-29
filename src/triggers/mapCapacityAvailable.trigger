Trigger mapCapacityAvailable on Lead (before insert, before update) {

    set <string> loadZones = new Set <string>( ); 
    set <string> utilities = new set <string>( );
    
    decimal totalAvailableCapacity;

    for ( Lead l : trigger.new) {
    
        If ( (trigger.isInsert || trigger.isUpdate) && (l.Load_Zone__c != null && l.Utility_1__c!= null) ) {
    
            loadZones.add (l.Load_Zone__c );
            utilities.add (l.utility_1__c );
            
            }
    }

    if ( loadZones.size( ) > 0 && utilities.size( ) > 0) {

        Aggregateresult availableCapacity = [SELECT sum(Project_Capacity_Available_kW_DC__c)sumCap 
        FROM shared_solar_system__c 
        WHERE System_Utility__c IN : utilities AND Service_Territory__c IN : loadZones AND open__c = TRUE];
        
         totalAvailableCapacity = (decimal)availableCapacity.get('sumCap');
                
         }
         
    else{
    
        return;}    
    
        
    for ( Lead l : trigger.new) {

       If ( (trigger.isInsert || trigger.isUpdate) && (l.Load_Zone__c != null && l.Utility_1__c!= null) ) {
         
                l.available_capacity__c = totalAvailableCapacity;
          
        }

        else {

            l.available_capacity__c = null;
    }
}
}