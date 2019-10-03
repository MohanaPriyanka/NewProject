/**
 * Created by PeterYao on 10/2/2019.
 * Description: Accepts a list of Zuora Account Ids and makes updates if necessary using SFDC as system of record. At
 *  this time, checks Gateway and Billing Terms, but could be extended to add Billing Batch.
 * Tested By: ZuoraAccountReconciliationServiceTest
 */

public with sharing class ZuoraAccountReconciliationService {
    @TestVisible
    private AccountsSelector accountsSelector = new AccountsSelector();
    @TestVisible
    private ZuoraAccountAsyncService nextAccountAsyncService;

    public void reconcileZuoraWithSFDC(Set<String> zuoraAccountIds, Set<String> zuoraAccountIdsReconciled) {
        try {
            Set<String> accountIds = getBatchOfAccountsToReconcile(zuoraAccountIds);
            reconcileZuoraWithSFDCInner(accountIds);
            zuoraAccountIds.removeAll(accountIds);
            zuoraAccountIdsReconciled.addAll(accountIds);
            if (zuoraAccountIds.size() > 0) {
                ZuoraAccountAsyncService accountAsyncService = new ZuoraAccountAsyncService(zuoraAccountIds, zuoraAccountIdsReconciled);
                if (Test.isRunningTest()) {
                    nextAccountAsyncService = accountAsyncService;
                } else {
                    System.enqueueJob(accountAsyncService);
                }
            }
        } catch (Util.BWException bwe) {
            Logger.logLater('ZuoraAccountReconciliationService', 'reconcileZuoraWithSFDC', 'Exception caught but retrying:\n' + bwe.getMessage() + '\n' + bwe.getStackTraceString(), Logger.WARN);
            ZuoraAccountAsyncService accountAsyncService = new ZuoraAccountAsyncService(zuoraAccountIds, zuoraAccountIdsReconciled);
            if (Test.isRunningTest()) {
                nextAccountAsyncService = accountAsyncService;
            } else {
                System.enqueueJob(accountAsyncService);
            }
        } catch (Exception e) {
            Logger.logLater('ZuoraAccountReconciliationService', 'reconcileZuoraWithSFDC', 'Exception caught and stopping:\n' + e.getMessage() + '\n' + e.getStackTraceString(), Logger.ERROR);
        } finally {
            Logger.flushLogs();
        }
    }

    @TestVisible
    private Set<String> getBatchOfAccountsToReconcile(Set<String> zuoraAccountIds) {
        if (zuoraAccountIds.size() <= ZuoraAPIHelper.maxActionUpdateRecords) {
            return zuoraAccountIds.clone();
        }

        Set<String> batchOfAccountIds = new Set<String>();
        for (String zuoraAccountId : new List<String>(zuoraAccountIds)) {
            batchOfAccountIds.add(zuoraAccountId);
            if (batchOfAccountIds.size() == ZuoraAPIHelper.maxActionUpdateRecords) {
                break;
            }
        }
        return batchOfAccountIds;
    }

    @TestVisible
    private void reconcileZuoraWithSFDCInner(Set<String> zuoraAccountIds) {
        List<String> zuoraAccountIdList = new List<String>(zuoraAccountIds);
        List<ZuoraAPI.ZuoraAccount> zuoraAccounts =
            ZuoraAccountSelector.query(zuoraAccountIdList, ZuoraAPI.accountFieldsToReconcile);
        Map<String, Map<String, Object>> zuoraIdToSFDCAccountMap = getZuoraIdToSFDCAccountMap(zuoraAccountIdList);

        List<ZuoraAPI.ZuoraAccount> zuoraAccountsToUpdate =
            getZuoraAccountsWithVariances(zuoraAccounts, zuoraIdToSFDCAccountMap);

        if (!zuoraAccountsToUpdate.isEmpty()) {
            ZuoraAPI.ActionItems actionItems = new ZuoraAPI.ActionItems();
            actionItems.type = 'Account';
            actionItems.objects = zuoraAccountsToUpdate;
            ZuoraAPIHelper.actionUpdate(actionItems);
        }
    }

    @TestVisible
    private List<ZuoraAPI.ZuoraAccount> getZuoraAccountsWithVariances(List<ZuoraAPI.ZuoraAccount> zuoraAccounts, Map<String, Map<String, Object>> zuoraIdToSFDCAccountMap) {
        List<ZuoraAPI.ZuoraAccount> zuoraAccountsToUpdate = new List<ZuoraAPI.ZuoraAccount>();
        for (ZuoraAPI.ZuoraAccount zuoraAccount : zuoraAccounts) {
            Map<String, Object> sfdcAccount = zuoraIdToSFDCAccountMap.get(zuoraAccount.Id);
            if (sfdcAccount == null) {
                Logger.logLater(
                    'ZuoraAccountReconciliationService',
                    'getZuoraAccountsWithVariances',
                    'Did not find a zuora account for ' + zuoraAccount.Id,
                    Logger.ERROR);
                continue;
            }

            ZuoraAPI.ZuoraAccount zuoraAccountToUpdate = new ZuoraAPI.ZuoraAccount(sfdcAccount);
            if (zuoraAccount.hasReconciliationVariance(zuoraAccountToUpdate)) {
                zuoraAccountsToUpdate.add(zuoraAccountToUpdate);
            }
        }
        return zuoraAccountsToUpdate;
    }

    @TestVisible
    private Map<String, Map<String, Object>> getZuoraIdToSFDCAccountMap(List<String> zuoraAccountIds) {
        List<Map<String, Object>> sfdcAggregateResultsAsMap = accountsSelector.selectForReconciliation(zuoraAccountIds);
        Map<String, Map<String, Object>> zuoraIdToSFDCAccountsMap = new Map<String, Map<String, Object>>();
        for (Map<String, Object> aggregateResultAsMap : sfdcAggregateResultsAsMap) {
            zuoraIdToSFDCAccountsMap.put((String) aggregateResultAsMap.get('Zuora_Id__c'), aggregateResultAsMap);
        }
        return zuoraIdToSFDCAccountsMap;
    }

}