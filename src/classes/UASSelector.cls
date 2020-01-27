/*************************************************************************************
 * Created By: peteryao on 1/20/19  
 * Description: 
 * Tested By: UASSelectorTest
 *************************************************************************************/
@SuppressWarnings('PMD.ApexCRUDViolation')
public without sharing class UASSelector {
    public static List<Utility_Account_Subscription__c> selectByAccounts(Set<Id> accounts) {
        return [
            SELECT Id,
                Utility_Account_Log__r.Account__c,
                Utility_Account_Log__r.Account__r.Id,
                Utility_Account_Log__r.Account__r.Name,
                Utility_Account_Log__r.Account__r.Cancellation_Comments__c,
                Utility_Account_Log__r.Account__r.Send_Bills_Contact__c,
                Utility_Account_Log__r.Account__r.Send_Bills_Contact__r.Email,
                Utility_Account_Log__r.Account__r.Send_Bills_Contact__r.FirstName,
                Utility_Account_Log__r.Account__r.Send_Bills_Contact__r.Additional_Email__c,
                Utility_Account_Log__r.Account__r.Additional_Contact__r.Email,
                Opportunity__r.Product__r.Cancellation_Paragraph_Two__c,
                Opportunity__r.Product__r.Cancellation_Paragraph_Three__c
            FROM Utility_Account_Subscription__c
            WHERE Utility_Account_Log__r.Account__c = :accounts
        ];
    }

    public static List<Utility_Account_Subscription__c> selectByUAL(Set<Id> ualIds) {
        return [
            SELECT Id,
                Utility_Account_Log__c,
                Utility_Account_Log__r.Name,
                Utility_Account_Log__r.Account__c,
                Utility_Account_Log__r.Account__r.Id,
                Utility_Account_Log__r.Account__r.Name,
                Utility_Account_Log__r.Account__r.Send_Bills_Contact__c,
                Utility_Account_Log__r.Account__r.Parent_Account__c
            FROM Utility_Account_Subscription__c
            WHERE Utility_Account_Log__c IN :ualIds
        ];
    }

    public static List<Utility_Account_Subscription__c> selectByIds(Set<Id> uasIds) {
        return [
            SELECT Id,
                Name,
                Opportunity__c,
                Opportunity__r.Id,
                Opportunity__r.Shared_Solar_System__r.Id
            FROM Utility_Account_Subscription__c
            WHERE Id IN :uasIds
        ];
    }

    public static Map<Id, Utility_Account_Subscription__c> selectByIdsAsMap(Set<Id> uasIds){
        Map<Id, Utility_Account_Subscription__c> uasWithClientMap = new Map<Id, Utility_Account_Subscription__c>([
            SELECT Id,
                Opportunity__r.Shared_Solar_System__r.BWC_Project_Entity_Manual__r.Client_Account__c,
                Externally_Serviced__c
            FROM Utility_Account_Subscription__c
            WHERE Id IN : uasIds
        ]);
        return uasWithClientMap;
    }
}