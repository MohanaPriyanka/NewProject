/*
    Developed by Cole Swain - colemswain@gmail.com (Last Updated 07/13/2016)
    
    createLoanHandler is a triggered batch script that runs after a loan contract is fully completed on the opportunity record.
    The script assigns the creates a loan record and attaches it to the opportunity. It does not allow for duplicates by utilizing the upsert function.
*/
public with sharing class createLoanHandler {
    private boolean m_isExecuting = false;
    private Integer BatchSize = 0;
    
    public createLoanHandler(boolean isExecuting, Integer size){
        m_isExecuting = isExecuting;
        BatchSize = size;
    }
    public void OnAfterUpdate(opportunity[] oldOpps, opportunity[] updatedOpps, Map<ID, opportunity> oldOppMap, Map<ID, opportunity> newOppMap){
        createLoan(updatedOpps);
    }

    private void createLoan(List<opportunity> newOppList){
       Set<Loan__c> newLoanSet = new Set<Loan__c>();
       integer i;

        for(i = 0;i < newOppList.size(); i++){
            if(newOpplist.get(i).Product_Line__c == 'Residential Loan'){
                if(newOppList.get(i).StageName == 'Complete'){
                    if(newOppList.get(i).State_ab__c != 'MA'){
                            Loan__c loan = new loan__c(
                            Name = newOppList.get(i).Name,
                            Unique_ID__c = newOppList.get(i).id,
                            Commencement_datee__c = newOppList.get(i).Commencement_date__c,
                            DOER_Solar_Loann__c = newOppList.get(i).DOER_Solar_Loan__c,
                            Interest_Ratee__c = newOppList.get(i).Interest_rate__c,
                            Maturity_datee__c = newOppList.get(i).Maturity_date2__c,
                            Opportunity__c = newOppList.get(i).Id,
                            Origination_datee__c = newOppList.get(i).Origination_date__c,
                            Principall__c = newOppList.get(i).Loan_Amount_Financed__c,
                            System_Costt__c = newOppList.get(i).Loan_Principle__c,
                            BlueWave_Capital__c = TRUE,
                            Partner__c = newOppList.get(i).Partner_tag_lookup__c,
                            State__c = newOppList.get(i).State_ab__c);
                    
                        newLoanSet.add(loan);
                    }

                    else{
                        Loan__c loan = new loan__c(
                            Name = newOppList.get(i).Name,
                            Unique_ID__c = newOppList.get(i).id,
                            Commencement_datee__c = newOppList.get(i).Commencement_date__c,
                            DOER_Solar_Loann__c = newOppList.get(i).DOER_Solar_Loan__c,
                            Interest_Ratee__c = newOppList.get(i).Interest_rate__c,
                            Maturity_datee__c = newOppList.get(i).Maturity_date2__c,
                            Opportunity__c = newOppList.get(i).Id,
                            Partner__c = newOppList.get(i).Partner_tag_lookup__c,
                            Origination_datee__c = newOppList.get(i).Origination_date__c,
                            Principall__c = newOppList.get(i).Loan_Amount_Financed__c,
                            System_Costt__c = newOppList.get(i).Loan_Principle__c,
                            State__c = newOppList.get(i).State_ab__c);
                    
                        newLoanSet.add(loan);
                    }
            }
        }
        upsert new list<Loan__c>(newLoanSet) Unique_ID__c;
    }
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
}

/*public with sharing class createLoanHandler {
    private boolean m_isExecuting = false;
    private Integer BatchSize = 0;
    
    public createLoanHandler(boolean isExecuting, Integer size){
        m_isExecuting = isExecuting;
        BatchSize = size;
    }
    public void OnAfterInsert(opportunity[] updatedOpps){
        createLoan(updatedOpps);
    }
    public Map<String, Loan_Traunch__c> assignLoanTranche(List<Opportunity> newOppList){
        Map<String, Loan_Traunch__c> trancheMap = new Map<String, Loan_Traunch__c>();
        try{
            List<Opportunity> oppList = [SELECT Id, State_ab__c, Product__r.Loan_Capital_Pool__r.Id, Loan_Amount_Financed__c, Product__r.Loan_Tranche_type__c,
                                            Direct_Disbursal_to_Installer_Authorized__c, Electronic_Disbursal_Authorized__c 
                                        FROM Opportunity
                                        WHERE Id IN : newOppList];

            for(Loan_Traunch__c trancheRecord : [SELECT Id, Name, State__c, Loan_Data__r.Id, Available_Capital__c, Tranche_Type__c
                                            FROM Loan_Traunch__c 
                                            WHERE Stage__c = 'Open'
                                            AND Available_Capital__c > 0]){
                for (Opportunity oppRecord : oppList){
                    System.debug(oppRecord.State_ab__c);
                    System.debug(trancheRecord.State__c);
                    System.debug(oppRecord.Product__r.Loan_Capital_Pool__r.Id);
                    System.debug(trancheRecord.Loan_Data__r.Id);
                    System.debug(oppRecord.Loan_Amount_Financed__c);
                    System.debug(trancheRecord.Available_Capital__c);
                    System.debug(oppRecord.Product__r.Loan_Tranche_type__c);
                    System.debug(trancheRecord.Tranche_Type__c);
                    //Error messages must be put in place
                    //if(trancheRecord.Available_Capital__c <= oppRecord.Loan_Amount_Financed__c){
                    //    System.debug('There is not enough capital available in the tranches');
                    //    //trancheRecord.addError('There is not enough capital available in the tranches' , false);
                    //    Apexpages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO,''+'There is not enough capital available in the tranches' ));
                    //}


                    if(trancheRecord.State__c == oppRecord.State_ab__c && 
                        trancheRecord.Loan_Data__r.Id == oppRecord.Product__r.Loan_Capital_Pool__r.Id &&
                        trancheRecord.Available_Capital__c >= oppRecord.Loan_Amount_Financed__c &&
                        trancheRecord.Tranche_Type__c == oppRecord.Product__r.Loan_Tranche_type__c){            
                    trancheMap.put(oppRecord.Id, trancheRecord);
                    System.debug(trancheMap.size());
                    }
                }
            }    
            System.debug(trancheMap);
            return trancheMap;
        }
        catch(exception e){
            System.debug(trancheMap);
            return null;
        }
    }

    public void createLoan(List<opportunity> newOppList){
        Set<Loan__c> newLoanSet = new Set<Loan__c>();
        Map<String, Loan_Traunch__c> trancheMap = new Map<String, Loan_Traunch__c>(assignLoanTranche(newOppList));        
        System.debug(trancheMap.size());
        integer i;
        for (i = 0; i < newOppList.size(); i++){
            if(newOppList.get(i).Product_Line__c == 'Residential Loan'){
                Loan__c loan = new loan__c(
                    Name = newOppList.get(i).Name,
                    Electronic_Disbursal_Authorized__c = newOppList.get(i).Electronic_Disbursal_Authorized__c,
                    Direct_Disbursal_to_Installer_Authorized__c = newOppList.get(i).Direct_Disbursal_to_Installer_Authorized__c,
                    Unique_ID__c = newOppList.get(i).id,
                    Loan_Tranche__c = trancheMap.get(newOppList.get(i).Id).Id,
                    //Interest_Ratee__c = newOppList.get(i).Loan_Interest_rate__c,
                    //Commencement_datee__c = newOppList.get(i).Commencement_date__c,
                    //DOER_Solar_Loann__c = newOppList.get(i).DOER_Solar_Loan__c,
                    //Interest_Ratee__c = newOppList.get(i).Interest_rate__c,
                    //Maturity_datee__c = newOppList.get(i).Maturity_date2__c,
                    Opportunity__c = newOppList.get(i).Id,
                    Sales_Agent__c = newOppList.get(i).BS_Sales_ID__c,
                    //Origination_datee__c = newOppList.get(i).Origination_date__c,
                    Principall__c = newOppList.get(i).Loan_Amount_Financed__c,
                    Financing_Fee__c = newOppList.get(i).Financing_Fee_SLA2__c,
                    System_Costt__c = newOppList.get(i).Loan_Principle__c,
                    Partner__c = newOppList.get(i).Partner_tag_lookup__c,
                    State__c = newOppList.get(i).State_ab__c,
                    Lead_ID__c = newOppList.get(i).Lead_ID__c,
                    Product__c = newOppList.get(i).Product__c);
                newLoanSet.add(loan);                
            }
        }        
        upsert new list<Loan__c>(newLoanSet) Unique_ID__c;
    }
}
    /*
     _______________________________________________________________________________________________________________________________   
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