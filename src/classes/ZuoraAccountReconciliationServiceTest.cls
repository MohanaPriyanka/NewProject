/**
 * Created by PeterYao on 10/2/2019.
 */
@IsTest
public with sharing class ZuoraAccountReconciliationServiceTest {
    private static ZuoraAccountReconciliationService accountReconciliationService = new ZuoraAccountReconciliationService();

    public static void useMocks() {
        accountReconciliationService.accountsSelector = (AccountsSelector) Test.createStub(AccountsSelector.class, new MockAccountsSelector());
    }

    @IsTest
    public static void testAsyncReconciliation() {
        Set<String> zuoraAccountIds = new Set<String>{
            '2c92c0f86b78f56c016b7b00480c2e24'
        };

        ZuoraAccountAsyncService accountAsyncService = new ZuoraAccountAsyncService(zuoraAccountIds);
        accountAsyncService.accountReconciliationService =
            (ZuoraAccountReconciliationService) Test.createStub(ZuoraAccountReconciliationService.class, new MockZuoraAccountReconciliationService());
        Test.startTest();
        Id jobId = System.enqueueJob(accountAsyncService);
        Test.stopTest();
        AsyncApexJob jobInfo = [
            SELECT Status, NumberOfErrors
            FROM AsyncApexJob WHERE Id = :jobId
        ];
        System.assertEquals('Completed', jobInfo.Status);
    }

    @IsTest
    public static void testAsyncReconciliationError() {
        ZuoraAccountAsyncService accountAsyncService = new ZuoraAccountAsyncService((Set<String>) null);
        accountAsyncService.accountReconciliationService =
            (ZuoraAccountReconciliationService) Test.createStub(ZuoraAccountReconciliationService.class, new MockZuoraAccountReconciliationService());
        Test.startTest();
        Id jobId = System.enqueueJob(accountAsyncService);
        Test.stopTest();
        AsyncApexJob jobInfo = [
            SELECT Status, NumberOfErrors
            FROM AsyncApexJob WHERE Id = :jobId
        ];
        System.assertEquals('Completed', jobInfo.Status);
        List<Error_Log__c> errorLogs = [
            SELECT Id, Message__c
            FROM Error_Log__c
            WHERE Class__c = 'ZuoraAccountAsyncService'
            AND Method__c = 'execute'
        ];
        System.debug(LoggingLevel.ERROR, errorLogs);
        System.assertEquals(1, errorLogs.size());
        System.assert(errorLogs[0].Message__c.contains('operation failed'));
    }

    @IsTest
    public static void testReconcileCompletion() {
        useMocks();
        // The mock adds a string to the end of the zuora account id
        Set<String> zuoraAccountIds = new Set<String>{
            '2c92c0f86d82b3db016d88b917585360',
            '2c92c0f86d82b3db016d88b917585361',
            '2c92c0f86d82b3db016d88b917585362',
            '2c92c0f86d82b3db016d88b917585363',
            // This one is returned by ZuoraAPIMock
            '2c92c0f86b78f56c016b7b00480c2e2'
        };
        Set<String> accountIdsReconciled = new Set<String>();
        accountReconciliationService.reconcileZuoraWithSFDC(zuoraAccountIds, accountIdsReconciled);
        System.assertEquals(0, zuoraAccountIds.size());
        System.assertEquals(5, accountIdsReconciled.size());
        System.assert(accountReconciliationService.nextAccountAsyncService == null);
    }

    @IsTest
    public static void testReconcileChain() {
        useMocks();
        // The mock adds a string to the end of the zuora account id
        Set<String> zuoraAccountIds = new Set<String>{
            '2c92c0f86d82b3db016d88b917585360',
            '2c92c0f86d82b3db016d88b917585361',
            '2c92c0f86d82b3db016d88b917585362',
            '2c92c0f86d82b3db016d88b917585363',
            // This one is returned by ZuoraAPIMock
            '2c92c0f86b78f56c016b7b00480c2e2'
        };
        for (Integer i = 0; i < 50; i++) {
            zuoraAccountIds.add('Ac92c0f86d82b3db016d88b9175853'+i);
        }
        Integer totalAccountsToReconcile = zuoraAccountIds.size();
        Set<String> accountIdsReconciled = new Set<String>();
        accountReconciliationService.reconcileZuoraWithSFDC(zuoraAccountIds, accountIdsReconciled);
        System.assertEquals(totalAccountsToReconcile-ZuoraAPIHelper.maxActionUpdateRecords, zuoraAccountIds.size());
        System.assertEquals(ZuoraAPIHelper.maxActionUpdateRecords, accountIdsReconciled.size());
        System.assert(accountReconciliationService.nextAccountAsyncService != null);
    }

    @IsTest
    public static void testReconcileRetry() {
        useMocks();
        // The mock adds a string to the end of the zuora account id
        Set<String> zuoraAccountIds = new Set<String>{
            '2c92c0f86d82b3db016d88b917585360',
            '2c92c0f86d82b3db016d88b917585361',
            '2c92c0f86d82b3db016d88b917585362',
            '2c92c0f86d82b3db016d88b917585363',
            // This one is returned by ZuoraAPIMock
            '2c92c0f86b78f56c016b7b00480c2e2'
        };
        for (Integer i = 0; i < 50; i++) {
            zuoraAccountIds.add('Ac92c0f86d82b3db016d88b9175853'+i);
        }
        Integer totalAccountsToReconcile = zuoraAccountIds.size();
        Set<String> accountIdsReconciled = new Set<String>();
        ZuoraAPIHelper.calloutMillis = ZuoraAPIHelper.maxCalloutMillis + 100;
        accountReconciliationService.reconcileZuoraWithSFDC(zuoraAccountIds, accountIdsReconciled);
        System.assertEquals(totalAccountsToReconcile, zuoraAccountIds.size());
        System.assertEquals(0, accountIdsReconciled.size());
        System.assert(accountReconciliationService.nextAccountAsyncService != null);
        List<Error_Log__c> errorLogs = [
            SELECT Id, Message__c
            FROM Error_Log__c
            WHERE Method__c = 'reconcileZuoraWithSFDC'
        ];
        System.assertEquals(1, errorLogs.size());
        System.assert(errorLogs[0].Message__c.contains('Exception caught but retrying'));
    }

    @IsTest
    public static void testReconcileInner() {
        useMocks();
        // The mock adds a string to the end of the zuora account id
        List<String> zuoraAccountIds = new List<String>{
            '2c92c0f86d82b3db016d88b917585360',
            '2c92c0f86d82b3db016d88b917585361',
            '2c92c0f86d82b3db016d88b917585362',
            '2c92c0f86d82b3db016d88b917585363',
            // This one is returned by ZuoraAPIMock
            '2c92c0f86b78f56c016b7b00480c2e2'
        };
        accountReconciliationService.reconcileZuoraWithSFDCInner(new Set<String>(zuoraAccountIds));

        System.assertEquals(2, ZuoraAPIHelper.endpointsCalled.size(), 'Expected one callout for query, another for /action/update');
        System.assertEquals('/v1/action/query', ZuoraAPIHelper.endpointsCalled[0].endpoint);
        for (String zuoraAccountId : zuoraAccountIds) {
            System.assert(ZuoraAPIHelper.endpointsCalled[0].jsonBody.contains(zuoraAccountId));
        }
        System.assertEquals('/v1/action/update/', ZuoraAPIHelper.endpointsCalled[1].endpoint);
        System.assert(ZuoraAPIHelper.endpointsCalled[1].jsonBody.contains('2c92c0f86b78f56c016b7b00480c2e24'));
    }

    @IsTest
    public static void testZuoraAPIAccountReconciliationForMultipleGateways() {
        String aggregateResultJSON =
            '[{"Id":"001S000000yKIbOIAW",' +
                '"Zuora_Id__c":"2c92c0f86d82b3db016d88b917585366",' +
                '"AccountName":"Harrison Harris 8",' +
                '"DaysInBillingPeriod":45,' +
                '"DistinctGateways":2,' +
                '"GatewayName":"Chargent Gateway B"}]';
        List<Object> aggregateResults = (List<Object>) JSON.deserializeUntyped(aggregateResultJSON);
        ZuoraAPI.ZuoraAccount reconciliationResult = new ZuoraAPI.ZuoraAccount((Map<String, Object>) aggregateResults[0]);

        ZuoraAPI.ZuoraAccount zuoraAccountToTest = new ZuoraAPI.ZuoraAccount();
        zuoraAccountToTest.PaymentTerm = 'Net 30';
        zuoraAccountToTest.PaymentGateway = null;
        System.assert(zuoraAccountToTest.hasReconciliationVariance(reconciliationResult), 'Expected a reconciliation variance');

        zuoraAccountToTest = new ZuoraAPI.ZuoraAccount();
        zuoraAccountToTest.PaymentTerm = 'Net 45';
        zuoraAccountToTest.PaymentGateway = null;
        System.assert(!zuoraAccountToTest.hasReconciliationVariance(reconciliationResult),
            'Did not expect a reconciliation variance because we use the default gateway and the account has multiple gateways');

        zuoraAccountToTest = new ZuoraAPI.ZuoraAccount();
        zuoraAccountToTest.PaymentTerm = 'Net 45';
        zuoraAccountToTest.PaymentGateway = 'Chargent Gateway B';
        System.assert(zuoraAccountToTest.hasReconciliationVariance(reconciliationResult), 'Expected a reconciliation variance');
    }

    @IsTest
    public static void testZuoraAPIAccountReconciliationForSingleGateway() {
        String aggregateResultJSON =
            '[{"Id":"001S000000yKIbOIAW",' +
                '"Zuora_Id__c":"2c92c0f86d82b3db016d88b917585366",' +
                '"AccountName":"Harrison Harris 8",' +
                '"DistinctGateways":1,' +
                '"GatewayName":"Chargent Gateway B"}]';
        List<Object> aggregateResults = (List<Object>) JSON.deserializeUntyped(aggregateResultJSON);
        ZuoraAPI.ZuoraAccount reconciliationResult = new ZuoraAPI.ZuoraAccount((Map<String, Object>) aggregateResults[0]);

        ZuoraAPI.ZuoraAccount zuoraAccountToTest = new ZuoraAPI.ZuoraAccount();
        zuoraAccountToTest.PaymentTerm = 'Net 30';
        zuoraAccountToTest.PaymentGateway = null;
        System.assert(zuoraAccountToTest.hasReconciliationVariance(reconciliationResult), 'Expected a reconciliation variance');

        zuoraAccountToTest = new ZuoraAPI.ZuoraAccount();
        zuoraAccountToTest.PaymentTerm = 'Net 30';
        zuoraAccountToTest.PaymentGateway = 'Chargent Gateway B';
        System.assert(!zuoraAccountToTest.hasReconciliationVariance(reconciliationResult), 'Did not expect a reconciliation variance');
    }

    @IsTest
    public static void testZuoraAccountsWithVariances() {
        useMocks();
        // The mock adds a string to the end of the zuora account id
        List<String> zuoraAccountIds = new List<String>{
            '2c92c0f86d82b3db016d88b91758536',
            '2c92c0f86d82b3db016d88b91758536',
            '2c92c0f86d82b3db016d88b91758536'
        };
        List<ZuoraAPI.ZuoraAccount> zuoraAccounts = new List<ZuoraAPI.ZuoraAccount>();
        // Should be a variance because the mock returns 2 gateways
        ZuoraAPI.ZuoraAccount zuoraAccount0 = new ZuoraAPI.ZuoraAccount();
        zuoraAccount0.Id = zuoraAccountIds[0]+'0';
        zuoraAccount0.PaymentGateway = 'Chargent Gateway';
        zuoraAccount0.PaymentTerm = 'Net 45';
        zuoraAccounts.add(zuoraAccount0);

        // Should not have a variance
        ZuoraAPI.ZuoraAccount zuoraAccount1 = new ZuoraAPI.ZuoraAccount();
        zuoraAccount1.Id = zuoraAccountIds[1]+'1';
        zuoraAccount1.PaymentGateway = 'Chargent Gateway B';
        zuoraAccount1.PaymentTerm = 'Net 30';
        zuoraAccounts.add(zuoraAccount1);

        // Should be a variance because the mock has Net 30
        ZuoraAPI.ZuoraAccount zuoraAccount2 = new ZuoraAPI.ZuoraAccount();
        zuoraAccount2.Id = zuoraAccountIds[2]+'2';
        zuoraAccount2.PaymentGateway = 'Chargent Gateway B';
        zuoraAccount2.PaymentTerm = 'Net 45';
        zuoraAccounts.add(zuoraAccount2);

        // Should log an error that it wasn't found
        ZuoraAPI.ZuoraAccount zuoraAccount3 = new ZuoraAPI.ZuoraAccount();
        zuoraAccount3.Id = zuoraAccountIds[2]+'3';
        zuoraAccount3.PaymentGateway = 'Chargent Gateway B';
        zuoraAccount3.PaymentTerm = 'Net 45';
        zuoraAccounts.add(zuoraAccount3);

        Map<String, Map<String, Object>> zuoraIdMap = accountReconciliationService.getZuoraIdToSFDCAccountMap(zuoraAccountIds);
        List<ZuoraAPI.ZuoraAccount> variances =
            accountReconciliationService.getZuoraAccountsWithVariances(zuoraAccounts, zuoraIdMap);
        Logger.flushLogs();
        System.assertEquals(2, variances.size());
        for (ZuoraAPI.ZuoraAccount zuoraAccount : variances) {
            System.assert(zuoraAccount.Id == zuoraAccountIds[0]+'0' || zuoraAccount.Id == zuoraAccountIds[2]+'2',
                'Expected either zuoraAccount0 or zuoraAccount1 to be the variance');
        }

        List<Error_Log__c> errorLogs = [
            SELECT Message__c
            FROM Error_Log__c
            WHERE Class__c = 'ZuoraAccountReconciliationService'
            AND Severity__c = :Logger.ERROR
        ];
        System.assertEquals(1, errorLogs.size());

    }

    @IsTest
    public static void testGetZuoraIdToSFDCMap() {
        useMocks();
        List<String> zuoraAccountIds = new List<String>{
            '2c92c0f86d82b3db016d88b91758536',
            '2c92c0f86d82b3db016d88b91758536',
            '2c92c0f86d82b3db016d88b91758536'
        };

        Map<String, Map<String, Object>> zuoraIdToSFDCAccountMap =
            accountReconciliationService.getZuoraIdToSFDCAccountMap(zuoraAccountIds);
        System.assertEquals(zuoraAccountIds.size(), zuoraIdToSFDCAccountMap.size());
        for (Integer i = 0; i < zuoraAccountIds.size(); i++) {
            System.assert(zuoraIdToSFDCAccountMap.containsKey(zuoraAccountIds[i]+i));
        }
    }

    @IsTest
    public static void testGetBatchOfAccounts() {
        List<String> strings = new List<String>();
        for (Integer i = 0; i < 50; i++) {
            strings.add(String.valueOf(i));
        }
        System.assert(accountReconciliationService.getBatchOfAccountsToReconcile(new Set<String>(strings)).contains('49'),
            'Expected 0 through 49 in the set');
        for (Integer i = 50; i < 100; i++) {
            strings.add(String.valueOf(i));
        }
        System.assert(!accountReconciliationService.getBatchOfAccountsToReconcile(new Set<String>(strings)).contains('50'),
            'Expected only 0 through 49 in the set');
        System.assertEquals(50, accountReconciliationService.getBatchOfAccountsToReconcile(new Set<String>(strings)).size());
    }

    @IsTest
    public static void testCommunicationProfile() {
        Account propertyAccount = new Account(
            Name = 'Account B',
            Client_Brand_Key__c = 'BluewaveLogo'
        );
        ZuoraAPI.ZuoraAccount accountToTest = new ZuoraAPI.ZuoraAccount(propertyAccount);
        accountToTest.PaymentTerm = 'Net 30';
        accountToTest.PaymentGateway = 'Chargent Gateway B';

        ZuoraAPI.ZuoraAccount accountFromZuora = new ZuoraAPI.ZuoraAccount();
        accountFromZuora.PaymentTerm = 'Net 30';
        accountFromZuora.PaymentGateway = 'Chargent Gateway B';
        accountFromZuora.communicationProfileId = 'AmpRed';
        System.assert(accountFromZuora.hasReconciliationVariance(accountToTest), 'Expected a reconciliation variance');

        accountFromZuora = new ZuoraAPI.ZuoraAccount();
        accountFromZuora.PaymentTerm = 'Net 30';
        accountFromZuora.PaymentGateway = 'Chargent Gateway B';
        accountFromZuora.communicationProfileId = 'BluewaveLogoXXX';
        Zuora_Setting__mdt zuoraSetting = ZuoraAPIHelper.getZuoraSetting();
        if (zuoraSetting.Zuora_Is_Live__c) {
            System.assert(!accountFromZuora.hasReconciliationVariance(accountToTest), 'Did not expect a reconciliation variance');
        } else {
            System.assert(accountFromZuora.hasReconciliationVariance(accountToTest), 'Expected a reconciliation variance');
        }
    }

    @IsTest
    public static void testClientBrandKeyValues(){
        List<String> clientBrandKeys = new List<String>();
        Schema.DescribeFieldResult field = Account.Client_Brand_Key__c.getDescribe();

        for (Schema.PicklistEntry f : field.getPicklistValues()) {
            clientBrandKeys.add(f.getLabel());
        }
        System.assert(clientBrandKeys.size() > 0);

        for (String clientBrandKey : clientBrandKeys){
            System.assert(ZuoraAPI.brandKeyToCommProfileMap.containsKey(clientBrandKey),'Need to Add Brand Key to Map: ' + clientBrandKey);
        }
    }

    /*************
     *** MOCKS ***
     *************/
    public class MockAccountsSelector implements StubProvider {
        public MockAccountsSelector() {}
        // StubProvider requires the excessive parameters
        @SuppressWarnings('PMD.ExcessiveParameterList')
        public Object handleMethodCall(Object stubbedObject, String stubbedMethodName, System.Type returnType,
            List<System.Type> listOfParamTypes, List<String> listOfParamNames, List<Object> listOfArgs) {
            switch on stubbedMethodName {
                when 'selectForReconciliation' {
                    List<String> zuoraAccountIds = (List<String>) listOfArgs[0];
                    String aggregateResultJSON = '[';
                    aggregateResultJSON +=
                        '{"Id":"001S000000yKIbOIAW",' +
                            '"Zuora_Id__c":"'+zuoraAccountIds[0]+'0",' +
                            '"AccountName":"Harrison Harris 8",' +
                            '"DaysInBillingPeriod":45,' +
                            '"DistinctGateways":2,' +
                            '"GatewayName":"Chargent Gateway B"}';
                    for (Integer i = 1; i < zuoraAccountIds.size(); i++) {
                        aggregateResultJSON +=
                            ',{"Id":"001S000000yKIbOIAW",' +
                                '"Zuora_Id__c":"'+zuoraAccountIds[i]+i+'",' +
                                '"AccountName":"Harrison Harris 8",' +
                                '"DaysInBillingPeriod":30,' +
                                '"DistinctGateways":1,' +
                                '"GatewayName":"Chargent Gateway B"}';

                    }
                    aggregateResultJSON += ']';
                    List<Object> aggregateResults = (List<Object>) JSON.deserializeUntyped(aggregateResultJSON);
                    List<Map<String, Object>> results = new List<Map<String, Object>>();
                    for (Object aggregateResult : aggregateResults) {
                        results.add((Map<String, Object>) aggregateResult);
                    }
                    return results;
                }
            }
            return null;
        }
    }

    public class MockZuoraAccountReconciliationService implements StubProvider {
        public MockZuoraAccountReconciliationService() {}
        // StubProvider requires the excessive parameters
        @SuppressWarnings('PMD.ExcessiveParameterList')
        public Object handleMethodCall(Object stubbedObject, String stubbedMethodName, System.Type returnType,
            List<System.Type> listOfParamTypes, List<String> listOfParamNames, List<Object> listOfArgs) {
            switch on stubbedMethodName {
                when 'reconcileZuoraWithSFDC' {
                    Set<String> zuoraAccountIds = (Set<String>) listOfArgs[0];
                    if (zuoraAccountIds == null) {
                        // Force apex to throw an exception
                        CalloutException ce = new CalloutException();
                        throw ce;
                    } else {
                        return null;
                    }
                }
            }
            return null;
        }
    }
}