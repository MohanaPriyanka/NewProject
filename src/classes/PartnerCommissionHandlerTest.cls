@isTest
public class PartnerCommissionHandlerTest {
    @testSetup public static void testDataSetup() {
        Journal_Entry__c entryOne = new Journal_Entry__c(
            Project__c = 'SSS-0002',
            Customer_Account__c = 'BW-00001',
            Amount__c = 10,
            Object_Type__c = 'PaymentPart'
        );
        Journal_Entry__c entryTwo = new Journal_Entry__c(
            Project__c = 'SSS-0002',
            Customer_Account__c = 'BW-00001',
            Amount__c = 12,
            Object_Type__c = 'InvoiceItem'
        );
        Journal_Entry__c entryThree = new Journal_Entry__c(
            Project__c = 'SSS-0002',
            Customer_Account__c = 'BW-00004',
            Amount__c = 12,
            Object_Type__c = 'InvoiceItem'
        );
        Journal_Entry__c entryFour = new Journal_Entry__c(
            Project__c = 'SSS-0003',
            Customer_Account__c = 'BW-00004',
            Amount__c = 10,
            Object_Type__c = 'PaymentPart'
        );
        Journal_Entry__c entryFive = new Journal_Entry__c(
            Project__c = 'SSS-0003',
            Customer_Account__c = 'BW-00002',
            Amount__c = 10,
            Object_Type__c = 'PaymentPart'
        );
        Journal_Entry__c entrySix = new Journal_Entry__c(
            Project__c = 'SSS-0003',
            Customer_Account__c = 'BW-00002',
            Amount__c = 10,
            Object_Type__c = 'PaymentPart'
        );
        Journal_Entry__c entrySeven = new Journal_Entry__c(
            Project__c = 'SSS-0002',
            Customer_Account__c = 'BW-00001',
            Amount__c = 10,
            Object_Type__c = 'InvoiceItem'
        );
        List<Journal_Entry__c> entryList = new List<Journal_Entry__c>{
            entryOne, entryTwo, entryThree, entryFour, entryFive, entrySix, entrySeven
        };
        insert entryList;
    }

    @IsTest
    private static void testSelectors() {
        useMocks();

        /*  BW-00001: 2 opps for sss #2 and #3, invoice and payment only for sss #2
            BW-00002: 2 opps for sss #2 and #3, payment for #3 only
            BW-00003: 1 opp for sss #2, no invoices or payments
            BW-00004: 2 opps for sss #2 and #3, invoice for #2 and payment for #3          */

        PartnerCommissionHandler commissionService = new PartnerCommissionHandler();
        Set<String> acctIds = commissionService.getOpportunitiesWithoutCommission(null);
        System.assertEquals(4, acctIds.size());
        System.assertEquals(7,commissionService.allOpsToCheck.size());
        System.assert(acctIds.contains('BW-00001'));
        System.assert(acctIds.contains('BW-00002'));
        System.assert(acctIds.contains('BW-00003'));
        System.assert(acctIds.contains('BW-00004'));

        commissionService.setJournalEntryMap(acctIds);
        System.assertEquals(4,commissionService.acctToJournalEntryMap.values().size());
        System.assertEquals('InvoiceItemPaymentPart',commissionService.acctToJournalEntryMap.get('BW-00001SSS-0002'));
        System.assertEquals('PaymentPart',commissionService.acctToJournalEntryMap.get('BW-00002SSS-0003'));
        System.assertEquals('InvoiceItem',commissionService.acctToJournalEntryMap.get('BW-00004SSS-0002'));
        System.assertEquals('PaymentPart',commissionService.acctToJournalEntryMap.get('BW-00004SSS-0003'));
    }

