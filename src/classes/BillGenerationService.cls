public class BillGenerationService {
    public static List<Schedule_Z_Subscription__c>  getScheduleZSubscriptionList(Set<Id> scheduleZIds){
        List<Schedule_Z_Subscription__c> szsList = ScheduleZSubscriptionSelector.getListForBilling(scheduleZIds);
        Set<Id> uasIdsAlreadyBilling = new Set<Id>();
        for (Schedule_Z_Subscription__c szs : szsList) {
            uasIdsAlreadyBilling.add(szs.Utility_Account_Subscription__c);
        }
        szsList.addAll(getOverdueScheduleZSubscriptions(uasIdsAlreadyBilling));
        return szsList;
    }

    public static List<Schedule_Z_Subscription__c> getOverdueScheduleZSubscriptions(Set<Id> uasIdsAlreadyBilling) {
        System_Properties__c sysProp = System_Properties__c.getAll().values()[0];
        Decimal minimumBalance = Util.nullToZero(sysProp.Minimum_Balance_Bills_for_Cancelled__c);
        Date maxPastDueDate = Date.today().addDays(-(Integer.valueOf(Util.nullToZero(sysProp.Days_Generate_Bills_For_Cancelled__c))));

        Set<Id> overdueUASIds = new Set<Id>();

        // For accounts with a balance, get all UASes that have at least 1 UASB that are not already getting a bill:
        List<AggregateResult> overdueUASBs = [
            SELECT Utility_Account_Subscription__c uasId
            FROM UASB__c
            WHERE Utility_Account_Subscription__r.Opportunity__r.Account.Max_Overdue_Due_Date_Merge__c >= : maxPastDueDate
            AND Utility_Account_Subscription__r.Opportunity__r.Account.Total_Outstanding_Balance_Merge__c > : minimumBalance
            AND Utility_Account_Subscription__c NOT IN : uasIdsAlreadyBilling
            GROUP BY Utility_Account_Subscription__c
        ];

        for (AggregateResult result : overdueUASBs){
            overdueUASIds.add((String)result.get('uasId'));
        }

        List<Utility_Account_Subscription__c> uasesWithAnOverdueUASB = [
            SELECT Id, (
                // We want to get a SZS for this overdue UAS, with which we can generate a bill
                SELECT Id, Utility_Account_Subscription__c, Utility_Account_Subscription__r.Opportunity__c
                FROM Schedule_Z_Subscriptions__r
                ORDER BY CreatedDate DESC
                LIMIT 1
            )
            FROM Utility_Account_Subscription__c
            WHERE Id IN : overdueUASIds
        ];

        List<Schedule_Z_Subscription__c> szsList = new List<Schedule_Z_Subscription__c>();
        for (Utility_Account_Subscription__c uas : uasesWithAnOverdueUASB) {
            szsList.addAll(uas.Schedule_Z_Subscriptions__r);
        }
        return szsList;
    }
}