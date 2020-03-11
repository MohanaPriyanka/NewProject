// Tested By : ClientBrandingServiceTest, SharedSolarSystemHandlerTest

@SuppressWarnings('PMD.ApexCRUDViolation')
public without sharing class SharedSolarSystemHandler implements Schedulable {

    @TestVisible
    private static SharedSolarSystemsSelector sssSelector = new SharedSolarSystemsSelector();
    @TestVisible
    private static UASSelector uasSelector = new UASSelector();
    @TestVisible
    private static FeatureService featureService = new FeatureService();

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
        List<Shared_Solar_System__c> newSSSList = sssSelector.getAllSharedSolarSystems();
        List<Shared_Solar_System__c> sssToUpdateList = new List<Shared_Solar_System__c>();

        for (Shared_Solar_System__c oldSSS : sssSelector.getAllSharedSolarSystems()){
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

    public void summarizeCapacity(List<Shared_Solar_System__c> sssList){
        Set <Id> sssIdSet = new Set<Id> ();
        List<Utility_Account_Subscription__c> reservedCapacityList = new List <Utility_Account_Subscription__c>();
        List<Utility_Account_Subscription__c> committedCapacityList = new List <Utility_Account_Subscription__c>();
        List<Utility_Account_Subscription__c> anchorCapacityList = new List <Utility_Account_Subscription__c>();

        for (Shared_Solar_System__c sss : sssList){
            sssIdSet.add(sss.Id);
        }

        List <Utility_Account_Subscription__c> relatedUAS = uasSelector.selectBySharedSolarSystem(sssIdSet);

        for (Utility_Account_Subscription__c uas: relatedUAS) {
            if ((uas.Customer_Group__c != 'Anchor' &&
                uas.Customer_Group__c != 'Public Offtake')
                && uas.Next_Schedule_Z_Status__c == 'Active Subscription'
                && (uas.Opportunity_Stage__c == 'Pending BlueWave Signature'
                || uas.Opportunity_Stage__c == 'QC in Process'
                || uas.Opportunity_Stage__c == 'Pending Quality Control Signature')) {
                reservedCapacityList.add(uas);
            }

            if ((uas.Customer_Group__c != 'Anchor' &&
                uas.Customer_Group__c != 'Public Offtake')
                && uas.Opportunity_Stage__c == 'Complete'
                && uas.Next_Schedule_Z_Status__c == 'Active Subscription') {
                committedCapacityList.add(uas);
            }

            if ((uas.Customer_Group__c == 'Anchor' ||
                uas.Customer_Group__c == 'Public Offtake')
                && uas.Next_Schedule_Z_Status__c == 'Active Subscription') {
                anchorCapacityList.add(uas);
            }
        }

        Boolean soFlag = featureService.isEnabled('Subscription_Orders');

        for (Shared_Solar_System__c sssSummary : sssList) {
            Decimal summarizedReservedCapacity = 0;
            Decimal summarizedCommittedCapacity = 0;
            Decimal summarizedAnchorCapacity = 0;

            if (soFlag) {
                if (reservedCapacityList.size() > 0 ) {
                    summarizedReservedCapacity = summarizeReservedCapacity(reservedCapacityList, sssSummary);
                }

                if (committedCapacityList.size() > 0 ) {
                    summarizedCommittedCapacity = summarizeCommittedCapacity(committedCapacityList, sssSummary);
                }

                if (anchorCapacityList.size() > 0) {
                    summarizedAnchorCapacity = summarizeAnchorCapacity(anchorCapacityList, sssSummary);
                } else if (sssSummary.Stage__c != 'Management') {
                    summarizedAnchorCapacity = sssSummary.Reserved_Anchor_Capacity__c;
                }
            } else {
                if (reservedCapacityList.size() > 0){
                    for (Utility_Account_Subscription__c res: reservedCapacityList){
                        if (res.Shared_Solar_System__c == sssSummary.Id
                            && res.Customer_Subscription_KW_DC__c  != null){
                            summarizedReservedCapacity = res.Customer_Subscription_KW_DC__c + summarizedReservedCapacity;
                        }
                    }
                }
                if (committedCapacityList.size() > 0){
                    for (Utility_Account_Subscription__c comm: committedCapacityList){
                        if (comm.Shared_Solar_System__c == sssSummary.Id
                            && comm.Customer_Subscription_KW_DC__c != null){
                            summarizedCommittedCapacity = comm.Customer_Subscription_KW_DC__c + summarizedCommittedCapacity;
                        }
                    }
                }
                if (anchorCapacityList.size() > 0) {
                    for (Utility_Account_Subscription__c anchor : anchorCapacityList){
                        if (anchor.Shared_Solar_System__c == sssSummary.Id
                            && anchor.Customer_Subscription_KW_DC__c != null){
                            summarizedAnchorCapacity = anchor.Customer_Subscription_KW_DC__c + summarizedAnchorCapacity;
                        }
                    }
                } else if (sssSummary.Stage__c != 'Management') {
                    summarizedAnchorCapacity = sssSummary.Reserved_Anchor_Capacity__c;
                }
            }


            sssSummary.Reserved_capacity_kW_DC__c = String.valueOf(summarizedReservedCapacity);
            sssSummary.Capacity_committed_kW_DC__c = summarizedCommittedCapacity;
            sssSummary.Anchor_capacity_reserved__c = summarizedAnchorCapacity;
        }
    }

    //TODO: THESE METHODS USE THE ROLLUP FIELD ON THE UAS - THE ABOVE IF/ELSE BLOCK WILL BE DEPRECATED AFTER SUBSCRIPTION ORDER RELEASE
    private Decimal summarizeReservedCapacity(List<Utility_Account_Subscription__c> reservedCapacityList, Shared_Solar_System__c sss) {
        Decimal summarizedReservedCapacity = 0;
        for (Utility_Account_Subscription__c res: reservedCapacityList){
            if (res.Shared_Solar_System__c == sss.Id && res.Future_Customer_Subscription_KWDC_Rollup__c  != null){
                summarizedReservedCapacity = res.Future_Customer_Subscription_KWDC_Rollup__c + summarizedReservedCapacity;
            }
        }
        return summarizedReservedCapacity;
    }

    private Decimal summarizeCommittedCapacity(List<Utility_Account_Subscription__c> committedCapacityList, Shared_Solar_System__c sss) {
        Decimal summarizedCommittedCapacity = 0;
        for (Utility_Account_Subscription__c comm : committedCapacityList){
            if (comm.Shared_Solar_System__c == sss.Id && comm.Future_Customer_Subscription_KWDC_Rollup__c != null){
                summarizedCommittedCapacity = comm.Future_Customer_Subscription_KWDC_Rollup__c + summarizedCommittedCapacity;
            }
        }
        return summarizedCommittedCapacity;
    }

    private Decimal summarizeAnchorCapacity(List<Utility_Account_Subscription__c> anchorCapacityList, Shared_Solar_System__c sss) {
        Decimal summarizedAnchorCapacity = 0;
        for (Utility_Account_Subscription__c anchor : anchorCapacityList){
            if (anchor.Shared_Solar_System__c == sss.Id
                && anchor.Future_Customer_Subscription_KWDC_Rollup__c != null){
                summarizedAnchorCapacity = anchor.Future_Customer_Subscription_KWDC_Rollup__c + summarizedAnchorCapacity;
            }
        }
        return summarizedAnchorCapacity;
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