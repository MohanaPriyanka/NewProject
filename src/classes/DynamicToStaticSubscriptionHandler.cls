/*************************************************************************************
 - * Created By:  Cole Swain
 - * Description: This is the code behind the "Update Subscriptions" button on the SSS. 
 - * This button is used when a new Schedule Z is enacted, and all UASes need to be updated 
 - * It moves the Future/Dynamic Subscription size to the Current/Static field 
 - * Edit - by Jordan: Updates the Next Schedule Z Status field, so 
 - * Additions become Enacted, Removals become Cancelled
 - *      
 - * Tested By: DynamicToStaticSubscriptionHandlerTest / RecalculateUALCostControllerTest
 - *************************************************************************************/


global with sharing class DynamicToStaticSubscriptionHandler {
    webservice static string DynamicToStaticSubscriptionHandler (String sssId){
        //String sssId;
        integer i;
        integer j;
        decimal updatedSubscriptionValueOnOpp = 0;
        List<Utility_Account_Subscription__c> uasList = new List<Utility_Account_Subscription__c>();
        List<Opportunity> oppList = new List<Opportunity>();

        for(Opportunity  opp : [SELECT Id, Name, Cs_capacity_allocated__c, (SELECT Id, Name, Customer_Subscription_KW_DC_STATIC__c, 
                                    Customer_Subscription_KW_DC__c, Next_Schedule_Z_Status__c FROM Utility_Account_Subscriptions__r)
                                   FROM Opportunity
                                   WHERE Shared_Solar_System__r.id = : sssId]){
            // If there are multiple opportunities, make sure each opp gets it's own subscription value counter
            updatedSubscriptionValueOnOpp = 0;
            for(Utility_Account_Subscription__c uas : opp.Utility_Account_Subscriptions__r){
                uasList.add(uas);
                updatedSubscriptionValueOnOpp = updatedSubscriptionValueOnOpp + uas.Customer_Subscription_KW_DC__c;
            }
            opp.Cs_capacity_allocated__c = updatedSubscriptionValueOnOpp;
            oppList.add(opp);
        }
        for(i=0;i<uasList.size();i++){
            uasList.get(i).Customer_Subscription_KW_DC_STATIC__c = uasList.get(i).Customer_Subscription_KW_DC__c;
            if (uasList.get(i).Next_Schedule_Z_Status__c == 'Not Enacted: Addition'){
                uaslist.get(i).Next_Schedule_Z_Status__c = 'Enacted';
            } else if (uasList.get(i).Next_Schedule_Z_Status__c == 'Enacted: Removed'){
                uaslist.get(i).Next_Schedule_Z_Status__c = 'Cancelled';
            }

        }   
        update uasList;
        update oppList;
        return null;
    }
}