    @IsTest
    private static void testFindUninvoicedCommission() {
        useMocks();
        PartnerCommissionHandler commiss = new PartnerCommissionHandler();
        PartnerCommissionHandler.PendingBillCommission oppLists = commiss.findUninvoicedCommission(null);
        System.assertEquals(2,oppLists.FirstBillOpps.size());
        System.assertEquals(3,oppLists.FirstPaymentOpps.size());

        /*  BW-00001: 2 opps for sss #2 and #3, invoice and payment only for sss #2
            BW-00002: 2 opps for sss #2 and #3, payment for #3 only
            BW-00003: 1 opp for sss #2, no invoices or payments
            BW-00004: 2 opps for sss #2 and #3, invoice for #2 and payment for #3          */

        Boolean containsBW001 = false;
        for (Opportunity firstBill : oppLists.FirstBillOpps){
            if (firstBill.Account.Account_Number__c == 'BW-00001'
                && firstBill.Shared_Solar_System__r.Unique_ID__c == 'SSS-0002'){
                containsBW001 = true;
            } else {
                System.assertEquals('BW-00004',firstBill.Account.Account_Number__c);
                System.assertEquals('SSS-0002',firstBill.Shared_Solar_System__r.Unique_Id__c);
            }
        }
        System.assert(containsBW001);

        containsBW001 = false;
        for (Opportunity firstPayment : oppLists.FirstPaymentOpps){
            if (firstPayment.Account.Account_Number__c == 'BW-00001'
                && firstPayment.Shared_Solar_System__r.Unique_ID__c == 'SSS-0002'){
                containsBW001 = true;
            } else if (firstPayment.Account.Account_Number__c == 'BW-00002') {
                System.assertEquals('SSS-0003',firstPayment.Shared_Solar_System__r.Unique_Id__c);
            } else {
                System.assertEquals('BW-00004',firstPayment.Account.Account_Number__c);
                System.assertEquals('SSS-0003',firstPayment.Shared_Solar_System__r.Unique_Id__c);
            }
        }
        System.assert(containsBW001);
    }

    @IsTest
    private static void testFindUninvoicedCommissionWithZeroAmount() {
        useMocks();
        List<Journal_Entry__c> entries = [
            SELECT Id, Amount__c
            FROM Journal_Entry__c
            WHERE Object_Type__c = 'InvoiceItem'
        ];
        System.assert(entries.size() >= 3);
        entries[0].Amount__c = 0;
        entries[1].Amount__c = 0;
        entries[2].Amount__c = 0;
        update entries;

        PartnerCommissionHandler commiss = new PartnerCommissionHandler();
        PartnerCommissionHandler.PendingBillCommission oppLists = commiss.findUninvoicedCommission(null);
        System.assertEquals(0,oppLists.FirstBillOpps.size());
        System.assertEquals(3,oppLists.FirstPaymentOpps.size());
    }

    @IsTest
    private static void testZuoraTriggers(){
        Account property = new Account(name = 'Account Property');
        insert property;

        Zuora__CustomerAccount__c billingAccount = new Zuora__CustomerAccount__c(
            Name = 'Test BillingAccount',
            Zuora__Zuora_Id__c = 'XXXXXXXXXX123',
            Zuora__Account__c = property.Id
        );
        insert billingAccount;

        Zuora__ZInvoice__c zInvoice = new Zuora__ZInvoice__c(
            Zuora__Zuora_Id__c = '12345',
            Zuora__Account__c = property.Id
        );

        Zuora__Payment__c zPayment = new Zuora__Payment__c(
            Zuora__External_Id__c = '12445',
            Zuora__BillingAccount__c = billingAccount.Id,
            Zuora__Account__c = property.Id
        );

        insert zPayment;
        insert zInvoice;

        List<Zuora__Payment__c> payments = [
            SELECT Id
            FROM Zuora__Payment__c
        ];
        System.assert(payments.size() > 0);
    }

    @IsTest
    private static void testOpportunityTriggers(){
        Util.disableAllTriggers();
        UtilityAccountSubscriptionHandlerTest.setupData();

        List<Opportunity> opportunities = [
            SELECT Id, Partner_tag_lookup__c, Product__c
            FROM Opportunity
        ];
        System.assertEquals(2,opportunities.size());

        Opportunity oppOne = new Opportunity(
            Id = opportunities[0].Id,
            Product_Line__c = 'Community Solar',
            StageName = 'New'
        );
        update oppOne;

        Commission_Structure__c commissionOne = new Commission_Structure__c(
            Name = 'Commission Structure One',
            Partner__c = opportunities[1].Partner_tag_lookup__c,
            Product__c = opportunities[1].Product__c,
            Active__c = true,
            Cents_kW_DC_Up_Front__c = 0.10,
            Cents_kW_DC_First_Bill__c = 0.23,
            Cents_kW_DC_First_Bill_Paid__c = 0.11
        );
        insert commissionOne;

        Opportunity oppTwo = new Opportunity(
            Id = opportunities[1].Id,
            Commission_Structure__c = commissionOne.Id,
            Product_Line__c = 'Community Solar'
        );
        update oppTwo;

        Commission_Structure__c commissionTwo = new Commission_Structure__c(
            Name = 'Commission Structure Two',
            Partner__c = opportunities[1].Partner_tag_lookup__c,
            Product__c = opportunities[1].Product__c,
            Active__c = false,
            Cents_kW_DC_Up_Front__c = 0.10,
            Cents_kW_DC_First_Bill__c = 0.23,
            Cents_kW_DC_First_Bill_Paid__c = 0.11
        );
        insert commissionTwo;
        Util.enableAllTriggers();

        Test.startTest();
            System.assertEquals(0,OpportunityTriggerHandler.partnerCommissionHandler.queuedIds.size());
            oppOne.StageName = 'Complete';
            oppTwo.Commission_Structure__c = commissionTwo.Id;
            update new List<Opportunity>{oppOne, oppTwo};
            System.assertEquals(2,OpportunityTriggerHandler.partnerCommissionHandler.queuedIds.size());
        Test.stopTest();
    }

