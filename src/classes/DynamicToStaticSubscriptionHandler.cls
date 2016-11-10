global with sharing class DynamicToStaticSubscriptionHandler {
    webservice static string DynamicToStaticSubscriptionHandler (String sssId){
        //String sssId;
        integer i;
        integer j;
        decimal updatedSubscriptionValueOnOpp = 0;
        List<Utility_Account_Subscription__c> uasList = new List<Utility_Account_Subscription__c>();
        List<Opportunity> oppList = new List<Opportunity>();

        for(Opportunity  opp : [SELECT Id, Name, Cs_capacity_allocated__c, (SELECT Id, Name, Customer_Subscription_KW_DC_STATIC__c, 
                                    Customer_Subscription_KW_DC__c FROM Utility_Account_Subscriptions__r)
                                   FROM Opportunity
                                   WHERE Shared_Solar_System__r.id = : sssId]){
            for(Utility_Account_Subscription__c uas : opp.Utility_Account_Subscriptions__r){
                uasList.add(uas);
                updatedSubscriptionValueOnOpp = updatedSubscriptionValueOnOpp + uas.Customer_Subscription_KW_DC__c;
            }
            opp.Cs_capacity_allocated__c = updatedSubscriptionValueOnOpp;
            oppList.add(opp);
        }
        for(i=0;i<uasList.size();i++){
            uasList.get(i).Customer_Subscription_KW_DC_STATIC__c = uasList.get(i).Customer_Subscription_KW_DC__c;
        }   
        /*for(Utility_Account_Subscription__c uas : [SELECT Id, Name, Opportunity__r, Customer_Subscription_KW_DC_STATIC__c, Customer_Subscription_KW_DC__c
                                                         FROM Utility_Account_Subscription__c   
                                                         WHERE Opportunity__r.Shared_Solar_System__r.Id = : sssId]){
            uas.Customer_Subscription_KW_DC_STATIC__c = uas.Customer_Subscription_KW_DC__c;
            uasList.add(uas);
        }*/
        update uasList;
        update oppList;
        return null;
    }
}