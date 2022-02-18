@isTest
public class ProductServiceTest {
    @isTest public static void testAMPEscalation() {
        Product_Escalation_Schedule__c oldAmpSchedule = ProductService.createEscalationSchedule(0.019, 0.1327, 20, 12);
        Product_Escalation_Schedule__c newAmpSchedule = ProductService.createEscalationSchedule(0.019, 0.1378, 20, 12);

        System.assertEquals(21, oldAmpSchedule.Product_Escalators__r.size());
        System.assertEquals(21, newAmpSchedule.Product_Escalators__r.size());

        System.assertEquals(0,oldAmpSchedule.Product_Escalators__r[0].Starting_Credit_Transfer__c);
        System.assertEquals(0.1327,oldAmpSchedule.Product_Escalators__r[0].New_Solar_Electricity_Rate__c);

        System.assertEquals(120,oldAmpSchedule.Product_Escalators__r[10].Starting_Credit_Transfer__c);
        System.assertEquals(120,newAmpSchedule.Product_Escalators__r[10].Starting_Credit_Transfer__c);
        System.assertEquals(0.1602,oldAmpSchedule.Product_Escalators__r[10].New_Solar_Electricity_Rate__c);
        System.assertEquals(0.1663,newAmpSchedule.Product_Escalators__r[10].New_Solar_Electricity_Rate__c);

        System.assertEquals(240,newAmpSchedule.Product_Escalators__r[20].Starting_Credit_Transfer__c);
        System.assertEquals(0.2007,newAmpSchedule.Product_Escalators__r[20].New_Solar_Electricity_Rate__c); 
    }
}