    @IsTest
    private static void testUASTriggers(){
        Util.disableAllTriggers();
        UtilityAccountSubscriptionHandlerTest.setupData();
        Util.enableAllTriggers();

        Utility_Account_Subscription__c uas = [
            SELECT Id, Opportunity__c
            FROM Utility_Account_Subscription__c
            WHERE Name = '0000234'
            LIMIT 1
        ];

        Opportunity newOpp = [
            SELECT Id, Partner_tag_lookup__c, Product__c
            FROM Opportunity
            WHERE Id != : uas.Opportunity__c
            LIMIT 1
        ];

        Test.startTest();
            System.assertEquals(0,UtilityAccountSubscriptionHandler.partnerCommissionHandler.queuedIds.size());
            uas.Opportunity__c = newOpp.Id;
            update uas;
            System.assertEquals(2,UtilityAccountSubscriptionHandler.partnerCommissionHandler.queuedIds.size());
        Test.stopTest();
    }

    @IsTest
    private static void testWithoutAnyRows(){
        Account propertyOne = new Account(name = 'Account Property');
        insert propertyOne;
        Account propertyTwo = new Account(name = 'Account Property');
        insert propertyTwo;
        // No mocks, so no Opportunities returned from Query:
        Test.startTest();
            PartnerCommissionHandler.updatePendingCommission(new Set<Id>{propertyOne.Id, propertyTwo.Id});
        Test.stopTest();

        List<Error_Log__c> logs = [
            SELECT Id
            FROM Error_Log__c
            WHERE Class__c = 'PartnerCommissionService'
        ];
        System.assertEquals(0,logs.size());
    }

    @IsTest
    private static void testQueueCalculatePartnerCommission(){
        Test.startTest();
            PartnerCommissionHandler handler = new PartnerCommissionHandler();
            handler.queueCalculatePartnerCommission(null);
        Test.stopTest();

        List<Error_Log__c> afterLogs = [
            SELECT Id
            FROM Error_Log__c
            WHERE Class__c LIKE '%PartnerCommission%'
        ];
        System.assertEquals(0,afterLogs.size());
    }

    private static void useMocks() {
        PartnerCommissionHandler.oppSelector = (OpportunitiesSelector) Test.createStub(OpportunitiesSelector.class, new MockOppSelector());
    }

    public class MockOppSelector extends MockProvider {
        public MockOppSelector() {
        }

