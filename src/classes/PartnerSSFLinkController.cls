/**
 * Created by aingram on 8/20/21.
 */

public with sharing class PartnerSSFLinkController {

    @AuraEnabled
    public static String getNewApplicationLink() {
        User currentUser = getUserFromId(UserInfo.getUserId());
        Contact partnerContact = getContact(currentUser.ContactId);
        String ssfUrl = Util.getCommunitySiteURL('Apply') + '/s/switch?partnerId=';
        ssfUrl += partnerContact.Partner_Lookup__c;
        return ssfUrl;

    }

    public static User getUserFromId(Id userId){
        return [
            SELECT Id, ContactId
            FROM User
            WHERE Id = :userId
            LIMIT 1
        ];
    }

    public static Contact getContact(Id contactId) {
        return [
            SELECT Id, Partner_Lookup__c, Sales_Representative__c
            FROM Contact
            WHERE Id = :contactId
            LIMIT 1
        ];
    }



}