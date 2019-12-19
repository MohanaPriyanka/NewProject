/**
 * Created by SarahRenfro on 9/25/2019.
 *
 * Tested By: TransferSelectorTest
 */

@SuppressWarnings('PMD.ApexCRUDViolation')
public without sharing class TransferSelector {
    public static List<Transfer__c> getTransfersByMonth(Integer billMonth, Integer billYear) {
        return [
            SELECT Id, Name, Shared_Solar_System__c, Shared_Solar_System__r.Id, Shared_Solar_System__r.Name,
                Shared_Solar_System__r.Billing_Method__c, Allocation_Schedule__c, Attempted_Transfer__c, Bill_Period__c,
                Bill_Period__r.Bill_Date__c, Default_Credit_Value__c, Bills_Generated__c, Attempted_kWh_Transfer__c,
                Total_Transferred__c, Transfer_Amount__c, Transfer_kWh__c, Transfer_Type__c, Date_of_Transfer__c, Bill_Period__r.Name,
                Bill_Period__r.Bill_Status__c, Allocation_Schedule__r.Name, Allocation_Schedule__r.Id
            FROM Transfer__c
            WHERE CALENDAR_MONTH(Bill_Period__r.Bill_Date__c) = :billMonth
            AND CALENDAR_YEAR(Bill_Period__r.Bill_Date__c) = :billYear
            AND Transfer_Type__c != 'One-Off'
            AND Transfer_Type__c !='Error'
            ORDER BY Name, Bills_Generated__c
        ];
    }

    public static Transfer__c getTransferById(String transferId) {
        List<Transfer__c> transfers = getAllTransfersById(new List<Id>{transferId});
        if (transfers.isEmpty()) {
            return null;
        } else {
            return transfers[0];
        }
    }

    public static List<Transfer__c> getAllTransfersById(List<Id> transferIdList) {
        return [
            SELECT Id, Name, Shared_Solar_System__c, Shared_Solar_System__r.Id, Shared_Solar_System__r.Name,
                Shared_Solar_System__r.Billing_Method__c, Allocation_Schedule__c, Attempted_Transfer__c, Bill_Period__c,
                Bill_Period__r.Bill_Date__c, Default_Credit_Value__c, Bills_Generated__c, Attempted_kWh_Transfer__c,
                Total_Transferred__c, Transfer_Amount__c, Transfer_Type__c, Date_of_Transfer__c, Bill_Period__r.Name,
                Bill_Period__r.Bill_Status__c, Allocation_Schedule__r.Name, Allocation_Schedule__r.Id
            FROM Transfer__c
            WHERE Id IN : transferIdList
            AND Transfer_Type__c != 'One-Off'
            AND Transfer_Type__c !='Error'
        ];
    }

    //Should this only be for on time or excess? Probably
    public static List<Transfer__c> getAllTransfersBySSS(List<Id> sssIds){
        return [
            SELECT Id, Name, Shared_Solar_System__c, Shared_Solar_System__r.Id, Shared_Solar_System__r.Name,
                Shared_Solar_System__r.Billing_Method__c, Allocation_Schedule__c, Attempted_Transfer__c, Bill_Period__c,
                Bill_Period__r.Bill_Date__c, Default_Credit_Value__c, Bills_Generated__c, Attempted_kWh_Transfer__c,
                Total_Transferred__c, Transfer_Amount__c, Transfer_Type__c, Date_of_Transfer__c, Bill_Period__r.Name,
                Bill_Period__r.Bill_Status__c, Allocation_Schedule__r.Name, Allocation_Schedule__r.Id
            FROM Transfer__c
            WHERE Shared_Solar_System__r.Id IN :sssIds
            AND (Attempted_kWh_Transfer__c != null OR Attempted_Transfer__c != null)
            ORDER By Bill_Period__r.Bill_Date__c ASC
        ];

    }

    public static List<Transfer__c> getTransfersForBillPeriods(Set<Id> sssIds) {
        return [
            SELECT Id, Bills_Generated__c, Bill_Period__c, Shared_Solar_System__c, Date_of_Transfer__c
            FROM Transfer__c
            WHERE Shared_Solar_System__c = :sssIds
            AND Bills_Generated__c = FALSE
            AND Bill_Period__c = NULL
        ];
    }


    public static List<Transfer__c> getAllTransfersByBillPeriod(Set<Id> billPeriodIds) {
        return [
            SELECT Id, Name, Shared_Solar_System__c, Allocation_Schedule__c, Attempted_Transfer__c, Bill_Period__c,
                Bill_Period__r.Bill_Date__c, Default_Credit_Value__c, Bills_Generated__c, Attempted_kWh_Transfer__c,
                Total_Transferred__c, Transfer_Amount__c, Transfer_Type__c, Date_of_Transfer__c, Bill_Period__r.Name,
                Bill_Period__r.Bill_Status__c, Allocation_Schedule__r.Id, Allocation_Schedule__r.Name
            FROM Transfer__c
            WHERE Bill_Period__c IN : billPeriodIds
            AND Transfer_Type__c != 'One-Off'
            AND Transfer_Type__c !='Error'
        ];
    }

}