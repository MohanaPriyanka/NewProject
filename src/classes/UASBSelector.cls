/* Tested by: ZuoraUsageServiceTest
 */

public class UASBSelector {
    public static List<UASB__c> uasbsNotYetInZuora() {
        return [
            SELECT Id, Name, Date__c,
            Billing_Period_Start_Date__c, Billing_Period_End_Date__c,
            Net_Metering_Credits_Allocated__c, Savings__c,
            Discounted_Bill__c, Shared_Solar_System__r.Name,
            Shared_Solar_System__r.System_Utility__c,
            Utility_Account_Subscription__r.Name,
            Shared_Solar_System__r.Utility__r.Name,
            Utility_Account_Subscription__r.Utility_Account_Log__r.Name,
            Utility_Account_Subscription__r.SRPC__r.Zuora__ChargeNumber__c,
            Utility_Account_Subscription__r.SRPC__r.Zuora__Subscription__r.Name,
            Utility_Account_Subscription__r.SRPC__r.Zuora__Subscription__r.Zuora__CustomerAccount__r.Zuora__Zuora_Id__c
            FROM UASB__c
            WHERE Zuora_Usage_Id__c = null
        ];
    }
}