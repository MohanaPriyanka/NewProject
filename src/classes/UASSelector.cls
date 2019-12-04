/*************************************************************************************
 * Created By: peteryao on 1/20/19  
 * Description: 
 * Tested By: UASSelectorTest
 *************************************************************************************/

public class UASSelector {
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
                Utility_Account_Log__r.Account__c,
                Utility_Account_Log__r.Account__r.Id,
                Utility_Account_Log__r.Account__r.Name,
                Utility_Account_Log__r.Account__r.Send_Bills_Contact__c
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
                Opportunity__r.Shared_Solar_System__r.Id,
                Shared_Solar_System__c
            FROM Utility_Account_Subscription__c
            WHERE Id IN :uasIds
        ];
    }

    public static Map<Id, Utility_Account_Subscription__c> getUASMap (Set<Id> uasIds) {
        Map<Id, Utility_Account_Subscription__c> uasMap = new Map<Id, Utility_Account_Subscription__c>( [
            SELECT Id, Shared_Solar_System__r.Client_Account__c, Shared_Solar_System__r.Expected_Yield_kWh_kW__c,
                Shared_Solar_System__r.Total_System_Size_kWh_DC__c,Shared_Solar_System__r.Utility__r.Number_of_Decimal_Places__c,
                Opportunity__r.NMC_Tariff__c, Opportunity__r.NMC_Tariff__r.Value_of_NMC__c, Opportunity__r.Product__c
            FROM Utility_Account_Subscription__c
            WHERE Id IN :uasIds
        ]);
        return uasMap;
    }
}