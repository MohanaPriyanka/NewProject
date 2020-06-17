/**
 * Created by SarahRenfro on 11/15/2019.
 *
 * Description: Used to create/update/insert Subscription Orders and Shared Solar System Orders
 *
 * Tested By: SubscriptionManagementServiceTest, SubscriptionSizingTestclass
 */
public without sharing class SubscriptionManagementService implements Queueable{
    @TestVisible
    private static UASSelector uasSelector = new UASSelector();
    @TestVisible
    private static SharedSolarSystemsSelector sssSelector = new SharedSolarSystemsSelector();
    @TestVisible
    private static SubscriptionOrderSelector soSelector = new SubscriptionOrderSelector();
    @TestVisible
    private static OpportunitiesSelector oppSelector = new OpportunitiesSelector();
    public Set<Id> oppIdsWithChangedNMCTariff;
    public Set<Id> oppIdsWithChangedSSS;
    public List<CSUtilityAccountSubscriptionFactory.UASOrder> uasOrders = new List<CSUtilityAccountSubscriptionFactory.UASOrder>();
    public List<Utility_Account_Subscription__c> upsertUASes = new List<Utility_Account_Subscription__c>();
    public List<Subscription_Order__c> soInsertList = new List<Subscription_Order__c>();
    public void execute(QueueableContext context) {
        FeatureService featureService = new FeatureService();
        if (oppIdsWithChangedNMCTariff != null && featureService.isEnabled('Subscription_Orders')) {
            changeNMCTariff(oppIdsWithChangedNMCTariff);
        }
        if (oppIdsWithChangedSSS != null && featureService.isEnabled('Subscription_Orders')) {
            transferSubscriptionsOnSSSChange();
            try {
                //Upsert UASes - for deactivating a uas, update; for inserting new uas, insert
                upsert upsertUASes;
                for (CSUtilityAccountSubscriptionFactory.UASOrder uasOrder : uasOrders){
                    uasOrder.sOrder.Utility_Account_Subscription__c = uasOrder.uas.Id;
                    soInsertList.add(uasOrder.sOrder);
                }
                insert soInsertList;
            } catch (Exception e) {
                Logger.logNow('SubscriptionManagementService', 'handleSSSChange',
                    'Error trying to update Subscriptions after Shared Solar System change on Opportunities:  ' + oppIdsWithChangedSSS +
                        '\n' + e.getMessage() + '\n' + e.getStackTraceString(), Logger.ERROR
                );
            }
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
            so.Effective_Date__c = System.now();
            if (so.RecordTypeId == systemChangeOrderRecordTypeId) {
                so.Approved_Change_in_Percent_Share__c = so.System_Change_Percent_Share_of_System__c - so.Previous_Percent_Share_of_System__c;
                so.Approved_Change_in_Subscription__c = so.System_Change_kW_DC_Rounded__c - so.Previous_kw_DC_Subscription__c;
            } else {
                so.Approved_Change_in_Percent_Share__c = so.Calculated_Change_in_Percent_Share_of_Sy__c;
                if (so.Calculated_Change_in_Subscription_KW_DC__c == null) {
                    throw new Util.BWException('Unable to calculate subscription - please make sure all necessary System Input fields are populated.');
                }
                so.Approved_Change_in_Subscription__c = so.Calculated_Change_in_kW_DC_Rounded__c;
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

        // To prevent calling a future method from a future method
        if(!System.isFuture()) {
            ClientInvoicingFeeAssignmentService.setSubOrderContractFeeDetailInFuture(approvedSOs);
        }
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
    @TestVisible
    private void transferSubscriptionsOnSSSChange() {
        //Get all createable fields for Active Subscriptions - if we add more fields later, this query will still grab them
        List<Utility_Account_Subscription__c> uasList = uasSelector.getUASForCloneByOpp(oppIdsWithChangedSSS);
        Map<Id, Opportunity> oppMap = oppSelector.selectOpportunityMap(oppIdsWithChangedSSS);
        for (Utility_Account_Subscription__c uas : uasList) {
            Utility_Account_Subscription__c cloneUAS = uas.clone(false, true, false, false );
            cloneUAS.Shared_Solar_System__c = oppMap.get(uas.Opportunity__c).Shared_Solar_System__c;
            cloneUAS.Subscription_Comment_c__c = 'UAS created after SSS was changed on Opportunity; ' + cloneUAS.Subscription_Comment_c__c;
            upsertUASes.add(cloneUAS);
            CSUtilityAccountSubscriptionFactory.UASOrder uasOrder = new CSUtilityAccountSubscriptionFactory.UASOrder();
            uasOrder.uas = cloneUAS;
            Subscription_Order__c so = new Subscription_Order__c(
                Type__c = 'Transfer',
                Change_in_Annual_kWh__c = uas.Annual_kWh_Subscription_Future_Rollup__c,
                Change_in_Annual_Cost__c = uas.Annual_Cost_Future_Rollup__c,
                Approval_Status__c = 'Approved',
                Effective_Date__c = System.now()
            );
            uasOrder.sOrder = so;
            uasOrders.add(uasOrder);
            uas.Next_Schedule_Z_Status__c = 'Inactive Subscription';
            upsertUASes.add(uas);
        }
        soInsertList.addAll(zeroSubscriptions(uasList, 'Transfer'));
    }
    public List<Subscription_Order__c> zeroSubscriptions(List<Utility_Account_Subscription__c> uasList, String zeroType) {
        List<Subscription_Order__c> zeroedSOs = new List<Subscription_Order__c>();
        for (Utility_Account_Subscription__c uas : uasList) {
            Subscription_Order__c zeroedSO = new Subscription_Order__c(
                Type__c = zeroType,
                Approval_Status__c = 'Approved',
                Effective_Date__c = System.now(),
                Utility_Account_Subscription__c = uas.Id,
                Comments__c = 'ZEROED'
            );
            if (uas.Subscription_Type__c == 'kWh') {
                zeroedSO.Change_in_Annual_kWh__c = (-1)*uas.Annual_kWh_Subscription_Future_Rollup__c;
            } else {
                zeroedSO.Change_in_Annual_Cost__c =(-1)*uas.Annual_Cost_Future_Rollup__c;
            }
            zeroedSOs.add(zeroedSO);
        }
        return zeroedSOs;
    }
/*****************************************************************************************************
 * TEST ONLY METHOD TO CREATE SUBSCRIPTION ORDERS EVERY TIME A UAS IS INSERTED IN A TEST SETUP METHOD
 *****************************************************************************************************/
    public void insertSubscriptionOrdersForTests(List<Utility_Account_Subscription__c> uasList) {
        List<Subscription_Order__c> soList = createSubscriptionOrdersForTests(uasList);
        insert soList;
    }
    public List<Subscription_Order__c> createSubscriptionOrdersForTests(List<Utility_Account_Subscription__c> uasList) {
        List<Subscription_Order__c> soInserts = new List<Subscription_Order__c>();
        Set<Id> oppIds = new Set<Id>();
        //Do not want to create subscription orders for the leads that have undergone Conversion (automatically get SOs)
        for (Utility_Account_Subscription__c uas : uasList) {
            oppIds.add(uas.Opportunity__c);
        }
        Map<Id, Opportunity> oppToSOMap = oppSelector.getOppsForTestMethods(oppIds);
        for (Utility_Account_Subscription__c uas : uasList) {
            //Do not want to create "Initial" subscription orders for uases inserted as a result of SSS change on Opp
            if (oppToSOMap.get(uas.Opportunity__c) != null && uas.Subscription_Comment_c__c == null) {
                Subscription_Order__c so = new Subscription_Order__c(
                    Utility_Account_Subscription__c = uas.Id,
                    Type__c = 'Initial',
                    Effective_Date__c = System.now(),
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
        return soInserts;
    }
}