/*
    Developed by Cole Swain - colemswain@gmail.com (Last Updated 07/06/2016)
    
    createResidentialEquipmentHandler is a triggered batch script that runs loan is created.
    The script creates a  Residential Equipment record and attaches it to the loan. It does not allow for duplicates by utilizing the upsert function.
*/
public with sharing class createResidentialEquipmentHandler {
    private boolean m_isExecuting = false;
    private Integer BatchSize = 0;
    
    public createResidentialEquipmentHandler (boolean isExecuting, Integer size){
        m_isExecuting = isExecuting;
        BatchSize = size;
    }
    public void OnAfterInsert(loan__c[] newLoans){
        createResidentialEquipment(newLoans);
    }
    /*
    public void OnAfterUpdate(loan__c[] oldOpps, loan__c[] updatedOpps, Map<ID, loan__c> oldOppMap, Map<ID, loan__c> newOppMap){
        createResidentialEquipment(updatedOpps);
    }*/

    private void createResidentialEquipment(List<loan__c> newLoansList){
       Set<Residential_Equipment__c> newEquipmentSet = new Set<Residential_Equipment__c>();
       integer i;

        for(i = 0;i < newLoansList.size(); i++){            
                Residential_Equipment__c equipment = new Residential_Equipment__c(
                    Name = newLoansList.get(i).Name,
                    Loan__c = newLoansList.get(i).Id,
                    Unique_ID__c = newLoansList.get(i).Id);
                    
                    newEquipmentSet.add(equipment);      
        }
        upsert new list<Residential_Equipment__c>(newEquipmentSet) Unique_ID__c;
        
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