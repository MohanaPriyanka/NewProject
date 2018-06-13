/**
 * Created by mstackhouse on 5/15/2018.
 *
 * When a schedule Z is created this class creates subscriptions from a customer's UAS.
 *
 *
 * Tested by: ScheduleZTriggerHandlerTest
 */

public with sharing class ScheduleZTriggerHandler {
    public static void createSubscriptions(List<Schedule_Z__c> scheduleZList) {
        Set<Id> scheduleZIds = new Set<Id>();
        Set<Id> sssList = new Set<Id>();
        for (Schedule_Z__c scheduleZ : scheduleZList) {
            sssList.add(scheduleZ.Shared_Solar_System__c);
            scheduleZIds.add(scheduleZ.Id);
        }

        List<Utility_Account_Subscription__c> accountSubscriptions = [
            SELECT Id, Customer_Subscription_KW_DC__c, Opportunity__r.Shared_Solar_System__c,
                Customer_Subscription_KW_DC_STATIC__c
            FROM Utility_Account_Subscription__c
            WHERE Opportunity__r.Shared_Solar_System__c IN : sssList
            AND Next_Schedule_Z_Status__c = 'Active Subscription'
            AND Opportunity_Stage__c = 'Complete'
        ];

        List<Schedule_Z__c> scheduleZListWithSystemSize = [
            SELECT Id, Shared_Solar_System__r.Total_System_Size_kW_DC_QC__c,
                Shared_Solar_System__r.Utility__r.Number_of_Decimal_Places__c
            FROM Schedule_Z__c
            WHERE Id IN : scheduleZIds
        ];

        List<Schedule_Z_Subscription__c> scheduleZSubscriptions = new List<Schedule_Z_Subscription__c>();

        for (Schedule_Z__c scheduleZ : scheduleZListWithSystemSize) {
            for (Utility_Account_Subscription__c uas : accountSubscriptions) {
                if (scheduleZ.Shared_Solar_System__c == uas.Opportunity__r.Shared_Solar_System__c) {
                    Decimal customerSubscriptionkWh;
                    if (uas.Customer_Subscription_KW_DC__c == null) {
                        customerSubscriptionkWh = uas.Customer_Subscription_KW_DC_STATIC__c;
                    } else {
                        customerSubscriptionkWh = uas.Customer_Subscription_KW_DC__c;
                    }
                    Schedule_Z_Subscription__c newSubscription = new Schedule_Z_Subscription__c(
                        Customer_Subscription_kW_DC__c = customerSubscriptionkWh,
                        Utility_Account_Subscription__c = uas.Id,
                        Schedule_Z__c = scheduleZ.Id,
                        Number_of_Decimal_Places__c = scheduleZ.Shared_Solar_System__r.Utility__r.Number_of_Decimal_Places__c,
                        System_Size_kW_DC__c = scheduleZ.Shared_Solar_System__r.Total_System_Size_kW_DC_QC__c
                    );
                    scheduleZSubscriptions.add(newSubscription);
                }
            }
        }

        insert scheduleZSubscriptions;
    }
}
