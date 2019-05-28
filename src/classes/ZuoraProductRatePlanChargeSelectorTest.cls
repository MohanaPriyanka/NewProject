/*************************************************************************************
 * Created By: peteryao on 2019-05-22  
 * Description: 
 * Test: 
 *************************************************************************************/
@IsTest
public with sharing class ZuoraProductRatePlanChargeSelectorTest {
    @TestSetup
    public static void testSetup() {
        zqu__ZProduct__c zProduct = new zqu__ZProduct__c(
            Name = 'Community Solar'
        );
        insert zProduct;
        zqu__ProductRatePlan__c productRatePlan = new zqu__ProductRatePlan__c(
            Name = 'Test Plan',
            zqu__ZuoraId__c = '1234',
            zqu__ZProduct__c = zProduct.Id
        );
        insert productRatePlan;
        zqu__ProductRatePlanCharge__c productRatePlanCharge = new zqu__ProductRatePlanCharge__c(
            Name = 'Test Charge',
            zqu__ProductRatePlan__c = productRatePlan.Id,
            zqu__ZuoraId__c = '9876'
        );
        insert productRatePlanCharge;
        zqu__ProductRatePlanCharge__c productRatePlanCharge2 = new zqu__ProductRatePlanCharge__c(
            Name = 'Test Charge Two',
            zqu__ProductRatePlan__c = productRatePlan.Id,
            zqu__ZuoraId__c = '5432'
        );
        insert productRatePlanCharge2;
    }

    @IsTest
    public static void testSelector() {
        zqu__ProductRatePlan__c productRatePlan = [SELECT Id FROM zqu__ProductRatePlan__c WHERE Name = 'Test Plan'];

        List<zqu__ProductRatePlanCharge__c> productRatePlanCharges =
            ZuoraProductRatePlanChargeSelector.getProductRatePlanCharge('Test Charge', productRatePlan.Id);
        System.assertEquals(1, productRatePlanCharges.size());
        System.assertEquals('9876', productRatePlanCharges[0].zqu__ZuoraId__c);
    }
}