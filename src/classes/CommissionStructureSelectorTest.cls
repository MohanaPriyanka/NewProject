@IsTest
public with sharing class CommissionStructureSelectorTest {
    @TestSetup public static void testSetup() {
        Product2 product1 = new Product2(
            Name = '10% Product',
            ProductCode = 'CS - BlueWave - 10%',
            IsActive = True);
        insert product1;
        Product2 product2 = new Product2(
            Name = '20% Product',
            ProductCode = 'CS - BlueWave - 20%',
            IsActive = True);
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
            Active__c = true,
            Cents_kW_DC_Up_Front__c = 0.10,
            Cents_kW_DC_First_Bill__c = 0.23,
            Cents_kW_DC_First_Bill_Paid__c = 0.11
        );
        Commission_Structure__c commissionTwo = new Commission_Structure__c(
            Name = 'Commission Structure Two',
            Partner__c = partnerOne.Id,
            Product__c = product2.Id,
            Active__c = true,
            Cents_kW_DC_Up_Front__c = 0.12,
            Cents_kW_DC_First_Bill_Paid__c = 0.50
        );
        Commission_Structure__c commissionThree = new Commission_Structure__c(
            Name = 'Commission Structure Two',
            Partner__c = partnerTwo.Id,
            Product__c = product2.Id,
            Active__c = true,
            Cents_kW_DC_Up_Front__c = 0.12,
            Cents_kW_DC_First_Bill_Paid__c = 0.50
        );
        insert new List<Commission_Structure__c>{
            commissionOne, commissionTwo, commissionThree
        };
    }

    @isTest
    public static void testGetActiveCommissionStructures() {
        List<Partner__c> partners = [
            SELECT Id
            FROM Partner__c
        ];

        CommissionStructureSelector selector = new CommissionStructureSelector();
        List<Commission_Structure__c> structures = selector.getActiveCommissionStructures(
            new Set<Id>{partners[0].Id, partners[1].Id}
        );

        System.assertEquals(3,structures.size());
    }
}