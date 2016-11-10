Trigger nmcCustomIdTrigger on Opportunity (before insert, before update) {
/*
    set <string> customIds = new Set <string>( ); 
    string NMCvariable;

    for ( Opportunity l : trigger.new) {
    
        If ( l.Tariff_Custom_ID__c!= null && (l.NMC_Tariff_Method__c == null || l.NMC_Tariff_Method__c == 'Automatic')) {
    
            NMCvariable = l.utilitymapper__c + ' ' + l.service_territory__c + ' ' + l.project_class__c;
            
            customIds.add (NMCvariable);}
    }

    if ( customIds.size( ) > 0 ) {
    
        map <string, Utility_NMC_Tariff__c> TariffIdMap = new map <string, Utility_NMC_Tariff__c> ( );
        
        for (Utility_NMC_Tariff__c obj : [SELECT id, name FROM Utility_NMC_Tariff__c WHERE name IN : customIds] ) {

            TariffIdMap.put (obj.name, obj); 
        }

    for ( Opportunity l : trigger.new) {

        if (( trigger.isUpdate || trigger.isInsert || trigger.oldMap.get(l.Id).Tariff_Custom_ID__c!= l.Tariff_Custom_ID__c) && TariffIdMap.containsKey (l.Tariff_Custom_ID__c)) {

            l.NMC_Tariff__c = tariffIdMap.get (l.Tariff_Custom_ID__c).id;
            }
        

        else (

        
            l.NMC_Tariff__c = null);
    }
}*/
}