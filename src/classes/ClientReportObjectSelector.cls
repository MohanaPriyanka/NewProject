/**
 * Created by SarahRenfro on 10/7/2019.
 *
 * Tested By: ClientReportingServiceTest
 */

public with sharing class ClientReportObjectSelector {
    @SuppressWarnings('PMD.ApexCRUDViolation')
    public static List<Client_Utility_Account_Subscription__c> getClientUASesByUASIds(Set<Id> uasIds) {
        return [
            SELECT Id, Customer__c, Annual_Cost_of_Electricity_Future__c, Annual_kWh_Subscription_Future__c, Shared_Solar_System__c, Utility_Account_Subscription__c
            FROM Client_Utility_Account_Subscription__c
            WHERE Utility_Account_Subscription__c IN :uasIds
        ];
    }

    @SuppressWarnings('PMD.ApexCRUDViolation')
    public static List<Client_Utility_Account_Subscription__c> getClientUASesByOppIds(Set<Id> oppIds) {
        return [
            SELECT Id, Customer__c, Annual_Cost_of_Electricity_Future__c, Annual_kWh_Subscription_Future__c,
                Shared_Solar_System__c, Utility_Account_Subscription__c, Utility_Account_Subscription__r.Opportunity__c,
                Utility_Account_Subscription__r.Shared_Solar_System_Name__c
            FROM Client_Utility_Account_Subscription__c
            WHERE Utility_Account_Subscription__r.Opportunity__c IN :oppIds
        ];
    }

    @SuppressWarnings('PMD.ApexCRUDViolation')
    public static List<Client_Allocation_Schedule_Subscription__c> getClientALSSBySZSIds(Set<Id> szsIds) {
        return [
            SELECT Id, Client_Utility_Account_Subscription__c, Customer_Subscription_kW_DC__c, Allocation_Schedule__c
            FROM Client_Allocation_Schedule_Subscription__c
            WHERE Allocation_Schedule_Subscription__c IN :szsIds
        ];
    }



}