// Tested By : ClientBrandingServiceTest, SharedSolarSystemHandlerTest

@SuppressWarnings('PMD.ApexCRUDViolation')
public without sharing class SharedSolarSystemHandler implements Schedulable {
    private UASSelector uasSelector = new UASSelector();
    private SharedSolarSystemsSelector sssSelector = new SharedSolarSystemsSelector();
    private List<Utility_Account_Subscription__c> reservedCapacityList = new List<Utility_Account_Subscription__c>();
    private List<Utility_Account_Subscription__c> committedCapacityList = new List<Utility_Account_Subscription__c>();
    private List<Utility_Account_Subscription__c> anchorCapacityList = new List<Utility_Account_Subscription__c>();

    public void execute(SchedulableContext sch) {
        updateSSS();
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
        Map<Id, Shared_Solar_System__c> oldSSSMap = new Map<Id, Shared_Solar_System__c>();
        List<Shared_Solar_System__c> newSSSList = sssSelector.getAllSSSes();
        List<Shared_Solar_System__c> sssToUpdateList = new List<Shared_Solar_System__c>();

        for (Shared_Solar_System__c oldSSS : sssSelector.getAllSSSes()){
            oldSSSMap.put(oldSSS.Id, oldSSS);
        }
        summarizeCapacity(newSSSList);

        for (Shared_Solar_System__c newSSS : newSSSList){
            if (newSSS.Reserved_capacity_kW_DC__c != oldSSSMap.get(newSSS.Id).Reserved_capacity_kW_DC__c ||
                newSSS.Capacity_committed_kW_DC__c != oldSSSMap.get(newSSS.Id).Capacity_committed_kW_DC__c ||
                newSSS.Anchor_capacity_reserved__c != oldSSSMap.get(newSSS.Id).Anchor_capacity_reserved__c){
                sssToUpdateList.add(newSSS);
            }
        }
        update sssToUpdateList;
    }

    public void summarizeCapacity(List<Shared_Solar_System__c> sssList){
        Set<Id> sssIds = new Set<Id>();
        Decimal reservedCapacity = 0;
        Decimal committedCapacity = 0;
        Decimal anchorCapacity = 0;

        for (Shared_Solar_System__c sss : sssList){
            sssIds.add(sss.Id);
        }

        List<Utility_Account_Subscription__c> relatedUAS = uasSelector.selectActiveUASBySSS(sssIds);

        for (Utility_Account_Subscription__c uas : relatedUAS) {
            if (!isAnchor(uas) && uas.Opportunity_Stage__c == 'Complete'){
                committedCapacityList.add(uas);
            } else if (!isAnchor(uas) && !isCancelledStatus(uas)){
                reservedCapacityList.add(uas);
            } else if (isAnchor(uas) && !isCancelledStatus(uas)) {
                anchorCapacityList.add(uas);
            }
        }

        for (Shared_Solar_System__c sss : sssList) {
            reservedCapacity = getCapacitySumOfUASList(reservedCapacityList,sss.Id);
            committedCapacity = getCapacitySumOfUASList(committedCapacityList,sss.Id);
            anchorCapacity = getCapacitySumOfUASList(anchorCapacityList,sss.Id);

            sss.Reserved_capacity_kW_DC__c = String.valueOf(reservedCapacity);
            sss.Capacity_committed_kW_DC__c = committedCapacity;
            if (anchorCapacity == 0 && sss.Stage__c != 'Management') {
                sss.Anchor_capacity_reserved__c = sss.Reserved_Anchor_Capacity__c;
            } else {
                sss.Anchor_capacity_reserved__c = anchorCapacity;
            }
        }
    }

    private Decimal getCapacitySumOfUASList(List<Utility_Account_Subscription__c> uasList, Id sssId){
        Decimal summarizedCapacity = 0;
        if (uasList.size() > 0) {
            for (Utility_Account_Subscription__c uas : uasList) {
                if (uas.Opportunity__r.Shared_Solar_System__c == sssId
                    && uas.Customer_Subscription_KW_DC__c != null) {
                    summarizedCapacity += uas.Customer_Subscription_KW_DC__c;
                }
            }
        }
        return summarizedCapacity;
    }

    private Boolean isAnchor(Utility_Account_Subscription__c uas){
        return (uas.Customer_Group__c == 'Anchor' ||
            uas.Customer_Group__c == 'Public Offtake'
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

    public void queueClientBrandKeyUpdate(Map<Id, Shared_Solar_System__c> oldSSSMap, List<Shared_Solar_System__c> newSSSes){
        Set<Id> sssWithChangedBrandKey = new Set<Id>();
        for (Shared_Solar_System__c newSSS : newSSSes){
            Shared_Solar_System__c oldSSS = oldSSSMap.get(newSSS.Id);
            if (newSSS.Client_Brand_Key__c != oldSSS.Client_Brand_Key__c
                || newSSS.BWC_Project_Entity__c != oldSSS.BWC_Project_Entity__c){
                sssWithChangedBrandKey.add(newSSS.Id);
            }
        }
        if (sssWithChangedBrandKey.size() > 0){
            ClientBrandingService brandService = new ClientBrandingService();
            brandService.sssIdWithChangedClientBrandKey = sssWithChangedBrandKey;
            System.enqueueJob(brandService);
        }
    }
}