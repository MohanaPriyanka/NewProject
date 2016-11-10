trigger utilityAccountLogConversion on Lead (before update){
/*
Map<Id, Id> feedback2OppId = new Map<Id, Id>();
Map<Id, Id> accountMap = new Map<Id, Id>();

For (Lead l : Trigger.new)
       {
             if (l.isConverted && l.convertedAccountId != null)
             {
                      feedback2OppId.put(l.Id, l.convertedAccountId);
                      accountMap.put(l.convertedAccountId,l.convertedAccountId);}}
     

     List<utility_account_log__c> ual = [SELECT lead__c, opportunity__c, account__c FROM utility_account_log__c WHERE lead__c IN :feedback2OppId.keySet()];
     
     for (utility_account_log__c u : ual)
     {
            u.account__c = feedback2OppId.get(u.lead__c);
     }
 
     update ual;
     
     List<account> acc = [SELECT UAL_convert__c FROM account WHERE id IN :accountMap.keySet()];
     
     for (account a : acc)
     {
            a.UAL_convert__c = TRUE;
     }
     
     update acc;
     */
}