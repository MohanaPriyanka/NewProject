/*************************************************************************************
 * Created By: peteryao on 2019-05-22  
 * Description: 
 * Test: ZuoraProductRatePlanSelectorTest
 *************************************************************************************/

public with sharing class ZuoraProductRatePlanSelector {
    public static List<zqu__ProductRatePlan__c> getProductRatePlan(String name) {
        return [
            SELECT Id, Name, zqu__ZuoraId__c
            FROM zqu__ProductRatePlan__c
            WHERE Name = :name
        ];
    }
}