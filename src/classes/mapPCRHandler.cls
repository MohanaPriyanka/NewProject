public with sharing class mapPCRHandler {
    private boolean m_isExecuting = false;
    private Integer BatchSize = 0;
    
    public mapPCRHandler(boolean isExecuting, Integer size){
        m_isExecuting = isExecuting;
        BatchSize = size;
    }
      
    public void OnBeforeUpdate (Lead [] newLead, Map<ID, Lead> oldLeadsMap){
          mapPCR(newLead, oldLeadsMap);
    }
   
    private void mapPCR (List <Lead> leadList, Map<ID, Lead> oldLeadsMap){
            list <string> leadids = new list <string>( );
            map <Id, Lead> leadmap = new map <id, Lead> ();
            string leadID;
            string shortID;
            string leadKey;
            string subKey;

      List<Contact> contactList = [SELECT Id, Name, Lead__c, Lead__r.Id FROM Contact];

      for(lead leadRecord : leadList){
        leadMap.put(leadRecord.Id, leadRecord);
        leadId = leadRecord.Id;
        shortId = leadId.subString(0,15);
        leadIds.add(shortId);
      }
      for (LASERCA__Personal_Credit_Report__c pcrRecord : [SELECT  Id, Name, Approval_Status__c, LASERCA__Lead__c,LASERCA__Lead__r.Personal_Credit_Report_Co_Applicant__c, PCR_Lead_ID__c, Product_line__c, 
                                                              LASERCA__Contact__c, Maximum_Disbursement_Monthly__c 
                                                            FROM LASERCA__Personal_Credit_Report__c 
                                                            WHERE PCR_Lead_ID__c IN : leadids]){
        for (lead leadRecord : leadMap.values()){
          leadkey = leadRecord.Id;
          subKey = leadKey.substring(0,15);  
          System.debug('MapPCR Execute');  
          if(pcrRecord.PCR_Lead_ID__c == leadRecord.Id && pcrRecord.LASERCA__Contact__c == null && pcrRecord.Product_line__c == 'Residential Loan'){
            leadRecord.Personal_Credit_Report__c = pcrRecord.Id;
            leadRecord.Maximum_monthly_Disbursement__c = pcrRecord.Maximum_Disbursement_Monthly__c;  
            leadRecord.Debt_income_status__c = pcrRecord.Approval_Status__c;      
          }else if(pcrRecord.PCR_Lead_ID__c == leadRecord.Id && pcrRecord.LASERCA__Contact__c == null && pcrRecord.Product_line__c == 'Community Solar'){
            leadRecord.Personal_Credit_Report__c = pcrRecord.Id;
            leadRecord.FICO_score_approval__c = pcrRecord.Approval_Status__c;
          }
        }
        for (contact contactRecord : contactList){
          if(pcrRecord.LASERCA__Contact__c == contactRecord.Id && pcrRecord.Product_line__c == 'Residential Loan'){
            leadMap.get(contactRecord.Lead__r.Id).Personal_Credit_Report_Co_Applicant__c = pcrRecord.Id;
            leadMap.get(pcrRecord.LASERCA__Lead__c).Maximum_monthly_Disbursement__c = pcrRecord.Maximum_Disbursement_Monthly__c;
          }
        }                  
      }
    }
  }





  //  public with sharing class mapPCRHandler {
  //  private boolean m_isExecuting = false;
  //  private Integer BatchSize = 0;
    
  //  public mapPCRHandler(boolean isExecuting, Integer size){
  //      m_isExecuting = isExecuting;
  //      BatchSize = size;
  //  }
      
  //  public void OnBeforeUpdate (Lead [] newLead){
  //        mapPCR(newLead);
  //        }

  //  private void mapPCR (List <Lead> trigLeads){
  //          list <string> leadids = new list <string>( );
  //          list <lead> leadUpdateList = new list <Lead>( );
  //          map <Id, Lead> leadmap = new map <id, Lead> ();
  //          string leadID;
  //          string shortID;
  //          string subkey;
  //          string leadkey;
  //          integer j;
  //          integer k;


  //    for(j = 0; j < trigLeads.size(); j++){
  //               leadmap.put(trigLeads.get(j).id, trigLeads.get(j));
  //               leadID = trigLeads.get(j).Id;
  //               shortID = leadID.substring(0,15);
  //               leadids.add (shortID);
  //               //system.debug(leadID);
  //               //system.debug(shortID);
  //               //system.debug(leadids);
  //    }
        
          
  //    List <LASERCA__Personal_Credit_Report__c> listPCRs = [SELECT  Id, name, LASERCA__Lead__c,LASERCA__Lead__r.Personal_Credit_Report_Co_Applicant__c, PCR_Lead_ID__c, 
  //                                                            LASERCA__Contact__c, Maximum_Disbursement_Monthly__c 
  //                                                          FROM LASERCA__Personal_Credit_Report__c 
  //                                                          WHERE PCR_Lead_ID__c IN : leadids] ;
                                                         
  //    //system.debug(listPCRs);          
  //    for(j = 0; j < trigLeads.size(); j++){
  //            subkey = trigleads.get(j).Id;
  //            leadkey = subkey.substring(0,15);
  //            //system.debug(leadkey);
  //      for (k=0; k < listPCRs.size(); k++){
  //      //system.debug(listPCRs.get(k).Id);
  //      //system.debug(listPCRs.get(k).PCR_Lead_ID__c);
  //      //system.debug(listPCRs.get(k).LASERCA__Contact__c);
  //      //system.debug(leadmap.get(listPCRs.get(k).LASERCA__Lead__c));
  //        if (listPCRs.get(k).PCR_Lead_ID__c == leadkey && listPCRs.get(k).LASERCA__Contact__c != NULL){                                        
  //           if(leadmap.get(listPCRs.get(k).LASERCA__Lead__c).Personal_Credit_Report_Co_Applicant__c == NULL){
  //              leadmap.get(listPCRs.get(k).LASERCA__Lead__c).Personal_Credit_Report_Co_Applicant__c = listPCRs.get(k).Id;
  //            }
  //          leadmap.get(listPCRs.get(k).LASERCA__Lead__c).Maximum_monthly_Disbursement__c = listPCRs.get(k).Maximum_Disbursement_Monthly__c;
  //        }
  //        else if (listPCRs.get(k).PCR_Lead_ID__c == leadkey && listPCRs.get(k).LASERCA__Contact__c == NULL){
  //          if(leadmap.get(listPCRs.get(k).LASERCA__Lead__c).Personal_Credit_Report__c == NULL){
  //            leadmap.get(listPCRs.get(k).LASERCA__Lead__c).Personal_Credit_Report__c = listPCRs.get(k).Id; 
  //          }
  //          leadmap.get(listPCRs.get(k).LASERCA__Lead__c).Maximum_monthly_Disbursement__c = listPCRs.get(k).Maximum_Disbursement_Monthly__c;
  //        }                                 
  //        else {leadmap.get(listPCRs.get(k).LASERCA__Lead__c).Personal_Credit_Report__c = NULL;
  //        } 
  //      }                     
  //    }
  //    //for (lead leadMapRecord : leadMap.values()){
  //    //  leadUpdateList.add(leadMapRecord);
  //    //}
  //    //update leadUpdateList;
  //  }
  //}