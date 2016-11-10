public with sharing class mapPCRHandler {
    private boolean m_isExecuting = false;
    private Integer BatchSize = 0;
    
    public mapPCRHandler(boolean isExecuting, Integer size){
        m_isExecuting = isExecuting;
        BatchSize = size;
    }
      
      public void OnBeforeUpdate (Lead [] newLead){
          mapPCR(newLead);
          }

      private void mapPCR (List <Lead> trigLeads){
            list <string> leadids = new list <string>( );
            map <Id, Lead> leadmap = new map <id, Lead> ();
            string leadID;
            string shortID;
            string subkey;
            string leadkey;
            integer j;
            integer k;


            for(j = 0; j < trigLeads.size(); j++){
                 leadmap.put(trigLeads.get(j).id, trigLeads.get(j));
                 leadID = trigLeads.get(j).Id;
                 shortID = leadID.substring(0,15);
                 leadids.add (shortID);
                 system.debug(leadID);
                 system.debug(shortID);
                 system.debug(leadids);
             }
        
          
            List <LASERCA__Personal_Credit_Report__c> listPCRs = [SELECT  Id, name, LASERCA__Lead__c, PCR_Lead_ID__c, LASERCA__Contact__c, Maximum_Disbursement_Monthly__c
                                                                  FROM LASERCA__Personal_Credit_Report__c 
                                                                  WHERE PCR_Lead_ID__c IN : leadids] ;
            system.debug(listPCRs);

           

          for(j = 0; j < trigLeads.size(); j++){
              subkey = trigleads.get(j).Id;
              leadkey = subkey.substring(0,15);
              system.debug(leadkey);
              
                          for (k=0; k < listPCRs.size(); k++){
                             system.debug(listPCRs.get(k).Id);
                             system.debug(listPCRs.get(k).PCR_Lead_ID__c);
                             system.debug(listPCRs.get(k).LASERCA__Contact__c);
                             system.debug(leadmap.get(listPCRs.get(k).LASERCA__Lead__c));
                             
                                    if (listPCRs.get(k).PCR_Lead_ID__c == leadkey && listPCRs.get(k).LASERCA__Contact__c != NULL){                                        
                                        if(leadmap.get(listPCRs.get(k).LASERCA__Lead__c).Personal_Credit_Report_Co_Applicant__c == NULL){
                                            leadmap.get(listPCRs.get(k).LASERCA__Lead__c).Personal_Credit_Report_Co_Applicant__c = listPCRs.get(k).Id;
                                        }
                                        leadmap.get(listPCRs.get(k).LASERCA__Lead__c).Maximum_monthly_Disbursement__c = listPCRs.get(k).Maximum_Disbursement_Monthly__c;
                                    }

                                    else if (listPCRs.get(k).PCR_Lead_ID__c == leadkey && listPCRs.get(k).LASERCA__Contact__c == NULL){
                                        if(leadmap.get(listPCRs.get(k).LASERCA__Lead__c).Personal_Credit_Report__c == NULL){
                                            leadmap.get(listPCRs.get(k).LASERCA__Lead__c).Personal_Credit_Report__c = listPCRs.get(k).Id; 
                                        }
                                        leadmap.get(listPCRs.get(k).LASERCA__Lead__c).Maximum_monthly_Disbursement__c = listPCRs.get(k).Maximum_Disbursement_Monthly__c;
                                    }
                                    
                                    else {leadmap.get(listPCRs.get(k).LASERCA__Lead__c).Personal_Credit_Report__c = NULL;} 
                          }
                          
          }

}
}