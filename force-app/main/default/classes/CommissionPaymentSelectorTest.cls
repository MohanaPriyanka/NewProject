@IsTest
public with sharing class CommissionPaymentSelectorTest {
    @TestSetup public static void testSetup() {
        CommissionStructureSelectorTest.testSetup();

        List<Commission_Structure__c> structures = [
            SELECT Id, Partner__c
            FROM Commission_Structure__c
        ];

        Account propAccount1 = new Account(Name = 'Account name');
        insert propAccount1;

        Opportunity opportunity1 = new Opportunity(
            Name = 'OppOne',
            AccountId = propAccount1.Id,
            StageName = 'Complete',
            Customer_Group__c = 'Residential',
            Commission_Structure__c = structures[0].Id,
            CloseDate = System.today()
        );
        Opportunity opportunity2 = new Opportunity(
            Name = 'OppOne',
            AccountId = propAccount1.Id,
            StageName = 'Complete',
            Customer_Group__c = 'Residential',
            Commission_Structure__c = structures[0].Id,
            CloseDate = System.today()
        );
        insert new List<Opportunity>{opportunity1, opportunity2};

        Invoice__c partnerInvoice = new Invoice__c(
            Name = 'Partner One January 2020',
            Due_Date__c = Date.newInstance(2020,03,14),
            Due_to_Accounting__c = Date.newInstance(2020,03,14),
            Invoice_Type__c = 'Direct',
            Partner__c = structures[0].Partner__c,
            Product_Line__c = 'Community Solar',
            Status__c = 'Received >> QC'
        );
        insert partnerInvoice;

        Commission_Payment__c paymentOne = new Commission_Payment__c(
            Commission_Structure__c = structures[0].Id,
            Opportunity__c = opportunity2.Id,
            Invoice__c = partnerInvoice.Id,
            Amount_Due__c = 100,
            Due_Date__c = Date.newInstance(2020,03,14),
            Due_to_Accounting__c = Date.newInstance(2020,03,14),
            Commission_Type__c = 'Contract Execution',
            Status__c = 'Approved'
        );
        Commission_Payment__c paymentTwo = new Commission_Payment__c(
            Commission_Structure__c = structures[0].Id,
            Opportunity__c = opportunity2.Id,
            Invoice__c = partnerInvoice.Id,
            Amount_Due__c = 100,
            Due_Date__c = Date.newInstance(2020,03,14),
            Due_to_Accounting__c = Date.newInstance(2020,03,14),
            Commission_Type__c = 'First Bill Paid',
            Status__c = 'Pending Approval'
        );
        Commission_Payment__c paymentThree = new Commission_Payment__c(
            Commission_Structure__c = structures[0].Id,
            Opportunity__c = opportunity2.Id,
            Invoice__c = partnerInvoice.Id,
            Amount_Due__c = 100,
            Due_Date__c = Date.newInstance(2020,03,14),
            Due_to_Accounting__c = Date.newInstance(2020,03,14),
            Commission_Type__c = 'Contract Execution',
            Status__c = 'Pending Approval'
        );
        insert new List<Commission_Payment__c>{paymentOne,paymentTwo,paymentThree};
    }

    @IsTest
    public static void testGetPendingCommissionPayments() {
        List<Opportunity> opps = [
            SELECT Id
            FROM Opportunity
        ];

        CommissionPaymentSelector selector = new CommissionPaymentSelector();
        List<Commission_Payment__c> payments = selector.getPendingCommissionPayments(
            new Set<Id>{opps[0].Id, opps[1].Id}, 'Contract Execution'
        );

        System.assertEquals(1,payments.size());
    }
}