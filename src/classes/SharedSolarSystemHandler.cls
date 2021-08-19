// Tested By : ClientBrandingServiceTest, SharedSolarSystemHandlerTest
@SuppressWarnings('PMD.ApexCRUDViolation')
public without sharing class SharedSolarSystemHandler implements Schedulable {

    @TestVisible private static SharedSolarSystemsSelector sssSelector = new SharedSolarSystemsSelector();
    @TestVisible private static SubscriptionOrderSelector subscripOrderSelector = new SubscriptionOrderSelector();
    private static fflib_SObjectUnitOfWork uow = new fflib_SObjectUnitOfWork(
        new List<SObjectType>{
            Shared_Solar_System__c.SObjectType
        }
    );
    private List<Utility_Account_Subscription__c> pendingSmallCSCapacityList;
    private List<Utility_Account_Subscription__c> committedSmallCSCapacityList;
    private List<Utility_Account_Subscription__c> pendingAnchorCapacityList;
    private List<Utility_Account_Subscription__c> committedAnchorCapacityList;
    private List<Utility_Account_Subscription__c> pendingDemandCapacityList;
    private List<Utility_Account_Subscription__c> committedDemandCapacityList;

    public void execute(SchedulableContext sch) {
        try {
            Util.disableTrigger('Disable_SharedSolarSystemTrigger__c');
            uow.registerWork(new Logger());
            updateSSS();
            Util.enableTrigger('Disable_SharedSolarSystemTrigger__c');
        } catch (Exception e) {
            Logger.logNow('SharedSolarSystemHandler', 'execute', e.getMessage() + '\n' + e.getStackTraceString(), Logger.ERROR);
        }
    }

    @AuraEnabled
    public static String updateStage(String sssToUpdate, String newStage) {
        Shared_Solar_System__c sss = new Shared_Solar_System__c();
        sss.Id = sssToUpdate;
        sss.Stage__c = newStage;
        try {
            update sss;
            return 'Success';
        } catch (Exception excep) {
            String customMessage = excep.getMessage();
            if (customMessage.contains('FIELD_CUSTOM_VALIDATION_EXCEPTION')) {
                Integer location = customMessage.indexOf('FIELD_CUSTOM_VALIDATION_EXCEPTION');
                Integer length = customMessage.length();
                customMessage = customMessage.substring(location + 35, length);
            }
            return customMessage;
        }
    }

    public void updateSSS() {
        Map<Id, Shared_Solar_System__c> allSSSes = sssSelector.getAllSSSMap();
        SharedSolarSystemInvoicer systems = new SharedSolarSystemInvoicer();
        summarizeCapacity(allSSSes, uow);
        systems.updateManagementRevenueStartDate(uow, allSSSes.values());
        uow.commitWork();
    }

    public void uncheckApexContext(List<Shared_Solar_System__c> sssList) {
        List<Shared_Solar_System__c> sssToUpdateList = new List<Shared_Solar_System__c>();
        for (Shared_Solar_System__c sss : sssList) {
            if (sss.Apex_Context__c) {
                Shared_Solar_System__c sssToUpdate = new Shared_Solar_System__c();
                sssToUpdate.Id = sss.Id;
                sssToUpdate.Apex_Context__c = false;
                sssToUpdateList.add(sssToUpdate);
            }
        }
        update sssToUpdateList;
    }

    public void summarizeCapacityBeforeUpdate(Map<Id, Shared_Solar_System__c> sssMap) {
        summarizeCapacity(sssMap, uow);
        // Don't uow.commitWork() because this is intended to be called from beforeUpdate
    }

    private void summarizeCapacity(Map<Id, Shared_Solar_System__c> sssMap, fflib_SObjectUnitOfWork uow) {
        //Requerying the sss loses any changes from beforeUpdate - still need to reference sssMap for updated record below
        List<Shared_Solar_System__c> sssesWithActiveUASes = sssSelector.getSSSWithActiveUASes(sssMap.values());
        for (Shared_Solar_System__c sssWithActiveUASes : sssesWithActiveUASes) {
            Shared_Solar_System__c sssToUpdate = sssMap.get(sssWithActiveUASes.Id);
            summarizeCapacityBySubscription(sssWithActiveUASes);
            registerCapacityChanges(sssToUpdate, uow);
        }
    }

    /**
     * @description Determines Pending/Committed Small CS Capacity, Pending/Committed Anchor capacity, and Pending/Committed
     * Demand Capacity based on the individual subscription (UAS)
     * existing subscriptions on the SSS
     * @param sssWithActiveUASes SSS with all necessary fields from selector, including UAS (subscriptions) and UAL fields
     */
    private void summarizeCapacityBySubscription(Shared_Solar_System__c sssWithActiveUASes) {
        pendingSmallCSCapacityList = new List<Utility_Account_Subscription__c>();
        committedSmallCSCapacityList = new List<Utility_Account_Subscription__c>();
        pendingAnchorCapacityList = new List<Utility_Account_Subscription__c>();
        committedAnchorCapacityList = new List<Utility_Account_Subscription__c>();
        pendingDemandCapacityList = new List<Utility_Account_Subscription__c>();
        committedDemandCapacityList = new List<Utility_Account_Subscription__c>();
        for (Utility_Account_Subscription__c uas : sssWithActiveUASes.Utility_Account_Subscriptions__r) {
            if (isAnchorOrPublicOfftake(uas)) {
                addCapacityToCapacityList(uas, committedAnchorCapacityList, pendingAnchorCapacityList);
            } else {
                addCapacityToCapacityList(uas, committedSmallCSCapacityList, pendingSmallCSCapacityList);
            }
            if (isDemandSubscription(sssWithActiveUASes, uas)) {
                addCapacityToCapacityList(uas, committedDemandCapacityList, pendingDemandCapacityList);
            }
        }
    }

    private void addCapacityToCapacityList(
        Utility_Account_Subscription__c uas, List<Utility_Account_Subscription__c> committedCapacityList,
        List<Utility_Account_Subscription__c> pendingCapacityList) {
        if (uas.Opportunity_Stage__c == 'Complete') {
            committedCapacityList.add(uas);
        } else if (!isCancelledStatus(uas)) {
            pendingCapacityList.add(uas);
        }
    }

    /**
     * @description Checks if the UAL is a "Demand" customer (typically exceeding 25 kW of Average Demand). We track this
     * because some projects have caps as to how much capacity can go to "Demand" customers
     * @param sss SSS with necessary parent Utility fields
     * @param uas UAS with necessary parent UAL fields
     * @return TRUE if a demand subscription, else FALSE
     */
    private Boolean isDemandSubscription(Shared_Solar_System__c sss, Utility_Account_Subscription__c uas) {
        Decimal ualAverageDemand = Util.nullToZero(uas.Utility_Account_Log__r.Average_Demand__c);
        return ualAverageDemand >= sss.Utility__r.Average_Demand_Threshold__c && !uas.Utility_Account_Log__r.Exclude_from_Demand_Capacity__c;
    }

    private void registerCapacityChanges(Shared_Solar_System__c sss, fflib_SObjectUnitOfWork uow) {
        sss.Reserved_Capacity_kW_DC__c = String.valueOf(sumCapacity(pendingSmallCSCapacityList));
        sss.Capacity_Committed_kW_DC__c = sumCapacity(committedSmallCSCapacityList);
        sss.Pending_Anchor_Capacity__c = sumCapacity(pendingAnchorCapacityList);
        sss.Anchor_Capacity_Reserved__c = sumCapacity(committedAnchorCapacityList);
        sss.Pending_Demand_Capacity__c = sumCapacity(pendingDemandCapacityList);
        sss.Committed_Demand_Capacity__c = sumCapacity(committedDemandCapacityList);
        uow.registerDirty(sss);
    }

    private Decimal sumCapacity(List<Utility_Account_Subscription__c> uasList) {
        Decimal summarizedCapacity = 0;
        for (Utility_Account_Subscription__c uas : uasList) {
            summarizedCapacity += Util.nullToZero(uas.Future_Customer_Subscription_KWDC_Rollup__c);
        }
        return summarizedCapacity;
    }

    private Boolean isAnchorOrPublicOfftake(Utility_Account_Subscription__c uas) {
        return (uas.Customer_Group__c == 'Anchor' || uas.Opportunity__r.Customer_Sub_Group__c == 'Public Offtake');
    }

    private Boolean isCancelledStatus(Utility_Account_Subscription__c uas) {
        return (uas.Opportunity_Stage__c == 'Expired'
            || uas.Opportunity_Stage__c == 'Cancelled'
            || uas.Opportunity_Stage__c == 'DUPLICATE'
            || uas.Opportunity_Stage__c == 'Unqualified'
            || uas.Opportunity_Stage__c == 'Rejected Contract'
            || uas.Opportunity_Stage__c == 'Dead'
            || uas.Opportunity_Stage__c == 'Lost'
        );
    }

    public void onUpdateCheckForChangedValues(Map<Id, Shared_Solar_System__c> oldSSSMap, List<Shared_Solar_System__c> newSSSes) {
        Set<Id> sssWithChangedBrandKey = new Set<Id>();
        Map<Id, Shared_Solar_System__c> sssWithChangedReacqStartDate = new Map<Id, Shared_Solar_System__c>();

        for (Shared_Solar_System__c newSSS : newSSSes) {
            Shared_Solar_System__c oldSSS = oldSSSMap.get(newSSS.Id);
            if (newSSS.Client_Brand_Key__c != oldSSS.Client_Brand_Key__c
                || newSSS.BWC_Project_Entity_Manual__c != oldSSS.BWC_Project_Entity_Manual__c) {
                sssWithChangedBrandKey.add(newSSS.Id);
            }
            if (newSSS.Reacquisition_Start_Date__c != oldSSS.Reacquisition_Start_Date__c &&
                newSSS.Reacquisition_Start_Date__c < System.today()) {
                sssWithChangedReacqStartDate.put(newSSS.Id, newSSS);
            }
        }
        if (sssWithChangedBrandKey.size() > 0) {
            queueClientBrandKeyUpdate(sssWithChangedBrandKey);
        }
        if (sssWithChangedReacqStartDate.size() > 0) {
            reacquisitionStartDateChange(sssWithChangedReacqStartDate);
        }
    }

    private void queueClientBrandKeyUpdate(Set<Id> sssWithChangedBrandKey) {
        ClientBrandingService brandService = new ClientBrandingService();
        brandService.sssIdWithChangedClientBrandKey = sssWithChangedBrandKey;
        System.enqueueJob(brandService);
    }

    private void reacquisitionStartDateChange(Map<Id, Shared_Solar_System__c> sssWithChangedReacqStartDate) {
        Set<Id> ordersToUpdate = new Set<Id>();
        // We don't want to prevent the enactment of an Allocation Schedule if we hit an error here, so use try/catch:
        try {
            for (Id sssId : sssWithChangedReacqStartDate.keySet()) {
                Date newReacqStartDate = sssWithChangedReacqStartDate.get(sssId).Reacquisition_Start_Date__c;
                // Query within a loop isn't ideal, but it allows us to limit the number of Subscription Orders
                // that are returned by the query by filtering for date and SSS at the same time
                Map<Id, Subscription_Order__c> soMap = subscripOrderSelector.getAcquisitionOrdersBySSS(sssId, newReacqStartDate);
                ordersToUpdate.addAll(soMap.keySet());
            }
            ClientInvoicingFeeAssignmentService service = new ClientInvoicingFeeAssignmentService(ordersToUpdate);
            service.setSubOrderContractFeeDetail();
        } catch (Exception e) {
            Logger.logNow(
                'SharedSolarSystemHandler',
                'reacquisitionStartDateChange',
                e.getMessage() + '\n' + e.getStackTraceString() + '\n' + JSON.serialize(ordersToUpdate),
                Logger.ERROR
            );
        }
    }
}