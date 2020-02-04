/**
 * Created by SarahRenfro on 11/15/2019.
 *
 * Description: Used to create/update/insert Subscription Orders and Shared Solar System Orders
 *
 * Tested By: SubscriptionManagementServiceTest
 */

public without sharing class SubscriptionManagementService{
    @TestVisible
    private static UASSelector uasSelector = new UASSelector();
    @TestVisible
    private static SharedSolarSystemsSelector sssSelector = new SharedSolarSystemsSelector();

    public void populateSubscriptionOrder(List<Subscription_Order__c> soList) {
        Set<Id> uasIds = new Set<Id>();
        for (Subscription_Order__c so : soList) {
            uasIds.add(so.Utility_Account_Subscription__c);
        }

        Map<Id, Utility_Account_Subscription__c> uasMap = uasSelector.getUASMap(uasIds);

        for (Subscription_Order__c so : soList) {
            Utility_Account_Subscription__c uas = uasMap.get(so.Utility_Account_Subscription__c);
            if (uas != null) {
                so.Client_Account__c = uas.Shared_Solar_System__r.Client_Account__c;
                so.Expected_Yield_kWh_kW__c = uas.Shared_Solar_System__r.Expected_Yield_kWh_kW__c;
                so.Total_System_Size_kW_DC__c = uas.Shared_Solar_System__r.Total_System_Size_kWh_DC__c;
                so.Utility_Number_of_Decimal_Places__c = uas.Shared_Solar_System__r.Utility__r.Number_of_Decimal_Places__c;
                so.Utility_NMC_Tariff__c = uas.Opportunity__r.NMC_Tariff__c;
                so.Value_of_NMC__c = uas.Opportunity__r.NMC_Tariff__r.Value_of_NMC__c;
                so.Product__c = uas.Opportunity__r.Product__c;
            }
        }
    }

    @SuppressWarnings('PMD.ApexCRUDViolation')
    private void stampApprovedValues(List<Subscription_Order__c> soList) {
        List<Subscription_Order__c> stampedSOs = new List<Subscription_Order__c>();
        for (Subscription_Order__c so : soList) {
            Subscription_Order__c clone = new Subscription_Order__c(Id = so.Id);
            if (so.RecordType.Name == 'System Change Order') {

                clone.Approved_Change_in_Percent_Share__c = so.System_Change_Percent_Share_of_System__c - so.Previous_Percent_Share_of_System__c;
                clone.Approved_Change_in_Subscription__c = so.System_Change_kW_DC_Subscription__c - so.Previous_kw_DC_Subscription__c;
            } else {
                clone.Approved_Change_in_Percent_Share__c = so.Calculated_Change_in_Percent_Share_of_Sy__c;
                clone.Approved_Change_in_Subscription__c = so.Calculated_Change_in_Subscription_KW_DC__c;
            }
            stampedSOs.add(clone);
        }

        if (stampedSOs.size() > 0 ) {
            update stampedSOs;
        }
    }


    @SuppressWarnings('PMD.ApexCRUDViolation')
    public void handleSystemOrderChange(List<Shared_Solar_System_Order__c> sssoList, Map<Id, Shared_Solar_System_Order__c> oldMap) {
        List<Shared_Solar_System__c> sssToUpdate = new List<Shared_Solar_System__c>();
        List<Subscription_Order__c> soListToInsert = new List<Subscription_Order__c>();
        FeatureService featureService = new FeatureService();

        if (featureService.isEnabled('Subscription_Orders')) {
            return;
        }

        //TODO: Yes i know this loop has queries in it but SSSOs be approved in Bulk
        for(Shared_Solar_System_Order__c ssso : sssoList) {
            if (ssso.Approval_Status__c == 'Approved' && oldMap.get(ssso.Id).Approval_Status__c != 'Approved') {
                Shared_Solar_System__c sss = updateSSSFromSSSO(ssso);
                sssToUpdate.add(sss);
                List<Utility_Account_Subscription__c> uasList = uasSelector.selectBySharedSolarSystem(ssso.Shared_Solar_System__c);
                List<Subscription_Order__c> soList = createSystemChangeOrders(uasList, ssso);
                soListToInsert.addAll(soList);
            }
        }

        update sssToUpdate;
        insert soListToInsert;
    }

    public Shared_Solar_System__c updateSSSFromSSSO(Shared_Solar_System_Order__c ssso) {
        Shared_Solar_System__c sssToUpdate = sssSelector.selectOne(ssso.Shared_Solar_System__c);
        sssToUpdate.Apex_Context__c = true;
        if (ssso.Total_System_Size_kW_DC__c != null && (ssso.Total_System_Size_kW_DC__c != sssToUpdate.Total_System_Size_kWh_DC__c)) {
            sssToUpdate.Total_System_Size_kWh_DC__c = ssso.Total_System_Size_kW_DC__c;
        }

        if (ssso.Yield__c != null && (ssso.Yield__c != sssToUpdate.Expected_Yield_kWh_kW__c)) {
            sssToUpdate.Expected_Yield_kWh_kW__c = ssso.Yield__c;
        }

        return sssToUpdate;
    }


    public List<Subscription_Order__c> createSystemChangeOrders(List<Utility_Account_Subscription__c> uasList, Shared_Solar_System_Order__c ssso) {

        Id systemChangeOrderRecordTypeId = Schema.SObjectType.Subscription_Order__c.getRecordTypeInfosByName().get('System Change Order').getRecordTypeId();
        List<Subscription_Order__c> soList = new List<Subscription_Order__c>();

        for (Utility_Account_Subscription__c uas : uasList) {
            Subscription_Order__c so = new Subscription_Order__c(
                RecordTypeId = systemChangeOrderRecordTypeId,
                Utility_Account_Subscription__c = uas.Id,
                Approval_Status__c = 'Approved',
                Effective_Date__c = System.now(),
                Previous_Annual_Cost__c = uas.Annual_Cost_Future_Rollup__c,
                Previous_Annual_kwh__c = uas.Annual_kWh_Subscription_Future_Rollup__c,
                Previous_kw_DC_Subscription__c = uas.Future_Customer_Subscription_KWDC_Rollup__c,
                Previous_Percent_Share_of_System__c = uas.Future_Share_of_System_Rollup__c
            );

            if (ssso != null) {
                so.Shared_Solar_System_Order__c = ssso.Id;
                so.Type__c = 'Shared Solar System Update';
            }

            soList.add(so);
        }

        return soList;
    }

    public void checkSOApproval(List<Subscription_Order__c> soList, Map<Id, Subscription_Order__c> oldMap) {
        List<Subscription_Order__c> approvedSOs = new List<Subscription_Order__c>();
        for (Subscription_Order__c so : soList) {
            if (so.Approval_Status__c == 'Approved' && (oldMap == null || (oldMap != null && oldMap.get(so.Id).Approval_Status__c != 'Approved'))) {
                approvedSOs.add(so);
            }
        }

        if (approvedSOs.size() > 0 ) {
            stampApprovedValues(approvedSOs);
        }
    }

}