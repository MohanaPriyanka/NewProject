@IsTest
public class PartnerCommissionHandlerTest {
    
    @TestSetup public static void testDataSetup() {
        Account customerAccount1 = new Account(
            Name = 'Customer 1'
        );
        Account customerAccount2 = new Account(
            Name = 'Customer 2'
        );
        Account customerAccount4 = new Account(
            Name = 'Customer 3'
        );
        insert new List<Account>{
            customerAccount1, customerAccount2, customerAccount4
        };
        Journal_Entry__c entryOne = new Journal_Entry__c(
            Project__c = 'SSS-0002',
            Customer_Account__c = 'BW-00001',
            Customer_Lookup__c = customerAccount1.Id,
            Amount__c = 10,
            Object_Type__c = 'PaymentPart'
        );
        Journal_Entry__c entryTwo = new Journal_Entry__c(
            Project__c = 'SSS-0002',
            Customer_Account__c = 'BW-00001',
            Customer_Lookup__c = customerAccount1.Id,
            Amount__c = 12,
            Object_Type__c = 'InvoiceItem'
        );
        Journal_Entry__c entryThree = new Journal_Entry__c(
            Project__c = 'SSS-0002',
            Customer_Account__c = 'BW-00004',
            Customer_Lookup__c = customerAccount4.Id,
            Amount__c = 12,
            Object_Type__c = 'InvoiceItem'
        );
        Journal_Entry__c entryFour = new Journal_Entry__c(
            Project__c = 'SSS-0003',
            Customer_Account__c = 'BW-00004',
            Customer_Lookup__c = customerAccount4.Id,
            Amount__c = 10,
            Object_Type__c = 'PaymentPart'
        );
        Journal_Entry__c entryFive = new Journal_Entry__c(
            Project__c = 'SSS-0003',
            Customer_Account__c = 'BW-00002',
            Customer_Lookup__c = customerAccount2.Id,
            Amount__c = 10,
            Object_Type__c = 'PaymentPart'
        );
        Journal_Entry__c entrySix = new Journal_Entry__c(
            Project__c = 'SSS-0003',
            Customer_Account__c = 'BW-00002',
            Customer_Lookup__c = customerAccount2.Id,
            Amount__c = 10,
            Object_Type__c = 'PaymentPart'
        );
        Journal_Entry__c entrySeven = new Journal_Entry__c(
            Project__c = 'SSS-0002',
            Customer_Account__c = 'BW-00001',
            Customer_Lookup__c = customerAccount1.Id,
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
        System.assert(acctIds.contains('BW-00001'));
        System.assert(acctIds.contains('BW-00002'));
        System.assert(acctIds.contains('BW-00003'));
        System.assert(acctIds.contains('BW-00004'));

        commissionService.setJournalEntryMap(acctIds);
        System.assertEquals(4, commissionService.acctToJournalEntryMap.values().size());
        System.assertEquals('InvoiceItemPaymentPart', commissionService.acctToJournalEntryMap.get('BW-00001SSS-0002'));
        System.assertEquals('PaymentPart', commissionService.acctToJournalEntryMap.get('BW-00002SSS-0003'));
        System.assertEquals('InvoiceItem', commissionService.acctToJournalEntryMap.get('BW-00004SSS-0002'));
        System.assertEquals('PaymentPart', commissionService.acctToJournalEntryMap.get('BW-00004SSS-0003'));
    }

    @IsTest
    private static void testFindUninvoicedCommission() {
        useMocks();
        PartnerCommissionHandler commiss = new PartnerCommissionHandler();
        PartnerCommissionHandler.PendingBillCommission oppLists = commiss.findUninvoicedCommission(null);
        System.assertEquals(2, oppLists.firstBillOpps.size(), 'Only 2 Opportunities have InvoiceItems');
        System.assertEquals(3, oppLists.firstPaymentOpps.size(), '3 Opportunities have PaymentParts');

        /*  BW-00001: 2 opps for sss #2 and #3, invoice and payment only for sss #2
            BW-00002: 2 opps for sss #2 and #3, payment for #3 only
            BW-00003: 1 opp for sss #2, no invoices or payments
            BW-00004: 2 opps for sss #2 and #3, invoice for #2 and payment for #3          */

        Boolean containsBW001 = false;
        for (Opportunity firstBill : oppLists.firstBillOpps) {
            if (firstBill.Account.Account_Number__c == 'BW-00001'
                && firstBill.Shared_Solar_System__r.Unique_ID__c == 'SSS-0002') {
                containsBW001 = true;
            } else {
                System.assertEquals('BW-00004', firstBill.Account.Account_Number__c);
                System.assertEquals('SSS-0002', firstBill.Shared_Solar_System__r.Unique_ID__c);
            }
        }
        System.assert(containsBW001);

        containsBW001 = false;
        for (Opportunity firstPayment : oppLists.firstPaymentOpps) {
            if (firstPayment.Account.Account_Number__c == 'BW-00001'
                && firstPayment.Shared_Solar_System__r.Unique_ID__c == 'SSS-0002') {
                containsBW001 = true;
            } else if (firstPayment.Account.Account_Number__c == 'BW-00002') {
                System.assertEquals('SSS-0003', firstPayment.Shared_Solar_System__r.Unique_ID__c);
            } else {
                System.assertEquals('BW-00004', firstPayment.Account.Account_Number__c);
                System.assertEquals('SSS-0003', firstPayment.Shared_Solar_System__r.Unique_ID__c);
            }
        }
        System.assert(containsBW001);
    }

    @IsTest
    private static void testEligibleOppsForCommission() {
        Journal_Entry__c invoiceJE = new Journal_Entry__c(
            Project__c = 'SSS-0002',
            Customer_Account__c = 'BW-00005',
            Amount__c = 10,
            Object_Type__c = 'InvoiceItem'
        );
        Journal_Entry__c paymentJE = new Journal_Entry__c(
            Project__c = 'SSS-0002',
            Customer_Account__c = 'BW-00005',
            Amount__c = 10,
            Object_Type__c = 'PaymentPart'
        );
        insert new List<Journal_Entry__c>{
            invoiceJE, paymentJE
        };

        // Mocked Opportunity is eligible for "First Bill Paid" Commission Payment but should be excluded
        // from "First Bill Sent" Commission Payments due to $0 for First Bill Sent Commission Structure
        String oppJSON = '[' +
            '{' +
            '"Id":"0000000EEE",' +
            '"Name":"Oppty FIVE",' +
            '"StageName":"Complete",' +
            '"Product_Line__c":"Community Solar",' +
            '"Commission_Stucture__c":"a4w3K0000000EMXQA2",' +
            '"Commission_Structure__r":{"Id":"a4w3K0000000EMXQA2",' +
            '"Cents_kW_DC_First_Bill_Paid__c":0.2400, ' +
            '"Cents_kW_DC_First_Bill__c":0.000},' +
            '"Partner_tag_lookup__c":"a0s3K0000006wCRQAY",' +
            '"Partner_tag_lookup__r":{"Id":"a0s3K0000006wCRQAY","Name":"Test Partner 2","Account__c":"0010a00001Ljv4ZAAR"},' +
            '"Partner_Account__c":"0010a00001Ljv4ZAAR",' +
            '"Partner_Account__r": {"Id":"0010a00001Ljv4ZAAR","Name":"Test Partner Account"},' +
            '"Shared_Solar_System__r" : {' +
            '"Unique_ID__c": "SSS-0002"}, ' +
            '"Account" : {' +
            '"Name" : "Account Four", ' +
            '"Account_Number__c" : "BW-00005"' +
            '}}]';

        useMocks(new List<Opportunity>(), (List<Opportunity>) JSON.deserialize(oppJSON, List<Opportunity>.class));
        PartnerCommissionHandler handler = new PartnerCommissionHandler();
        PartnerCommissionHandler.PendingBillCommission oppLists = handler.findUninvoicedCommission(null);
        System.assertEquals(0, handler.oppsWithoutInvoiceCommission.size(),
            'Opportunity should not be considered for Invoice Commission Payment if Commission Structure has $0 for First Bill Sent.');
        System.assertEquals(1, handler.oppsWithoutPaymentCommission.size(), 'Opportunity should be considered for Payment Commission Payment');
        System.assertEquals(0, oppLists.firstBillOpps.size(), 'Opportunity is not eligible for PaymentPart Commission Payment');
        System.assertEquals(1, oppLists.firstPaymentOpps.size(), 'Opportunity should have pending PaymentPart Commission Payment');
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
        System.assertEquals(0, oppLists.firstBillOpps.size());
        System.assertEquals(3, oppLists.firstPaymentOpps.size());
    }

    @IsTest
    private static void testOpportunityTriggers() {
        Util.disableAllTriggers();
        UtilityAccountSubscriptionHandlerTest.setupData();

        List<Opportunity> opportunities = [
            SELECT Id, Partner_tag_lookup__c, Product__c
            FROM Opportunity
        ];
        System.assertEquals(2, opportunities.size());

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
            Cents_kW_DC_Up_Front__c = 0.10,
            Cents_kW_DC_First_Bill__c = 0.23,
            Cents_kW_DC_First_Bill_Paid__c = 0.11,
            Type__c = 'Variable by kW'
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
            Cents_kW_DC_Up_Front__c = 0.10,
            Cents_kW_DC_First_Bill__c = 0.23,
            Cents_kW_DC_First_Bill_Paid__c = 0.11
        );
        insert commissionTwo;
        Util.enableAllTriggers();

        Test.startTest();
        System.assertEquals(0, OpportunityTriggerHandler.partnerCommissionHandler.queuedIds.size());
        oppOne.StageName = 'Complete';
        oppTwo.Commission_Structure__c = commissionTwo.Id;
        update new List<Opportunity>{
            oppOne, oppTwo
        };
        System.assertEquals(2, OpportunityTriggerHandler.partnerCommissionHandler.queuedIds.size());
        Test.stopTest();
    }

