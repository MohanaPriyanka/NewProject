/**
 * @description Transfers subscriptions between or within customers. They need three Subscription Orders: one to zero
 * out the old UAS, a Transfer SO to move the old capacity to the new UAS, and a Resize to handle any change in capacity
 * due to yield, system size, or decimal changes.
 * Tested By: SubscriptionTransferServiceTest
 */
public without sharing class SubscriptionTransferService {
    private static UASSelector uasSelectorInstance = new UASSelector();
    @TestVisible private static SharedSolarSystemsSelector sssSelector = new SharedSolarSystemsSelector();
    private static SubscriptionTransferCalculator calculator = new SubscriptionTransferCalculator();
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

    /**
     * @description Changes the SSS on the opportunity by:
     * - zeroing out the existing UASes
     * - setting the existing UASes to inactive
     * - creating a new UAS for each of the existing UASes on the new SSS
     * - creating a new subscription order for each of the new UASes
     * - updating the opportunity's SSS
     * @param oppId oppId
     * @param newSSSId new SSS Id
     */
    public void changeOpportunitySSS(Id oppId, Id newSSSId) {
        Shared_Solar_System__c sss = sssSelector.selectOne(newSSSId);
        Opportunity opp = new Opportunity(
            Id = oppId,
            Shared_Solar_System__c = newSSSId
        );
        uowForTransferSO.registerDirty(opp);
        //Get all createable fields for Active Subscriptions - if we add more fields later, this query will still grab them
        List<Utility_Account_Subscription__c> oldUASes = uasSelectorInstance.getUASForCloneByOpp(new Set<Id>{oppId});
        for (Utility_Account_Subscription__c oldUAS : oldUASes) {
            Utility_Account_Subscription__c uasForNewSSS = cloneNewUAS(oldUAS, newSSSId, sss.Name);
            Decimal desiredAmount =
                oldUAS.Subscription_Type__c == 'kWh' ? oldUAS.Annual_kWh_Subscription_Future_Rollup__c : oldUAS.Annual_Cost_Future_Rollup__c;
            registerTransferAndResize(oldUAS, uasForNewSSS, sss, desiredAmount);
        }
        UtilityAccountSubscriptions utilityAccountSubscriptions = new UtilityAccountSubscriptions(oldUASes);
        utilityAccountSubscriptions.registerSubscriptionOrdersToZeroOutUAS('Transfer', uowForTransferSO);
        uowForTransferSO.commitWork();
        uowForResizeSO.commitWork();
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
            new Map<Id, Utility_Account_Subscription__c>(UASSelector.selectByIds(new Set<Id>{newUASId, oldUASId}));
        Utility_Account_Subscription__c oldUAS = uasMap.get(oldUASId);
        Utility_Account_Subscription__c newUAS = uasMap.get(newUASId);

        if (oldUAS.Subscription_Type__c != newUAS.Subscription_Type__c) {
            throw new Util.BWException('Subscriptions must be the same type, ' +
                'the old UAS is ' + oldUAS.Subscription_Type__c + ' and the new UAS is ' + newUAS.Subscription_Type__c);
        }

        Shared_Solar_System__c sss = sssSelector.selectOne(newUAS.Shared_Solar_System__c);

        registerTransferAndResize(oldUAS, newUAS, sss, amountToTransfer);

        UtilityAccountSubscriptions utilityAccountSubscriptions =
            new UtilityAccountSubscriptions(new List<Utility_Account_Subscription__c>{oldUAS});
        utilityAccountSubscriptions.registerSubscriptionOrdersToZeroOutUAS('Transfer', uowForTransferSO);
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
        uowForTransferSO.registerDirty(oldUAS);
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
            (newUAS.Id == null?0:newUAS.Future_Customer_Subscription_KWDC_Rollup__c)
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