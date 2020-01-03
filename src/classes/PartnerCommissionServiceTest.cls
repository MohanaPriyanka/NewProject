@isTest
public class PartnerCommissionServiceTest {
    @testSetup public static void testDataSetup() {
        Journal_Entry__c entryOne = new Journal_Entry__c(
            Project__c = 'SSS-0002',
            Customer_Account__c = 'BW-00001',
            Object_Type__c = 'PaymentPart'
        );
        Journal_Entry__c entryTwo = new Journal_Entry__c(
            Project__c = 'SSS-0002',
            Customer_Account__c = 'BW-00001',
            Object_Type__c = 'InvoiceItem'
        );
        Journal_Entry__c entryThree = new Journal_Entry__c(
            Project__c = 'SSS-0002',
            Customer_Account__c = 'BW-00004',
            Object_Type__c = 'InvoiceItem'
        );
        Journal_Entry__c entryFour = new Journal_Entry__c(
            Project__c = 'SSS-0003',
            Customer_Account__c = 'BW-00004',
            Object_Type__c = 'PaymentPart'
        );
        Journal_Entry__c entryFive = new Journal_Entry__c(
            Project__c = 'SSS-0003',
            Customer_Account__c = 'BW-00002',
            Object_Type__c = 'PaymentPart'
        );
        Journal_Entry__c entrySix = new Journal_Entry__c(
            Project__c = 'SSS-0003',
            Customer_Account__c = 'BW-00002',
            Object_Type__c = 'PaymentPart'
        );
        Journal_Entry__c entrySeven = new Journal_Entry__c(
            Project__c = 'SSS-0002',
            Customer_Account__c = 'BW-00001',
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

        PartnerCommissionService commissionService = new PartnerCommissionService();
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
        PartnerCommissionService commiss = new PartnerCommissionService();
        PartnerCommissionService.PendingCommission oppLists = commiss.findUninvoicedCommission(null);
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

        Map<String, Object> params = commiss.getFlowParams(oppLists.FirstBillOpps[0], '');
        System.assertEquals(oppLists.FirstBillOpps[0].Name,params.get('OpportunityName'));
    }

    @IsTest
    private static void testTriggers(){
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
    private static void testWithoutAnyRows(){
        Account propertyOne = new Account(name = 'Account Property');
        insert propertyOne;
        Account propertyTwo = new Account(name = 'Account Property');
        insert propertyTwo;
        // No mocks, so no Opportunities returned from Query:
        Test.startTest();
            PartnerCommissionService.updatePendingCommission(new Set<Id>{propertyOne.Id, propertyTwo.Id});
        Test.stopTest();

        List<Error_Log__c> logs = [
            SELECT Id
            FROM Error_Log__c
            WHERE Class__c = 'PartnerCommissionService'
        ];
        System.assertEquals(0,logs.size());
    }

    private static void useMocks() {
        PartnerCommissionService.oppSelector = (OpportunitiesSelector) Test.createStub(OpportunitiesSelector.class, new MockOppSelector());
    }

    public class MockOppSelector extends MockProvider {
        public MockOppSelector() {
        }

        public override Object handleMethodCall(MethodCall methodCall) {
            String oppListAsJSON = '[' +
                '{' +
                '"Id":"0000000AAA",' +
                '"Name":"Oppty FourA",' +
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
            }
            return null;
        }
    }
}