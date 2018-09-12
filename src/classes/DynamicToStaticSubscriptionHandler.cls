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

global without sharing class DynamicToStaticSubscriptionHandler {
    /* Used by the "Update Subscriptions" button on the Shared Solar System to mass update UASes
    once a new schedule z has been enacted */
    webservice static string DynamicToStaticSubscriptionHandler (String sssId){
        List<Utility_Account_Subscription__c> uasList = [SELECT Id, Name, Customer_Subscription_KW_DC_STATIC__c, 
                                                          Customer_Subscription_KW_DC__c, Next_Schedule_Z_Status__c 
                                                          FROM Utility_Account_Subscription__c
                                                          WHERE Opportunity__r.Shared_Solar_System__c = : sssId];
        for (Utility_Account_Subscription__c uas : uasList){
            uas.Customer_Subscription_KW_DC_STATIC__c = uas.Customer_Subscription_KW_DC__c;
            if (uas.Next_Schedule_Z_Status__c == 'Not Enacted: Addition'){
                uas.Next_Schedule_Z_Status__c = 'Enacted';
            } else if (uas.Next_Schedule_Z_Status__c == 'Enacted: Removed'){
                uas.Next_Schedule_Z_Status__c = 'Cancelled';
            }
        }   
        Database.executeBatch(new GenericBatchDMLOperation(uasList, 'Update'));
        return null;
    }

    /* Used by DocuSign buttons on the opportunity to sum UASes under that opportunity
    for a merge field on the CS contract right before the contract is sent */
    webservice static void sumUASes (Id opportunityId){
        Opportunity opp = [SELECT Id, Name, DocuSign_Subscription_Size__c
                           FROM Opportunity
                           WHERE Id = : opportunityId
                           LIMIT 1];

        AggregateResult uasSUM = [SELECT SUM(Customer_Subscription_KW_DC__c) subscriptionSum
                                  FROM Utility_Account_Subscription__c 
                                  WHERE Opportunity__c = : opportunityId];

        opp.DocuSign_Subscription_Size__c = (Decimal)uasSUM.get('subscriptionSum');

        update opp;
    }
}