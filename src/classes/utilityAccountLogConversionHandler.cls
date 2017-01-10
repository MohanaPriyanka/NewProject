public with sharing class utilityAccountLogConversionHandler {
    private boolean m_isExecuting = false;
    private Integer BatchSize = 0;
    
    public utilityAccountLogConversionHandler(boolean isExecuting, Integer size){
        m_isExecuting = isExecuting;
        BatchSize = size;
    }
    public void OnBeforeUpdate(List<Lead> convertedLeads){
        utilityAccountLogConversion(convertedLeads);
    }

    private void utilityAccountLogConversion(List<Lead> leadsList){
        Map<Id, Id> feedback2OppId = new Map<Id, Id>();
        Map<Id, Id> accountMap = new Map<Id, Id>();

        for(Lead L : leadsList){
             if (l.isConverted && l.convertedAccountId != null && l.Product_Line__c == 'Community Solar'){
                      feedback2OppId.put(l.Id, l.convertedAccountId);
                      accountMap.put(l.convertedAccountId,l.convertedAccountId);
            }
        }

        if(accountMap.size() > 0){
                 List<utility_account_log__c> ual = [SELECT Lead__c, Opportunity__c, Account__c 
                                                     FROM Utility_account_log__c 
                                                     WHERE Lead__c IN :feedback2OppId.keySet()];
                for (utility_account_log__c u : ual){
                    u.Account__c = feedback2OppId.get(u.Lead__c);
                }            
                update ual;
                List<account> acc = [SELECT UAL_convert__c 
                                     FROM Account 
                                     WHERE Id 
                                     IN :accountMap.keySet()];
                for (Account a : acc){
                    a.UAL_convert__c = TRUE;
                }    
                update acc;
        }
    }
}