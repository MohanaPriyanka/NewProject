/**
 * @description Created by jeffparlin on 3/3/22.
 */
@IsTest
public class PartnerCommissionGenerationTest {

    private static fflib_SObjectUnitOfWork unitOfWork = new fflib_SObjectUnitOfWork(new List<SObjectType> {
        Commission_Payment__c.SObjectType,
        Subscription_Order__c.SObjectType,
        Opportunity.SObjectType
    });

    @TestSetup
    private static void insertData() {
        PartnerCommissionTestDataFactory dataFactory = new PartnerCommissionTestDataFactory();
        dataFactory.buildBaseComponents();
        dataFactory.buildBaseVariableRateDeals(4);
    }

    @IsTest
    private static void testVariableContractExecutionCommission() {
        enableClawbacks(true);

        // Retrieve test data
        List<Utility_Account_Subscription__c> utilityAccountSubscriptions = [
            SELECT Id, Annual_kWh_Subscription_Future_Rollup__c, Opportunity__r.Product__c, Opportunity__c
            FROM Utility_Account_Subscription__c
            ORDER BY Opportunity__r.Name ASC
        ];
        System.assertEquals(4, utilityAccountSubscriptions.size(), 'Should be 4 UAS loaded');

        // Create Resize subscription orders for 2 subscriptions (e.g. prior to Contract Close)
        createResizeSubscriptionOrder(utilityAccountSubscriptions[1], 1.5);
        createResizeSubscriptionOrder(utilityAccountSubscriptions[2], 0.5);

        // Cancel a subscription AND deal before the Contract Execution commission was paid.
        // This subscription/opportunity should NOT get any Contract Execution Commission Payments
        createCancellationSubscriptionOrder(utilityAccountSubscriptions[3]);
        cancelOpportunity(utilityAccountSubscriptions[3]);

        unitOfWork.commitWork();

        // Call the PartnerCommissionGenerator service
        Test.startTest();
        Id partnerAccountId = [SELECT Id,Partner__c FROM Account WHERE Name = 'Solar Test Partner'].Id;
        PartnerCommissionGenerator generator = new PartnerCommissionGenerator(new List<Id>{partnerAccountId});
        System.enqueueJob(generator);
        Test.stopTest();

        // Inspect Partner Invoice
        List<Invoice__c> partnerInvoices = [
            SELECT Id, Approved_Commission_Payment_Total_Due__c,
                (SELECT Id FROM Commission_Payments__r WHERE Commission_Type__c = 'Contract Execution')
            FROM Invoice__c
        ];
        System.assertEquals(1, partnerInvoices.size(), '1 Partner Invoice should have been generated');
        System.assertEquals(3, partnerInvoices[0].Commission_Payments__r.size(),
            '3 Contract Execution Commission Payments should have been generated');

        // Inspect Commission Payments & Subscription Orders
        List<Commission_Payment__c> commissionPayments = [
            SELECT Id, Status__c, Commission_Type__c, Amount_Due__c, Contract_Execution_Amount__c,
                (SELECT Id, Approved_Change_in_Subscription__c, Contract_Close_Commission__c, Contract_Close_Estimated_Commission__c,
                    Contract_Close_Commission_Amount__c
                FROM Subscription_Orders__r)
            FROM Commission_Payment__c
            WHERE Commission_Type__c = 'Contract Execution'
            AND Invoice__c IN : partnerInvoices
        ];
        for (Commission_Payment__c payment : commissionPayments) {
            System.assertEquals('Pending Approval', payment.Status__c, 'Newly generated Commission Payment should be in Pending status');
            Decimal sumOfSubscriptionOrderAmounts = 0;
            for (Subscription_Order__c so : payment.Subscription_Orders__r) {
                System.assertEquals(so.Contract_Close_Commission_Amount__c, so.Contract_Close_Estimated_Commission__c,
                    'Contract Close Commission Amount should be equivalent to the respective Estimated Commission Amount');
                System.assertEquals(payment.Id, so.Contract_Close_Commission__c,
                    'Commission Payment should be stamped on Subscription Order lookup');
                sumOfSubscriptionOrderAmounts += so.Contract_Close_Commission_Amount__c;
            }
            System.assertNotEquals(0, payment.Contract_Execution_Amount__c,
                'Data used in this test should not result in a Commission Payment with $0 contract execution amount');
            System.assertEquals(sumOfSubscriptionOrderAmounts, payment.Contract_Execution_Amount__c,
                'Commission payment should represent a sum of Contract Close Commission from child subscription orders');
        }

        System.assert([
            SELECT Id FROM Commission_Payment__c WHERE Opportunity__c =: utilityAccountSubscriptions[3].Opportunity__c].isEmpty(),
            'Cancelled deal should not have any Contract Execution Commission Payment generated');
    }

