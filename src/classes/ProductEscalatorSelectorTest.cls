@IsTest
public with sharing class ProductEscalatorSelectorTest {
    @IsTest
    public static void testGetEscalators() {
        Product_Escalation_Schedule__c oldAmpSchedule = ProductService.createEscalationSchedule(0.019, 0.1327, 20, 12);
        Product_Escalation_Schedule__c newAmpSchedule = ProductService.createEscalationSchedule(0.019, 0.1378, 20, 12);

        Map<Id, List<Product_Escalator__c>> scheduleMap = ProductEscalatorSelector.getProductEscalationMap();

        System.assertEquals(2,scheduleMap.size());
        System.assertEquals(21,scheduleMap.get(oldAmpSchedule.Id).size());
    }
}