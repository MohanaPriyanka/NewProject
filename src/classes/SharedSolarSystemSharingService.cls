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
    private static SharedSolarSystemsSelector sssSelector = new SharedSolarSystemsSelector();

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
        for (Account acc : [SELECT Id, Parent_Account__c FROM Account WHERE Id IN :propertyIdList AND Parent_Account__c != NULL]) {
            parentAccountIdSet.add(acc.Parent_Account__c);
        }
        for (User user : [SELECT Id FROM User WHERE IsActive = TRUE AND AccountId IN :parentAccountIdSet]) {
            userIdList.add(user.Id);
        }
        evaluateSharingViaUsers(userIdList);
    }

    //Evaluates the Apex based SSS Sharing for the user list
    public void evaluateSharingViaUsers(List<Id> userIdList) {
        Map<Id, List<Id>> parentAccountIdToUserListMap = new Map<Id, List<Id>>();
        for (User user : [SELECT Id, AccountId FROM User WHERE Id IN :userIdList AND AccountId != NULL]) {
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
            if (opp.Shared_Solar_System__c != null) {
                sssShareList.addAll(generateSSSAccess(
                    new List<Id>{opp.Shared_Solar_System__c},
                    parentAccountIdToUserListMap.get(opp.Parent_Account_ID__c),
                    'Read'));
            }
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
            if (eligibility.IsActive__c) {
                partnerAccountToSharedSolarSystems.putValue(eligibility.Account__c, eligibility.Shared_Solar_System__c);
            }
        }
        Set<Id> partnerAccountIds = CollectionUtil.toIds(partnerAccountToSharedSolarSystems.keySet());
        List<User> users =
            userAndGroupSelector.getUsersByAccountIds(partnerAccountIds);
        MultiMap partnerAccountToUsers = MultiMap.newSetInstance();
        for (User user : users) {
            partnerAccountToUsers.putValue(user.AccountId, user.Id);
        }
        List<Shared_Solar_System__Share> shares = new List<Shared_Solar_System__Share>();
        for (Id partnerAccountId : partnerAccountIds) {
            Set<Id> sharedSolarSystemIds = CollectionUtil.toIds(partnerAccountToSharedSolarSystems.getValues(partnerAccountId));
            Set<Id> userIds = CollectionUtil.toIds(partnerAccountToUsers.getValues(partnerAccountId));
            shares.addAll(generateSSSAccess(
                new List<Id>(sharedSolarSystemIds),
                new List<Id>(userIds),
                'Read',
                Schema.Shared_Solar_System__Share.RowCause.Manual)
            );
        }
        insert shares;
    }

    /**
     * @description Creates new shares as partner eligibility records are updated. Logs an error if there are eligibility
     * records updated to become inactive - this should not happen since a validation rule prevents users from updating active 
     * records
     * @param oldMap Trigger.oldMap
     * @param newMap Trigger.newMap
     */
    public void changeSharesAfterEligibilityUpdate(
        Map<Id, Partner_Shared_Solar_System_Eligibility__c> oldMap,
        Map<Id, Partner_Shared_Solar_System_Eligibility__c> newMap) {
        List<Partner_Shared_Solar_System_Eligibility__c> eligibilitiesToShare = new List<Partner_Shared_Solar_System_Eligibility__c>();
        for (Partner_Shared_Solar_System_Eligibility__c newEligibility : newMap.values()) {
            if (oldMap.get(newEligibility.Id).IsActive__c && !newEligibility.IsActive__c) {
                Logger.logLater(
                    'SharedSolarSystemSharingService',
                    'changeSharesAfterEligibilityUpdate',
                    'Did not expect an update to ' + newEligibility.Id + ' to make it change from active to inactive',
                    Logger.ERROR
                );
            } else if (!oldMap.get(newEligibility.Id).IsActive__c && newEligibility.IsActive__c) {
                eligibilitiesToShare.add(newEligibility);
            }
        }
        shareSharedSolarSystems(eligibilitiesToShare);
        Logger.flushLogs();
    }

    /**
     * @description Removes SSS Shares for the list of eligibilities, intended for a scheduled job to call for 
     * eligibilities that end that day
     * @param eligibilities The list of Partner SSS Eligibility records that ended
     */
    public void unshareSharedSolarSystems(List<Partner_Shared_Solar_System_Eligibility__c> eligibilities) {
        Set<Id> partnerAccountIds = new Set<Id>();
        // PartnerSSSEligibilities.validate() ensures that only one eligibility exists for an account/system/day
        Map<String, Partner_Shared_Solar_System_Eligibility__c> eligibilitiesByAccountAndSystem = 
            new Map<String, Partner_Shared_Solar_System_Eligibility__c>();
        for (Partner_Shared_Solar_System_Eligibility__c eligibility : eligibilities) {
            partnerAccountIds.add(eligibility.Account__c);
            eligibilitiesByAccountAndSystem.put(getEligibilityKey(eligibility.Account__c, eligibility.Shared_Solar_System__c), eligibility);
        }
        List<User> users = userAndGroupSelector.getUsersByAccountIds(partnerAccountIds);
        Map<Id, User> userIdMap = new Map<Id, User>(users);
        List<Shared_Solar_System__Share> sharesToDelete = new List<Shared_Solar_System__Share>();
        for (Shared_Solar_System__Share sssShare : sssSelector.getSSSSharesForUsers(users)) {
            String accountSystemKey = getEligibilityKey(userIdMap.get(sssShare.UserOrGroupId)?.AccountId, sssShare.ParentId);
            if (eligibilitiesByAccountAndSystem.containsKey(accountSystemKey)) {
                sharesToDelete.add(sssShare);
            }
        }
        delete sharesToDelete;
    }

    private String getEligibilityKey(Id accountId, Id sssId) {
        return accountId + '|' + sssId;
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