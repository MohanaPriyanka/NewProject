public without sharing class PartnerAccountSSSTriggerHandler {
    public static void afterInsert(List<Partner_Account_Shared_Solar_System__c> records) {
        shareSharedSolarSystems(records);
    }

    public static void afterDelete(Map<Id, Partner_Account_Shared_Solar_System__c> oldMap) {
        unshareSharedSolarSystems(oldMap);
    }

    private static void shareSharedSolarSystems(List<Partner_Account_Shared_Solar_System__c> records) {
        Map<Id, Set<Id>> partnerAccountToSharedSolarSystems = new Map<Id, Set<Id>>();
        for (Partner_Account_Shared_Solar_System__c passs : records) {
            if (!partnerAccountToSharedSolarSystems.containsKey(passs.Partner_Account__c)) {
                partnerAccountToSharedSolarSystems.put(passs.Partner_Account__c, new Set<Id>());
            }
            partnerAccountToSharedSolarSystems.get(passs.Partner_Account__c).add(passs.Shared_Solar_System__c);
        }

        Map<Id, Set<Id>> partnerAccountToUsers = getUsersByAccountIds(partnerAccountToSharedSolarSystems.keySet());

        List<Shared_Solar_System__share> shares = new List<Shared_Solar_System__share>();
        for (Id partnerAccountId : partnerAccountToSharedSolarSystems.keySet()) {
            Set<Id> sharedSolarSystemIds = partnerAccountToSharedSolarSystems.get(partnerAccountId);
            Set<Id> partnerIds = partnerAccountToUsers.get(partnerAccountId);
            if (partnerIds != null) {
                for (Id sharedSolarSystemId : sharedSolarSystemIds) {
                    for (Id partnerId : partnerIds) {
                        shares.add(createSharedSolarSystemShare(sharedSolarSystemId, partnerId));
                    }
                }
            }
        }

        if (shares.size() > 0) {
            insert shares;
        }
    }

    private static void unshareSharedSolarSystems(Map<Id, Partner_Account_Shared_Solar_System__c> oldMap) {
        Set<Id> partnerAccountIds = new Set<Id>();
        Set<Id> sharedSolarSystemIds = new Set<Id>();
        for (Partner_Account_Shared_Solar_System__c passs : oldMap.values()) {
            partnerAccountIds.add(passs.Partner_Account__c);
            sharedSolarSystemIds.add(passs.Shared_Solar_System__c);
        }

        Map<Id, Set<Id>> partnerAccountToUsers = getUsersByAccountIds(partnerAccountIds);
        if (partnerAccountToUsers.size() > 0) {
            Set<Id> userIds = new Set<Id>();
            for (Set<Id> userIdList : partnerAccountToUsers.values()) {
                userIds.addAll(userIdList);
            }

            List<Shared_Solar_System__share> shares = [
                SELECT ParentId, UserOrGroupId
                FROM Shared_Solar_System__share
                WHERE ParentId IN :sharedSolarSystemIds AND UserOrGroupId IN :userIds
            ];

            if (shares.size() > 0) {
                Map<Id, Map<Id, Shared_Solar_System__share>> shareMap = new Map<Id, Map<Id, Shared_Solar_System__share>>();
                for (Shared_Solar_System__share share : shares) {
                    if (!shareMap.containsKey(share.ParentId)) {
                        shareMap.put(share.ParentId, new Map<Id, Shared_Solar_System__share>());
                    }
                    Map<Id, Shared_Solar_System__share> userIdToShareMap = shareMap.get(share.ParentId);
                    userIdToShareMap.put(share.UserOrGroupId, share);
                }

                List<Shared_Solar_System__share> sharesToDelete = new List<Shared_Solar_System__share>();
                for (Partner_Account_Shared_Solar_System__c passs : oldMap.values()) {
                    Set<Id> tempUserIds = partnerAccountToUsers.get(passs.Partner_Account__c);
                    Map<Id, Shared_Solar_System__share> tempShareMap = shareMap.get(passs.Shared_Solar_System__c);
                    if (tempUserIds != null && tempShareMap != null) {
                        for (Id userId : tempUserIds) {
                            Shared_Solar_System__share tempShare = tempShareMap.get(userId);
                            if (tempShare != null) {
                                sharesToDelete.add(tempShare);
                            }
                        }
                        
                    }
                }

                if (sharesToDelete.size() > 0) {
                    delete sharesToDelete;
                }
            }
        }
    }

    private static Shared_Solar_System__share createSharedSolarSystemShare(Id sharedSolarSystemId, Id userId) {
        return new Shared_Solar_System__share(
            ParentId = sharedSolarSystemId,
            UserOrGroupId = userId,
            AccessLevel = 'Read',
            RowCause = Schema.Shared_Solar_System__share.RowCause.Manual
        );
    }

    private static Map<Id, Set<Id>> getUsersByAccountIds(Set<Id> accountIds) {
        List<User> users = [
            SELECT Id, AccountId
            FROM User
            WHERE AccountId IN :accountIds
        ];
        Map<Id, Set<Id>> partnerAccountToUsers = new Map<Id, Set<Id>>();
        for (User u : users) {
            if (!partnerAccountToUsers.containsKey(u.AccountId)) {
                partnerAccountToUsers.put(u.AccountId, new Set<Id>());
            }
            partnerAccountToUsers.get(u.AccountId).add(u.Id);
        }
        return partnerAccountToUsers;
    }
}