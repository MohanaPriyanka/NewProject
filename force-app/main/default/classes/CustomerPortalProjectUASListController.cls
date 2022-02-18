/**
 * Created by rebeccanachison on 10/4/21.
 * Description: Called from CustomerPortalProjectUASList lwc.
 *      Finds logged in user's active utility account subscriptions for the Member Portal
 * Tested By: CustomerPortalProjectControllerTest
 */

public without sharing class CustomerPortalProjectUASListController {

    @AuraEnabled(cacheable=true)
    public static List<Utility_Account_Subscription__c> getUtilityAccountSubscriptions() {

        List<Utility_Account_Subscription__c> utilityAccountSubscriptions = new List<Utility_Account_Subscription__c>();

        User currentUser;

        try {
            currentUser = [
                SELECT Id, AccountId
                FROM User
                WHERE Id = :UserInfo.getUserId()
            ];
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }

        if (currentUser == null || currentUser.AccountId == null) {
            throw new AuraHandledException('Cannot find associated account');
        }

        try {
            //Get Utility Account Subscriptions from related completed Community Solar opportunities using the current user's account id
            UASSelector uasSelector = new UASSelector();
            utilityAccountSubscriptions = uasSelector.getActiveUASByParentAccount(currentUser.AccountId);
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }


        return utilityAccountSubscriptions;
    }
}