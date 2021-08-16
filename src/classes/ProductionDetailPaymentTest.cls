/**
 * @description Created by PeterYao on 8/13/2021.
 */
@IsTest
public with sharing class ProductionDetailPaymentTest {
    @IsTest
    public static void testCreateProductionDetailFromCollectionItem() {
        ProductionToBillServiceTest.useMocks();
        List<Transfer_Part__c> beforeBillParts = [
            SELECT Id
            FROM Transfer_Part__c
            WHERE Type__c = 'Payment'
        ];

        System.assertEquals(0, beforeBillParts.size());

        List<Journal_Entry__c> collectionEntries = ProductionToBillServiceTest.getPaymentJournalEntries();
        ProductionDetailPaymentService service = new ProductionDetailPaymentService();
        service.calculateProductionDetailFromCollectionItem(collectionEntries);

        List<Transfer_Part__c> paymentParts = service.productionDetailToInsert;

        System.assertEquals(8, paymentParts.size());

        for (Transfer_Part__c part : paymentParts) {
            switch on String.valueOf(part.Bill_Part__c + '/' + part.Journal_Entry__c) {
                when 'a8y0a000000Gu3rAAA' {
                    // Balance is zero, no part should be made:
                    System.assert(false);
                }
                when 'a8y0a000000Gu3rBBB/a920a000000HuJoAAA' {
                    System.assertEquals(120, part.Amount__c);
                }
                when 'a8y0a000000Gu3rCCC/a920a000000HuJoAAA' {
                    System.assertEquals(1.87, part.Amount__c);
                }
                when 'a8y0a000000Gu3rDDD/a920a000000HuJoAAB' {
                    System.assertEquals(29, part.Amount__c);
                }
                when 'a8y0a000000Gu3rEEE/a920a000000HuJoAAC' {
                    System.assertEquals(30.61, part.Amount__c);
                }
                when 'a8y0a000000Gu3rEEE/a920a000000HuJoAAB' {
                    System.assertEquals(2.72, part.Amount__c);
                }
                when 'a8y0a000000Gu3rFFF/a920a000000HuJoAAC' {
                    System.assertEquals(29.39, part.Amount__c);
                }
                when 'a8y0a000000Gu3rGGG/a920a000000HuJoAAD' {
                    System.assertEquals(37.23, part.Amount__c);
                }
                when 'a8y0a000000Gu3rGGG/a920a000000HuJoAAE' {
                    System.assertEquals(62.55, part.Amount__c);
                }
                when else {
                    System.assert(false);
                }
            }
        }
    }
}