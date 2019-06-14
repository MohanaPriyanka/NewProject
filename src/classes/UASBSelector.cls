/* Tested by: ZuoraUsageServiceTest
 */

public class UASBSelector {
    public static List<UASB__c> uasbsNotYetInZuora() {
        return [
            SELECT Id, Name, Date__c, System_Bill__c,
            Net_Metering_Credits_Allocated__c, Savings__c,
            Discounted_Bill__c, Shared_Solar_System__r.Name,
            Shared_Solar_System__r.System_Utility__c,
            Utility_Account_Subscription__r.Name,
            Shared_Solar_System__r.Utility__r.Name,
            Utility_Account_Subscription__r.Utility_Account_Log__r.Name,
            Utility_Account_Subscription__r.Opportunity__r.Shared_Solar_System__r.BWC_Project_Entity_Manual__r.Client_Account__r.Account_Number__c,
            Utility_Account_Subscription__r.Opportunity__r.Shared_Solar_System__r.Unique_ID__c,
            Utility_Account_Subscription__r.Opportunity__r.Account.Zuora_Id__c,
            Client_Account_Number__c
            FROM UASB__c
            WHERE Zuora_Id__c = null
        ];
    }
}