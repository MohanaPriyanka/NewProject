public with sharing class assignServiceTerritoryHandler {
    private boolean m_isExecuting = false;
    private Integer BatchSize = 0;
    
    public assignServiceTerritoryHandler(boolean isExecuting, Integer size){
        m_isExecuting = isExecuting;
        BatchSize = size;
    }

      public void OnBeforeInsert (Lead [] newLead){
          assignServiceTerritory(newLead);
          }

      
      public void OnBeforeUpdate (Lead [] newLead){
          assignServiceTerritory(newLead);
          }

      private void assignServiceTerritory (List <Lead> trigLeads){

            set <string> leadzips = new Set <string>( );
            map <string, service_territory__c> mapServiceTerritory = new map <string, service_territory__c> ( );
            string zipkey;
            integer j;
            integer k;


            for(j = 0; j < trigLeads.size(); j++){
                 leadzips.add (trigLeads.get(j).parcel_zip__c);
             }
        
            if ( leadzips.size( ) > 0 ) {
                    for (service_territory__c obj : [SELECT Id, name, city__c, service_territory__c 
                                                     FROM service_territory__c 
                                                     WHERE name IN : leadzips] ) {
                                                    
                                                     mapServiceTerritory.put (obj.name, obj); 
                    }
            }

            for(k=0; k < trigLeads.size(); k++){
                zipkey = trigLeads.get(k).parcel_zip__c; 
                if(mapServiceTerritory.containsKey (zipkey)){ 
                    trigLeads.get(k).service_territory__c = mapServiceTerritory.get(zipkey).service_territory__c;
                }    

                else {trigLeads.get(k).service_territory__c = null;
                }
            }
    }
    }