    @IsTest
    private static void testVariableFirstBillSentCommission() {
        enableClawbacks(true);

        // Retrieve test data
        List<Utility_Account_Subscription__c> utilityAccountSubscriptions = [
            SELECT Id, Annual_kWh_Subscription_Future_Rollup__c, Opportunity__r.Commission_Structure__c, Opportunity__c,
                (SELECT Id, Contract_Close_Commission_Amount__c, Contract_Close_Commission__c, Contract_Close_Estimated_Commission__c
                FROM Subscription_Orders__r)
            FROM Utility_Account_Subscription__c
            ORDER BY Opportunity__r.Name ASC
        ];
        System.assertEquals(4, utilityAccountSubscriptions.size(), 'Should be 4 UAS loaded');

        // Create Invoice/Commission Payment records as if created previously for Contract Execution
        createVariableContractExecutionPayments(utilityAccountSubscriptions);

        // Set First Bill Sent on all Opportunities
        for (Utility_Account_Subscription__c uas : utilityAccountSubscriptions) {
            unitOfWork.registerDirty(new Opportunity(
                Id = uas.Opportunity__c,
                First_Bill_Sent_Date__c = Date.today().addDays(-5)
            ));
        }

        // Create Resize subscription orders for 1 subscription (e.g. AFTER Contract Close but before First Bill Sent)
        createResizeSubscriptionOrder(utilityAccountSubscriptions[1], 1.5);

        unitOfWork.commitWork();

        // Call the PartnerCommissionGenerator service
        Test.startTest();
        Id partnerAccountId = [SELECT Id,Partner__c FROM Account WHERE Name = 'Solar Test Partner'].Id;
        PartnerCommissionGenerator generator = new PartnerCommissionGenerator(new List<Id>{partnerAccountId});
        System.enqueueJob(generator);
        Test.stopTest();

        // Inspect Partner Invoice
        List<Invoice__c> partnerInvoices = [
            SELECT Id, Approved_Commission_Payment_Total_Due__c,
                (SELECT Id FROM Commission_Payments__r WHERE Commission_Type__c = 'First Bill Sent')
            FROM Invoice__c
            WHERE Date_QC_Complete__c = NULL
        ];
        System.assertEquals(1, partnerInvoices.size(), '1 Partner Invoice should have been generated');
        System.assertEquals(4, partnerInvoices[0].Commission_Payments__r.size(),
            '4 Contract Execution Commission Payments should have been generated');

        // Inspect Commission Payments & Subscription Orders
        List<Commission_Payment__c> commissionPayments = [
            SELECT Id, Status__c, Commission_Type__c, Amount_Due__c, Contract_Execution_Amount__c, First_Bill_Paid_Amount__c,
                First_Bill_Sent_Amount__c,
                (SELECT Id, Approved_Change_in_Subscription__c, First_Bill_Sent_Commission__c, First_Bill_Sent_Estimated_Commission__c,
                    First_Bill_Sent_Commission_Amount__c, Contract_Close_Commission__c, Contract_Close_Estimated_Commission__c,
                    Contract_Close_Commission_Amount__c
                FROM First_Bill_Subscription_Orders__r)
            FROM Commission_Payment__c
            WHERE Commission_Type__c = 'First Bill Sent'
            AND Invoice__c IN : partnerInvoices
            ORDER BY Opportunity__r.Name
        ];

        for (Commission_Payment__c payment : commissionPayments) {
            System.assertNotEquals(0, payment.First_Bill_Sent_Amount__c,
                'This commission payment should have a first bill sent amount');
        }

        System.assertEquals(0, commissionPayments[0].Contract_Execution_Amount__c,
            'No Contract Execution amounts should be in this commission payment');
        System.assertEquals(commissionPayments[0].First_Bill_Subscription_Orders__r[0].First_Bill_Sent_Estimated_Commission__c,
            commissionPayments[0].First_Bill_Sent_Amount__c,
            'First Bill Sent payment amount should equal value on the 1 related Subscription Order');

        System.assertNotEquals(0, commissionPayments[1].Contract_Execution_Amount__c,
            'This commission payment should have a contract execution amount due to 1 included resize subscription order');
        System.assertEquals(commissionPayments[1].First_Bill_Subscription_Orders__r[1].Contract_Close_Estimated_Commission__c,
            commissionPayments[1].Contract_Execution_Amount__c,
            'Invalid Contract Execution Amount retrieved from resize Subscription order from this deal');
        System.assertEquals(commissionPayments[1].First_Bill_Subscription_Orders__r[0].First_Bill_Sent_Estimated_Commission__c +
            commissionPayments[1].First_Bill_Subscription_Orders__r[1].First_Bill_Sent_Estimated_Commission__c,
            commissionPayments[1].First_Bill_Sent_Amount__c,
            'First Bill Sent amount should be aggregate/sum of 2 subscription orders');

        System.assertEquals(0, commissionPayments[2].Contract_Execution_Amount__c,
            'No Contract Execution amounts should be in this commission payment');
        System.assertEquals(commissionPayments[2].First_Bill_Subscription_Orders__r[0].First_Bill_Sent_Estimated_Commission__c,
            commissionPayments[0].First_Bill_Sent_Amount__c,
            'First Bill Sent payment amount should equal value on the 1 related Subscription Order');

        System.assertEquals(0, commissionPayments[3].Contract_Execution_Amount__c,
            'No Contract Execution amounts should be in this commission payment');
        System.assertEquals(commissionPayments[3].First_Bill_Subscription_Orders__r[0].First_Bill_Sent_Estimated_Commission__c,
            commissionPayments[0].First_Bill_Sent_Amount__c,
            'First Bill Sent payment amount should equal value on the 1 related Subscription Order');
    }