    @IsTest
    private static void testWithoutAnyRows() {
        Account propertyOne = new Account(Name = 'Account Property');
        insert propertyOne;
        Account propertyTwo = new Account(Name = 'Account Property');
        insert propertyTwo;
        // No mocks, so no Opportunities returned from Query:
        Test.startTest();
        PartnerCommissionHandler.upsertCommissions(new Set<Id>{
            propertyOne.Id, propertyTwo.Id
        });
        Test.stopTest();

        List<Error_Log__c> logs = [
            SELECT Id
            FROM Error_Log__c
            WHERE Class__c = 'PartnerCommissionService'
        ];
        System.assertEquals(0, logs.size());
    }

    @IsTest
    private static void testChangeCommissionStructure() {
        Util.disableAllTriggers();
        UtilityAccountSubscriptionHandlerTest.setupData();

        List<Opportunity> opportunities = [
            SELECT Id, Partner_tag_lookup__c, Product__c, Partner_Account__c, Shared_Solar_System__c
            FROM Opportunity
            LIMIT 1
        ];
        Partner__c partner = [
            SELECT Id
            FROM Partner__c
            LIMIT 1
        ];

        Commission_Structure__c commissionOne = new Commission_Structure__c(
            Name = 'Commission Structure One',
            Partner__c = opportunities[0].Partner_tag_lookup__c,
            Partner_Account__c = opportunities[0].Partner_Account__c,
            Product__c = opportunities[0].Product__c,
            Cents_kW_DC_Up_Front__c = 0.10,
            Cents_kW_DC_First_Bill__c = 0.23,
            Cents_kW_DC_First_Bill_Paid__c = 0.11
        );
        insert commissionOne;

        Partner_Shared_Solar_System_Eligibility__c partnerEligibility =
            new Partner_Shared_Solar_System_Eligibility__c(
                Account__c = opportunities[0].Partner_Account__c,
                Shared_Solar_System__c = opportunities[0].Shared_Solar_System__c,
                Commission_Structure__c = commissionOne.Id,
                Start_Date__c = Date.newInstance(2020, 1, 1)
            );
        insert partnerEligibility;

        //No commission structure assigned at Complete
        Opportunity oppOne = new Opportunity(
            Id = opportunities[0].Id,
            Product_Line__c = 'Community Solar',
            StageName = 'Complete',
            CS_Capacity_Allocated__c = 15.00,
            Commission_Structure__c = commissionOne.Id
        );
        update oppOne;

        Invoice__c invoice = new Invoice__c(
            Name = 'Test Invoice',
            Partner__c = partner.Id,
            Status__c = 'Submitted to Accounting',
            Due_Date__c = System.today().addMonths(3),
            Due_to_Accounting__c = System.today().addMonths(4),
            Product_Line__c = 'Community Solar',
            Invoice_Type__c = 'Direct'
        );
        insert invoice;

        Commission_Payment__c cp = new Commission_Payment__c(
            Amount_Due__c = 100,
            Commission_Structure__c = commissionOne.Id,
            Opportunity__c = oppOne.Id,
            Due_Date__c = System.today(),
            Name = 'Test Commission Payment',
            Commission_Type__c = 'Contract Execution',
            Status__c = 'Pending Approval',
            Invoice__c = invoice.Id
        );
        insert cp;

        Commission_Structure__c commissionTwo = new Commission_Structure__c(
            Name = 'Commission Structure Two',
            Partner__c = opportunities[0].Partner_tag_lookup__c,
            Product__c = opportunities[0].Product__c,
            Cents_kW_DC_Up_Front__c = 0.10,
            Cents_kW_DC_First_Bill__c = 0.23,
            Cents_kW_DC_First_Bill_Paid__c = 0.11
        );
        insert commissionTwo;

        oppOne.Commission_Structure__c = commissionTwo.Id;
        update oppOne;

        Test.startTest();
        PartnerCommissionHandler.invokeCommissionStructureChange(new List<Id>{
            oppOne.Id
        });
        Test.stopTest();

        List<Commission_Payment__c> commissionPayments = [
            SELECT Id, Opportunity__c, Commission_Structure__c, Future_Customer_Subscription_kW_DC__c,
                Commission_Type__c, Status__c
            FROM Commission_Payment__c
            WHERE Opportunity__c = :oppOne.Id
        ];

        System.assertEquals(1, commissionPayments.size());
        System.assertEquals(commissionPayments[0].Commission_Structure__c, commissionTwo.Id);
        System.assertEquals(commissionPayments[0].Future_Customer_Subscription_kW_DC__c, 15.00);
        System.assertEquals(commissionPayments[0].Commission_Type__c, 'Contract Execution');
        System.assertEquals(commissionPayments[0].Status__c, 'Pending Approval');
    }

