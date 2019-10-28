/*************************************************************************************
 * Created By: peteryao on 10/24/19  
 * Description: Handles DML for Copado objects so we can mock them out
 * Test: CopadoServiceTest
 *************************************************************************************/
@SuppressWarnings('PMD.ApexCRUDViolation')
public with sharing class CopadoService {
    public void insertPromotedUserStories(List<copado__Promoted_User_Story__c> promotedUserStories) {
        insert promotedUserStories;
    }

    public copado__Promotion__c insertPromotion(copado__Promotion__c promotion) {
        if (Test.isRunningTest()) {
            // Because we can't assign managed package licenses in sandbox, and Copado has a custom validation that checks
            // for license, to avoid the error below, we'll skip promotion insertion if it's a test:
            // FIELD_CUSTOM_VALIDATION_EXCEPTION, Copado Deployer License nor Copado Change Management License is enabled. Please contact your administrator.
            String json = '{"attributes":{"type":"copado__Promotion__c","url":"/services/data/v47.0/sobjects/copado__Promotion__c/a5tS00000004UiEIAU"},"Id":"a5tS00000004UiEIAU","Name":"P01457"}';
            promotion = (copado__Promotion__c) System.JSON.deserialize(json, copado__Promotion__c.class);
        } else {
            insert promotion;
            promotion = [SELECT Id, Name FROM copado__Promotion__c WHERE Id = :promotion.Id];
        }
        return promotion;
    }
}