/**
 * @description Created by jeffparlin on 02/14/21. AggregateResult can't be mocked so wrap with AggregateResultProxy
 * which can be mocked by test methods.
 * See also: https://salesforce.stackexchange.com/questions/173193/is-there-a-way-i-can-mock-an-aggregateresult
 * Tested By: AggregateResultProxyTest
 */
public class AggregateResultProxy {
    private Map<String,Object> valuesByAlias = new Map<String,Object>();

    public AggregateResultProxy withAggregateResult(AggregateResult groupedResult) {
        String groupedResultJson = JSON.serialize(groupedResult);
        this.valuesByAlias = (Map<String,Object>) JSON.deserializeUntyped(groupedResultJson);
        return this;
    }

    public AggregateResultProxy withAliasAndValue(String alias, Object val) {
        this.valuesByAlias.put(alias,val);
        return this;
    }

    public Map<String,Object> getValuesByAlias() {
        return this.valuesByAlias;
    }
}