    @IsTest
    private static void testAssignCommissionStructure() {
        Util.disableAllTriggers();
        UtilityAccountSubscriptionHandlerTest.setupData();

        List<Opportunity> opportunities = [
            SELECT Id, Partner_tag_lookup__c, Product__c, Partner_Account__c, Shared_Solar_System__c
            FROM Opportunity
            ORDER BY Name
        ];
        System.assertEquals(2,opportunities.size());

        Commission_Structure__c commissionOne = new Commission_Structure__c(
            Name = 'Commission Structure One',
            Partner__c = opportunities[0].Partner_tag_lookup__c,
            Partner_Account__c = opportunities[0].Partner_Account__c,
            Product__c = opportunities[0].Product__c,
            Cents_kW_DC_Up_Front__c = 0.10,
            Cents_kW_DC_First_Bill__c = 0.23,
            Cents_kW_DC_First_Bill_Paid__c = 0.11,
            Type__c = 'Variable by kW'
        );
        insert commissionOne;

        Partner_Shared_Solar_System_Eligibility__c partnerEligibility =
            new Partner_Shared_Solar_System_Eligibility__c(
                Account__c = opportunities[0].Partner_Account__c,
                Shared_Solar_System__c = opportunities[0].Shared_Solar_System__c,
                Commission_Structure__c = commissionOne.Id,
                Start_Date__c = Date.newInstance(2020,1,1)
            );
        insert partnerEligibility;

        Opportunity oppOne = new Opportunity(
            Id = opportunities[0].Id,
            Product_Line__c = 'Community Solar',
            StageName = 'Complete',
            CS_Capacity_Allocated__c = 15.00,
            Commission_Structure__c = commissionOne.Id
        );
        update oppOne;
        Util.enableAllTriggers();

        Test.startTest();
        PartnerCommissionHandler.invokeCommissionStructureChange(new List<Id>{oppOne.Id});
        Test.stopTest();

        List<Commission_Payment__c> commissionPayments = [
            SELECT Id, Opportunity__c, Commission_Structure__c, Future_Customer_Subscription_kW_DC__c,
                Commission_Type__c, Status__c
            FROM Commission_Payment__c
            WHERE Opportunity__c = :oppOne.Id
        ];

        System.assertEquals(1, commissionPayments.size() );
        System.assertEquals(commissionPayments[0].Commission_Structure__c, commissionOne.Id);
        System.assertEquals(commissionPayments[0].Future_Customer_Subscription_kW_DC__c, 15.00);
        System.assertEquals(commissionPayments[0].Commission_Type__c, 'Contract Execution' );
        System.assertEquals(commissionPayments[0].Status__c, 'Pending Approval' );
    }

