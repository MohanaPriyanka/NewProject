/**
 * Created by peteryao on 8/5/20.
 */
@IsTest
public with sharing class ProductSelectorTest {
    @IsTest
    private static void testSelectForACToDCConversion() {
        Product2 normalCSProduct = new Product2( Name = 'BlueWave Community Solar',
            Family = 'Community Solar',
            Product_Type__c = 'Community Solar',
            State__c = 'MA',
            ProductCode = 'CS - BlueWave - 10%',
            IsActive = true,
            Max_Subscription_kW_AC_for_DC_calc__c = 25);
        Product2 publicCSProduct = new Product2(  Name = 'BlueWave Public Offtake CS',
            Family = 'Community Solar',
            Product_Type__c = 'Community Solar',
            Customer_Subscription_Type__c = 'Electricity Cost ($)',
            Sizing_Method__c = 'Project Ratio',
            State__c = 'MA',
            ProductCode = 'CS - Bluewave - Public CS - 20%',
            IsActive = true);
        insert new List<Product2>{normalCSProduct, publicCSProduct};
        Set<Id> productIds = new Set<Id>{normalCSProduct.Id, publicCSProduct.Id};
        List<Product2> productsWithACToDCConversion = new ProductSelector().selectForACToDCConversion(productIds);
        System.assertEquals(1, productsWithACToDCConversion.size());
        System.assertEquals(normalCSProduct.Id, productsWithACToDCConversion[0].Id);
    }
}