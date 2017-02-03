public with sharing class LoanTrancheUpdateHandler {
    private boolean m_isExecuting = false;
    private Integer BatchSize = 0;
    
    public LoanTrancheUpdateHandler(boolean isExecuting, Integer size){
        m_isExecuting = isExecuting;
        BatchSize = size;
    }
    //public void OnBeforeInsert(loan__c[] newLoans){
    //    assignLoanTranche(newLoans);
    //}

    //public void OnBeforeUpdate(loan__c[] updatedLoans, loan__c[] oldLoans, Map<ID, loan__c> oldLoanMap, Map<ID, loan__c> newLoanMap){
    //    assignLoanTranche(updatedLoans);
    //}   

    //private List<Loan_Traunch__c> getLoanTranche(){
    //    List<Loan_Traunch__c> trancheList = new List<Loan_Traunch__c>();                                   
    //    //query for all of the products that are active | NOTE: will need to add queried fields as new product variations come into the system. Look for a way to return all fields.
    //    for(Loan_Traunch__c trancheRecord : [SELECT Id, Name, State__c, Loan_Data__r.Id, Available_Capital__c, Tranche_Type__c
    //                                    FROM Loan_Traunch__c 
    //                                    WHERE Stage__c = 'Open']){
    //        trancheList.add(trancheRecord);
    //    }
    //    system.debug(trancheList);
    //    return trancheList;        
    //}        
    //private void assignLoanTranche(List<Loan__c> loanList){
    //    List<Loan_Traunch__c> trancheList = new List<Loan_Traunch__c>(getLoanTranche());
    //    for(Loan__c loanRecord : loanList){                            
    //        //if(loanRecord.Product__r.Loan_Tranche_type__c != null && loanRecord.Principall__c != null && loanRecord.State__c != null){
    //            if(trancheList.size()>0){
    //                for(Loan_Traunch__c trancheRecord : trancheList){
    //                system.debug(trancheRecord.Loan_Data__r.Id);
    //                system.debug(loanRecord.Product__r.Loan_Capital_Pool__r.Id ); 
    //                system.debug(trancheRecord.Available_Capital__c);
    //                system.debug(loanRecord.Principall__c );
    //                system.debug(trancheRecord.Tranche_Type__c);
    //                system.debug(loanRecord.Product__r.Loan_Tranche_type__c );                           
    //                    if(trancheRecord.State__c == loanRecord.State__c && 
    //                        trancheRecord.Loan_Data__r.Id == LoanRecord.Product__r.Loan_Capital_Pool__r.Id &&
    //                        trancheRecord.Available_Capital__c >= loanRecord.Principall__c &&
    //                        trancheRecord.Tranche_Type__c == loanRecord.Product__r.Loan_Tranche_type__c){
    //                            loanRecord.Loan_Tranche__c = trancheRecord.Id;
    //                    }
    //                }                    
    //            }             
    //        //}
    //    }
    



/*
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

VERSION 2 | Used parameters in SOQL; however it did not abide by governor limits as the SOQL was done inside of for loops.


    private List<Loan_Traunch__c> getLoanTranche (String trancheType, Decimal loanAmount, String state, Id capitalPoolId){
        String query =      'Select Id, Name, Loan_Term__c, '+
                            '           Loan_Financing_Fee_Terms__c '+
                            ' From Loan_Traunch__c ';
        query += 'Where State__c = :state ';
        query += 'AND Capital_Pool__r.Id = :capitalPoolId ';        
        query += 'AND Available_Capital__c >= :loanAmount ';
        query += 'AND Tranche_Type__c >= :trancheType ';
        query += 'AND Stage = Open ';        
        query += 'LIMIT 1';                         

        return Database.query(query);
    }
    private void assignLoanTranche(List<Loan__c> loanList){
        for(Loan__c loanRecord : loanList){
            if(loanRecord.Product__r.Loan_Tranche_type__c != null && loanRecord.Principall__c != null && loanRecord.State__c != null){
                if(getLoanTranche(loanRecord.Product__r.Loan_Tranche_type__c, loanRecord.Principall__c, loanRecord.State__c, loanRecord.Loan_Tranche__r.Loan_Data__r.Id).size() > 0){
                    for(Loan_Traunch__c loanTranche : getLoanTranche(loanRecord.Product__r.Loan_Tranche_type__c, loanRecord.Principall__c, loanRecord.State__c, loanRecord.Loan_Tranche__r.Loan_Data__r.Id)){
                        loanRecord.Loan_Tranche__c = loanTranche.Id;
                    }
                }
            }
        }
    }
 

   /* ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
   
   VERSION 1 | Created to allows for DOER loans to go into their own tranche, SC/NC loans to be put into a BW holding tranche and for others to go into standard Avidia Tranches. Not efficient.

    private void assignLoanTranche(List<Loan__c> loanList){
        //instantiate the various trancheLists.
        List<Loan_Traunch__c> trancheListStandard = new List<Loan_Traunch__c>();
        List<Loan_Traunch__c> trancheListMSLPHolding = new List<Loan_Traunch__c>();
        List<Loan_Traunch__c> trancheListBlueWaveHolding = new List<Loan_Traunch__c>();
        //instantiate variables
        integer i;
        integer j;
        string loanTrancheStatus;
            //query the loan tranches for the following records: standard tranches
            for(Loan_Traunch__c tranche : [SELECT Id, Name, Tranche_Cap__c, Available_Capital__c, State__c
                                           FROM Loan_Traunch__c
                                           WHERE Available_Capital__c > 0 
                                           AND Tranche_type__c = 'Standard'
                                           AND Stage__c = 'Open' 
                                           ORDER BY Available_Capital__c]){
                //add the query results to the trancheList
                trancheListStandard.add(tranche);
            }
            //query the loan tranches for the following records: MSLP Holding Tranche
            for(Loan_Traunch__c holdingTranche : [SELECT Id, Name, Tranche_Cap__c, Available_Capital__c
                                                  FROM Loan_Traunch__c
                                                  WHERE Tranche_type__c = 'MSLP - Holding Tranche'
                                                  AND Stage__c = 'Open']){
                //add the query results to the trancheList
                trancheListMSLPHolding.add(holdingTranche);
            }

            //query the loan tranches for the following records: BlueWave Holding Tranche
            for(Loan_Traunch__c bluewaveHoldingTranche : [SELECT Id, Name, Tranche_Cap__c, Available_Capital__c
                                                          FROM Loan_Traunch__c
                                                          WHERE Tranche_type__c = 'BlueWave - Holding Tranche'
                                                          AND Stage__c = 'Open']){
                //add the queary results to the bluewaveHoldingTranche
                trancheListBlueWaveHolding.add(bluewaveHoldingTranche);
                }                                             
                //run a loop that updates all of the newLoans with the tranche that has the most available capital.
                if(loanList.size() > 0){
                    for(i = 0; i < loanList.size(); i++){
                        //ensure that the loan assignment doesn't reassign old loans to new tranches everytime a tranche has more capital than another.
                        if(loanList.get(i).Tranche_assignment__c == 'Automatic' || loanList.get(i).Tranche_assignment__c == null){
                            //if the loan is part of the MSLP program and has not yet been purchased from Avidia, set it to the MSLP holding tranche.
                            if(loanList.get(i).DOER_Solar_Loann__c == TRUE && loanList.get(i).Date_of_loan_purchase__c == null && trancheListMSLPHolding.size() > 0){
                                loanList.get(i).Loan_tranche__c = trancheListMSLPHolding.get(0).id;
                            }
                            //if the loan has been fronted by BlueWave and is not part of the MSLP program, set it to the BlueWave Holding Tranche.
                            else if(loanList.get(i).DOER_Solar_Loann__c == FALSE && loanList.get(i).bluewave_capital__c == TRUE && trancheListBlueWaveHolding.size() > 0){
                                loanList.get(i).Loan_tranche__c = trancheListBlueWaveHolding.get(0).id;
                            }
                            //All else - set it to the tranche that is open and with the most available capital.
                            else if(trancheListStandard.size() > 0){
                                //cycle through the loan tranches to find the tranche with the most available capital in the loan's state. Assign it accordingly.
                                for(j = 0; j < trancheListStandard.size(); j++){
                                    if(trancheListStandard.get(j).State__c == loanList.get(i).State__c){
                                    loanList.get(i).Loan_tranche__c = trancheListStandard.get(j).id;
                                    //set the loan's tranche assignment value to manual to ensure that future reassignment doesn't automatically happen.
                                    loanList.get(i).Tranche_assignment__c = 'Manual';                                                       
                                    }
                                }
                            }
                            else{
                                return;
                            }
                        }    
                    }
                }*/
    }
    /*
        
    public void OnBeforeInsert(Energy_Usage_Update__c[] newEnergyUsageUpdates){
    }
    
    
    @future public static void OnAfterInsertAsync(Set<Id> newEnergyUsageUpdateIDs){
    }
    

    
    public void OnAfterUpdate(Energy_Usage_Update__c[] oldEnergyUsageUpdates, Energy_Usage_Update__c[] updatedEnergyUsageUpdates, Map<ID, Energy_Usage_Update__c> oldEnergyUsageUpdateMap, Map<ID, Energy_Usage_Update__c> newEnergyUsageUpdateMap){
        
    }
    
    @future public static void OnAfterUpdateAsync(Set<Id> updatedEnergyUsageUpdateIDs){
    }
    
    public void OnBeforeDelete(Energy_Usage_Update__c[] EnergyUsageUpdatesToDelete, Map<ID, Energy_Usage_Update__c> EnergyUsageUpdateMap){
        
    }
    
    public void OnAfterDelete(Energy_Usage_Update__c[] deletedEnergyUsageUpdates, Map<ID, Energy_Usage_Update__c> EnergyUsageUpdateMap){
        
    }
    
    @future public static void OnAfterDeleteAsync(Set<Id> deletedEnergyUsageUpdateIDs){
        
    }
    
    public void OnUndelete(Energy_Usage_Update__c[] restoredEnergyUsageUpdates){
        
    }
    
    public boolean IsTriggerContext{
        get{ return m_isExecuting;}
    }
    
    public boolean IsVisualforcePageContext{
        get{ return !IsTriggerContext;}
    }
    
    public boolean IsWebServiceContext{
        get{ return !IsTriggerContext;}
    }
    
    public boolean IsExecuteAnonymousContext{
        get{ return !IsTriggerContext;}
    }
    */