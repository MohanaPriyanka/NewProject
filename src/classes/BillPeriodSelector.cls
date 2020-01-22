/**
 * Created by SarahRenfro on 10/14/2019.
 *
 * Tested By: TransferSelector Test
 */

@SuppressWarnings('PMD.ApexCRUDViolation')
public without sharing class BillPeriodSelector {

    public static List<Bill_Period__c> getBillPeriodsByMonth(Integer billMonth, Integer billYear){
        return [
            SELECT Id, Shared_Solar_System__c, Bill_Date__c, Bill_Status__c
            FROM Bill_Period__c
            WHERE CALENDAR_MONTH(Bill_Date__c) = :billMonth
            AND CALENDAR_YEAR(Bill_Date__c) = :billYear
        ];
    }

}