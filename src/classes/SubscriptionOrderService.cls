/**
 * Created by SarahRenfro on 11/15/2019.
 *
 * Tested By: SubscriptionOrderServiceTest
 */

public without sharing class SubscriptionOrderService {

    public void onBeforeInsert(List<Subscription_Order__c> soList) {

        Set<Id> uasIds = new Set<Id>();
        for (Subscription_Order__c so : soList) {
            uasIds.add(so.Utility_Account_Subscription__c);
        }

        Map<Id, Utility_Account_Subscription__c> soToUASMap = UASSelector.getUASMap(uasIds);

        for (Subscription_Order__c so : soList) {
            Utility_Account_Subscription__c uas = soToUASMap.get(so.Utility_Account_Subscription__c);
            try {
                if (uas.Shared_Solar_System__r.Client_Account__c != null) {
                    so.Client_Account__c = uas.Shared_Solar_System__r.Client_Account__c;
                }
                so.Expected_Yield_kWh_kW__c = uas.Shared_Solar_System__r.Expected_Yield_kWh_kW__c;
                so.Total_System_Size_kW_DC__c = uas.Shared_Solar_System__r.Total_System_Size_kWh_DC__c;
                so.Utility_Number_of_Decimal_Places__c = uas.Shared_Solar_System__r.Utility__r.Number_of_Decimal_Places__c;
                so.Utility_NMC_Tariff__c = uas.Opportunity__r.NMC_Tariff__c;
                so.Value_of_NMC__c = uas.Opportunity__r.NMC_Tariff__r.Value_of_NMC__c;
                so.Product__c = uas.Opportunity__r.Product__c;
            } catch (Exception e) {
                Logger.logNow('SubscriptionOrderService', 'onBeforeInsert', JSON.serialize(so) + '\n' + 'Unable to populate Subscription Order: ' + e.getMessage() + '\n' + e.getStackTraceString());
            }
        }
    }

}