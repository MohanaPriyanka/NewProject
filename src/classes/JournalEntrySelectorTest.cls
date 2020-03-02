@isTest
public class JournalEntrySelectorTest {
    @testSetup public static void setupTestData() {
        Date mayBillDate = Date.newInstance(2019,05,20);
        Date juneBillDate = Date.newInstance(2019,06,20);

        Journal_Entry__c entryOne = new Journal_Entry__c(
            Object_Type__c = 'InvoiceItem',
            Query_Type__c = 'InvoiceItem',
            Project__c = 'SSS-000001',
            Client__c = 'BW-0009470',
            Amount__c = 252.73,
            External_Id__c = '2c92c0fa6e3a9391016e3df87b1f687a',
            Customer_Account__c = 'bw-00524',
            Date__c = mayBillDate
        );
        Journal_Entry__c entryTwo = new Journal_Entry__c(
            Object_Type__c = 'InvoiceItem',
            Query_Type__c = 'InvoiceItem',
            Project__c = 'SSS-000001',
            Client__c = 'BW-0009470',
            Amount__c = 135.06,
            External_Id__c = '2c92c0fa6e3a9391016e3e30d48066d2',
            Customer_Account__c = 'bw-00524',
            Date__c = juneBillDate
        );
        Journal_Entry__c entryThree = new Journal_Entry__c(
            Object_Type__c = 'InvoiceItem',
            Query_Type__c = 'InvoiceItem',
            Project__c = 'SSS-000022',
            Client__c = 'BW-0009470',
            Amount__c = 255.63,
            External_Id__c = '2c92c0fb6e3aa321016e3df574337a9b',
            Customer_Account__c = 'bw-05268',
            Date__c = mayBillDate
        );
        Journal_Entry__c entryFour = new Journal_Entry__c(
            Object_Type__c = 'InvoiceItem',
            Query_Type__c = 'InvoiceItem',
            Project__c = 'SSS-000045',
            Client__c = 'BW-0009186',
            Amount__c = 1997.03,
            External_Id__c = '2c92c0fa6e3a938d016e3dfdc93450b2',
            Customer_Account__c = 'bw-05956',
            Date__c = mayBillDate
        );
        Journal_Entry__c entryFive = new Journal_Entry__c(
            Object_Type__c = 'InvoiceItem',
            Query_Type__c = 'InvoiceItem',
            Project__c = 'SSS-000002',
            Client__c = 'BW-0009470',
            Amount__c = 37.23,
            External_Id__c = '2c92c0fb6e3aa322016e3df698ff7e9f',
            Customer_Account__c = 'bw-04202',
            Date__c = mayBillDate
        );
        Journal_Entry__c entrySix = new Journal_Entry__c(
            Object_Type__c = 'InvoiceItem',
            Query_Type__c = 'InvoiceItem',
            Project__c = 'SSS-000002',
            Client__c = 'BW-0009470',
            Amount__c = 62.55,
            External_Id__c = '2c92c0fa6e3a938d016e3e2ed1f832aa',
            Customer_Account__c = 'bw-04202',
            Date__c = juneBillDate
        );
        Journal_Entry__c entrySeven = new Journal_Entry__c(
            Object_Type__c = 'PaymentPart',
            Query_Type__c = 'PaymentPart_IV',
            Project__c = 'SSS-000045',
            Client__c = 'BW-0009186',
            Amount__c = 200,
            External_Id__c = '2c92c0fa6e3a938d016e3dfdc93330b2',
            Customer_Account__c = 'bw-05956',
            Date__c = mayBillDate.addDays(10)
        );
        Journal_Entry__c entryEight = new Journal_Entry__c(
            Object_Type__c = 'PaymentPart',
            Query_Type__c = 'PaymentPart_DM',
            Project__c = 'SSS-000002',
            Client__c = 'BW-0009470',
            Amount__c = 300,
            External_Id__c = '2c92c0fb6e3aa322016e3df698f2229f',
            Customer_Account__c = 'bw-04202',
            Date__c = mayBillDate.addDays(10)
        );
        Journal_Entry__c entryNine = new Journal_Entry__c(
            Object_Type__c = 'PaymentPart',
            Query_Type__c = 'PaymentPart_IV',
            Project__c = 'SSS-000002',
            Client__c = 'BW-0009470',
            Amount__c = 133,
            External_Id__c = '2c92c0fa6e3a938d016e3e2ed1f111aa',
            Customer_Account__c = 'bw-04202',
            Date__c = juneBillDate.addDays(10)
        );
        List<Journal_Entry__c> entries = new List<Journal_Entry__c>{
            entryOne, entryTwo, entryThree, entryFour, entryFive, entrySix, entrySeven, entryEight, entryNine
        };
        insert entries;
    }

    @isTest public static void testGetSFJournalEntriesFromExternalId() {
        JournalEntrySelector selector = new JournalEntrySelector();
        Set<String> externalIds = new Set<String>{'2c92c0fa6e3a9391016e3df87b1f687a', '2c92c0fb6e3aa322016e3df698ff7e9f'};
        List<Journal_Entry__c> entries = selector.getSFJournalEntriesFromExternalId(externalIds);
        System.assertEquals(2,entries.size());
    }
}