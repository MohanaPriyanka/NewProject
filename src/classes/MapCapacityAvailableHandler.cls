// Jordan 12.9.2016 to replace trigger on lead

public with sharing class MapCapacityAvailableHandler {
    private boolean m_isExecuting = false;
    private Integer BatchSize = 0;
    
    public mapCapacityAvailableHandler (boolean isExecuting, Integer size){
        m_isExecuting = isExecuting;
        BatchSize = size;
    }
    
    public void OnBeforeInsert (Lead[] newLead){
      mapCapacityAvailable(newLead);
      }

     public void OnBeforeUpdate (Lead[] newLead){
      mapCapacityAvailable(newLead);
      }
      
    private void mapCapacityAvailable (List <Lead> trigleads){
  
        integer j;
        integer k;
        string partner;
        integer fico;
        string loadzone;
        string utility;

        List <Shared_Solar_System__c> listSSS = [ SELECT Id, Name, System_Utility__c, Service_Territory__c, Credit_Score_Requirement__c, Sales_Partners__c, Project_Capacity_Available_kW_DC__c
                                                  FROM Shared_Solar_System__c
                                                  WHERE Open__c = True];

        for(j = 0; j < trigleads.size(); j++){

          decimal totalavailablecapacity = 0;

          if(trigleads.get(j).LASER_Credit_Score__c == NULL){
            fico = 900;
          }

          else if (trigleads.get(j).LASER_Credit_Score__c != NULL){
            fico = Integer.valueof(trigleads.get(j).LASER_Credit_Score__c);
          }

          partner = 'blank';

          if(trigleads.get(j).Partner_Name__c != NULL){
            partner = trigleads.get(j).Partner_Name__c;
          }
          
           loadzone = trigleads.get(j).Load_Zone__c;
           utility = trigleads.get(j).Utility_1__c;

              for(k =0 ; k < listSSS.size(); k++){
                  system.debug(listsss.get(k).Sales_Partners__c);
                  string ssspartner = 'blank';

                  if(listsss.get(k).Sales_Partners__c != NULL){
                  ssspartner = listsss.get(k).Sales_Partners__c;
                  }

                  if(listSSS.get(k).System_Utility__c == utility && listSSS.get(k).Service_Territory__c == loadzone && listSSS.get(k).Credit_Score_Requirement__c <= fico){
                        system.debug(listSSS.get(k).Sales_Partners__c);
                            if(listSSS.get(k).Sales_Partners__c == 'All' || ssspartner.contains(partner) ){
                                  system.debug(listSSS.get(k).Name);
                                  totalavailablecapacity = totalavailablecapacity + listSSS.get(k).Project_Capacity_Available_kW_DC__c;
                            }
                  }
              }

           trigleads.get(j).Available_Capacity__c = totalavailablecapacity;   
        }      
  

  }
  }