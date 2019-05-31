/**
 * Created by mstackhouse on 5/15/2018.
 *
 * Description: Creates subscriptions from a customer's UAS when a schedule Z is created. Updates old Schedule Z's when
 * new ones are enacted, and marks UASes as Removed if they aren't on the new schedule Z.
 *
 * Tested by: ScheduleZTriggerHandlerTest, CSCancellationServiceTest
 */

public without sharing class ScheduleZTriggerHandler {
    // For newly enacted Schedule Zs, we want to set the previous Schedule Z to retired, and update any UASes that
    // that aren't on the new Schedule Z.
    public static void handleNewlyEnactedScheduleZ(Map<Id, Schedule_Z__c> oldMap, List<Schedule_Z__c> newScheduleZS) {
        List<Schedule_Z__c> szToUpdate = new List<Schedule_Z__c>();
        List<Schedule_Z__c> enactedScheduleZS = new List<Schedule_Z__c>();

        // Create a list of the Sched Z's that changed Status__c
        List<Id> systemIdsWithEnactedSZs = new List<Id>();
        for (Schedule_Z__c schedZ : newScheduleZS) {
            if (schedZ.Status__c == 'Enacted by Utility' && schedZ.Date_Enacted_by_Utility__c != null &&
                (oldMap == null ||
                    (oldMap != null &&
                        oldMap.containsKey(schedZ.Id) &&
                        (oldMap.get(schedZ.Id).Status__c != 'Enacted by Utility' || oldMap.get(schedZ.Id).Date_Enacted_by_Utility__c == null)))) {
                systemIdsWithEnactedSZs.add(schedZ.Shared_Solar_System__c);
                enactedScheduleZS.add(schedZ);
            }
        }

        List<Shared_Solar_System__c> sharedSolarSystemsWithEnactedSZs = [
            SELECT Id,
            (SELECT Id, Date_Enacted_by_Utility__c
            FROM Schedule_Zs__r
            WHERE Date_Schedule_Z_Retired_by_Utility__c = NULL
            AND Date_Enacted_by_Utility__c != NULL
            ORDER BY Date_Enacted_by_Utility__c DESC)
            FROM Shared_Solar_System__c
            WHERE Id IN :systemIdsWithEnactedSZs
        ];

        // We need to get all all Schedule Zs with their subscriptions for the next step in the process to find UASes
        // with Schedule Z Subscriptions not on the new Schedule Z.
        Map<Id, Set<Id>> szToUASesMap = getSZtoUASesMap(sharedSolarSystemsWithEnactedSZs);
        List<Utility_Account_Subscription__c> uasesToRetire = new List<Utility_Account_Subscription__c>();
        for (Shared_Solar_System__c sss : sharedSolarSystemsWithEnactedSZs) {
            if (sss.Schedule_Zs__r.size() > 1) {
                sss.Schedule_Zs__r[1].Date_Schedule_Z_Retired_by_Utility__c = sss.Schedule_Zs__r[0].Date_Enacted_by_Utility__c;
                szToUpdate.add(sss.Schedule_Zs__r[1]);
                uasesToRetire.addAll(
                    findUASesToRetire(
                        sss.Schedule_Zs__r[1].Id,
                        sss.Schedule_Zs__r[0].Date_Enacted_by_Utility__c,
                        sss.Schedule_Zs__r[0].Id,
                        szToUASesMap
                    )
                );
            }
        }
        if (szToUpdate.size() > 0) {
            update szToUpdate;
        }
        if (uasesToRetire.size() > 0) {
            update uasesToRetire;
        }

        if (Util.getSystemPropertyCheckbox('Use_Zuora_For_Subscription_Billing__c') && enactedScheduleZS.size() > 0) {
            ZuoraSubscriptionAsyncService asyncService = new ZuoraSubscriptionAsyncService();
            asyncService.initForScheduleZEnactment(enactedScheduleZS);
            Database.executeBatch(asyncService, 100);
        }
    }

    private static Map<Id, Set<Id>> getSZtoUASesMap(List<Shared_Solar_System__c> sssList) {
        Set<Id> scheduleZIds = new Set<Id>();
        for (Shared_Solar_System__c sss : sssList) {
            // We only have to check for UASes not on the next SZ if there is more than one Enacted and non-Retired SZ
            if (sss.Schedule_Zs__r.size() > 1) {
                scheduleZIds.add(sss.Schedule_Zs__r[0].Id);
                scheduleZIds.add(sss.Schedule_Zs__r[1].Id);
            }
        }
        List<Schedule_Z__c> scheduleZsWithSubscriptions = [
            SELECT Id,
            (SELECT Id, Utility_Account_Subscription__c FROM Schedule_Z_Subscriptions__r)
            FROM Schedule_Z__c
            WHERE Id = :scheduleZIds
        ];
        Map<Id, Set<Id>> scheduleZIdToUASesMap = new Map<Id, Set<Id>>();
        for (Schedule_Z__c scheduleZ : scheduleZsWithSubscriptions) {
            Set<Id> uasIds = new Set<Id>();
            for (Schedule_Z_Subscription__c szs : scheduleZ.Schedule_Z_Subscriptions__r) {
                uasIds.add(szs.Utility_Account_Subscription__c);
            }
            scheduleZIdToUASesMap.put(scheduleZ.Id, uasIds);
        }

        return scheduleZIdToUASesMap;
    }

    private static List<Utility_Account_Subscription__c> findUASesToRetire(Id retiredScheduleZId, Date retiredDate, Id enactedScheduleZId, Map<Id, Set<Id>> szToUASesMap) {
        List<Utility_Account_Subscription__c> uasesToRetire = new List<Utility_Account_Subscription__c>();
        for (Id uasOnOldSZId : szToUASesMap.get(retiredScheduleZId)) {
            if (!szToUASesMap.get(enactedScheduleZId).contains(uasOnOldSZId)) {
                Utility_Account_Subscription__c uas = new Utility_Account_Subscription__c(
                    Id = uasOnOldSZId,
                    Date_Removed_from_Project__c = retiredDate
                );
                uasesToRetire.add(uas);
            }
        }
        return uasesToRetire;
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