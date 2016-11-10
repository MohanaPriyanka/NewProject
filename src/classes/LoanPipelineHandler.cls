/* ON update lead

    1.) Changes from unfinished to finished 
        This includes leads that go through the whole application right? 
        >> Create new loan pipeline record and attach loan ID

    2.) Changes from not converted to converted
        >> update loan pipeline record with opportunity ID

ON update opportunity

    Changes from anything to complete
    >> update loan pipeline record with Loan ID

*/

public with sharing class LoanPipelineHandler {
    private boolean m_isExecuting = false;
    private Integer BatchSize = 0;
    
    public LoanPipelineHandler(boolean isExecuting, Integer size){
        m_isExecuting = isExecuting;
        BatchSize = size;
    }

public void OnBeforeUpdate(Lead[] newLeads, Lead[] oldLeads){
      loanpipeline(newLeads, oldLeads);
  }

private void loanpipeline(List<Lead> newLeads, List<Lead> oldLeads){
        system.debug(newLeads);
        system.debug(oldLeads);

        integer m;
        integer n;
        integer j;
        integer k;
        Map <Id, Lead> mapoldvalues = new Map<Id, Lead> ();
        List <Lead> finishedleads = new list<Lead> ();
        List <Lead> convertedleads = new list<Lead> ();
        List <string> mcecRecords = new list<string> ();


        for(Lead oldleadvals: oldLeads){
              mapoldvalues.put(oldleadvals.id, oldleadvals);
        }
               // IF lead goes from unfinished to finished, add to list and create new MCEC record
                for(m = 0; m < newLeads.size(); m++){  
                        string newvalueID = newLeads.get(m).Id;
                        boolean newrecord = newLeads.get(m).Unfinished_Lead__c;
                        boolean oldrecord = mapoldvalues.get(newvalueID).Unfinished_Lead__c;
                        boolean DOER = newLeads.get(m).DOER_Solar_Loan__c;
                            if (newrecord == FALSE && oldrecord == TRUE && DOER == TRUE) { 
                                 finishedleads.add(newLeads.get(m));
                            }
                } 
                system.debug(finishedleads);

                                      for(j = 0; j< finishedleads.size(); j++){
                                          if(finishedleads.get(j).MCEC_Reporting_Object__c == NULL){
                                                 MCEC_Report_Data__c newpipeline = new MCEC_Report_Data__c (
                                                 Name = finishedleads.get(j).FirstName + finishedleads.get(j).LastName,
                                                 Lead__c = finishedleads.get(j).Id
                                                 );
                                                insert newpipeline;
                                                system.debug(newpipeline.id);
                                                finishedleads.get(j).MCEC_Reporting_Object__c = newpipeline.id;
                                          }
                                      }


                 // IF lead is converted, update MCEC object with newly created opportunity            
                  for(n = 0; n < newLeads.size(); n++){  
                        string newvalueID = newLeads.get(n).Id;
                        boolean newrecord = newLeads.get(n).isConverted;
                        boolean oldrecord = mapoldvalues.get(newvalueID).isConverted;
                        boolean DOER = newLeads.get(n).DOER_Solar_Loan__c;
                             if (newrecord == TRUE && oldrecord == FALSE && DOER == TRUE && newLeads.get(n).MCEC_Reporting_Object__c != NULL) { 
                                     convertedleads.add(newLeads.get(n));
                                     mcecRecords.add(newLeads.get(n).MCEC_Reporting_Object__c);
                             }
                  } 
                  system.debug(convertedleads);


                  Map <Id, MCEC_Report_Data__c> mapmcec = new Map <Id, MCEC_Report_Data__c> ([SELECT Id, Lead__c, Opportunity__c
                                                                                              FROM MCEC_Report_Data__c
                                                                                              WHERE Id IN : mcecRecords]);     
                  system.debug(mapmcec);

                                      for(k = 0; k< convertedleads.size(); k++){
                                           string idfromlead = convertedleads.get(k).MCEC_Reporting_Object__c;
                                           system.debug(idfromlead);
                                           system.debug(mapmcec.get(idfromlead).Opportunity__c);
                                           mapmcec.get(idfromlead).Opportunity__c = convertedleads.get(k).ConvertedOpportunityId;
                                           system.debug(mapmcec.get(idfromlead).Opportunity__c);
                                           update mapmcec.get(idfromlead);
                                      }
                                      



}
}