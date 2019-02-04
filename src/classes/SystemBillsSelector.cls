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

    public static List<SysteM_Bill__c> selectSystemBills() {
        return [
            SELECT Id, Name, Account_Bill__c, Property_Account__c, Opportunity__c, Shared_Solar_System__c,
                Shared_Solar_System_ID2__c, Unique_ID__c, Total_Due__c, Balance_Net_Late_Payments__c, Carry_Over_Balance__c,
                Due_This_Month__c, Bill_Number__c, Date__c, Date_of_Last_Payment__c, Late_Fee_Payments__c, Late_Fees__c,
                Late_Payments__c, Payments_Net_Previous_Balances__c, Previous_Month_Overdue_Balance__c, Total_Payments_This_Month__c,
                Waive_Late_Fees__c, Recurring_Billing__c, Payment_Plan_Balance__c, Payment_Plan_Balance_to_Distribute__c,
                Distribute_This_Balance_as_Payment_Plan__c, Past_Bill_Amount__c, Past_Bill_Payment__c, Refund_this_Balance__c,
                Date_Refunded__c, Adjustments__c, Amount_to_Add__c, Amount_to_Deduct__c, Early_Payments__c,
                Carry_Forward_Adjustments__c, Distribute_This_Balance_12mo__c, Carry_Forward_Payments__c, Balance_Adjustments__c,
                SystemModstamp
            FROM System_Bill__c
        ];
    }
}