/**
 * @description Created by jeffparlin on 2/14/22.
 */
@IsTest
public class OppCommissionableDateSetterTest {

    private static final String ACCOUNT_ID_PREFIX = Util.getFakeId(Account.SObjectType).left(12);
    private static final String SYSTEM_ID_PREFIX = Util.getFakeId(Shared_Solar_System__c.SObjectType).left(12);
    private static final String OPP_ID_PREFIX = Util.getFakeId(Opportunity.SObjectType).left(12);

    @IsTest
    private static void mockTestDateSetter() {
        useMocks();
        Set<Id> accountIds = new Set<Id>();
        accountIds.add(ACCOUNT_ID_PREFIX + 'AAA');
        accountIds.add(ACCOUNT_ID_PREFIX + 'BBB');
        OpportunityCommissionableDateSetter instance = new OpportunityCommissionableDateSetter(accountIds);

        Test.startTest();
            instance.execute();
            List<Opportunity> oppsToUpdate = instance.opportunitiesToUpdate;
        Test.stopTest();
        Test.getEventBus().deliver();

        System.assertEquals(Date.newInstance(2022, 01, 01), oppsToUpdate[0].First_Bill_Sent_Date__c,
            'Automation should set first bill sent date');
        System.assertEquals(Date.newInstance(2022, 01, 15), oppsToUpdate[1].First_Bill_Paid_Date__c,
            'Automation should set first bill paid date');
        System.assertEquals(1, [SELECT Id FROM Error_Log__c WHERE Class__c = 'OpportunityCommissionableDateSetter'].size(),
            'Error log should have been generated due to inability to update mock data in the database');
    }

    private static List<Opportunity> mockFirstBillSentOpps() {
        sfab_FabricatedSObject acc1 = new sfab_FabricatedSObject(Account.class);
        acc1.setField(Account.Id, ACCOUNT_ID_PREFIX + 'AAA');
        acc1.setField(Account.Account_Number__c, '12345');

        sfab_FabricatedSObject system1 = new sfab_FabricatedSObject(Shared_Solar_System__c.class);
        system1.setField(Shared_Solar_System__c.Id, SYSTEM_ID_PREFIX + 'AAA');
        system1.setField(Shared_Solar_System__c.Unique_ID__c, 'SSS-0001');

        sfab_FabricatedSObject opp1 = new sfab_FabricatedSObject(Opportunity.class);
        opp1.setField(Opportunity.Id, OPP_ID_PREFIX + 'AAA');
        opp1.setField(Opportunity.Name, 'Oppty A');
        opp1.setParent('Account', acc1);
        opp1.setParent('Shared_Solar_System__r', system1);

        return new List<Opportunity>{(Opportunity) opp1.toSObject()};
    }

    private static List<Opportunity> mockFirstBillPaidOpps() {
        sfab_FabricatedSObject acc2 = new sfab_FabricatedSObject(Account.class);
        acc2.setField(Account.Id, ACCOUNT_ID_PREFIX + 'BBB');
        acc2.setField(Account.Account_Number__c, '67890');

        sfab_FabricatedSObject system2 = new sfab_FabricatedSObject(Shared_Solar_System__c.class);
        system2.setField(Shared_Solar_System__c.Id, SYSTEM_ID_PREFIX + 'BBB');
        system2.setField(Shared_Solar_System__c.Unique_ID__c, 'SSS-0002');

        sfab_FabricatedSObject opp2 = new sfab_FabricatedSObject(Opportunity.class);
        opp2.setField(Opportunity.Id, OPP_ID_PREFIX + 'BBB');
        opp2.setField(Opportunity.Name, 'Oppty B');
        opp2.setParent('Account', acc2);
        opp2.setParent('Shared_Solar_System__r', system2);

        return new List<Opportunity>{(Opportunity) opp2.toSObject()};
    }

    private static void useMocks() {
        OpportunityCommissionableDateSetter.oppSelector = (OpportunitiesSelector)
            Test.createStub(OpportunitiesSelector.class, new MockOppSelector());
        OpportunityCommissionableDateSetter.glSelector = (JournalEntrySelector)
            Test.createStub(JournalEntrySelector.class, new MockJournalEntrySelector());
    }

    private class MockOppSelector extends MockProvider {
        public override Object handleMethodCall(MethodCall methodCall) {
            switch on methodCall.stubbedMethodName {
                when 'selectWithoutFirstBillSentStamped' {
                    return mockFirstBillSentOpps();
                }
                when 'selectWithoutFirstBillPaidStamped' {
                    return mockFirstBillPaidOpps();
                }
            }
            return null;
        }
    }

    private class MockJournalEntrySelector extends MockProvider {
        public override Object handleMethodCall(MethodCall methodCall) {
            if (methodCall.stubbedMethodName == 'getCommissionableEntriesFromToday') {
                List<Journal_Entry__c> returnList = new List<Journal_Entry__c>{
                    new Journal_Entry__c(
                        Customer_Account__c = '12345',
                        Object_Type__c = 'InvoiceItem',
                        Project__c = 'SSS-0001',
                        Date__c = Date.newInstance(2022, 01, 01)
                    ),
                    new Journal_Entry__c(
                        Customer_Account__c = '67890',
                        Object_Type__c = 'PaymentPart',
                        Project__c = 'SSS-0002',
                        Date__c = Date.newInstance(2022, 01, 15)
                    )
                };
                return returnList;
            }
            return null;
        }
    }

}