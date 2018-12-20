/**
 * Created by mstackhouse on 5/15/2018.
 *
 * When a schedule Z is created this class creates subscriptions from a customer's UAS.
 *
 *
 * Tested by: ScheduleZTriggerHandlerTest
 */

public without sharing class ScheduleZTriggerHandler {

    public static void handleDates(List<Schedule_Z__c> oldScheduleZS, List<Schedule_Z__c> newScheduleZS) {
        // Create map of the old schedZs Id:Sched Z
        Map<Id, Schedule_Z__c> oldMap = new Map<Id, Schedule_Z__c>();
        for (Schedule_Z__c schedZ : oldScheduleZS) {
            oldMap.put(schedZ.Id, schedZ);
        }

        // Create a list of the Sched Z's that changed Status__c
        List<Schedule_Z__c> statusChangedSZs = new List<Schedule_Z__c>();
        for (Schedule_Z__c schedZ : newScheduleZS) {
            if (oldMap.containsKey(schedZ.Id) &&
                schedZ.Status__c != oldMap.get(schedZ.Id).Status__c) {
                statusChangedSZs.add(schedZ);
            }
        }

        List<Id> systems = new List<Id>();
        for (Schedule_Z__c schedZ : statusChangedSZs) {
            if (schedZ.Status__c == 'Enacted by Utility') {
                // need to find previous schedule Z and set the 'Date Schedule Z Retired by Utility' to today
                //   for now, add it to a list so that all queries can be done in one query
                systems.add(schedZ.Shared_Solar_System__c);
            }
        }

        List<Shared_Solar_System__c> sssList = [
            SELECT Id,
            (SELECT Id FROM Schedule_Zs__r
            WHERE Date_Schedule_Z_Retired_by_Utility__c = NULL
            AND Date_Enacted_by_Utility__c != NULL ORDER BY Date_Enacted_by_Utility__c DESC)
            FROM Shared_Solar_System__c
            WHERE Id IN : systems
        ];

        List<Schedule_Z__c> SZToUpdate = new List<Schedule_Z__c>();
        for (Shared_Solar_System__c sss : sssList) {
            if (sss.Schedule_Zs__r.size() > 0) {
                sss.Schedule_Zs__r.get(0).Date_Schedule_Z_Retired_by_Utility__c = System.today();
                SZToUpdate.add(sss.Schedule_Zs__r.get(0));
            }
        }

        update SZToUpdate;
    }

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