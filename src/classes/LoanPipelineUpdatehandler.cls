public with sharing class LoanPipelineUpdatehandler {
    private boolean m_isExecuting = false;
    private Integer BatchSize = 0;
    
    public LoanPipelineUpdatehandler (boolean isExecuting, Integer size){
        m_isExecuting = isExecuting;
        BatchSize = size;
    }
    public void OnAfterInsert(loan__c[] loanList){
        pipelineupdate (loanList);
    }

    private void pipelineupdate (List<Loan__c> loanList){
    
    integer i;
    integer j;
    integer k;
    string loanopportunity;
    List<string> oppRecords = new list<string>();
        
        if(LoanList.size() > 0){
        for(i=0; i < LoanList.size(); i++){
            if(LoanList.get(i).DOER_Solar_Loann__c == TRUE){
                oppRecords.add(LoanList.get(i).Opportunity__c);     
                system.debug(oppRecords);
            }
        }
        
        List <MCEC_Report_Data__c> listmcec = new list <MCEC_Report_Data__c> ([SELECT Id, Opportunity__c
                                                                              FROM MCEC_Report_Data__c
                                                                              WHERE Opportunity__c IN : oppRecords ]);     
        system.debug(listmcec);
        
        

        for(k=0; k < LoanList.size(); k++){
           loanopportunity =  LoanList.get(k).Opportunity__c;
           system.debug(loanopportunity);

                    for (j=0; j < listmcec.size(); j++){
                        if(listmcec.get(j).Opportunity__c == loanopportunity){
                            listmcec.get(j).Loan__c = LoanList.get(k).Id;
                            system.debug(LoanList.get(k).Id);
                            update listmcec.get(j);
                        }

                    }
        
        }

    
       } // if > 0
    } // end pipelineupdate
        
} // end class