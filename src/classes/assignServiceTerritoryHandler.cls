public with sharing class assignServiceTerritoryHandler {
    private boolean m_isExecuting = false;
    private Integer BatchSize = 0;
    
    public assignServiceTerritoryHandler(boolean isExecuting, Integer size){
        m_isExecuting = isExecuting;
        BatchSize = size;
    }

      public void OnBeforeInsert (Lead [] newLeads){
          List<lead> leadListToExecute = new List<lead>();
          for(Lead l : newLeads){
              if(l.Product_Line__c == 'Community Solar'){
                  leadListToExecute.add(l);
              }
          }
          if(leadListToExecute.size() > 0){
              assignServiceTerritory(leadListToExecute);  
          }    
      }     
      public void OnBeforeUpdate (Lead [] newLeads){
          List<lead> leadListToExecute = new List<lead>();
          for(Lead l : newLeads){
              if(l.Product_Line__c == 'Community Solar'){
                  leadListToExecute.add(l);
              }
          }
          if(leadListToExecute.size() > 0){
              assignServiceTerritory(leadListToExecute);  
          }   
      }

      private void assignServiceTerritory (List <Lead> trigLeads){

            set <string> leadzips = new Set <string>( );
            map <string, Service_territory__c> mapServiceTerritory = new map <String, Service_territory__c> ( );
            string zipKey;
            integer j;
            integer k;

            for(j = 0; j < trigLeads.size(); j++){
                 leadzips.add (trigLeads.get(j).Parcel_zip__c);
             }
        
            if (leadzips.size( ) > 0 ) {
                    for (Service_territory__c obj : [SELECT Id, Name, City__c, Service_territory__c 
                                                     FROM Service_territory__c 
                                                     WHERE Name IN : leadZips] ) {                                                   
                    mapServiceTerritory.put (obj.Name, obj); 
                    }
            }
            for(k=0; k < trigLeads.size(); k++){
                zipKey = trigLeads.get(k).Parcel_zip__c; 
                if(mapServiceTerritory.containsKey (zipKey)){ 
                    trigLeads.get(k).Service_territory__c = mapServiceTerritory.get(zipkey).Service_territory__c;
                }else {
                    trigLeads.get(k).Service_territory__c = null;
                }
            }
      }
}