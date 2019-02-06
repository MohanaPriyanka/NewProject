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

    public static List<System_Bill__c> selectAllSystemBills() {
        return [
            SELECT Id, Name, Account_Bill__c, Property_Account__c, Opportunity__c, Shared_Solar_System__c,
                Shared_Solar_System_ID2__c, Unique_ID__c, Total_Due__c, Balance_Net_Late_Payments__c, Carry_Over_Balance__c,
                Due_This_Month__c, Bill_Number__c, Date__c, Date_of_Last_Payment__c, Late_Fee_Payments__c, Late_Fees__c,
                Late_Payments__c, Payments_Net_Previous_Balances__c, Previous_Month_Overdue_Balance__c, Total_Payments_This_Month__c,
                Waive_Late_Fees__c, Recurring_Billing__c, Payment_Plan_Balance__c, Payment_Plan_Balance_to_Distribute__c,
                Distribute_This_Balance_as_Payment_Plan__c, Past_Bill_Amount__c, Past_Bill_Payment__c,
                Date_Refunded__c, Adjustments__c, Distribute_This_Balance_12mo__c, Property_Account_ID__c,
                Previous_Overpayment__c, Net_Metering_Credits_Allocated__c, Adjustments_UASB__c, Balance_Adjustment__c,
                Production_kWH__c, Bill_Date__c, Billing_Period_End_Date__c, Billing_Period_Start_Date__c,
                Property_Account__r.Parent_Account__r.Id, Property_Account__r.Id, Shared_Solar_System_ID__c,
                SystemModstamp
            FROM System_Bill__c
            ORDER BY Bill_Number__c
        ];
    }
}