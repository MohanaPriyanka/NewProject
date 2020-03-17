/**
 * Created by SarahRenfro on 11/15/2019.
 *
 * Description: Used to create/update/insert Subscription Orders and Shared Solar System Orders
 *
 * Tested By: SubscriptionManagementServiceTest
 */

public without sharing class SubscriptionManagementService implements Queueable{
    @TestVisible
    private static UASSelector uasSelector = new UASSelector();
    @TestVisible
    private static SharedSolarSystemsSelector sssSelector = new SharedSolarSystemsSelector();
    @TestVisible
    private static SubscriptionOrderSelector soSelector = new SubscriptionOrderSelector();

    public Set<Id> oppIdsWithChangedNMCTariff;

    public void execute(QueueableContext context) {
        FeatureService featureService = new FeatureService();
        if (oppIdsWithChangedNMCTariff != null && featureService.isEnabled('Subscription_Orders')) {
            changeNMCTariff(oppIdsWithChangedNMCTariff);
        }
    }

    @SuppressWarnings('PMD.ApexCRUDViolation')
    public void changeNMCTariff(Set<Id> oppIds) {
        List<Utility_Account_Subscription__c> uases = uasSelector.selectByOpp(oppIds);
        List<Subscription_Order__c> soList = createSystemChangeOrders(uases, null);
        if (soList.size() > 0 ) {
            insert soList;
        }
    }

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

    @TestVisible
    private List<Subscription_Order__c> stampApprovedValues(Set<Id> soIds) {
        Id systemChangeOrderRecordTypeId = Schema.SObjectType.Subscription_Order__c.getRecordTypeInfosByName().get('System Change Order').getRecordTypeId();
        List<Subscription_Order__c> stampSOs = soSelector.selectByIds(soIds);

        for (Subscription_Order__c so : stampSOs ) {
            so.Effective_Date__c = System.today();
            if (so.RecordTypeId == systemChangeOrderRecordTypeId) {
                so.Approved_Change_in_Percent_Share__c = so.System_Change_Percent_Share_of_System__c - so.Previous_Percent_Share_of_System__c;
                so.Approved_Change_in_Subscription__c = so.System_Change_kW_DC_Subscription__c - so.Previous_kw_DC_Subscription__c;
            } else {
                so.Approved_Change_in_Percent_Share__c = so.Calculated_Change_in_Percent_Share_of_Sy__c;
                so.Approved_Change_in_Subscription__c = so.Calculated_Change_in_Subscription_KW_DC__c;
            }
        }

        return stampSOs;
    }


    @SuppressWarnings('PMD.ApexCRUDViolation')
    public void handleSharedSolarSystemOrders(List<Shared_Solar_System_Order__c> sssoList, Map<Id, Shared_Solar_System_Order__c> oldMap) {
        List<Shared_Solar_System__c> sssToUpdate = new List<Shared_Solar_System__c>();
        List<Subscription_Order__c> soListToInsert = new List<Subscription_Order__c>();
        FeatureService featureService = new FeatureService();

        if (!featureService.isEnabled('Subscription_Orders')) {
            return;
        }

        List<Shared_Solar_System_Order__c> approvedSSSOs = checkSSSOApproval(sssoList, oldMap);

        for(Shared_Solar_System_Order__c ssso : approvedSSSOs) {
            Shared_Solar_System__c sss = updateSSSFromSSSO(ssso);
            sssToUpdate.add(sss);
            List<Utility_Account_Subscription__c> uasList = uasSelector.selectActiveUASBySSS(new Set<Id>{ssso.Shared_Solar_System__c});
            List<Subscription_Order__c> soList = createSystemChangeOrders(uasList, ssso);
            soListToInsert.addAll(soList);
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
                so.Type__c = 'Shared Solar System Update';
                so.Shared_Solar_System_Order__c = ssso.Id;
            } else {
                so.Type__c = 'Resize';
            }

            soList.add(so);
        }

        return soList;
    }

    @SuppressWarnings('PMD.ApexCRUDViolation')
    public void checkSOApproval(List<Subscription_Order__c> soList, Map<Id, Subscription_Order__c> oldMap) {
        Set<Id> approvedSOs = new Set<Id>();
        for (Subscription_Order__c so : soList) {
            if (so.Approval_Status__c == 'Approved' && (oldMap == null || (oldMap != null && oldMap.get(so.Id).Approval_Status__c != 'Approved'))) {
                approvedSOs.add(so.Id);
            }
        }

        List<Subscription_Order__c> updateSOs = stampApprovedValues(approvedSOs);
        update updateSOs;

    }

    public List<Shared_Solar_System_Order__c> checkSSSOApproval(List<Shared_Solar_System_Order__c> sssoList, Map<Id, Shared_Solar_System_Order__c> oldMap) {
        List<Shared_Solar_System_Order__c> approvedSSSOs = new List<Shared_Solar_System_Order__c>();
        for (Shared_Solar_System_Order__c ssso : sssoList) {
            if (ssso.Approval_Status__c == 'Approved' && oldMap.get(ssso.Id).Approval_Status__c != 'Approved') {
                approvedSSSOs.add(ssso);
            }
        }

        return approvedSSSOs;
    }

/*****************************************************************************************************
 * TEST ONLY METHOD TO CREATE SUBSCRIPTION ORDERS EVERY TIME A UAS IS INSERTED IN A TEST SETUP METHOD
 *****************************************************************************************************/
    public void createSubscriptionOrdersForTests(List<Utility_Account_Subscription__c> uasList) {

        List<Subscription_Order__c> soInserts = new List<Subscription_Order__c>();
        Set<Id> oppIds = new Set<Id>();

        //Do not want to create subscription orders for the leads that have undergone Conversion (automatically get SOs)
        for (Utility_Account_Subscription__c uas : uasList) {
            oppIds.add(uas.Opportunity__c);
        }

        Map<Id, Opportunity> oppToSOMap = new Map<Id, Opportunity>([
            SELECT Id, Lead__r.IsConverted, Lead__c
            FROM Opportunity
            WHERE Id IN :oppIds
            AND Lead__r.IsConverted = FALSE
        ]);

        for (Utility_Account_Subscription__c uas : uasList) {
            if (oppToSOMap.get(uas.Opportunity__c) != null) {
                Subscription_Order__c so = new Subscription_Order__c(
                    Utility_Account_Subscription__c = uas.Id,
                    Type__c = 'Initial',
                    Effective_Date__c = System.today(),
                    Approval_Status__c = 'Approved'
                );
                if (uas.Subscription_Type__c == 'kWh') {
                    so.Change_in_Annual_kWh__c = uas.Annual_kwh_subscription_future__c;
                } else {
                    so.Change_in_Annual_Cost__c = uas.Subscribed_Annual_Cost_of_Electricity__c;
                }
                soInserts.add(so);
            }
        }

        insert soInserts;
    }
}