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
                c = [Select Id, Phone, MobilePhone, Email, FirstName, LastName, MailingStreet, MailingCity, MailingState, MailingPostalCode, AccountId from Contact where Id = :u.ContactId];
            }
            catch(Exception ex) {

            }
        }
        return c;
    }

    @AuraEnabled
    public static Boolean isPaperless(Id parentAccountId) {
        Boolean isPaperless = true;
        try {
            AccountsSelector selector = new AccountsSelector();
            List<Account> properties = selector.getPropertiesFromParent(new Set<Id>{
                parentAccountId
            });
            for (Account property : properties) {
                if (property.Bill_Delivery_Preference__c != 'Email Only') {
                    isPaperless = false;
                }
            }
        } catch (Exception excep){
            Logger.logNow('MyAccountController','isPaperless',excep.getMessage() + excep.getStackTraceString());
        }
        return isPaperless;
    }

    @AuraEnabled
    public static void setToPaperless(Id parentAccountId) {
        try {
            AccountsSelector selector = new AccountsSelector();
            List<Account> properties = selector.getPropertiesFromParent(new Set<Id>{parentAccountId});
            for (Account property : properties){
                property.Bill_Delivery_Preference__c = 'Email Only';
            }
            update properties;
        } catch (Exception excep){
            Logger.logNow('MyAccountController','setToPaperless',excep.getMessage() + excep.getStackTraceString());
        }
    }

    @AuraEnabled
    public static Contact updateContactInfo(Contact contactToUpdate) {
        update contactToUpdate;
        return contactToUpdate;
    }
}