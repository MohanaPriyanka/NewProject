/**
 * Created by PeterYao on 3/12/2019.
 * Tested By: ScheduleZSubscriptionSelector and TestBilLCreationdandPayment
 */

public with sharing class ScheduleZSubscriptionSelector {

    private static String fields = 'Id, Customer_Subscription_kW_DC__c, Percent_Share__c, System_Size_kW_DC__c,' +
        'Utility_Account_Subscription__r.Customer_Subscription_KW_DC_STATIC__c,' +
        'Utility_Account_Subscription__r.Customer_Subscription_KW_DC__c,' +
        'Utility_Account_Subscription__c, ' +
        'Utility_Account_Subscription__r.Id,' +
        'Utility_Account_Subscription__r.Name,' +
        'Utility_Account_Subscription__r.Next_Schedule_Z_Status__c, ' +
        'Utility_Account_Subscription__r.Name_on_Account_From_Log__c, ' +
        'Utility_Account_Subscription__r.Utility_Account_Log__c,' +
        'Utility_Account_Subscription__r.Utility_Account_Log__r.Name,' +
        'Utility_Account_Subscription__r.Utility_Account_Log__r.Premise_Number__c,' +
        'Utility_Account_Subscription__r.UAS_Number__c,' +
        'Utility_Account_Subscription__r.Share_of_System__c,' +
        'Utility_Account_Subscription__r.Max_Account_Bill_Number__c,' +
        'Utility_Account_Subscription__r.Opportunity__c,' +
        'Utility_Account_Subscription__r.Opportunity__r.Name,' +
        'Utility_Account_Subscription__r.Opportunity__r.AccountId,' +
        'Utility_Account_Subscription__r.Opportunity__r.Account.Name,' +
        'Utility_Account_Subscription__r.Opportunity_Stage__c, ' +
        'Utility_Account_Subscription__r.Opportunity__r.Shared_Solar_System__r.Id,' +
        'Utility_Account_Subscription__r.Opportunity__r.Shared_Solar_System__c,' +
        'Utility_Account_Subscription__r.Opportunity__r.Shared_Solar_System__r.Name,' +
        'Utility_Account_Subscription__r.Opportunity__r.Shared_Solar_System__r.Total_System_Size_kwh_dc__c,' +
        'Utility_Account_Subscription__r.Opportunity__r.Shared_Solar_System__r.Billing_Method__c,' +
        'Utility_Account_Subscription__r.Opportunity__r.Shared_Solar_System__r.Billing_Anchors__c,' +
        'Utility_Account_Subscription__r.Opportunity__r.Shared_Solar_System__r.Count_of_Transfers__c,' +
        'Utility_Account_Subscription__r.Opportunity__r.Customer_Group__c,' +
        'Utility_Account_Subscription__r.Opportunity__r.NMC_Value__c,' +
        'Utility_Account_Subscription__r.Opportunity__r.Product__r.NMC_Discount__c,' +
        'Utility_Account_Subscription__r.Opportunity__r.Product__r.NM_Rate_Floor__c,' +
        'Utility_Account_Subscription__r.Opportunity__r.Product__r.Solar_Electricity_Rate__c,' +
        'Utility_Account_Subscription__r.Opportunity__r.Product__r.Pricing_Structure__c,' +
        'Utility_Account_Subscription__r.Opportunity__r.Product__r.Percent_Share_Decimal_Places__c,' +
        'Utility_Account_Subscription__r.Opportunity__r.Product_Escalation_Schedule__c,' +
        'Schedule_Z__r.Shared_Solar_System__r.Utility__r.Credits_Allocated_Rounding_Method__c, ' +
        // To show date of last credit for stopped subscriptions in the preview bills screen
        '(SELECT Id, System_Bill__r.Account_Bill__r.Parent_Account__r.Last_Bill_Send_Date_New_Charges__c, ' +
        '   System_Bill__r.Account_Bill__r.Parent_Account__r.Account_Balance__c ' +
        ' FROM Utility_Account_Subscription_Bills__r ' +
        ' ORDER BY Date__c DESC LIMIT 1) ';

    private static String whereClauseForBilling = 'Schedule_Z__c IN : scheduleZs ' +
        ' AND Stop_Credit_Transfer__c = FALSE ' +
        ' AND ( Utility_Account_Subscription__r.Opportunity__r.Shared_Solar_System__r.Billing_Anchors__c!= \'RadianGen\' ' +
        ' OR Utility_Account_Subscription__r.Opportunity__r.Customer_Group__c= \'Residential\' ' +
        ' OR Utility_Account_Subscription__r.Opportunity__r.Customer_Group__c= \'Non-Residential\' )';

    public static String getQueryString(String whereClause, String orderBy) {
        if (whereClause == null || whereClause == '') {
            whereClause = '';
        } else {
            whereClause = ' WHERE ' + whereClause;
        }
        if (orderBy == null || orderBy == '') {
            orderBy = ' ORDER BY Utility_Account_Subscription__r.Name_on_Account_From_Log__c';
        } else {
            orderBy = ' ORDER BY ' + orderBy;
        }
        return 'SELECT ' + fields + ' FROM Schedule_Z_Subscription__c ' + whereClause + orderBy;

    }

    public static List<Schedule_Z_Subscription__c> getListForBilling(Set<Id> scheduleZs) {
        return Database.query(getQueryString(whereClauseForBilling, null));
    }

    public static List<Schedule_Z_Subscription__c> getScheduleZSubscriptionsList(Set<Id> scheduleZSubscriptionIds) {
        return [
            SELECT Id, Name, Schedule_Z__c, Schedule_Z__r.Id, Utility_Account_Subscription__c
            FROM Schedule_Z_Subscription__c
            WHERE Id IN :scheduleZSubscriptionIds
        ];
    }
}