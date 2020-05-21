/**
 * Created by SarahRenfro on 2/11/2020.
 *
 * Tested By: SubscriptionManagementServiceTestclass
 */
@SuppressWarnings('PMD.ApexCRUDViolation')
public inherited sharing class SubscriptionOrderSelector {

    public List<Subscription_Order__c> selectByIds(Set<Id> soIds) {
        return [
            SELECT Id,
                Name,
                System_Change_Percent_Share_of_System__c,
                System_Change_kW_DC_Subscription__c,
                System_Change_kW_DC_Rounded__c,
                Previous_Percent_Share_of_System__c,
                Previous_kw_DC_Subscription__c,
                Calculated_Change_in_Percent_Share_of_Sy__c,
                Calculated_Change_in_Subscription_KW_DC__c,
                Calculated_Change_in_kW_DC_Rounded__c,
                RecordType.Name,
                Total_System_Size_kW_DC__c,
                Utility_Number_of_Decimal_Places__c
            FROM Subscription_Order__c
            WHERE Id IN :soIds
        ];
    }
}