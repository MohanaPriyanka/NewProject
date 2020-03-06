/**
 * Created by pyao on 2/1/2019.
 * Tested By: SystemBillsSelectorTest
 */

public with sharing class SystemBillsSelector {
    public static List<System_Bill__c> selectSystemBillsModifiedAfter(Datetime timestamp) {
        return [
            SELECT Id, Name, SystemModstamp
            FROM System_Bill__c
            WHERE SystemModstamp >= :timestamp
        ];
    }

    private static String fields = 'Id, Account_Bill__c, Account_Bill__r.Parent_Account__c, Account_Bill__r.Published__c, ' +
        'Account_Bill__r.Id, Account_Bill__r.Total_Due__c, Adjustments__c, Balance_Adjustment__c, ' +
        'Balance_Net_Late_Payments__c, Bill_Number__c, ' +
        'Carry_Over_Balance__c, Date__c, Date_of_Last_Payment__c, Date_Refunded__c, Distribute_This_Balance_12mo__c, '+
        'Distribute_This_Balance_as_Payment_Plan__c, Due_This_Month__c, Late_Fee_Payments__c, Late_Fees__c, '+
        'Late_Payments__c, Name, Opportunity__c, Opportunity__r.Id, '+
        'Past_Bill_Amount__c, Past_Bill_Payment__c, Payment_Plan_Balance__c, Payment_Plan_Balance_to_Distribute__c, '+
        'Payments_Net_Previous_Balances__c, Previous_Month_Overdue_Balance__c, Previous_Overpayment__c, '+
        'Property_Account__c, Property_Account__r.Id, Property_Account__r.Parent_Account__r.Id, '+
        'Property_Account_ID__c, Recurring_Billing__c, Shared_Solar_System__c, Shared_Solar_System_ID__c, '+
        'Shared_Solar_System_ID2__c, SystemModstamp, Total_Due__c, Total_Payments_This_Month__c, Unique_ID__c, '+
        'Waive_Late_Fees__c, Monthly_Late_Fee_Interest__c, ' +
        '(SELECT Id, Opportunity__c FROM Utility_Account_Subscription_Bills__r)';

    public static List<System_Bill__c> selectAllSystemBills() {
        return selectAllSystemBills(null, null);
    }

    public static List<System_Bill__c> selectAllSystemBills(String whereClause, String orderBy) {
        if (whereClause == null || whereClause == '') {
            whereClause = '';
        } else {
            whereClause = ' WHERE ' + whereClause;
        }
        if (orderBy == null || orderBy == '') {
            orderBy = ' ORDER BY Bill_Number__c';
        } else {
            orderBy = ' ORDER BY ' + orderBy;
        }
        return Database.query('SELECT ' + fields + ' FROM System_Bill__c ' + whereClause + orderBy);
    }

}