    @IsTest
    private static void testQueueCalculatePartnerCommission() {
        Test.startTest();
        PartnerCommissionHandler handler = new PartnerCommissionHandler();
        handler.queueCalculatePartnerCommission(null);
        Test.stopTest();

        List<Error_Log__c> afterLogs = [
            SELECT Id
            FROM Error_Log__c
            WHERE Class__c LIKE '%PartnerCommission%'
        ];
        System.assertEquals(0, afterLogs.size());
    }

    @IsTest
    private static void testCreateCommissionPaymentsFromJournalEntries() {
        useMocks();
        Test.startTest();
        Object accountsWithCommissionableJournalEntries = new PartnerCommissionHandler().executePostBatch();
        Test.stopTest();
        System.assertEquals(3, ((Set<Id>) accountsWithCommissionableJournalEntries).size(),
            'Expected to run the PartnerCommissionHandler with three accounts');
    }

    private static void useMocks() {
        PartnerCommissionHandler.oppSelector = (OpportunitiesSelector) Test.createStub(OpportunitiesSelector.class, new MockOppSelector(null, null));
    }
    private static void useMocks(List<Opportunity> oppsWithoutFirstBillCommission, List<Opportunity> oppsWithoutFirstPaymentCommission) {
        PartnerCommissionHandler.oppSelector = (OpportunitiesSelector) Test.createStub(OpportunitiesSelector.class, new MockOppSelector(oppsWithoutFirstBillCommission, oppsWithoutFirstPaymentCommission));
    }

