/*************************************************************************************
 * Created By:  Cole Swain
 *
 * Description: This class handles most actions needed to be performed by the Community Solar Customer Portal's My Account Page.
 *
 * Tested By: CommunitySolarCustomerPortalTest
 *************************************************************************************/

public without sharing class MyAccountController {
    @AuraEnabled
    public static Contact getContactInfo() {
        User u =  [Select Id, ContactId from User where Id = :UserInfo.getUserId()];
        Contact c;
        if (u.ContactId != null) {
            try {
                c = [Select Id, Phone, MobilePhone, Email, FirstName, LastName, MailingStreet, MailingCity, MailingState, MailingPostalCode from Contact where Id = :u.ContactId];
            }
            catch(Exception ex) {

            }
        }
        return c;
    }

    @AuraEnabled
    public static Contact updateContactInfo(Contact contactToUpdate) {
        update contactToUpdate;
        return contactToUpdate;
    }
}