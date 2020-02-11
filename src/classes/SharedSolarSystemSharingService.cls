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

public with sharing class SharedSolarSystemSharingService {

    //Evaluates the Apex based SSS Sharing for the Subscription Change Event
//    public void evaluateSharingViaSubscriptionChange(List<Subscription_Change_Event__e> subscriptionChangeEventList) {
//        List<Id> propertyIdList = new List<Id>();
//        for(Subscription_Change_Event__e subscriptionChangeEvent : subscriptionChangeEventList){
//            if(subscriptionChangeEvent.Property_Account_Id__c != null){
//                propertyIdList.add(subscriptionChangeEvent.Property_Account_Id__c);
//            }
//        }
//        evaluateSharingViaProperties(propertyIdList);
//    }
    //Evaluates the Apex based SSS Sharing for the property list
    public void evaluateSharingViaProperties(List<Id> propertyIdList) {
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
    public List<Shared_Solar_System__Share> generateSSSAccess(List<Id> recordIds, List<Id> userIdList, String accessLevel) {
        List<Shared_Solar_System__Share> shareRecords = new List<Shared_Solar_System__Share>();
        for (Id record : recordIds) {
            for (Id userId : userIdList) {
                Shared_Solar_System__Share sssShare = new Shared_Solar_System__Share();
                sssShare.ParentId = record;
                sssShare.UserOrGroupId = userId;
                sssShare.AccessLevel = accessLevel;
                sssShare.RowCause = Schema.Shared_Solar_System__Share.RowCause.Customer_Portal_Access__c;
                shareRecords.add(sssShare);
            }
        }
        return shareRecords;
    }
}