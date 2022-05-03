// Tested By: UserTriggerHandlerTest
@SuppressWarnings('PMD.ApexCRUDViolation')
public without sharing class UserTriggerHandler {
    public static void afterInsert(List<User> users) {
        shareSharedSolarSystems(users);
        createRelatedContacts(CollectionUtil.getIdSet(users));
        setActiveFlagOnUsers(CollectionUtil.getIdSet(users));
        updateContact(CollectionUtil.getIdSet(users));
    }
    public static void afterUpdate(List<User> users,Map<Id,User> oldMap) {
        setActiveFlagOnUsers(CollectionUtil.getIdSet(users));
        updateContact(CollectionUtil.getIdSet(users));
    }
    
    @Future    
    public static void createRelatedContacts(Set<Id> userIds) {
        List<Contact> insertContactList=new List<Contact>();
        Contact cntObj = new Contact();
        Id perchAccountId = [SELECT Id FROM Account WHERE Name = 'Perch Energy' LIMIT 1]?.Id;
        List<User> users = [SELECT Id, UserType, FirstName, LastName, Email FROM User WHERE Id IN :userIds];
        for (User u : users) {            
            if( u.UserType=='Standard' && u.Email.contains('perchenergy.com') ){
                cntObj=new Contact();
                cntObj.FirstName=u.FirstName;
                cntObj.LastName=u.LastName;
                cntObj.Email=u.Email;
                cntObj.User__c=u.Id;
                cntObj.AccountId=perchAccountId;
                cntObj.RecordTypeId=Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Contact').getRecordTypeId();
                insertContactList.add(cntObj);    
            }
        }
        if(insertContactList != null && insertContactList.size() > 0){
            insert insertContactList;
        }
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
        
        List<Partner_Shared_Solar_System_Eligibility__c> partnerSSSEligibilities = [
            SELECT Account__c, Shared_Solar_System__c
            FROM Partner_Shared_Solar_System_Eligibility__c
            WHERE Account__c IN :partnerAccountIds
        ];
        
        Map<Id, Set<Id>> partnerAccountToSharedSolarSystems = new Map<Id, Set<Id>>();
        for (Partner_Shared_Solar_System_Eligibility__c eligibility : partnerSSSEligibilities) {
            if (!partnerAccountToSharedSolarSystems.containsKey(eligibility.Account__c)) {
                partnerAccountToSharedSolarSystems.put(eligibility.Account__c, new Set<Id>());
            }
            partnerAccountToSharedSolarSystems.get(eligibility.Account__c).add(eligibility.Shared_Solar_System__c);
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
    @Future
    public static void setActiveFlagOnUsers(Set<Id> userIds) {
        List<User> usersToUpdate = new List<User>();  
        for(User u : [SELECT Id, AccountId,IsActive,IsPortalEnabled
                      FROM User
                      WHERE Id IN :userIds AND IsPortalEnabled!=true AND AccountId != null AND (Profile.Name='Community Solar Community User' OR Profile.Name='Community Solar User' OR  Profile.Name='Customer Community Plus Login User') AND IsActive=true]){
                          u.IsPortalEnabled = true;
                          usersToUpdate.add(u);
                      }
        if(usersToUpdate.size()>0){
            update usersToUpdate;
        }
    }
    @Future
    public static void updateContact(Set<Id> userIds) {        
        List<Contact> cnt = new List<Contact>();  
        for(User u : [SELECT Id, AccountId, IsActive, IsPortalEnabled, ContactId, Contact.Active_Communities_User__c
                      FROM User
                      WHERE Id IN :userIds AND ContactId!=null AND Contact.Active_Communities_User__c!= true AND IsActive=true AND (Profile.Name='Community Solar User' OR Profile.Name='Community Solar Community User' OR Profile.Name='Customer Community Plus Login User' ) ]){
                          Contact cntobj = new Contact();
                          cntobj.Id=u.contactId;
                          cntobj.Active_Communities_User__c=true;
                          cnt.add(cntobj);
                      }
        
        if (cnt.size()>0){
            update cnt;            
        }
    }
}
