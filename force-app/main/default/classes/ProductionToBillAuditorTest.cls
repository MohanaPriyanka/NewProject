@IsTest
private with sharing class ProductionToBillAuditorTest {

    @IsTest
    private static void testJEAuditor() {
        ProductionToBillJEAuditor jeAuditor = new ProductionToBillJEAuditor();
        Test.startTest();
        Database.executeBatch(jeAuditor);
        Test.stopTest();
        List<Error_Log__c> errorLogs = [
            SELECT Message__c
            FROM Error_Log__c
            WHERE Severity__c = :Logger.ERROR
            AND Class__c = 'ProductionToBillJEAuditor'
        ];
        System.assertEquals(0, errorLogs.size(), 'Expected batch to run successfully but got this: ' + errorLogs);
    }

    @IsTest
    private static void testJEAuditorReconciliation() {
        Id journalEntry1 = Util.getFakeId(Journal_Entry__c.SObjectType);
        Id journalEntry2 = Util.incrementFakeId(journalEntry1);
        Id journalEntry3 = Util.incrementFakeId(journalEntry2);
        UniversalMocker journalEntrySelectorMock = UniversalMocker.mock(JournalEntrySelector.class);
        AggregateResultProxy je1Aggregate = new AggregateResultProxy();
        je1Aggregate.withAliasAndValue('Journal_Entry__c', journalEntry1);
        je1Aggregate.withAliasAndValue('Object_Type__c', 'InvoiceItem');
        je1Aggregate.withAliasAndValue('AMOUNT', 100);

        AggregateResultProxy je2Aggregate = new AggregateResultProxy();
        je2Aggregate.withAliasAndValue('Journal_Entry__c', journalEntry2);
        je2Aggregate.withAliasAndValue('Object_Type__c', 'DebitMemo');
        je2Aggregate.withAliasAndValue('AMOUNT', 200);

        journalEntrySelectorMock.when('selectForReconciliation').thenReturn(new List<AggregateResultProxy>{je1Aggregate, je2Aggregate});

        ProductionToBillJEAuditor.journalEntrySelector = (JournalEntrySelector) journalEntrySelectorMock.createStub();

        List<Journal_Entry__c> scope = new List<Journal_Entry__c>();
        scope.add(new Journal_Entry__c(
            Id = journalEntry1,
            Amount__c = 101
        ));
        scope.add(new Journal_Entry__c(
            Id = journalEntry2,
            Amount__c = -200
        ));
        scope.add(new Journal_Entry__c(
            Id = journalEntry3,
            Amount__c = 400
        ));

        ProductionToBillJEAuditor jeAuditor = new ProductionToBillJEAuditor();
        jeAuditor.execute(null, scope);
        jeAuditor.finish(null);
        List<Error_Log__c> errorLogs = [
            SELECT Message__c
            FROM Error_Log__c
            WHERE Severity__c = :Logger.ERROR
            AND Class__c = 'ProductionToBillJEAuditor'
        ];
        System.assertEquals(1, errorLogs.size(), 'Expected one error log after the batch finishes');
        System.assert(errorLogs[0].Message__c.contains(journalEntry1),
            'Expected errors to include journalEntry1 since the aggregate PD amount is 100 and the JE amount is 101, but got this: ' + errorLogs[0].Message__c);
        System.assert(!errorLogs[0].Message__c.contains(journalEntry2),
            'Expected errors to not include journalEntry2 since it is a debit memo and the aggregate PD amount is 200 and the JE amount is -200, but got this: ' + errorLogs[0].Message__c);
        System.assert(errorLogs[0].Message__c.contains(journalEntry3),
            'Expected errors to include journalEntry3 since it has no aggregate PDs, but got this: ' + errorLogs[0].Message__c);
    }

    @IsTest
    private static void testJEAuditorReconciliationForPartiallyAppliedCreditMemos() {
        Id journalEntry1 = Util.getFakeId(Journal_Entry__c.SObjectType);
        UniversalMocker journalEntrySelectorMock = UniversalMocker.mock(JournalEntrySelector.class);
        AggregateResultProxy je1Aggregate = new AggregateResultProxy();
        je1Aggregate.withAliasAndValue('Journal_Entry__c', journalEntry1);
        je1Aggregate.withAliasAndValue('Object_Type__c', 'CreditMemo');
        je1Aggregate.withAliasAndValue('AMOUNT', 100);

        journalEntrySelectorMock.when('selectForReconciliation').thenReturn(new List<AggregateResultProxy>{je1Aggregate});

        ProductionToBillJEAuditor.journalEntrySelector = (JournalEntrySelector) journalEntrySelectorMock.createStub();

        List<Journal_Entry__c> scope = new List<Journal_Entry__c>();
        scope.add(new Journal_Entry__c(
            Id = journalEntry1,
            Amount__c = 120,
            Credit_Memo_Unapplied_Amount__c = 20
        ));

        ProductionToBillJEAuditor jeAuditor = new ProductionToBillJEAuditor();
        jeAuditor.execute(null, scope);
        jeAuditor.finish(null);
        List<Error_Log__c> errorLogs = [
            SELECT Message__c
            FROM Error_Log__c
            WHERE Severity__c = :Logger.ERROR
            AND Class__c = 'ProductionToBillJEAuditor'
        ];
        System.assertEquals(0, errorLogs.size(),
            'Expected no error logs because a $120 CM with $20 Unapplied should have $100 of production details, but got this: ' + errorLogs);
    }


    @IsTest
    private static void testJEQueueNextJob() {
        ProductionToBillJEAuditor jeAuditor = new ProductionToBillJEAuditor();
        jeAuditor.query = jeAuditor.jesCreatedOrModifiedToday;
        Object nextAuditor = jeAuditor.queueNextJob();
        System.assert(nextAuditor instanceof ProductionToBillJEAuditor,
            'Expected the next auditor job to be the ProductionToBillJEAuditor if the current query was jesCreatedOrModifiedToday');
        jeAuditor.query = jeAuditor.jesForPDsCreatedOrModifiedToday;
        nextAuditor = jeAuditor.queueNextJob();
        System.assert(nextAuditor instanceof ProductionToBillExServicedUASBAuditor,
            'Expected the next auditor job to be the ProductionToBillExServicedUASBAuditor if the current query was jesForPDsCreatedOrModifiedToday');
        jeAuditor.query = 'SELECT Id FROM Journal_Entry__c';
        nextAuditor = jeAuditor.queueNextJob();
        System.assertEquals(null, nextAuditor,
            'Did not expect to queue another job if the current job was started with an unsupported query (for instance, ' +
                'if auditing for all history');
    }

    @IsTest
    private static void testUASBAuditor() {
        ProductionToBillExServicedUASBAuditor uasbAuditor = new ProductionToBillExServicedUASBAuditor();
        Test.startTest();
        Database.executeBatch(uasbAuditor);
        Test.stopTest();
        List<Error_Log__c> errorLogs = [
            SELECT Message__c
            FROM Error_Log__c
            WHERE Severity__c = :Logger.ERROR
            AND Class__c = 'ProductionToBillExServicedUASBAuditor'
        ];
        System.assertEquals(0, errorLogs.size(), 'Expected batch to run successfully but got this: ' + errorLogs);
    }

    @IsTest
    private static void testUASBAuditorReconciliation() {
        Id uasb1 = Util.getFakeId(UASB__c.SObjectType);
        Id uasb2 = Util.incrementFakeId(uasb1);
        Id uasb3 = Util.incrementFakeId(uasb2);

        UniversalMocker uasbSelectorMock = UniversalMocker.mock(UASBSelector.class);
        AggregateResultProxy uasbAggregate1 = new AggregateResultProxy();
        uasbAggregate1.withAliasAndValue('Externally_Serviced_UASB__c', uasb1);
        uasbAggregate1.withAliasAndValue('AMOUNT', 100);

        AggregateResultProxy uasbAggregate2 = new AggregateResultProxy();
        uasbAggregate2.withAliasAndValue('Externally_Serviced_UASB__c', uasb2);
        uasbAggregate2.withAliasAndValue('AMOUNT', 200);

        uasbSelectorMock.when('selectForReconciliation').thenReturn(new List<AggregateResultProxy>{uasbAggregate1, uasbAggregate2});

        ProductionToBillExServicedUASBAuditor.uasbSelector = (UASBSelector) uasbSelectorMock.createStub();

        List<UASB__c> scope = new List<UASB__c>();
        scope.add(new UASB__c(
            Id = uasb1,
            Credits_Allocated__c = 101
        ));
        scope.add(new UASB__c(
            Id = uasb2,
            Credits_Allocated__c = 200
        ));
        scope.add(new UASB__c(
            Id = uasb3,
            Credits_Allocated__c = 400
        ));

        ProductionToBillExServicedUASBAuditor uasbAuditor = new ProductionToBillExServicedUASBAuditor();
        uasbAuditor.execute(null, scope);
        uasbAuditor.finish(null);
        List<Error_Log__c> errorLogs = [
            SELECT Message__c
            FROM Error_Log__c
            WHERE Severity__c = :Logger.ERROR
            AND Class__c = 'ProductionToBillExServicedUASBAuditor'
        ];
        System.assertEquals(1, errorLogs.size(), 'Expected one error log after the batch finishes, but got this: ' + errorLogs);
        System.assert(errorLogs[0].Message__c.contains(uasb1),
            'Expected errors to include uasb1 since the aggregate PD amount is 100 and the JE amount is 101, but got this: ' + errorLogs[0].Message__c);
        System.assert(!errorLogs[0].Message__c.contains(uasb2),
            'Expected errors to not include uasb3 since the aggregate PD amount is 200 and the JE amount is 200, but got this: ' + errorLogs[0].Message__c);
        System.assert(errorLogs[0].Message__c.contains(uasb3),
            'Expected errors to include uasb3 since it has no aggregate PDs, but got this: ' + errorLogs[0].Message__c);
    }

    @IsTest
    private static void testUASBQueueNextJob() {
        ProductionToBillExServicedUASBAuditor uasbAuditor = new ProductionToBillExServicedUASBAuditor();
        uasbAuditor.query = uasbAuditor.externallyServicedUASBsCreatedOrModifiedToday;
        Object nextAuditor = uasbAuditor.queueNextJob();
        System.assert(nextAuditor instanceof ProductionToBillExServicedUASBAuditor,
            'Expected the next auditor job to be the ProductionToBillExServicedUASBAuditor if the current query was externallyServicedUASBsCreatedOrModifiedToday');
        uasbAuditor.query = uasbAuditor.uasbsForPDsCreatedOrModifiedToday;
        nextAuditor = uasbAuditor.queueNextJob();
        System.assert(nextAuditor instanceof ProductionToBillExServicedAdjustAuditor,
            'Expected the next auditor job to be the ProductionToBillExServicedAdjustAuditor if the current query was uasbsForPDsCreatedOrModifiedToday');
        uasbAuditor.query = 'SELECT Id FROM UASB__c';
        nextAuditor = uasbAuditor.queueNextJob();
        System.assertEquals(null, nextAuditor,
            'Did not expect to queue another job if the current job was started with an unsupported query (for instance, ' +
                'if auditing for all history');
    }

    @IsTest
    private static void testAdjustAuditor() {
        ProductionToBillExServicedAdjustAuditor adjustAuditor = new ProductionToBillExServicedAdjustAuditor();
        Test.startTest();
        Database.executeBatch(adjustAuditor);
        Test.stopTest();
        List<Error_Log__c> errorLogs = [
            SELECT Message__c
            FROM Error_Log__c
            WHERE Severity__c = :Logger.ERROR
            AND Class__c = 'ProductionToBillExServicedAdjustAuditor'
        ];
        System.assertEquals(0, errorLogs.size(), 'Expected batch to run successfully but got this: ' + errorLogs);
    }

    @IsTest
    private static void testAdjustAuditorReconciliation() {
        Id adjust1 = Util.getFakeId(Bill_Adjustment__c.SObjectType);
        Id adjust2 = Util.incrementFakeId(adjust1);
        Id adjust3 = Util.incrementFakeId(adjust2);

        UniversalMocker adjustmentSelectorMock = UniversalMocker.mock(AdjustmentSelector.class);
        AggregateResultProxy adjustAggregate1 = new AggregateResultProxy();
        adjustAggregate1.withAliasAndValue('Externally_Serviced_Bill_Adjustment__c', adjust1);
        adjustAggregate1.withAliasAndValue('AMOUNT', 100);

        AggregateResultProxy adjustAggregate2 = new AggregateResultProxy();
        adjustAggregate2.withAliasAndValue('Externally_Serviced_Bill_Adjustment__c', adjust2);
        adjustAggregate2.withAliasAndValue('AMOUNT', 200);

        adjustmentSelectorMock.when('selectForReconciliation').thenReturn(new List<AggregateResultProxy>{adjustAggregate1, adjustAggregate2});

        ProductionToBillExServicedAdjustAuditor.adjustmentSelector = (AdjustmentSelector) adjustmentSelectorMock.createStub();

        List<Bill_Adjustment__c> scope = new List<Bill_Adjustment__c>();
        scope.add(new Bill_Adjustment__c(
            Id = adjust1,
            Adjustment_Amount__c = 101
        ));
        scope.add(new Bill_Adjustment__c(
            Id = adjust2,
            Adjustment_Amount__c = 200
        ));
        scope.add(new Bill_Adjustment__c(
            Id = adjust3,
            Adjustment_Amount__c = 400
        ));

        ProductionToBillExServicedAdjustAuditor adjustmentAuditor = new ProductionToBillExServicedAdjustAuditor();
        adjustmentAuditor.execute(null, scope);
        adjustmentAuditor.finish(null);
        List<Error_Log__c> errorLogs = [
            SELECT Message__c
            FROM Error_Log__c
            WHERE Severity__c = :Logger.ERROR
            AND Class__c = 'ProductionToBillExServicedAdjustAuditor'
        ];
        System.assertEquals(1, errorLogs.size(), 'Expected one error log after the batch finishes, but got this: ' + errorLogs);
        System.assert(errorLogs[0].Message__c.contains(adjust1),
            'Expected errors to include adjust1 since the aggregate PD amount is 100 and the JE amount is 101, but got this: ' + errorLogs[0].Message__c);
        System.assert(!errorLogs[0].Message__c.contains(adjust2),
            'Expected errors to not include adjust2 since the aggregate PD amount is 200 and the JE amount is 200, but got this: ' + errorLogs[0].Message__c);
        System.assert(errorLogs[0].Message__c.contains(adjust3),
            'Expected errors to include adjust3 since it has no aggregate PDs, but got this: ' + errorLogs[0].Message__c);
    }

    @IsTest
    private static void testAdjustQueueNextJob() {
        ProductionToBillExServicedAdjustAuditor adjustmentAuditor = new ProductionToBillExServicedAdjustAuditor();
        adjustmentAuditor.query = adjustmentAuditor.externallyServicedAdjustmentsCreatedOrModifiedToday;
        Object nextAuditor = adjustmentAuditor.queueNextJob();
        System.assert(nextAuditor instanceof ProductionToBillExServicedAdjustAuditor,
            'Expected the next auditor job to be the ProductionToBillExServicedAdjustAuditor if the current query was externallyServicedAdjustmentsCreatedOrModifiedToday');
        adjustmentAuditor.query = adjustmentAuditor.adjustmentsForPDsCreatedOrModifiedToday;
        nextAuditor = adjustmentAuditor.queueNextJob();
        System.assertEquals(null, nextAuditor,
            'Did not expect to queue another job if the current job adjustmentsForPDsCreatedOrModifiedToday, since the auditing chain is done');
        adjustmentAuditor.query = 'SELECT Id FROM Bill_Adjustment__c';
        nextAuditor = adjustmentAuditor.queueNextJob();
        System.assertEquals(null, nextAuditor,
            'Did not expect to queue another job if the current job was started with an unsupported query (for instance, ' +
                'if auditing for all history');
    }
}