    public class MockOppSelector extends MockProvider {
        private List<Opportunity> oppsWithoutFirstBillCommission;
        private List<Opportunity> oppsWithoutFirstPaymentCommission;

        public MockOppSelector(List<Opportunity> oppsWithoutFirstBillCommission, List<Opportunity> oppsWithoutFirstPaymentCommission) {
            this.oppsWithoutFirstBillCommission = oppsWithoutFirstBillCommission;
            this.oppsWithoutFirstPaymentCommission = oppsWithoutFirstPaymentCommission;
        }

        public override Object handleMethodCall(MethodCall methodCall) {
            String oppListAsJSON = '[' +
                '{' +
                '"Id":"0000000AAA",' +
                '"Name":"Oppty FourA",' +
                '"StageName":"Complete",' +
                '"Product_Line__c":"Community Solar",' +
                '"Partner_tag_lookup__c":"a0s3K0000006wCRQAY",' +
                '"Partner_tag_lookup__r":{"Id":"a0s3K0000006wCRQAY","Name":"Test Partner 2","Account__c":"0010a00001Ljv4ZAAR"},' +
                '"Partner_Account__c":"0010a00001Ljv4ZAAR",' +
                '"Partner_Account__r": {"Id":"0010a00001Ljv4ZAAR","Name":"Test Partner Account"},' +
                '"Shared_Solar_System__r" : {' +
                '"Unique_ID__c": "SSS-0002"}, ' +
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
                '"Partner_tag_lookup__c":"a0s3K0000006wCRQAY",' +
                '"Partner_tag_lookup__r":{"Id":"a0s3K0000006wCRQAY","Name":"Test Partner 2","Account__c":"0010a00001Ljv4ZAAR"},' +
                '"Partner_Account__c":"0010a00001Ljv4ZAAR",' +
                '"Partner_Account__r": {"Id":"0010a00001Ljv4ZAAR","Name":"Test Partner Account"},' +
                '"Shared_Solar_System__r" : {' +
                '"Unique_ID__c": "SSS-0003"}, ' +
                '"Account" : {' +
                '"Name" : "Account Four", ' +
                '"Account_Number__c" : "BW-00004"' +
                '}' +
                '},' +
                '{' +
                '"Id":"0000000BBA",' +
                '"Shared_Solar_System__r" : {' +
                '"Unique_ID__c": "SSS-0003"}, ' +
                '"Name":"Oppty TwoA",' +
                '"StageName":"Complete",' +
                '"Product_Line__c":"Community Solar",' +
                '"Partner_tag_lookup__c":"a0s3K0000006wCRQAY",' +
                '"Partner_tag_lookup__r":{"Id":"a0s3K0000006wCRQAY","Name":"Test Partner 2","Account__c":"0010a00001Ljv4ZAAR"},' +
                '"Partner_Account__c":"0010a00001Ljv4ZAAR",' +
                '"Partner_Account__r": {"Id":"0010a00001Ljv4ZAAR","Name":"Test Partner Account"},' +
                '"Account" : {' +
                '"Name" : "Account Two",' +
                '"Account_Number__c" : "BW-00002"' +
                '}' +
                '},' +
                '{' +
                '"Id":"0000000BBB",' +
                '"Shared_Solar_System__r" : {' +
                '"Unique_ID__c": "SSS-0002"}, ' +
                '"Name":"Oppty TwoB",' +
                '"StageName":"Complete",' +
                '"Product_Line__c":"Community Solar",' +
                '"Partner_tag_lookup__c":"a0s3K0000006wCRQAY",' +
                '"Partner_tag_lookup__r":{"Id":"a0s3K0000006wCRQAY","Name":"Test Partner 2","Account__c":"0010a00001Ljv4ZAAR"},' +
                '"Partner_Account__c":"0010a00001Ljv4ZAAR",' +
                '"Partner_Account__r": {"Id":"0010a00001Ljv4ZAAR","Name":"Test Partner Account"},' +
                '"Account" : {' +
                '"Name" : "Account Two",' +
                '"Account_Number__c" : "BW-00002"' +
                '}' +
                '},' +
                '{' +
                '"Id":"0000000CCC",' +
                '"Shared_Solar_System__r" : {' +
                '"Unique_ID__c": "SSS-0002"}, ' +
                '"Name":"Oppty Three",' +
                '"StageName":"Complete",' +
                '"Product_Line__c":"Community Solar",' +
                '"Partner_tag_lookup__c":"a0s3K0000006wCRQAY",' +
                '"Partner_tag_lookup__r":{"Id":"a0s3K0000006wCRQAY","Name":"Test Partner 2","Account__c":"0010a00001Ljv4ZAAR"},' +
                '"Partner_Account__c":"0010a00001Ljv4ZAAR",' +
                '"Partner_Account__r": {"Id":"0010a00001Ljv4ZAAR","Name":"Test Partner Account"},' +
                '"Account" : {' +
                '"Name" : "Account Three",' +
                '"Account_Number__c" : "BW-00003"' +
                '}' +
                '},' +
                '{' +
                '"Id":"0000000DDA",' +
                '"Shared_Solar_System__r" : {' +
                '"Unique_ID__c": "SSS-0002"}, ' +
                '"Name":"Oppty OneA",' +
                '"StageName":"Complete",' +
                '"Product_Line__c":"Community Solar",' +
                '"Partner_tag_lookup__c":"a0s3K0000006wCRQAY",' +
                '"Partner_tag_lookup__r":{"Id":"a0s3K0000006wCRQAY","Name":"Test Partner 2","Account__c":"0010a00001Ljv4ZAAR"},' +
                '"Partner_Account__c":"0010a00001Ljv4ZAAR",' +
                '"Partner_Account__r": {"Id":"0010a00001Ljv4ZAAR","Name":"Test Partner Account"},' +
                '"Account" : {' +
                '"Name" : "Account One",' +
                '"Account_Number__c" : "BW-00001"' +
                '}' +
                '},' +
                '{' +
                '"Id":"0000000DDB",' +
                '"Shared_Solar_System__r" : {' +
                '"Unique_ID__c": "SSS-0003"}, ' +
                '"Name":"Oppty OneB",' +
                '"StageName":"Complete",' +
                '"Product_Line__c":"Community Solar",' +
                '"Partner_tag_lookup__c":"a0s3K0000006wCRQAY",' +
                '"Partner_tag_lookup__r":{"Id":"a0s3K0000006wCRQAY","Name":"Test Partner 2","Account__c":"0010a00001Ljv4ZAAR"},' +
                '"Partner_Account__c":"0010a00001Ljv4ZAAR",' +
                '"Partner_Account__r": {"Id":"0010a00001Ljv4ZAAR","Name":"Test Partner Account"},' +
                '"Account" : {' +
                '"Name" : "Account One",' +
                '"Account_Number__c" : "BW-00001"' +
                '}' +
                '}' +
                ']';
            switch on methodCall.stubbedMethodName {
                when 'selectWithoutFirstPaymentCommission' {
                    if (oppsWithoutFirstPaymentCommission != null) {
                        return oppsWithoutFirstPaymentCommission;
                    }
                    return (List<Opportunity>) JSON.deserialize(oppListAsJSON, List<Opportunity>.class);
                }
                when 'selectWithoutFirstInvoiceCommission' {
                    if (oppsWithoutFirstBillCommission != null) {
                        return oppsWithoutFirstBillCommission;
                    }
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
        public override Object handleMethodCall(MethodCall methodCall) {
            return null;
        }
    }
}