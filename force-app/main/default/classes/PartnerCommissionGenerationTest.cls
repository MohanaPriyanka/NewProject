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

        // Inspect newly-created Partner Invoice
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
            System.assertEquals(sumOfSubscriptionOrderAmounts, payment.Contract_Execution_Amount__c,
                'Commission payment should represent a sum of Contract Close Commission from child subscription orders');
        }

        System.assert([
            SELECT Id FROM Commission_Payment__c WHERE Opportunity__c =: utilityAccountSubscriptions[3].Opportunity__c].isEmpty(),
            'Cancelled deal should not have any Contract Execution Commission Payment generated');
    }

    @IsTest
    private static void testVariableFirstBillSentCommission() {
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

        // Inspect newly-created Partner Invoice
        List<Invoice__c> partnerInvoices = [
            SELECT Id, Approved_Commission_Payment_Total_Due__c,
                (SELECT Id FROM Commission_Payments__r WHERE Commission_Type__c = 'First Bill Sent')
            FROM Invoice__c
            WHERE Date_QC_Complete__c = NULL
        ];
        System.assertEquals(1, partnerInvoices.size(), '1 Partner Invoice should have been generated');
        System.assertEquals(4, partnerInvoices[0].Commission_Payments__r.size(),
            '4 First Bill Sent Commission Payments should have been generated');

        // Inspect Commission Payments & Subscription Orders
        List<Commission_Payment__c> commissionPayments = [
            SELECT Id, Status__c, Commission_Type__c, Amount_Due__c, Contract_Execution_Amount__c, First_Bill_Paid_Amount__c,
                First_Bill_Sent_Amount__c,
                (SELECT Id, Approved_Change_in_Subscription__c, First_Bill_Sent_Commission__c, First_Bill_Sent_Estimated_Commission__c,
                    First_Bill_Sent_Commission_Amount__c, Contract_Close_Commission__c, Contract_Close_Estimated_Commission__c,
                    Contract_Close_Commission_Amount__c
                FROM First_Bill_Subscription_Orders__r
                ORDER BY CreatedDate ASC)
            FROM Commission_Payment__c
            WHERE Commission_Type__c = 'First Bill Sent'
            AND Invoice__c IN : partnerInvoices
            ORDER BY Opportunity__r.Name
        ];

        for (Commission_Payment__c payment : commissionPayments) {
            System.assertNotEquals(0, payment.First_Bill_Sent_Amount__c,
                'This commission payment should have a first bill sent amount');
        }

        // SCENARIO A: One Initial Subscription Order
        System.assertEquals(0, commissionPayments[0].Contract_Execution_Amount__c,
            'No Contract Execution amounts should be in this commission payment');
        System.assertEquals(commissionPayments[0].First_Bill_Subscription_Orders__r[0].First_Bill_Sent_Estimated_Commission__c,
            commissionPayments[0].First_Bill_Sent_Amount__c,
            'First Bill Sent payment amount should equal value on the 1 related Subscription Order');

        // SCENARIO B: One Initial Subscription Order and one Resize Subscription Order
        // True-ups should take place for outstanding contract execution amount due
        System.assertNotEquals(0, commissionPayments[1].Contract_Execution_Amount__c,
            'This commission payment should have a contract execution amount (for true up) due to 1 included resize subscription order');
        System.assertEquals(commissionPayments[1].First_Bill_Subscription_Orders__r[1].Contract_Close_Estimated_Commission__c,
            commissionPayments[1].Contract_Execution_Amount__c,
            'Invalid Contract Execution Amount retrieved from resize Subscription order from this deal');
        System.assertEquals(commissionPayments[1].First_Bill_Subscription_Orders__r[0].First_Bill_Sent_Estimated_Commission__c +
            commissionPayments[1].First_Bill_Subscription_Orders__r[1].First_Bill_Sent_Estimated_Commission__c,
            commissionPayments[1].First_Bill_Sent_Amount__c,
            'First Bill Sent amount should be aggregate/sum of 2 subscription orders');
    }

    @IsTest
    private static void testVariableFirstBillPaidCommission() {
        // Retrieve test data
        List<Utility_Account_Subscription__c> utilityAccountSubscriptions = [
            SELECT Id, Annual_kWh_Subscription_Future_Rollup__c, Opportunity__r.Commission_Structure__c, Opportunity__c,
                (SELECT Id, Contract_Close_Commission_Amount__c, Contract_Close_Commission__c, Contract_Close_Estimated_Commission__c,
                First_Bill_Sent_Commission_Amount__c, First_Bill_Sent_Estimated_Commission__c
                FROM Subscription_Orders__r)
            FROM Utility_Account_Subscription__c
            ORDER BY Opportunity__r.Name ASC
        ];
        System.assertEquals(4, utilityAccountSubscriptions.size(), 'Should be 4 UAS loaded');

        // Create Invoice/Commission Payment records as if created previously for Contract Execution
        createVariableContractExecutionPayments(utilityAccountSubscriptions);

        // Create Invoice/Commission Payment records as if created previously for First Bill Sent
        createVariableFirstBillSentPayments(utilityAccountSubscriptions);

        // Create Resize subscription orders for 1 subscription (e.g. AFTER First Bill Sent but BEFORE First Bill Paid)
        createResizeSubscriptionOrder(utilityAccountSubscriptions[1], 2);

        // Cancel a subscription after first bill sent but BEFORE first bill paid
        createCancellationSubscriptionOrder(utilityAccountSubscriptions[3]);
        cancelOpportunity(utilityAccountSubscriptions[3]);

        // Set First Bill Sent and First Bill Paid on all Opportunities
        for (Utility_Account_Subscription__c uas : utilityAccountSubscriptions) {
            unitOfWork.registerDirty(new Opportunity(
                Id = uas.Opportunity__c,
                First_Bill_Sent_Date__c = Date.today().addDays(-30),
                First_Bill_Paid_Date__c = Date.today().addDays(-15)
            ));
        }

        unitOfWork.commitWork();

        // Call the PartnerCommissionGenerator service
        Test.startTest();
        Id partnerAccountId = [SELECT Id,Partner__c FROM Account WHERE Name = 'Solar Test Partner'].Id;
        PartnerCommissionGenerator generator = new PartnerCommissionGenerator(new List<Id>{partnerAccountId});
        System.enqueueJob(generator);
        Test.stopTest();

        // Inspect newly-created Partner Invoice
        List<Invoice__c> partnerInvoices = [
            SELECT Id, Approved_Commission_Payment_Total_Due__c,
            (SELECT Id FROM Commission_Payments__r WHERE Commission_Type__c = 'First Bill Paid')
            FROM Invoice__c
            WHERE Date_QC_Complete__c = NULL
        ];
        System.assertEquals(1, partnerInvoices.size(), '1 Partner Invoice should have been generated');
        System.assertEquals(4, partnerInvoices[0].Commission_Payments__r.size(),
            '4 First Bill Paid Commission Payments should have been generated');

        // Inspect Commission Payments & Subscription Orders
        List<Commission_Payment__c> commissionPayments = [
            SELECT Id, Status__c, Commission_Type__c, Amount_Due__c, Contract_Execution_Amount__c, First_Bill_Paid_Amount__c,
                First_Bill_Sent_Amount__c,
                (SELECT Id, Approved_Change_in_Subscription__c, First_Bill_Sent_Commission__c, First_Bill_Sent_Estimated_Commission__c,
                First_Bill_Sent_Commission_Amount__c, Contract_Close_Commission__c, Contract_Close_Estimated_Commission__c,
                Contract_Close_Commission_Amount__c, First_Bill_Paid_Estimated_Commission__c, First_Bill_Paid_Commission_Amount__c,
                First_Bill_Paid_Commission__c
                FROM First_Bill_Paid_Subscription_Orders__r
                ORDER BY CreatedDate ASC)
            FROM Commission_Payment__c
            WHERE Commission_Type__c = 'First Bill Paid'
            AND Invoice__c IN : partnerInvoices
            ORDER BY Opportunity__r.Name
        ];

        // SCENARIO A: One Initial Subscription Order
        System.assertEquals(0, commissionPayments[0].Contract_Execution_Amount__c,
            'No Contract Execution amounts should be in this commission payment');
        System.assertEquals(0, commissionPayments[0].First_Bill_Sent_Amount__c,
            'No First Bill Sent amounts should be in this commission payment');
        System.assertEquals(commissionPayments[0].First_Bill_Paid_Subscription_Orders__r[0].First_Bill_Paid_Estimated_Commission__c,
            commissionPayments[0].First_Bill_Paid_Amount__c,
            'First Bill Paid payment amount should equal value on the 1 related Subscription Order');

        // SCENARIO B: One Initial Subscription Order and one Resize Subscription Order
        // True-ups should take place for outstanding contract execution / first bill sent amounts due
        System.assertNotEquals(0, commissionPayments[1].Contract_Execution_Amount__c,
            'This commission payment should have a contract execution amount (for true up) due to 1 included resize subscription order');
        System.assertNotEquals(0, commissionPayments[1].First_Bill_Sent_Amount__c,
            'This commission payment should have a first bill sent amount (for true up) due to 1 included resize subscription order');
        System.assertEquals(commissionPayments[1].First_Bill_Paid_Subscription_Orders__r[1].Contract_Close_Estimated_Commission__c,
            commissionPayments[1].Contract_Execution_Amount__c,
            'Invalid Contract Execution Amount retrieved from resize Subscription order from this deal');
        System.assertEquals(commissionPayments[1].First_Bill_Paid_Subscription_Orders__r[1].First_Bill_Sent_Estimated_Commission__c,
            commissionPayments[1].First_Bill_Sent_Amount__c,
            'Invalid First Bill Sent amount retrieved from resize subscription order from this deal');
        System.assertEquals(commissionPayments[1].First_Bill_Paid_Subscription_Orders__r[0].First_Bill_Paid_Estimated_Commission__c +
            commissionPayments[1].First_Bill_Paid_Subscription_Orders__r[1].First_Bill_Paid_Estimated_Commission__c,
            commissionPayments[1].First_Bill_Paid_Amount__c,
            'First Bill Paid amount should be aggregate/sum of 2 subscription orders');

        // SCENARIO C: One Initial Subscription Order, One Cancellation Subscription Order put in after First Bill Sent
        System.assertEquals(commissionPayments[3].First_Bill_Paid_Subscription_Orders__r[0].Contract_Close_Commission_Amount__c * -1,
            commissionPayments[3].Contract_Execution_Amount__c,
            'This commission payment contains a clawback on contract close, so the amount should net out the previously paid amount');
        System.assertEquals(commissionPayments[3].First_Bill_Paid_Subscription_Orders__r[0].First_Bill_Sent_Commission_Amount__c * -1,
            commissionPayments[3].First_Bill_Sent_Amount__c,
            'This commission payment contains a clawback on first bill sent, so the amount should net out the previously paid amount');
    }

    @IsTest
    private static void testVariableClawbackCommission() {
        enableClawbacks(true);

        // Retrieve test data
        Utility_Account_Subscription__c subscription = [
            SELECT Id, Annual_kWh_Subscription_Future_Rollup__c, Opportunity__r.Commission_Structure__c, Opportunity__c,
            (SELECT Id, Contract_Close_Commission_Amount__c, Contract_Close_Commission__c, Contract_Close_Estimated_Commission__c,
                First_Bill_Sent_Commission_Amount__c, First_Bill_Sent_Estimated_Commission__c, First_Bill_Paid_Commission_Amount__c,
                First_Bill_Paid_Commission__c, First_Bill_Paid_Estimated_Commission__c
            FROM Subscription_Orders__r)
            FROM Utility_Account_Subscription__c
            ORDER BY Opportunity__r.Name ASC
            LIMIT 1
        ];

        // Create Contract Execution, First Bill Sent, and First Bill Paid commissions as if already existing
        createVariableContractExecutionPayments(new List<Utility_Account_Subscription__c>{subscription});
        createVariableFirstBillSentPayments(new List<Utility_Account_Subscription__c>{subscription});
        createVariableFirstBillPaidPayments(new List<Utility_Account_Subscription__c>{subscription});

        // Create Cancellation Subscription order as if the subscription was cancelled within the clawback period, after
        // First Bill Paid commission payment has already been paid out
        createCancellationSubscriptionOrder(subscription);
        cancelOpportunity(subscription);

        unitOfWork.commitWork();

        // Call the PartnerCommissionGenerator service
        Test.startTest();
        Id partnerAccountId = [SELECT Id,Partner__c FROM Account WHERE Name = 'Solar Test Partner'].Id;
        PartnerCommissionGenerator generator = new PartnerCommissionGenerator(new List<Id>{partnerAccountId});
        System.enqueueJob(generator);
        Test.stopTest();

        // Inspect Commission Payments & Subscription Orders
        List<Commission_Payment__c> commissionPayments = [
            SELECT Id, Status__c, Commission_Type__c, Amount_Due__c, Contract_Execution_Amount__c, First_Bill_Paid_Amount__c,
                First_Bill_Sent_Amount__c,
                (SELECT Id, Approved_Change_in_Subscription__c, First_Bill_Sent_Commission__c, First_Bill_Sent_Estimated_Commission__c,
                    First_Bill_Sent_Commission_Amount__c, Contract_Close_Commission__c, Contract_Close_Estimated_Commission__c,
                    Contract_Close_Commission_Amount__c, First_Bill_Paid_Estimated_Commission__c, First_Bill_Paid_Commission_Amount__c,
                    First_Bill_Paid_Commission__c
                FROM Subscription_Orders__r
                ORDER BY CreatedDate ASC)
            FROM Commission_Payment__c
            WHERE Commission_Type__c = 'Cancellation/Refund'
            AND Invoice__c IN (SELECT Id FROM Invoice__c)
            ORDER BY Opportunity__r.Name
        ];

        System.assertEquals(1, commissionPayments.size(), '1 chargeback (clawback) commission payment should have been generated');
        System.assertEquals(commissionPayments[0].Subscription_Orders__r[0].Contract_Close_Commission_Amount__c,
            commissionPayments[0].Contract_Execution_Amount__c,
            'Clawback commission should be the negative value of any commission paid out to the partner already');
        System.assertEquals(commissionPayments[0].Subscription_Orders__r[0].First_Bill_Sent_Commission_Amount__c,
            commissionPayments[0].First_Bill_Sent_Amount__c,
            'Clawback commission should be the negative value of any commission paid out to the partner already');
        System.assertEquals(commissionPayments[0].Subscription_Orders__r[0].First_Bill_Paid_Commission_Amount__c,
            commissionPayments[0].First_Bill_Paid_Amount__c,
            'Clawback commission should be the negative value of any commission paid out to the partner already');
    }

    @IsTest
    private static void testQueueableChain() {
        List<Id> partnerAccountIds = new List<Id>{
            Util.getFakeId(Account.SObjectType),
            Util.getFakeId(Account.SObjectType).left(12) + 'ABC'
        };

        PartnerCommissionGenerator generator = new PartnerCommissionGenerator(partnerAccountIds);
        Id beforeTestCurrentPartner = generator.currentPartner;
        System.assertNotEquals(null, beforeTestCurrentPartner, 'Current partner Id should be filled in');

        try {
            Test.startTest();
            System.enqueueJob(generator);
            Test.stopTest();
        } catch (System.AsyncException e) {
            System.assert(e.getMessage().contains('Maximum stack depth has been reached.'), 'Test should fail with AsyncException');
        }
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
                subscriptionOrder.Contract_Close_Commission_Amount__c = subscriptionOrder.Contract_Close_Estimated_Commission__c;
                unitOfWork.registerDirty(subscriptionOrder, Subscription_Order__c.Contract_Close_Commission__c, payment);
            }
        }
    }

    private static void createVariableFirstBillSentPayments(List<Utility_Account_Subscription__c> subscriptions) {
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
                Status__c = 'Approved',
                Commission_Type__c = 'First Bill Sent',
                Invoice__c = partnerInvoice.Id
            );
            unitOfWork.registerNew(payment);
            for (Subscription_Order__c subscriptionOrder : uas.Subscription_Orders__r) {
                subscriptionOrder.First_Bill_Sent_Commission_Amount__c = subscriptionOrder.First_Bill_Sent_Estimated_Commission__c;
                unitOfWork.registerDirty(subscriptionOrder, Subscription_Order__c.First_Bill_Sent_Commission__c, payment);
            }
        }
    }

    private static void createVariableFirstBillPaidPayments(List<Utility_Account_Subscription__c> subscriptions) {
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
                Status__c = 'Approved',
                Commission_Type__c = 'First Bill Paid',
                Invoice__c = partnerInvoice.Id
            );
            unitOfWork.registerNew(payment);
            for (Subscription_Order__c subscriptionOrder : uas.Subscription_Orders__r) {
                subscriptionOrder.First_Bill_Paid_Commission_Amount__c = subscriptionOrder.First_Bill_Paid_Estimated_Commission__c;
                unitOfWork.registerDirty(subscriptionOrder, Subscription_Order__c.First_Bill_Paid_Commission__c, payment);
            }
        }
    }
}