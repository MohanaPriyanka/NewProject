@IsTest
public class CapacityAllocatedEvaluatorTest {

    @IsTest
    public static void testNormalExecution() {
        useMocks();
        List<List<Opportunity>> inputList = new List<List<Opportunity>>();
        inputList.add(new List<Opportunity>{
            new Opportunity(
                Id = Util.getFakeId(Opportunity.SObjectType)
            )}
        );
        List<List<Opportunity>> results = CapacityAllocatedEvaluator.setCapacityAllocatedOnOpps(inputList);
        Opportunity resultingOpp = results[0][0];
        System.assertEquals(7.661, resultingOpp.CS_Capacity_Allocated__c);
    }

    @IsTest
    public static void testFailure() {
        List<List<Opportunity>> inputList = new List<List<Opportunity>>();
        inputList.add(new List<Opportunity>{
            new Opportunity(
                Id = Util.getFakeId(Opportunity.SObjectType)
            )}
        );
        System.assertEquals(0, [SELECT Id FROM Error_Log__c].size(), 'No logs should be present prior to test');
        CapacityAllocatedEvaluator.setCapacityAllocatedOnOpps(inputList);
        System.assertEquals(1, [SELECT Id FROM Error_Log__c].size(), '1 log should be present after test');
    }

    public static void useMocks() {
        UniversalMocker uasSelectorMock = UniversalMocker.mock(UASSelector.class);
        uasSelectorMock.when('getUASSummaryByOpportunity').thenReturn(new Map<Id, Decimal>{
            Util.getFakeId(Opportunity.SObjectType) => 7.661
        });
        CapacityAllocatedEvaluator.utilityAccountSelector = (UASSelector) uasSelectorMock.createStub();
    }
}