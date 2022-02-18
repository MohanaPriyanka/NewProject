/**
 * Created by rebeccanachison on 9/28/21.
 * Description: Called from CustomerPortalProjectCarousel lwc.
 *      Finds logged in user's shared solar systems for the Member Portal
 * Tested By: CustomerPortalProjectControllerTest
 */

public without sharing class CustomerPortalProjectCarouselController {

    @AuraEnabled(cacheable=true)
    public static List<Shared_Solar_System__c> getUserSharedSolarSystems() {

        List<Shared_Solar_System__c> sharedSolarSystems = new List<Shared_Solar_System__c>();

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
            //Get Shared Solar Systems from related completed Community Solar opportunities using the current user's account id
            SharedSolarSystemsSelector sharedSolarSystemsSelector = new SharedSolarSystemsSelector();
            sharedSolarSystems = sharedSolarSystemsSelector.getAllSSSByParentAccount(currentUser.AccountId);
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }


        return sharedSolarSystems;
    }

}