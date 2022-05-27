/**
 * @description created by jeffparlin on 5/26/22. Evaluates total capacity allocated for an Opportunity and sets
 * in respective CS_Capacity_Allocated__c field(Customer kWdc at Complete) on Opportunity. Initiated by
 * Countersign Contracts flow as of time of creation
 */
public without sharing class CapacityAllocatedEvaluator {

    @TestVisible private static UASSelector utilityAccountSelector = new UASSelector();
    @TestVisible private Map<Id, Decimal> oppToUASSummaryMap = new Map<Id, Decimal>();
    private List<Opportunity> opportunities;

    @InvocableMethod(
        Label='Capacity Allocated Evaluator'
        Description='Evaluates CS_Capacity_Allocated__c for passed-in Opportunities and returns resulting SObjects')
    public static List<List<Opportunity>> setCapacityAllocatedOnOpps(List<List<Opportunity>> oppList) {
        List<List<Opportunity>> returnList = new List<List<Opportunity>>();
        CapacityAllocatedEvaluator evaluator = new CapacityAllocatedEvaluator(oppList[0]);
        evaluator.execute();
        returnList.add(evaluator.opportunities);
        return returnList;
    }

    public CapacityAllocatedEvaluator(List<Opportunity> opps) {
        this.opportunities = opps;
    }

    public void execute() {
        oppToUASSummaryMap = utilityAccountSelector.getUASSummaryByOpportunity(CollectionUtil.getIdSet(opportunities));
        for (Opportunity opp : opportunities) {
            setCapacityAllocated(opp);
        }
        Logger.flushLogs();
    }

    private void setCapacityAllocated(Opportunity opp) {
        Decimal uasSummary = oppToUASSummaryMap.get(opp.Id);
        if (uasSummary == null) {
            Logger.logLater(
                'CapacityAllocatedEvaluator',
                'setCapacityAllocated',
                'Could not get CS_Capacity_Allocated__c for opp: ' + String.valueOf(opp.Id) +
                    'and map: ' + JSON.serialize(oppToUASSummaryMap),
                'INFO'
            );
            return;
        }
        opp.CS_Capacity_Allocated__c = uasSummary;
    }
}