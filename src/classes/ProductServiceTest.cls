@isTest
public class ProductServiceTest {
    @isTest public static void testAMPEscalation() {
        List<Product_Escalator__c> oldAmpSchedule = ProductService.createEscalators(0.019, 0.1327, 20, 12);
        List<Product_Escalator__c> newAmpSchedule = ProductService.createEscalators(0.019, 0.1378, 20, 12);

        System.assertEquals(21, oldAmpSchedule.size());
        System.assertEquals(21, newAmpSchedule.size());

        System.assertEquals(0,oldAmpSchedule[0].Number_of_Credit_Transfers__c);
        System.assertEquals(0.1327,oldAmpSchedule[0].New_Solar_Electricity_Rate__c);

        System.assertEquals(120,oldAmpSchedule[10].Number_of_Credit_Transfers__c);
        System.assertEquals(120,newAmpSchedule[10].Number_of_Credit_Transfers__c);
        System.assertEquals(0.1602,oldAmpSchedule[10].New_Solar_Electricity_Rate__c);
        System.assertEquals(0.1663,newAmpSchedule[10].New_Solar_Electricity_Rate__c);

        System.assertEquals(240,newAmpSchedule[20].Number_of_Credit_Transfers__c);
        System.assertEquals(0.2007,newAmpSchedule[20].New_Solar_Electricity_Rate__c);
    }
}