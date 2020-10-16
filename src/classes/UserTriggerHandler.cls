public without sharing class UserTriggerHandler {
    public static void afterInsert(List<User> users) {
        shareSharedSolarSystems(users);
    }

    private static void shareSharedSolarSystems(List<User> users) {
        Set<Id> userIds = new Set<Id>();
        for (User u : users) {
            userIds.add(u.Id);
        }

        String partnerAccountRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Partner_Account').getRecordTypeId();
        List<User> partners = [
            SELECT Id, AccountId
            FROM User
            WHERE Id IN :userIds AND AccountId != null AND Account.RecordTypeId = :partnerAccountRecordTypeId
        ];

        Set<Id> partnerIds = new Set<Id>();
        for (User partner : partners) {
            partnerIds.add(partner.Id);
        }

        if (partnerIds.size() > 0) {
            shareSharedSolarSystemsAsync(partnerIds);
        }
    }

    @Future
    private static void shareSharedSolarSystemsAsync(Set<Id> partnerIds) {
        List<User> partners = [
            SELECT Id, AccountId
            FROM User
            WHERE Id IN :partnerIds
        ];
        Set<Id> partnerAccountIds = new Set<Id>();
        for (User partner : partners) {
            partnerAccountIds.add(partner.AccountId);
        }

        List<Partner_Account_Shared_Solar_System__c> passsList = [
            SELECT Partner_Account__c, Shared_Solar_System__c
            FROM Partner_Account_Shared_Solar_System__c
            WHERE Partner_Account__c IN :partnerAccountIds
        ];

        Map<Id, Set<Id>> partnerAccountToSharedSolarSystems = new Map<Id, Set<Id>>();
        for (Partner_Account_Shared_Solar_System__c passs : passsList) {
            if (!partnerAccountToSharedSolarSystems.containsKey(passs.Partner_Account__c)) {
                partnerAccountToSharedSolarSystems.put(passs.Partner_Account__c, new Set<Id>());
            }
            partnerAccountToSharedSolarSystems.get(passs.Partner_Account__c).add(passs.Shared_Solar_System__c);
        }

        List<Shared_Solar_System__share> shares = new List<Shared_Solar_System__share>();
        for (User partner : partners) {
            Set<Id> sharedSolarSystemIds = partnerAccountToSharedSolarSystems.get(partner.AccountId);
            if (sharedSolarSystemIds != null && sharedSolarSystemIds.size() > 0) {
                for (Id sharedSolarSystemId : sharedSolarSystemIds) {
                    shares.add(createSharedSolarSystemShare(sharedSolarSystemId, partner.Id));
                }
            }
        }

        if (shares.size() > 0) {
            insert shares;
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
}