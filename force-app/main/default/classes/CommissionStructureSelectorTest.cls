@IsTest
public with sharing class CommissionStructureSelectorTest {
    @TestSetup public static void testSetup() {
        Product2 product1 = new Product2(
            Name = '10% Product',
            ProductCode = 'CS - BlueWave - 10%',
            IsActive = true);
        insert product1;
        Product2 product2 = new Product2(
            Name = '20% Product',
            ProductCode = 'CS - BlueWave - 20%',
            IsActive = true);
        insert product2;

        Partner__c partnerOne = new Partner__c(
            Name = 'Partner One'
        );
        Partner__c partnerTwo = new Partner__c(
            Name = 'Partner Two'
        );
        insert new List<Partner__c>{
            partnerOne, partnerTwo
        };

        Commission_Structure__c commissionOne = new Commission_Structure__c(
            Name = 'Commission Structure One',
            Partner__c = partnerOne.Id,
            Product__c = product1.Id,
            Cents_kW_DC_Up_Front__c = 0.10,
            Cents_kW_DC_First_Bill__c = 0.23,
            Cents_kW_DC_First_Bill_Paid__c = 0.11,
            Type__c = 'Variable by kW'
        );
        Commission_Structure__c commissionTwo = new Commission_Structure__c(
            Name = 'Commission Structure Two',
            Partner__c = partnerOne.Id,
            Product__c = product2.Id,
            Cents_kW_DC_Up_Front__c = 0.12,
            Cents_kW_DC_First_Bill_Paid__c = 0.50,
            Type__c = 'Variable by kW'
        );
        Commission_Structure__c commissionThree = new Commission_Structure__c(
            Name = 'Commission Structure Two',
            Partner__c = partnerTwo.Id,
            Product__c = product2.Id,
            Cents_kW_DC_Up_Front__c = 0.12,
            Cents_kW_DC_First_Bill_Paid__c = 0.50,
            Type__c = 'Variable by kW'
        );
        insert new List<Commission_Structure__c>{
            commissionOne, commissionTwo, commissionThree
        };
    }

    @IsTest
    public static void getCommissionStructureMapByIds() {
        Map<Id, Commission_Structure__c> commissionStructuresIds = new Map<Id, Commission_Structure__c>([SELECT Id FROM Commission_Structure__c]);
        Map<Id, Commission_Structure__c> checkMap = new CommissionStructureSelector().getCommissionStructureMapByIds(commissionStructuresIds.keySet());
        System.assertEquals(3, checkMap.size(), 'Selector should return a map of 3 Commission Structures');
    }
}