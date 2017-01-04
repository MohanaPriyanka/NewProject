public with sharing class MapPCRtoLeadHandler {
  private boolean m_isExecuting = false;
  private Integer BatchSize = 0;
    
  public MapPCRtoLeadHandler (boolean isExecuting, Integer size){
      m_isExecuting = isExecuting;
      BatchSize = size;
  }

  public void OnBeforeUpdate (LASERCA__Personal_Credit_Report__c[] newPCR){
      MapPCRtoLead(newPCR);
  }

  private void MapPCRtoLead (List<LASERCA__Personal_Credit_Report__c> newPCR){ 
    integer j;
    integer k;
    integer i;
    integer h;
    integer l;
    list <string> leadids = new list <string>( );
    list <string> contactids = new list <string>();
    list <lead> leadupdatelist = new list <lead>( );

  for(j = 0; j < newPCR.size(); j++){
      decimal monthlydebt = newPCR.get(j).LASERCA__Sum_of_monthly_Personal_Debt__c;

      if(newPCR.get(j).LASERCA__Lead__c != null && (monthlydebt == NULL || monthlydebt == 0)){         
              system.debug(monthlydebt);
              leadids.add(newPCR.get(j).LASERCA__Lead__c);
      }

      if(newPCR.get(j).LASERCA__Contact__c != null && (monthlydebt == NULL || monthlydebt == 0)){         
              system.debug(monthlydebt);
              contactids.add(newPCR.get(j).LASERCA__Contact__c);
      }
  }

  if(leadids.size()>0){

  List <Lead> listleads = [ SELECT id, Product_Line__c, Personal_Credit_Report__c 
                            FROM Lead
                            WHERE id IN : leadids];  
  system.debug(listleads);

      for(i = 0; i < newPCR.size(); i++){
        string leadid = newPCR.get(i).LASERCA__Lead__c; 
        string contactid = newPCR.get(i).LASERCA__Contact__c;
        system.debug(leadid);
        system.debug(contactid);
        decimal monthlydebt = newPCR.get(i).LASERCA__Sum_of_monthly_Personal_Debt__c;

          if(listleads.size()> 0){
            if(newPCR.get(i).LASERCA__Lead__c != null && (monthlydebt == NULL || monthlydebt == 0)){
              for(k = 0; k < listleads.size(); k++){
                system.debug(listleads.get(k).Id);
                system.debug(leadid);

                if(listleads.get(k).id == leadid && contactid == null && listleads.get(k).Product_Line__c == 'Residential Loan' && listleads.get(k).Personal_Credit_Report__c != newPCR.get(i).Id){
                    listleads.get(k).Personal_Credit_Report__c = newPCR.get(i).Id;
                    listleads.get(k).Maximum_monthly_Disbursement__c = newPCR.get(i).Maximum_Disbursement_Monthly__c;  
                    listleads.get(k).Debt_income_status__c = newPCR.get(i).Approval_Status__c; 
                    leadupdatelist.add(listleads.get(k));  
                    system.debug(leadupdatelist);
                }

                if(listleads.get(k).id == leadid && contactid == null && listleads.get(k).Product_Line__c == 'Community Solar' && listleads.get(k).Personal_Credit_Report__c != newPCR.get(i).Id){
                    listleads.get(k).Personal_Credit_Report__c = newPCR.get(i).Id;
                    listleads.get(k).FICO_score_approval__c = newPCR.get(i).Approval_Status__c;
                    leadupdatelist.add(listleads.get(k)); 

                }

                if(listleads.get(k).id == newPCR.get(i).Lead_from_Contact__c && contactid != null){
                    listleads.get(k).Personal_Credit_Report_Co_Applicant__c = newPCR.get(i).id;
                    leadupdatelist.add(listleads.get(k));
                }
              }
            }
          }

        if(leadupdatelist.size()>0){
              update leadupdatelist;
              system.debug(leadupdatelist);
        }
      } // end PCR loop 

  } // end of if leadids > 0


}
}