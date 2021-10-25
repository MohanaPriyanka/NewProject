/**
 * @description Transfers subscriptions between or within customers. They need three Subscription Orders: one to zero
 * out the old UAS, a Transfer SO to move the old capacity to the new UAS, and a Resize to handle any change in capacity
 * due to yield, system size, or decimal changes.
 * Tested By: SubscriptionTransferServiceTest, ClientReportingServiceTest
 */
public without sharing class SubscriptionTransferService {
    private static UASSelector uasSelectorInstance = new UASSelector();
    @TestVisible private static SharedSolarSystemsSelector sssSelector = new SharedSolarSystemsSelector();
    private static SubscriptionTransferCalculator calculator = new SubscriptionTransferCalculator();
    @TestVisible private static EntitySelector entitySelector = new EntitySelector();
    @TestVisible private static ScheduleZSubscriptionSelector alssSelector = new ScheduleZSubscriptionSelector();
    @TestVisible private static final String OPP_ON_ACTIVE_ALS = 'This Opportunity has UASes that are on an ALS that is not rejected';
    @TestVisible private static final String INVALID_CONTRACT_ASSIGNMENT_ENTITY =
        'Opportunity\'s Contract has an Assignment Agreement and the requested system has a Contract Assignment Entity ' +
            'that is different from that of the existing system. Valid systems to transfer to are:';
    @TestVisible private static fflib_SObjectUnitOfWork uowForTransferSO = new fflib_SObjectUnitOfWork(
        new List<SObjectType>{
            Opportunity.SObjectType,
            Subscription_Transfer__c.SObjectType,
            Utility_Account_Subscription__c.SObjectType,
            Subscription_Order__c.SObjectType
        }
    );
    // Since the Resize SO depends on UAS Future_Customer_Subscription_KWDC_Rollup__c including the value of the new
    // Transfer SO, the Resize SO needs to happen in a subsequent transaction
    @TestVisible private static fflib_SObjectUnitOfWork uowForResizeSO = new fflib_SObjectUnitOfWork(
        new List<SObjectType>{
            Subscription_Order__c.SObjectType
        }
    );

    // Updating the old uas records to inactive needs to happen before inserting the new uas records
    @TestVisible private static fflib_SObjectUnitOfWork uowForUpdateOldUASRecords = new fflib_SObjectUnitOfWork(
        new List<SObjectType>{
            Utility_Account_Subscription__c.SObjectType
        }
    );

    /**
     * @description Changes the SSS on the opportunity by:
     * - zeroing out the existing UASes
     * - setting the existing UASes to inactive
     * - creating a new UAS for each of the existing UASes on the new SSS
     * - creating a new subscription order for each of the new UASes
     * - updating the opportunity's SSS
     * @param oppId oppId
     * @param newSSSId new SSS Id
     * @return Request object with success/error information
     */
    public List<InvocableOpportunitySystemUpdater.Request> changeOpportunitySSS(Id oppId, Id newSSSId) {
        Shared_Solar_System__c sss = sssSelector.selectOne(newSSSId);
        List<Opportunity> opportunities = OpportunitiesSelector.selectByIds(new List<Id>{
            oppId
        });
        try {
            validateNewSSSForOpp(opportunities[0], sss);
        } catch (Exception e) {
            InvocableOpportunitySystemUpdater.Request request = new InvocableOpportunitySystemUpdater.Request();
            request.opportunityId = oppId;
            request.sssId = newSSSId;
            request.isSuccess = false;
            request.errorMessage = e.getMessage();
            return new List<InvocableOpportunitySystemUpdater.Request>{
                request
            };
        }
        Opportunity opp = new Opportunity(
            Id = oppId,
            Shared_Solar_System__c = newSSSId
        );
        uowForTransferSO.registerDirty(opp);
        //Get all createable fields for Active Subscriptions - if we add more fields later, this query will still grab them
        List<Utility_Account_Subscription__c> oldUASes = uasSelectorInstance.getUASForCloneByOpp(new Set<Id>{
            oppId
        });
        for (Utility_Account_Subscription__c oldUAS : oldUASes) {
            Utility_Account_Subscription__c uasForNewSSS = cloneNewUAS(oldUAS, newSSSId, sss.Name);
            Decimal desiredAmount =
                oldUAS.Subscription_Type__c == 'kWh' ? oldUAS.Annual_kWh_Subscription_Future_Rollup__c : oldUAS.Annual_Cost_Future_Rollup__c;
            registerTransferAndResize(oldUAS, uasForNewSSS, sss, desiredAmount);
        }
        UtilityAccountSubscriptions utilityAccountSubscriptions = new UtilityAccountSubscriptions(oldUASes);
        utilityAccountSubscriptions.registerSubscriptionOrdersToZeroOutUAS('Transfer', uowForTransferSO);
        uowForUpdateOldUASRecords.commitWork();
        uowForTransferSO.commitWork();
        uowForResizeSO.commitWork();

        InvocableOpportunitySystemUpdater.Request request = new InvocableOpportunitySystemUpdater.Request();
        request.opportunityId = oppId;
        request.sssId = newSSSId;
        request.isSuccess = true;
        return new List<InvocableOpportunitySystemUpdater.Request>{
            request
        };
    }

    @TestVisible
    private void validateNewSSSForOpp(Opportunity opp, Shared_Solar_System__c sss) {
        List<Schedule_Z_Subscription__c> activeALSSes = alssSelector.getActiveALSSesForOpportunities(new Set<Id>{
            opp.Id
        });
        if (!activeALSSes.isEmpty()) {
            throw new Util.BWException(OPP_ON_ACTIVE_ALS + ':\n' + activeALSSesToString(activeALSSes));
        }
        if (opp.Contract.Assignment_Agreement__c == null || opp.Contract.Assignment_Agreement__r.Status == 'Rejected') {
            return;
        }
        List<Shared_Solar_System__c> sharedSolarSystems =
            entitySelector.getSystemsForContractAssignmentEntity(opp.Shared_Solar_System__r.Contract_Assignment_Entity__c);
        if (!CollectionUtil.getIds(sharedSolarSystems).contains(sss.Id)) {
            throw new Util.BWException('This Opportunity cannot be transferred to ' + sss.Name +
                ' because the ' + INVALID_CONTRACT_ASSIGNMENT_ENTITY + '\n' + validSystemsToString(sharedSolarSystems)
            );
        }
    }

    private String validSystemsToString(List<Shared_Solar_System__c> sharedSolarSystems) {
        String validSystems = '';
        for (Shared_Solar_System__c validSystem : sharedSolarSystems) {
            validSystems += validSystem.Name + '\n';
        }
        return validSystems;
    }

    private String activeALSSesToString(List<Schedule_Z_Subscription__c> activeALSSes) {
        String alsses = '';
        for (Schedule_Z_Subscription__c activeALSS : activeALSSes) {
            alsses += activeALSS.Utility_Account_Subscription__r.Name + ' (' + activeALSS.Schedule_Z__r.Status__c + ')\n';
        }
        return alsses;
    }

    /**
     * @description Transfers a subscription from an existing UAS to another existing UAS (between customers)
     * @param oldUASId Id of the old UAS, with Annual_kWh or cost rollups
     * @param newUASId Id of the new UAS
     * @param amountToTransfer Total amount to transfer, including any resize portion, either in kWh or dollars
     * depending on the subscription type
     */
    public void transferToUAS(Id oldUASId, Id newUASId, Decimal amountToTransfer) {
        Map<Id, Utility_Account_Subscription__c> uasMap =
            new Map<Id, Utility_Account_Subscription__c>(UASSelector.selectByIds(new Set<Id>{
                newUASId, oldUASId
            }));
        Utility_Account_Subscription__c oldUAS = uasMap.get(oldUASId);
        Utility_Account_Subscription__c newUAS = uasMap.get(newUASId);

        if (oldUAS.Subscription_Type__c != newUAS.Subscription_Type__c) {
            throw new Util.BWException('Subscriptions must be the same type, ' +
                'the old UAS is ' + oldUAS.Subscription_Type__c + ' and the new UAS is ' + newUAS.Subscription_Type__c);
        }

        Shared_Solar_System__c sss = sssSelector.selectOne(newUAS.Shared_Solar_System__c);

        registerTransferAndResize(oldUAS, newUAS, sss, amountToTransfer);

        UtilityAccountSubscriptions utilityAccountSubscriptions =
            new UtilityAccountSubscriptions(new List<Utility_Account_Subscription__c>{
                oldUAS
            });
        utilityAccountSubscriptions.registerSubscriptionOrdersToZeroOutUAS('Transfer', uowForTransferSO);
        uowForUpdateOldUASRecords.commitWork();
        uowForTransferSO.commitWork();
        uowForResizeSO.commitWork();
    }

    private void registerTransferAndResize(Utility_Account_Subscription__c oldUAS, Utility_Account_Subscription__c newUAS,
        Shared_Solar_System__c sss, Decimal desiredAnnualkWhOrCost) {
        Subscription_Transfer__c transfer = getNewSubscriptionTransferRecord(oldUAS);
        uowForTransferSO.registerNew(transfer);
        uowForTransferSO.registerDirty(oldUAS, Utility_Account_Subscription__c.Transferred_To__c, transfer);
        if (newUAS.Id == null) {
            uowForTransferSO.registerNew(newUAS, Utility_Account_Subscription__c.Transferred_From__c, transfer);
        } else {
            uowForTransferSO.registerDirty(newUAS, Utility_Account_Subscription__c.Transferred_From__c, transfer);
        }
        Subscription_Order__c transferSO = getNewTransferSO(oldUAS, newUAS, sss);
        uowForTransferSO.registerNew(transferSO, Subscription_Order__c.Utility_Account_Subscription__c, newUAS);

        Subscription_Order__c resizeSO = getNewResizeSO(
            'Residual resize when transferring from UAS ' + oldUAS.Id,
            newUAS.Subscription_Type__c,
            desiredAnnualkWhOrCost
        );
        uowForResizeSO.registerNew(resizeSO, Subscription_Order__c.Utility_Account_Subscription__c, newUAS);
        oldUAS.Next_Schedule_Z_Status__c = 'Inactive Subscription';
        uowForUpdateOldUASRecords.registerDirty(oldUAS);
    }

    private Subscription_Transfer__c getNewSubscriptionTransferRecord(Utility_Account_Subscription__c oldUAS) {
        Subscription_Transfer__c transfer = new Subscription_Transfer__c();
        if (oldUAS.Subscription_Type__c == 'kWh') {
            transfer.Sum_of_Old_Subscriptions__c = oldUAS.Annual_kWh_Subscription_Future_Rollup__c;
            transfer.Sum_of_New_Subscriptions__c = oldUAS.Annual_kWh_Subscription_Future_Rollup__c;
        } else {
            transfer.Sum_of_Old_Subscriptions__c = oldUAS.Annual_Cost_Future_Rollup__c;
            transfer.Sum_of_New_Subscriptions__c = oldUAS.Annual_Cost_Future_Rollup__c;
        }
        return transfer;
    }

    private Subscription_Order__c getNewTransferSO(Utility_Account_Subscription__c oldUAS,
        Utility_Account_Subscription__c newUAS, Shared_Solar_System__c sss) {
        Subscription_Order__c so = new Subscription_Order__c(
            Type__c = 'Transfer',
            Approval_Status__c = 'Approved',
            Effective_Date__c = System.now()
        );
        Decimal amountToTransfer = 0;
        if (oldUAS.Future_Customer_Subscription_KWDC_Rollup__c == 0 &&
            !oldUAS.Subscription_Orders__r.isEmpty() &&
            oldUAS.Subscription_Orders__r[0].Type__c == 'Cancellation') {
            amountToTransfer = oldUAS.Subscription_Orders__r[0].Previous_kw_DC_Subscription__c;
        } else {
            amountToTransfer = oldUAS.Future_Customer_Subscription_KWDC_Rollup__c;
        }
        Decimal annualkWhOrCost = calculator.getAnnualkWhOrCost(
            oldUAS.Subscription_Type__c,
            sss,
            oldUAS.Sizing_Method__r,
            amountToTransfer,
            // If the new UAS already exists, we want to include the current subscription when calculating the amount
            // to back into. But if it doesn't exist yet, it might be cloned and still have a
            // Future_Customer_Subscription_KWDC_Rollup__c value which we want to ignore
            (newUAS.Id == null ? 0 : newUAS.Future_Customer_Subscription_KWDC_Rollup__c)
        );
        setCostOrkWh(so, oldUAS.Subscription_Type__c, annualkWhOrCost);
        so.Comments__c = 'Transferring ' + oldUAS.Future_Customer_Subscription_KWDC_Rollup__c;
        return so;
    }

    private Subscription_Order__c getNewResizeSO(String comment, String subscriptionType, Decimal newAmount) {
        Subscription_Order__c resizeSO = new Subscription_Order__c(
            Type__c = 'Resize',
            Approval_Status__c = 'Approved',
            Effective_Date__c = System.now(),
            Comments__c = comment
        );
        setCostOrkWh(resizeSO, subscriptionType, newAmount);
        return resizeSO;
    }

    private void setCostOrkWh(Subscription_Order__c so, String subscriptionType, Decimal amount) {
        if (subscriptionType == 'kWh') {
            so.New_Annual_kWh__c = amount;
        } else {
            so.New_Annual_Cost__c = amount;
        }
    }

    private Utility_Account_Subscription__c cloneNewUAS(Utility_Account_Subscription__c oldUAS, Id newSSSId, String newSSSName) {
        Utility_Account_Subscription__c uasForNewSSS = oldUAS.clone(false, true, false, false);
        uasForNewSSS.Shared_Solar_System__c = newSSSId;
        uasForNewSSS.Subscription_Comment_c__c = 'UAS created as transfer from  ' + oldUAS.Shared_Solar_System__r.Name +
            ' to ' + newSSSName;
        return uasForNewSSS;
    }
}