/*************************************************************************************
 * Created By: peteryao on 2019-05-22  
 * Description: 
 * Test: 
 *************************************************************************************/
@IsTest
public with sharing class ZuoraProductRatePlanSelectorTest {
    @TestSetup
    public static void testSetup() {
        ZuoraProductRatePlanChargeSelectorTest.testSetup();
    }

    @IsTest
    public static void testSelector() {
        List<zqu__ProductRatePlan__c> productRatePlans =
            ZuoraProductRatePlanSelector.getProductRatePlan('Test Plan');
        System.assertEquals(1, productRatePlans.size());
        System.assertEquals('1234', productRatePlans[0].zqu__ZuoraId__c);
    }
}