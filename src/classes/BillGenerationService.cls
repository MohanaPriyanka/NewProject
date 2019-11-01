public class BillGenerationService {
    public static List<Schedule_Z_Subscription__c>  getScheduleZSubscriptionList(Set<Id> scheduleZIds){
        List<Schedule_Z_Subscription__c> onTimeSZSes;
        List<Schedule_Z_Subscription__c> overdueSZSes;
        Set<Id> uasIdsAlreadyBilling = new Set<Id>();

        onTimeSZSes = ScheduleZSubscriptionSelector.getListForBilling(scheduleZIds);
        for (Schedule_Z_Subscription__c szs : onTimeSZSes) {
            uasIdsAlreadyBilling.add(szs.Utility_Account_Subscription__c);
        }
        overdueSZSes = ScheduleZSubscriptionSelector.getOverdueSZSubscriptions(System_Properties__c.getAll().values()[0], uasIdsAlreadyBilling);
        onTimeSZSes.addAll(overdueSZSes);
        return onTimeSZSes;
    }
}