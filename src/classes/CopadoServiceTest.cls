/*************************************************************************************
 * Created By: peteryao on 10/24/19  
 * Description: 
 * Test: 
 *************************************************************************************/
@IsTest
public with sharing class CopadoServiceTest {
    private static CopadoService copadoService = new CopadoService();

    @IsTest
    private static void testInsertPromotedUserStories() {
        Boolean caughtException = false;
        try {
            copadoService.insertPromotedUserStories(new List<copado__Promoted_User_Story__c>());
        } catch (Exception e) {
            caughtException = true;
        }
        System.assert(!caughtException);
    }

    @IsTest
    private static void testInsertPromotion() {
        copado__Deployment_Flow__c dpf = new copado__Deployment_Flow__c(
            copado__Active__c = true
        );
        insert dpf;

        copado__Project__c proj = new copado__Project__c(
            Name = 'Default',
            copado__Deployment_Flow__c = dpf.Id
        );
        insert proj;

        copado__Promotion__c promotion = new copado__Promotion__c(
            copado__Project__c = proj.Id
        );

        promotion = copadoService.insertPromotion(promotion);
        System.assertNotEquals(null, promotion.Name);
    }
}