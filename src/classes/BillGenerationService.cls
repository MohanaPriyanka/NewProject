public class BillGenerationService {
    public static List<Schedule_Z_Subscription__c>  getScheduleZSubscriptionList(Set<Id> scheduleZIds){
        List<Schedule_Z_Subscription__c> onTimeSZSes;
        List<Schedule_Z_Subscription__c> overdueSZSes;
        Set<Id> uasIdsAlreadyBilling = new Set<Id>();

        onTimeSZSes = ScheduleZSubscriptionSelector.getListForBilling(scheduleZIds);
        for (Schedule_Z_Subscription__c szs : onTimeSZSes) {
            uasIdsAlreadyBilling.add(szs.Utility_Account_Subscription__c);
        }
        System_Properties__c sysProp = System_Properties__c.getAll().values()[0];
        Decimal minimumBalance = Util.nullToZero(sysProp.Minimum_Balance_Bills_for_Cancelled__c);
        Date maxPastDueDate = Date.today().addDays(-(Integer.valueOf(Util.nullToZero(sysProp.Days_Generate_Bills_For_Cancelled__c))));
        overdueSZSes = ScheduleZSubscriptionSelector.getOverdueSZSubscriptions(
            minimumBalance,
            maxPastDueDate,
            uasIdsAlreadyBilling
        );
        onTimeSZSes.addAll(overdueSZSes);
        return onTimeSZSes;
    }
}