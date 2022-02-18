/**
 * @description Created by jeffparlin on 2/14/22.
 */
@IsTest
public class AggregateResultProxyTest {

    @TestSetup
    public static void insertData() {
        Opportunity opp1 = new Opportunity(Name = 'Test1', StageName = 'Complete', CloseDate = System.today(), Amount = 50);
        Opportunity opp2 = new Opportunity(Name = 'Test2', StageName = 'Complete', CloseDate = System.today(), Amount = 100);
        insert new List<Opportunity>{opp1, opp2};
    }

    @IsTest
    private static void testWithAggregateResult() {
        List<AggregateResult> groupedResults = [SELECT AVG(Amount)aver FROM Opportunity];
        List<AggregateResultProxy> groupedProxyResults = new List<AggregateResultProxy>();
        for (AggregateResult aggregateResult : groupedResults) {
            groupedProxyResults.add(new AggregateResultProxy().withAggregateResult(aggregateResult));
        }

        for (AggregateResultProxy proxyResult : groupedProxyResults) {
            Map<String,Object> result = proxyResult.getValuesByAlias();
            System.assertEquals(75, result.get('aver'), 'Incorrect aggregate result datapoint retrieved from map');
        }
    }

    @IsTest
    private static void testWithValuesOnly() {
        List<AggregateResultProxy> groupedProxyResults = new List<AggregateResultProxy>();
        AggregateResultProxy resultProxy = new AggregateResultProxy().withAliasAndValue('aver', 75);
        groupedProxyResults.add(resultProxy);

        for (AggregateResultProxy proxyResult : groupedProxyResults) {
            Map<String,Object> result = proxyResult.getValuesByAlias();
            System.assertEquals(75, result.get('aver'), 'Incorrect aggregate result datapoint retrieved from map');
        }
    }

}