    private static void enableClawbacks(Boolean enabled) {
        FeatureService.Mock mockFeatureService = new FeatureService.Mock(
            new Map<String, Boolean>{
                'Clawback_Partner_Commissions' => enabled
            });
        VariableRateCommissionProcessor.featureService = (FeatureService)
            Test.createStub(FeatureService.class, mockFeatureService);
    }

    private static void createResizeSubscriptionOrder(Utility_Account_Subscription__c uas, Decimal multiplier) {
        Subscription_Order__c so = new Subscription_Order__c(
            Type__c = 'Resize',
            New_Annual_kWh__c = uas.Annual_kWh_Subscription_Future_Rollup__c * multiplier,
            Effective_Date__c = System.now(),
            Approval_Status__c = 'Approved',
            Comments__c = 'Resize'
        );
        unitOfWork.registerNew(so, Subscription_Order__c.Utility_Account_Subscription__c, uas);
    }

    private static void createCancellationSubscriptionOrder(Utility_Account_Subscription__c uas) {
        Subscription_Order__c so = new Subscription_Order__c(
            Type__c = 'Cancellation',
            New_Annual_kWh__c = 0,
            Effective_Date__c = System.now(),
            Approval_Status__c = 'Approved'
        );
        unitOfWork.registerNew(so, Subscription_Order__c.Utility_Account_Subscription__c, uas);
    }

    private static void cancelOpportunity(Utility_Account_Subscription__c uas) {
        Opportunity opp = new Opportunity(
            Id = uas.Opportunity__c,
            StageName = 'Cancelled'
        );
        unitOfWork.registerDirty(opp);
    }

    private static void createVariableContractExecutionPayments(List<Utility_Account_Subscription__c> subscriptions) {
        Invoice__c partnerInvoice = new Invoice__c(
            Name = 'Test',
            Product_Line__c = 'Community Solar',
            Status__c = 'Submitted to Accounting',
            Date_QC_Complete__c = Date.today().addDays(-7)
        );
        insert partnerInvoice;

        for (Utility_Account_Subscription__c uas : subscriptions) {
            Commission_Payment__c payment = new Commission_Payment__c(
                Commission_Structure__c = uas.Opportunity__r.Commission_Structure__c,
                Name = 'Test',
                Opportunity__c = uas.Opportunity__c,
                Status__c = 'Pending Approval',
                Commission_Type__c = 'Contract Execution',
                Invoice__c = partnerInvoice.Id
            );
            unitOfWork.registerNew(payment);
            for (Subscription_Order__c subscriptionOrder : uas.Subscription_Orders__r) {
                unitOfWork.registerDirty(subscriptionOrder, Subscription_Order__c.Contract_Close_Commission__c, payment);
            }
        }
    }
}