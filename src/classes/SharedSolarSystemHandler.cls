/**
 * @description Trigger handler for Shared_Solar_System__c
 * Tested By : ClientBrandingServiceTest, SharedSolarSystemHandlerTest
*/
@SuppressWarnings('PMD.ApexCRUDViolation')
public without sharing class SharedSolarSystemHandler implements Schedulable {

    @TestVisible private static SharedSolarSystemsSelector sssSelector = new SharedSolarSystemsSelector();
    @TestVisible private static SubscriptionOrderSelector subscripOrderSelector = new SubscriptionOrderSelector();
    private static fflib_SObjectUnitOfWork uow;
    private SharedSolarSystemInvoicer invoicer = new SharedSolarSystemInvoicer();
    private SharedSolarSystemCapacityCalculator capacityCalculator = new SharedSolarSystemCapacityCalculator();
    private Map<Id,Shared_Solar_System__c> oldMap;
    private Map<Id,Shared_Solar_System__c> newMap;
    private List<Shared_Solar_System__c> newList;

    /**
     * @description No-arg constructor for use with Schedulable interface
     */
    @SuppressWarnings('PMD.EmptyStatementBlock')
    public SharedSolarSystemHandler() {
    }

    /**
     * @description Constructor for trigger context
     * @param oldMap Trigger.oldMap
     * @param newMap Trigger.newMap
     * @param newList Trigger.new
     */
    public SharedSolarSystemHandler(Map<Id,Shared_Solar_System__c> oldMap, Map<Id,Shared_Solar_System__c> newMap,
        List<Shared_Solar_System__c> newList) 
    {
        this.oldMap = oldMap;
        this.newMap = newMap;
        this.newList = newList;
    }
    
    public void beforeInsert() {
        capacityCalculator.calculateMaximumSubscriptionCapacityForSMART(newList);
        invoicer.updateManagementRevenueStartDateBeforeTrigger(newList);
    }
    
    public void beforeUpdate() {
        new SystemCapacityRollupCalculator(newMap.keySet()).performRollupBeforeUpdate(newMap);
        capacityCalculator.calculateMaximumSubscriptionCapacityForSMART(newList);
        invoicer.updateManagementRevenueStartDateBeforeTrigger(newList);
    }
    
    public void afterUpdate() {
        uncheckApexContext(newList);
        onUpdateCheckForChangedValues(oldMap, newList);
    }

    /**
     * @description Checks/updates Shared_Solar_System__c records on a scheduled frequency as needed
     * @param sch SchedulableContext
     */
    public void execute(SchedulableContext sch) {
        uow = new fflib_SObjectUnitOfWork(new List<SObjectType>{Shared_Solar_System__c.SObjectType});
        try {
            Util.disableTrigger('Disable_SharedSolarSystemTrigger__c');
            updateAllSSS();
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

    @TestVisible
    private void updateAllSSS() {
        Map<Id, Shared_Solar_System__c> allSSSes = sssSelector.getAllSSSMap();
        new SystemCapacityRollupCalculator(allSSSes.keySet()).performRollup();
        SharedSolarSystemInvoicer systemInvoicer = new SharedSolarSystemInvoicer();
        systemInvoicer.updateManagementRevenueStartDate(uow, allSSSes.values());
        uow.commitWork();
        Logger.flushLogs();
    }

    private void uncheckApexContext(List<Shared_Solar_System__c> sssList) {
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

    private void onUpdateCheckForChangedValues(Map<Id, Shared_Solar_System__c> oldSSSMap, List<Shared_Solar_System__c> newSSSes) {
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