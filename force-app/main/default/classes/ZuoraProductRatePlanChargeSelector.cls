/*************************************************************************************
 * Created By: peteryao on 2019-05-22  
 * Description: 
 * Test: ZuoraProductRatePlanChargeSelectorTest
 *************************************************************************************/

public with sharing class ZuoraProductRatePlanChargeSelector {
    public static List<zqu__ProductRatePlanCharge__c> getProductRatePlanCharge(String name, Id productRatePlanId) {
        return [
            SELECT Id, Name, zqu__ZuoraId__c, zqu__ProductRatePlan__c
            FROM zqu__ProductRatePlanCharge__c
            WHERE Name = :name
            AND zqu__ProductRatePlan__c = :productRatePlanId
        ];
    }
}