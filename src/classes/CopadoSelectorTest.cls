/*************************************************************************************
 * Created By: peteryao on 10/24/19  
 * Description: 
 * Test: 
 *************************************************************************************/
@IsTest
public with sharing class CopadoSelectorTest {
    private static CopadoSelector copadoSelector = new CopadoSelector();

    @IsTest
    private static void testGetUserStories() {
        System.assertEquals(0, copadoSelector.getUserStoriesToPromote().size());
    }

    @IsTest
    private static void testProductionEnvironments() {
        Boolean caughtException = false;
        try {
            copadoSelector.getProductionEnvironment();
        } catch (Util.BWException bwe) {
            caughtException = true;
            System.assert(bwe.getMessage().contains('Expected a single production environment'));
        }
        System.assert(caughtException);
    }

    @IsTest
    private static void testDefaultCredentials() {
        Boolean caughtException = false;
        try {
            copadoSelector.getDefaultCredential(Util.getFakeId(copado__Environment__c.SObjectType));
        } catch (Util.BWException bwe) {
            caughtException = true;
            System.assert(bwe.getMessage().contains('Expected a single default credential'));
        }
        System.assert(caughtException);
    }
}