        public override Object handleMethodCall(MethodCall methodCall) {
            //"Partner_tag_lookup__c":"a0s3K0000006wCRQAY"
            //"Partner_tag_lookup__r":{"Id":"a0s3K0000006wCRQAY","Name":"Test Partner 2"}

            String oppListAsJSON = '[' +
                '{' +
                '"Id":"0000000AAA",' +
                '"Name":"Oppty FourA",' +
                '"StageName":"Complete",' +
                '"Product_Line__c":"Community Solar",' +
                '"Partner_tag_lookup__c":"a0s3K0000006wCRQAY",'+
                '"Partner_tag_lookup__r":{"Id":"a0s3K0000006wCRQAY","Name":"Test Partner 2"},' +
                '"Shared_Solar_System__r" : {' +
                '"Unique_Id__c": "SSS-0002"}, ' +
                '"Account" : {' +
                '"Name" : "Account Four", ' +
                '"Account_Number__c" : "BW-00004"' +
                '}' +
                '},' +
                '{' +
                '"Id":"0000000AAB",' +
                '"Name":"Oppty FourB",' +
                '"StageName":"Complete",' +
                '"Product_Line__c":"Community Solar",' +
                '"Partner_tag_lookup__c":"a0s3K0000006wCRQAY",'+
                '"Partner_tag_lookup__r":{"Id":"a0s3K0000006wCRQAY","Name":"Test Partner 2"},' +
                '"Shared_Solar_System__r" : {' +
                '"Unique_Id__c": "SSS-0003"}, ' +
                '"Account" : {' +
                '"Name" : "Account Four", ' +
                '"Account_Number__c" : "BW-00004"' +
                '}' +
                '},' +
                '{' +
                '"Id":"0000000BBA",' +
                '"Shared_Solar_System__r" : {' +
                '"Unique_Id__c": "SSS-0003"}, ' +
                '"Name":"Oppty TwoA",' +
                '"StageName":"Complete",' +
                '"Product_Line__c":"Community Solar",' +
                '"Partner_tag_lookup__c":"a0s3K0000006wCRQAY",'+
                '"Partner_tag_lookup__r":{"Id":"a0s3K0000006wCRQAY","Name":"Test Partner 2"},' +
                '"Account" : {' +
                '"Name" : "Account Two",' +
                '"Account_Number__c" : "BW-00002"' +
                '}' +
                '},' +
                '{' +
                '"Id":"0000000BBB",' +
                '"Shared_Solar_System__r" : {' +
                '"Unique_Id__c": "SSS-0002"}, ' +
                '"Name":"Oppty TwoB",' +
                '"StageName":"Complete",' +
                '"Product_Line__c":"Community Solar",' +
                '"Partner_tag_lookup__c":"a0s3K0000006wCRQAY",'+
                '"Partner_tag_lookup__r":{"Id":"a0s3K0000006wCRQAY","Name":"Test Partner 2"},' +
                '"Account" : {' +
                '"Name" : "Account Two",' +
                '"Account_Number__c" : "BW-00002"' +
                '}' +
                '},' +
                '{' +
                '"Id":"0000000CCC",' +
                '"Shared_Solar_System__r" : {' +
                '"Unique_Id__c": "SSS-0002"}, ' +
                '"Name":"Oppty Three",' +
                '"StageName":"Complete",' +
                '"Product_Line__c":"Community Solar",' +
                '"Partner_tag_lookup__c":"a0s3K0000006wCRQAY",'+
                '"Partner_tag_lookup__r":{"Id":"a0s3K0000006wCRQAY","Name":"Test Partner 2"},' +
                '"Account" : {' +
                '"Name" : "Account Three",' +
                '"Account_Number__c" : "BW-00003"' +
                '}' +
                '},' +
                '{' +
                '"Id":"0000000DDA",' +
                '"Shared_Solar_System__r" : {' +
                '"Unique_Id__c": "SSS-0002"}, ' +
                '"Name":"Oppty OneA",' +
                '"StageName":"Complete",' +
                '"Product_Line__c":"Community Solar",' +
                '"Partner_tag_lookup__c":"a0s3K0000006wCRQAY",'+
                '"Partner_tag_lookup__r":{"Id":"a0s3K0000006wCRQAY","Name":"Test Partner 2"},' +
                '"Account" : {' +
                '"Name" : "Account One",' +
                '"Account_Number__c" : "BW-00001"' +
                '}' +
                '},' +
                '{' +
                '"Id":"0000000DDB",' +
                '"Shared_Solar_System__r" : {' +
                '"Unique_Id__c": "SSS-0003"}, ' +
                '"Name":"Oppty OneB",' +
                '"StageName":"Complete",' +
                '"Product_Line__c":"Community Solar",' +
                '"Partner_tag_lookup__c":"a0s3K0000006wCRQAY",'+
                '"Partner_tag_lookup__r":{"Id":"a0s3K0000006wCRQAY","Name":"Test Partner 2"},' +
                '"Account" : {' +
                '"Name" : "Account One",' +
                '"Account_Number__c" : "BW-00001"' +
                '}' +
                '}' +
                ']';
            switch on methodCall.stubbedMethodName {
                when 'selectWithoutFirstPaymentCommission' {
                    return (List<Opportunity>) JSON.deserialize(oppListAsJSON, List<Opportunity>.class);
                }
                when 'selectWithoutFirstInvoiceCommission' {
                    return (List<Opportunity>) JSON.deserialize(oppListAsJSON, List<Opportunity>.class);
                }
                when 'selectByIdWithApprovedCommissionPayment' {
                    return (List<Opportunity>) JSON.deserialize(oppListAsJSON, List<Opportunity>.class);
                }
            }
            return null;
        }
    }

    public class MockPartnerCommissionHandler extends MockProvider {
        public MockPartnerCommissionHandler() {}
        public override Object handleMethodCall(MethodCall methodCall) {
            return null;
        }

    }
}