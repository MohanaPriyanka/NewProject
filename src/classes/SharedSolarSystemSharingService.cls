/**
 * Created by joeychan on 2020-01-31.
 *
 * Sharing Service for the Shared Solar System
 *
 * Tested by: SharedSolarSystemSharingServiceTest.cls
 *
 */
@SuppressWarnings('PMD.ApexCRUDViolation')
public without sharing class SharedSolarSystemSharingService {
    private static UserAndGroupSelector userAndGroupSelector = new UserAndGroupSelector();
    private static SharedSolarSystemsSelector sssSelector = new SharedSolarSystemsSelector();

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
    
    private List<Shared_Solar_System__Share> generateSSSAccess(List<Id> sssIds, List<Id> userIdList, String accessLevel, String rowClause) {
        List<Shared_Solar_System__Share> shareRecords = new List<Shared_Solar_System__Share>();
        for (Id sssId : sssIds) {
            if (sssId == null) {
                continue;
            }
            for (Id userId : userIdList) {
                Shared_Solar_System__Share sssShare = new Shared_Solar_System__Share();
                sssShare.ParentId = sssId;
                sssShare.UserOrGroupId = userId;
                sssShare.AccessLevel = accessLevel;
                sssShare.RowCause = rowClause;
                shareRecords.add(sssShare);
            }
        }
        return shareRecords;
    }
}