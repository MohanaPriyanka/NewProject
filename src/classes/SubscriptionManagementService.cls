/**
 * @description Created by SarahRenfro on 11/15/2019.
 *
 * Description: Used to create/update/insert Subscription Orders and Shared Solar System Orders
 *
 * Tested By: SubscriptionManagementServiceTest, SubscriptionSizingTestclass
 */
@SuppressWarnings('PMD.ApexCRUDViolation')
public without sharing class SubscriptionManagementService {
    @TestVisible private static UASSelector uasSelector = new UASSelector();
    @TestVisible private static SharedSolarSystemsSelector sssSelector = new SharedSolarSystemsSelector();
    @TestVisible private static SubscriptionOrderSelector soSelector = new SubscriptionOrderSelector();
    @TestVisible private static OpportunitiesSelector oppSelector = new OpportunitiesSelector();
    private static CapacityReservationOrderSelector croSelector = new CapacityReservationOrderSelector();
    private static CapacityReserver capacityReserver = new CapacityReserver();
    private static fflib_SObjectUnitOfWork uow = new fflib_SObjectUnitOfWork(
        new List<SObjectType>{
            Shared_Solar_System__c.SObjectType,
            Subscription_Order__c.SObjectType
        }
    );

    public void populateSubscriptionOrder(List<Subscription_Order__c> soList) {
        MultiMap subscriptionOrdersByUASId =
            CollectionUtil.multiMapByField(soList, Subscription_Order__c.Utility_Account_Subscription__c);
        Set<Id> uasIds = CollectionUtil.toIds(subscriptionOrdersByUASId.keySet());
        Map<Id, Utility_Account_Subscription__c> uasMap = uasSelector.getUASMap(uasIds);
        for (Subscription_Order__c so : soList) {
            Utility_Account_Subscription__c uas = uasMap.get(so.Utility_Account_Subscription__c);
            so.Previous_Annual_Cost__c = uas.Annual_Cost_Future_Rollup__c;
            so.Previous_Annual_kwh__c = uas.Annual_kWh_Subscription_Future_Rollup__c;
            so.Previous_kw_DC_Subscription__c = uas.Future_Customer_Subscription_KWDC_Rollup__c;
            so.Previous_Percent_Share_of_System__c = uas.Future_Share_of_System_Rollup__c;
            so.Client_Account__c = uas.Shared_Solar_System__r.Client_Account__c;
            so.Expected_Yield_kWh_kW__c = uas.Shared_Solar_System__r.Expected_Yield_kWh_kW__c;
            so.Total_System_Size_kW_DC__c = uas.Shared_Solar_System__r.Total_System_Size_kWh_DC__c;
            so.Utility_Number_of_Decimal_Places__c = uas.Shared_Solar_System__r.Utility__r.Number_of_Decimal_Places__c;
            so.Product__c = uas.Opportunity__r.Product__c;
            so.Utility_NMC_Tariff__c = uas.Sizing_Method__c;
            so.Value_of_NMC__c = uas.Sizing_Method__r.Value_of_NMC__c;
            so.Size_Ratio__c = uas.Sizing_Method__r.Size_Ratio__c;
            if (so.Approval_Status__c == 'Approved') {
                // Only want to set to "Approved" if we are confident the formulas and calculations were successful
                // A SO is set to "Approved" in the after trigger context with stampApprovedValues()
                // but do not want to throw error if a DataLoad or Test class inserts SOs as "Approved"
                so.Approval_Status__c = null;
            }
        }
    }

    /**
     * @description Evaluate SOs and related records after insert. Must requery via soSelector to retrieve any relationship values
     * Stamp all calculated subscription values and mark the SO as Approved.
     * Validation rules should stop an SO from being inserted without having all the necessary data values to be marked as "Approved"
     *
     * Call 2 future methods:
     *     One to publish SO Change Event to register changes in an Opportunities subscriptions
     *     One to assign CFDs to the SOs
     * @param soMap Map of SOs being inserted or updated
     */
    @SuppressWarnings('PMD.ApexCRUDViolation')
    public void evaluateApprovedSubscriptionOrders(Map<Id, Subscription_Order__c> soMap) {
        List<Subscription_Order__c> sOrdersToApprove = stampApprovedValues(soSelector.selectByIds(soMap.keySet()));

        try {
            update sOrdersToApprove;
        } catch (Exception e) {
            Logger.logNow(
                'SubscriptionManagementService',
                'stampApprovedValues',
                'Failed to insert SOs as Approved:\n' + JSON.serialize(soMap.keySet()) + '\n' +
                    e.getMessage() + '\n' + e.getStackTraceString(),
                Logger.ERROR);
        }

        try {
            publishSubscriptionOrderChangeEvents(sOrdersToApprove);
            ClientInvoicingFeeAssignmentService.setSubOrderContractFeeDetail(soMap.keySet());
        } catch (Exception e) {
            Logger.logNow(
                'SubscriptionManagementService',
                'publishSubscriptionOrderChangeEvents',
                'Did not publish subscription change events, or set CFDs on these SOs:\n' + JSON.serialize(soMap.keySet()) + '\n' +
                    e.getMessage() + '\n' + e.getStackTraceString(),
                Logger.ERROR);
        }
    }

    @TestVisible
    private List<Subscription_Order__c> stampApprovedValues(List<Subscription_Order__c> soList) {
        for (Subscription_Order__c so : soList) {
            so.Effective_Date__c = System.now();
            if (so.System_Change_Percent_Share_of_System__c == null) {
                throw new Util.BWException('A Subscription Order is unable to be created due to the UAS missing required data. Please ensure UAS ' + so.Utility_Account_Subscription__r.Id + ' has: ' + '\n' +
                    '1. An Opportunity' + '\n' +
                    '2. A Shared Solar System' + '\n' +
                    '3. A Sizing Method ' + '\n' +
                    'After populating the correct fields above, try again. If you still experience an error, contact BizApps');
            }
            so.Approved_Change_in_Percent_Share__c = so.System_Change_Percent_Share_of_System__c - so.Previous_Percent_Share_of_System__c;
            so.Approved_Change_in_Subscription__c = so.System_Change_kW_DC_Rounded__c - so.Previous_kw_DC_Subscription__c;
            switch on so.Product__r.Customer_Subscription_Type__c {
                when 'kWh' {
                    so.Change_in_Annual_kWh__c = so.New_Annual_kWh__c - so.Previous_Annual_kwh__c;
                } when else {
                    so.Change_in_Annual_Cost__c = so.New_Annual_Cost__c - so.Previous_Annual_Cost__c;
                }
            }
            so.Approval_Status__c = 'Approved';
        }

        return soList;
    }

    @SuppressWarnings('PMD.ApexCRUDViolation')
    public void handleSharedSolarSystemOrders(List<Shared_Solar_System_Order__c> sssoList, Map<Id, Shared_Solar_System_Order__c> oldMap) {
        List<Shared_Solar_System_Order__c> approvedSSSOs = getApprovedSSSOs(sssoList, oldMap);
        MultiMap crosBySSSO = croSelector.getCapacityReservationOrdersBySSSO(approvedSSSOs);
        for (Shared_Solar_System_Order__c ssso : approvedSSSOs) {
            List<Capacity_Reservation_Order__c> capacityReservationOrders = new List<Capacity_Reservation_Order__c>();
            CollectionUtil.toTypedList(crosBySSSO.getValues(ssso.Id), capacityReservationOrders);
            uow.registerDirty(updateSSSFromSSSO(ssso, capacityReservationOrders));
            List<Utility_Account_Subscription__c> uasList = uasSelector.selectActiveUASBySSS(new Set<Id>{
                ssso.Shared_Solar_System__c
            });
            uow.registerNew(createSystemChangeSubscriptionOrders(uasList, ssso, null));
        }
        uow.commitWork();
    }

    public Shared_Solar_System__c updateSSSFromSSSO(Shared_Solar_System_Order__c ssso, List<Capacity_Reservation_Order__c> capacityReservationOrders) {
        Shared_Solar_System__c sssToUpdate = sssSelector.selectOne(ssso.Shared_Solar_System__c);
        sssToUpdate.Apex_Context__c = true;
        if (ssso.Total_System_Size_kW_DC__c != null && (ssso.Total_System_Size_kW_DC__c != sssToUpdate.Total_System_Size_kWh_DC__c)) {
            sssToUpdate.Total_System_Size_kWh_DC__c = ssso.Total_System_Size_kW_DC__c;
        }
        if (ssso.Yield__c != null && (ssso.Yield__c != sssToUpdate.Expected_Yield_kWh_kW__c)) {
            sssToUpdate.Expected_Yield_kWh_kW__c = ssso.Yield__c;
        }
        capacityReserver.updateSystem(sssToUpdate, capacityReservationOrders);
        return sssToUpdate;
    }

    public List<Subscription_Order__c> createSystemChangeSubscriptionOrders(List<Utility_Account_Subscription__c> uasList, Shared_Solar_System_Order__c ssso, String soComments) {
        List<Subscription_Order__c> soList = new List<Subscription_Order__c>();
        for (Utility_Account_Subscription__c uas : uasList) {
            Subscription_Order__c so = new Subscription_Order__c(
                Utility_Account_Subscription__c = uas.Id,
                Effective_Date__c = System.now(),
                New_Annual_kWh__c = uas.Annual_kWh_Subscription_Future_Rollup__c,
                New_Annual_Cost__c = uas.Annual_Cost_Future_Rollup__c,
                Shared_Solar_System_Order__c = ssso?.Id,
                Type__c = (ssso != null) ? 'Shared Solar System Update' : 'Resize',
                Comments__c = soComments
            );
            soList.add(so);
        }
        return soList;
    }

    public List<Shared_Solar_System_Order__c> getApprovedSSSOs(List<Shared_Solar_System_Order__c> sssoList, Map<Id, Shared_Solar_System_Order__c> oldMap) {
        List<Shared_Solar_System_Order__c> approvedSSSOs =
            (List<Shared_Solar_System_Order__c>) new SObjectFilter(oldMap, sssoList, Shared_Solar_System_Order__c.Approval_Status__c, SObjectFilter.ANY_VALUE, 'Approved')
                .get(SObjectFilter.SOBJECT_LIST);
        return approvedSSSOs;
    }


    /**
     * @description In order to get the related Opportunity from the deleted Subscription Orders and UASes, we have to query
     * for the related UAS (as the relationships for the deleted record have already been removed). Method publishes
     * platform event for Opportunity to reevaluate subscription totals
     * @param subscriptionOrders deleted subscription orders from SOTrigger
     * @param deletedUASMap deleted UASes from UASTrigger
     */
    public void publishSubscriptionOrderChangeEventsOnDelete(List<Subscription_Order__c> subscriptionOrders, Map<Id, Utility_Account_Subscription__c> deletedUASMap) {
        Map<Id, Utility_Account_Subscription__c> uasMap = new Map<Id, Utility_Account_Subscription__c>();
        if (deletedUASMap == null) {
            uasMap = uasSelector.getUASMap(new Set<Id>{
                subscriptionOrders[0].Utility_Account_Subscription__c
            });
        } else {
            uasMap = deletedUASMap;
        }

        Set<Id> oppIds = new Set<Id>();
        for (Utility_Account_Subscription__c uas : uasMap.values()) {
            oppIds.add(uas.Opportunity__c);
        }

        List<Subscription_Order_Change_Event__e> changeEvents = new List<Subscription_Order_Change_Event__e>();
        for (Id oppId : oppIds) {
            Subscription_Order_Change_Event__e event = new Subscription_Order_Change_Event__e(
                Opportunity_Id__c = oppId
            );
            changeEvents.add(event);
        }
        EventBus.publish(changeEvents);
    }

    /**
     * @description Method called to publish a platform event when a subscription order is approved (ie inserted because
     * all subscription orders are inserted as approved). Platform event is passed the Opportunity Id.
     * @param subscriptionOrders Set of Opportunity Ids from Subscription Orders that have been approved
     */
    public void publishSubscriptionOrderChangeEvents(List<Subscription_Order__c> subscriptionOrders) {
        List<Subscription_Order_Change_Event__e> changeEvents = new List<Subscription_Order_Change_Event__e>();
        for (Subscription_Order__c so : subscriptionOrders) {
            Subscription_Order_Change_Event__e event = new Subscription_Order_Change_Event__e(
                Opportunity_Id__c = so.Utility_Account_Subscription__r.Opportunity__r.Id
            );
            changeEvents.add(event);
        }
        EventBus.publish(changeEvents);
    }

    /**
     * @description The Subscription Order Change Event is a platform event that is published to asynchronously summarize
     * an Opportunity's total active subscriptions
     * @param changeEvents Subscription Order Change Events with Opportunity Ids to evaluate
     */
    public void handleSubscriptionOrderChangeEvents(List<Subscription_Order_Change_Event__e> changeEvents) {
        Set<Object> opportunityIds =
            CollectionUtil.multiMapByField(changeEvents, Subscription_Order_Change_Event__e.Opportunity_Id__c).keySet();
        Set<Id> oppIds = CollectionUtil.toIds(opportunityIds);
        Map<Id, Decimal> oppSubscriptionMap = oppSelector.getAggregateOpportunitySubscriptions(oppIds);
        List<Opportunity> oppsToUpdate = new List<Opportunity>();
        for (Id oppId : oppIds) {
            Decimal sumSubscriptions = (oppSubscriptionMap.get(oppId) == null ? 0 : oppSubscriptionMap.get(oppId));
            Opportunity opp = new Opportunity(
                Id = oppId,
                Total_Subscribed_kW_DC__c = sumSubscriptions
            );
            oppsToUpdate.add(opp);
        }

        update oppsToUpdate;
    }
}