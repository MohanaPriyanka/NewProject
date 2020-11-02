// Tested By : ClientBrandingServiceTest, SharedSolarSystemHandlerTest
@SuppressWarnings('PMD.ApexCRUDViolation')
public without sharing class SharedSolarSystemHandler implements Schedulable {
    @TestVisible
    private static SharedSolarSystemsSelector sssSelector = new SharedSolarSystemsSelector();
    @TestVisible
    private static SubscriptionOrderSelector subscripOrderSelector = new SubscriptionOrderSelector();
    private static fflib_SObjectUnitOfWork uow = new fflib_SObjectUnitOfWork(
        new List<SObjectType>{Shared_Solar_System__c.SObjectType}
    );
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
        } catch (Exception excep){
            String customMessage = excep.getMessage();
            if (customMessage.contains('FIELD_CUSTOM_VALIDATION_EXCEPTION')){
                Integer location = customMessage.indexOf('FIELD_CUSTOM_VALIDATION_EXCEPTION');
                Integer length = customMessage.length();
                customMessage = customMessage.subString(location + 35, length);
            }
            return customMessage;
        }
    }
    public void updateSSS() {
        Map<Id, Shared_Solar_System__c> allSSSes = sssSelector.getAllSSSMap();
        SharedSolarSystems systems = new SharedSolarSystems(allSSSes.values());
        summarizeCapacity(allSSSes, uow);
        systems.updateManagementRevenueStartDate(uow);
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
        List<Shared_Solar_System__c> sssWithActiveUASes = sssSelector.getSSSWithActiveUASes(sssMap.values());
        for (Shared_Solar_System__c activeSSS : sssWithActiveUASes) {
            Shared_Solar_System__c sss = sssMap.get(activeSSS.Id);
            List<Utility_Account_Subscription__c> pendingSmallCSCapacityList = new List<Utility_Account_Subscription__c>();
            List<Utility_Account_Subscription__c> committedSmallCSCapacityList = new List<Utility_Account_Subscription__c>();
            List<Utility_Account_Subscription__c> committedAnchorCapacityList = new List<Utility_Account_Subscription__c>();
            List<Utility_Account_Subscription__c> pendingAnchorCapacityList = new List<Utility_Account_Subscription__c>();
            Decimal pendingSmallCSCapacity = 0;
            Decimal committedSmallCSCapacity = 0;
            Decimal pendingAnchorCapacity = 0;
            Decimal committedAnchorCapacity = 0;

            for (Utility_Account_Subscription__c uas : activeSSS.Utility_Account_Subscriptions__r) {
                if (!isAnchorOrPublicOfftake(uas) && uas.Opportunity_Stage__c == 'Complete'){
                    committedSmallCSCapacityList.add(uas);
                } else if (!isAnchorOrPublicOfftake(uas) && !isCancelledStatus(uas)) {
                    pendingSmallCSCapacityList.add(uas);
                } else if (isAnchorOrPublicOfftake(uas) && uas.Opportunity_Stage__c == 'Complete') {
                    committedAnchorCapacityList.add(uas);
                } else if (isAnchorOrPublicOfftake(uas) && !isCancelledStatus(uas)) {
                    pendingAnchorCapacityList.add(uas);
                }
            }
            pendingSmallCSCapacity = sumCapacity(pendingSmallCSCapacityList);
            committedSmallCSCapacity = sumCapacity(committedSmallCSCapacityList);
            pendingAnchorCapacity = sumCapacity(pendingAnchorCapacityList);
            committedAnchorCapacity = sumCapacity(committedAnchorCapacityList);

            registerCapacityChanges(sss, uow, pendingSmallCSCapacity, committedSmallCSCapacity, pendingAnchorCapacity, committedAnchorCapacity);
        }
    }

    private void registerCapacityChanges(
        Shared_Solar_System__c sss,
        fflib_SObjectUnitOfWork uow,
        Decimal pendingSmallCSCapacity,
        Decimal committedSmallCSCapacity,
        Decimal pendingAnchorCapacity,
        Decimal committedAnchorCapacity)
    {
        if (sss.Reserved_Capacity_kW_DC__c != String.valueOf(pendingSmallCSCapacity)) {
            sss.Reserved_Capacity_kW_DC__c = String.valueOf(pendingSmallCSCapacity);
            uow.registerDirty(sss, new List<SObjectField>{
                Shared_Solar_System__c.Reserved_Capacity_kW_DC__c
            });
        }
        if (sss.Capacity_Committed_kW_DC__c != committedSmallCSCapacity) {
            sss.Capacity_Committed_kW_DC__c = committedSmallCSCapacity;
            uow.registerDirty(sss, new List<SObjectField>{
                Shared_Solar_System__c.Capacity_Committed_kW_DC__c
            });
        }
        if (sss.Pending_Anchor_Capacity__c != pendingAnchorCapacity) {
            sss.Pending_Anchor_Capacity__c = pendingAnchorCapacity;
            uow.registerDirty(sss, new List<SObjectField>{
                Shared_Solar_System__c.Pending_Anchor_Capacity__c
            });
        }
        if (sss.Anchor_Capacity_Reserved__c != committedAnchorCapacity) {
            sss.Anchor_Capacity_Reserved__c = committedAnchorCapacity;
            uow.registerDirty(sss, new List<SObjectField>{
                Shared_Solar_System__c.Anchor_Capacity_Reserved__c
            });
        }
    }
    private Decimal sumCapacity(List<Utility_Account_Subscription__c> uasList) {
        Decimal summarizedCapacity = 0;
        for (Utility_Account_Subscription__c uas : uasList) {
            summarizedCapacity += Util.nullToZero(uas.Future_Customer_Subscription_KWDC_Rollup__c);
        }
        return summarizedCapacity;
    }
    private Boolean isAnchorOrPublicOfftake(Utility_Account_Subscription__c uas){
        return (uas.Customer_Group__c == 'Anchor' ||
            uas.Opportunity__r.Customer_Sub_Group__c == 'Public Offtake'
        );
    }
    private Boolean isCancelledStatus(Utility_Account_Subscription__c uas){
        return (uas.Opportunity_Stage__c == 'Expired'
            || uas.Opportunity_Stage__c == 'Cancelled'
            || uas.Opportunity_Stage__c == 'DUPLICATE'
            || uas.Opportunity_Stage__c == 'Unqualified'
            || uas.Opportunity_Stage__c == 'Rejected Contract'
            || uas.Opportunity_Stage__c == 'Dead'
            || uas.Opportunity_Stage__c == 'Lost'
        );
    }

    public void onUpdateCheckForChangedValues(Map<Id, Shared_Solar_System__c> oldSSSMap, List<Shared_Solar_System__c> newSSSes){
        Set<Id> sssWithChangedBrandKey = new Set<Id>();
        Map<Id,Shared_Solar_System__c> sssWithChangedReacqStartDate = new Map<Id,Shared_Solar_System__c>();

        for (Shared_Solar_System__c newSSS : newSSSes){
            Shared_Solar_System__c oldSSS = oldSSSMap.get(newSSS.Id);
            if (newSSS.Client_Brand_Key__c != oldSSS.Client_Brand_Key__c
                || newSSS.BWC_Project_Entity_Manual__c != oldSSS.BWC_Project_Entity_Manual__c){
                sssWithChangedBrandKey.add(newSSS.Id);
            }
            if (newSSS.Reacquisition_Start_Date__c != oldSSS.Reacquisition_Start_Date__c &&
                newSSS.Reacquisition_Start_Date__c < System.Today()){
                sssWithChangedReacqStartDate.put(newSSS.Id,newSSS);
            }
        }
        if (sssWithChangedBrandKey.size() > 0){
            queueClientBrandKeyUpdate(sssWithChangedBrandKey);
        }
        if (sssWithChangedReacqStartDate.size() > 0){
            reacquisitionStartDateChange(sssWithChangedReacqStartDate);
        }
    }

    private void queueClientBrandKeyUpdate(Set<Id> sssWithChangedBrandKey){
        ClientBrandingService brandService = new ClientBrandingService();
        brandService.sssIdWithChangedClientBrandKey = sssWithChangedBrandKey;
        System.enqueueJob(brandService);
    }

    private void reacquisitionStartDateChange(Map<Id,Shared_Solar_System__c> sssWithChangedReacqStartDate){
        Set<Id> ordersToUpdate = new Set<Id>();
        // We don't want to prevent the enactment of an Allocation Schedule if we hit an error here, so use try/catch:
        try {
            for (Id sssId : sssWithChangedReacqStartDate.keySet()){
                Date newReacqStartDate = sssWithChangedReacqStartDate.get(sssId).Reacquisition_Start_Date__c;
                // Query within a loop isn't ideal, but it allows us to limit the number of Subscription Orders
                // that are returned by the query by filtering for date and SSS at the same time
                Map<Id, Subscription_Order__c> soMap = subscripOrderSelector.getAcquisitionOrdersBySSS(sssId,newReacqStartDate);
                ordersToUpdate.addAll(soMap.keySet());
            }
            ClientInvoicingFeeAssignmentService service = new ClientInvoicingFeeAssignmentService();
            service.setSubOrderContractFeeDetail(ordersToUpdate);
        } catch (Exception excep){
            Logger.logNow(
                'SharedSolarSystemHandler',
                'reacquisitionStartDateChange',
                excep.getMessage() + excep.getStackTraceString() + JSON.serialize(ordersToUpdate)
            );
        }
    }
}