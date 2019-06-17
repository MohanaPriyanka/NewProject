/*
*
* Test: UtilityAccountLogConvertTestClass
* */


public without sharing class utilityAccountLogConversionHandler {

    public static void utilityAccountLogConversion(List<Lead> leadsList){
        Map<Id, Id> feedback2OppId = new Map<Id, Id>();
        Map<Id, Id> accountMap = new Map<Id, Id>();

        for(Lead l : leadsList){
             if (l.IsConverted && l.ConvertedAccountId != null && l.Product_line__c == 'Community Solar'){
                      feedback2OppId.put(l.Id, l.ConvertedAccountId);
                      accountMap.put(l.ConvertedAccountId, l.ConvertedAccountId);
            }
        }

        if(accountMap.size() > 0){
                 List<Utility_Account_Log__c> ual = [SELECT Lead__c, Opportunity__c, Account__c
                                                     FROM Utility_Account_Log__c
                                                     WHERE Lead__c IN :feedback2OppId.keySet()];

                for (Utility_Account_Log__c u : ual){
                    u.Account__c = feedback2OppId.get(u.Lead__c);
                }            
                update ual;
                List<Account> acc = [SELECT UAL_Convert__c
                                     FROM Account 
                                     WHERE Id 
                                     IN :accountMap.keySet()];
                for (Account a : acc){
                    a.UAL_Convert__c = true;
                }    
                update acc;
        }
    }
}