/**
 * Created by joeychan on 2020-01-31.
 *
 * Sharing Service for the Shared Solar System
 *
 * Tested by: SharedSolarSystemSharingServiceTest.cls
 *
 * Customer Portal User Activation Process fires the Platform Event Portal_User_Activated__e
 * Trigger then uses the SharedSolarSystemSharingService.evaluateSharingViaUsers to share the SSS records based on
 * Opportunity Stage and Product Line
 */
@SuppressWarnings('PMD.ApexCRUDViolation')
public without sharing class SharedSolarSystemSharingService {
    private static UserAndGroupSelector userAndGroupSelector = new UserAndGroupSelector();

    //Evaluates the Apex based SSS Sharing for the Subscription Change Event
    public void evaluateSharingViaSubscriptionChange(List<Subscription_Change_Event__e> subscriptionChangeEventList) {
        List<Id> propertyIdList = new List<Id>();
        for(Subscription_Change_Event__e subscriptionChangeEvent : subscriptionChangeEventList){
            if(subscriptionChangeEvent.Property_Account_Id__c != null){
                propertyIdList.add(subscriptionChangeEvent.Property_Account_Id__c);
            }
        }
        try {
            evaluateSharingViaProperties(propertyIdList);
        } catch (Exception excep){
            Logger.logNow('SharedSolarSystemSharingService',
                'evaluateSharingViaSubscriptionChange',
                JSON.serialize(subscriptionChangeEventList) + excep.getMessage() + '_' + excep.getStackTraceString());
        }
    }
    //Evaluates the Apex based SSS Sharing for the property list
    @TestVisible
    private void evaluateSharingViaProperties(List<Id> propertyIdList) {
        Set<Id> parentAccountIdSet = new Set<Id>();
        List<Id> userIdList = new List<Id>();
        for (Account acc : [SELECT Id, Parent_Account__c FROM Account WHERE Id IN :propertyIdList AND Parent_Account__c != null]) {
            parentAccountIdSet.add(acc.Parent_Account__c);
        }
        for (User user : [SELECT Id FROM User WHERE IsActive = true AND AccountId IN :parentAccountIdSet]) {
            userIdList.add(user.Id);
        }
        evaluateSharingViaUsers(userIdList);
    }

    //Evaluates the Apex based SSS Sharing for the user list
    public void evaluateSharingViaUsers(List<Id> userIdList) {
        Map<Id, List<Id>> parentAccountIdToUserListMap = new Map<Id, List<Id>>();
        for (User user : [SELECT Id, AccountId FROM User WHERE Id IN :userIdList AND AccountId != null]) {
            List<Id> uIdList = parentAccountIdToUserListMap.get(user.AccountId);
            if (uIdList == null) {
                uIdList = new List<Id>();
            }
            uIdList.add(user.Id);
            parentAccountIdToUserListMap.put(user.AccountId, uIdList);
        }
        List<Shared_Solar_System__Share> existingSSSUserShares = [
                SELECT Id
                FROM Shared_Solar_System__Share
                WHERE UserOrGroupId IN :userIdList
                AND RowCause = 'Customer_Portal_Access__c'
        ];
        delete existingSSSUserShares;

        List<Shared_Solar_System__Share> sssShareList = new List<Shared_Solar_System__Share>();
        for (Opportunity opp : [
                SELECT Id, Product_Line__c, Parent_Account_ID__c, Shared_Solar_System__c
                FROM Opportunity
                WHERE Product_Line__c = 'Community Solar'
                AND StageName = 'Complete'
                AND Parent_Account_ID__c IN :parentAccountIdToUserListMap.keySet()
        ]) {
            sssShareList.addAll(generateSSSAccess(new List<Id>{
                    opp.Shared_Solar_System__c
            }, parentAccountIdToUserListMap.get(opp.Parent_Account_ID__c), 'Read'));
        }
        Util.insertAndLog(sssShareList, 'SharedSolarSystemApexSharing', 'evaluateSharingViaUser');
    }

    /**
     * @description Shares systems to partners when new partner eligibility records are inserted
     * @param eligibilities List of Partner_Shared_Solar_System_Eligibility records (Trigger.new)
     */
    public void shareSharedSolarSystems(List<Partner_Shared_Solar_System_Eligibility__c> eligibilities) {
        MultiMap partnerAccountToSharedSolarSystems = MultiMap.newSetInstance();
        for (Partner_Shared_Solar_System_Eligibility__c eligibility : eligibilities) {
            if (eligibility.Active__c) {
                partnerAccountToSharedSolarSystems.putValue(eligibility.Account__c, eligibility.Shared_Solar_System__c);
            }
        }
        Set<Id> partnerAccountIds = CollectionUtil.toIds(partnerAccountToSharedSolarSystems.keySet());
        MultiMap partnerAccountToUsers =
            userAndGroupSelector.getUsersByAccountIds(partnerAccountIds);

        List<Shared_Solar_System__Share> shares = new List<Shared_Solar_System__Share>();
        for (Id partnerAccountId : partnerAccountIds) {
            Set<Id> sharedSolarSystemIds = CollectionUtil.toIds(partnerAccountToSharedSolarSystems.getValues(partnerAccountId));
            Set<Id> userIds = CollectionUtil.toIds(partnerAccountToUsers.getValues(partnerAccountId));
            if (userIds != null) {
                shares.addAll(generateSSSAccess(
                    new List<Id>(sharedSolarSystemIds),
                    new List<Id>(userIds),
                    'Read',
                    Schema.Shared_Solar_System__Share.RowCause.Manual)
                );
            }
        }
        insert shares;
    }

    /**
     * @description Creates new shares, or removes shares, as partner eligibility records are updated
     * @param oldMap Trigger.oldMap
     * @param newMap Trigger.newMap
     */
    public void changeSharesAfterEligibilityUpdate(
        Map<Id, Partner_Shared_Solar_System_Eligibility__c> oldMap,
        Map<Id, Partner_Shared_Solar_System_Eligibility__c> newMap) {
        Set<Id> partnerAccountIdsToUnshare = new Set<Id>();
        Set<Id> sharedSolarSystemIdsToUnshare = new Set<Id>();
        List<Partner_Shared_Solar_System_Eligibility__c> eligibilitiesToShare = new List<Partner_Shared_Solar_System_Eligibility__c>();
        for (Partner_Shared_Solar_System_Eligibility__c newEligibility : newMap.values()) {
            if (oldMap.get(newEligibility.Id).Active__c && !newEligibility.Active__c) {
                partnerAccountIdsToUnshare.add(newEligibility.Account__c);
                sharedSolarSystemIdsToUnshare.add(newEligibility.Shared_Solar_System__c);
            } else if (!oldMap.get(newEligibility.Id).Active__c && newEligibility.Active__c) {
                eligibilitiesToShare.add(newEligibility);
            }
        }
        unshareSharedSolarSystems(partnerAccountIdsToUnshare, sharedSolarSystemIdsToUnshare);
        shareSharedSolarSystems(eligibilitiesToShare);
    }

    /**
     * @description Removes shares when partner eligibility records are deleted
     * @param oldMap Trigger.oldMap
     */
    public void unshareSharedSolarSystemsAfterDelete(Map<Id, Partner_Shared_Solar_System_Eligibility__c> oldMap) {
        Set<Id> partnerAccountIds = new Set<Id>();
        Set<Id> sharedSolarSystemIds = new Set<Id>();
        for (Partner_Shared_Solar_System_Eligibility__c eligibility : oldMap.values()) {
            partnerAccountIds.add(eligibility.Account__c);
            sharedSolarSystemIds.add(eligibility.Shared_Solar_System__c);
        }
        unshareSharedSolarSystems(partnerAccountIds, sharedSolarSystemIds);
    }

    private static void unshareSharedSolarSystems(Set<Id> partnerAccountIds, Set<Id> sharedSolarSystemIds) {
        MultiMap partnerAccountToUsers = userAndGroupSelector.getUsersByAccountIds(partnerAccountIds);
        if (partnerAccountToUsers.isEmpty()) {
            return;
        }

        Set<Id> userIds = CollectionUtil.toIds(partnerAccountToUsers.values());
        List<Shared_Solar_System__Share> shares = [
            SELECT ParentId, UserOrGroupId
            FROM Shared_Solar_System__Share
            WHERE ParentId IN :sharedSolarSystemIds
            AND UserOrGroupId IN :userIds
        ];

        delete shares;
    }

    private List<Shared_Solar_System__Share> generateSSSAccess(List<Id> sssIds, List<Id> userIdList, String accessLevel) {
        return generateSSSAccess(sssIds, userIdList, accessLevel, Schema.Shared_Solar_System__Share.RowCause.Customer_Portal_Access__c);
    }
    private List<Shared_Solar_System__Share> generateSSSAccess(List<Id> sssIds, List<Id> userIdList, String accessLevel, String rowClause) {
        List<Shared_Solar_System__Share> shareRecords = new List<Shared_Solar_System__Share>();
        for (Id record : sssIds) {
            for (Id userId : userIdList) {
                Shared_Solar_System__Share sssShare = new Shared_Solar_System__Share();
                sssShare.ParentId = record;
                sssShare.UserOrGroupId = userId;
                sssShare.AccessLevel = accessLevel;
                sssShare.RowCause = rowClause;
                shareRecords.add(sssShare);
            }
        }
        return shareRecords;
    }
}