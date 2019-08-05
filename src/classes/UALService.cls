/**
 * Created by jlugo on 2019-07-08.
 * Tested by system tests in RESTRouterV2Test.
 */

public without sharing class UALService {

    private UALSelector ualSelector = new UALSelector();

    public Utility_Account_Log__c insertUAL(Utility_Account_Log__c utilityAccountLog) {
        insert utilityAccountLog;
        utilityAccountLog = ualSelector.selectOne(utilityAccountLog.Id);
        return utilityAccountLog;
    }

    public List<Utility_Account_Log__c> insertUALs(List<Utility_Account_Log__c> utilityAccountLogs) {
        insert utilityAccountLogs;
        Set<Id> ualIds = new Set<Id>();
        for (Utility_Account_Log__c ual : utilityAccountLogs) {
            ualIds.add(ual.Id);
        }
        return ualSelector.selectAll(ualIds);
    }

    public Utility_Account_Log__c updateUAL(Utility_Account_Log__c utilityAccountLog) {
        update utilityAccountLog;
        utilityAccountLog = ualSelector.selectOne(utilityAccountLog.Id);
        return utilityAccountLog;
    }

}