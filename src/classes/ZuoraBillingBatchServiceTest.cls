@IsTest
public with sharing class ZuoraBillingBatchServiceTest {
    private static ZuoraBillingBatchService billBatchService = new ZuoraBillingBatchService();

    private static void useMocks() {
        billBatchService.accountsSelector = (AccountsSelector) Test.createStub(AccountsSelector.class, new MockAccountsSelector());
        billBatchService.zuoraAcctSelector = (ZuoraAccountSelector) Test.createStub(ZuoraAccountSelector.class, new MockZuoraAccountSelector());
    }

    @IsTest
    public static void testBatchUpdate() {
        useMocks();
        ZuoraAPI.ActionItems actionItem = billBatchService.updateAccountBatches(Date.Today());
        System.assertEquals(3,actionItem.objects.size());
        for (Object obj : actionItem.objects){
            ZuoraAPI.ZuoraAccount account = (ZuoraAPI.ZuoraAccount) obj;
            if (account.Id == 'xxxxxxxxxx123'){
                System.assertEquals('Batch2',account.Batch);
            } else if (account.Id == 'xxxxxxxxxx789'){
                System.assertEquals('Batch2',account.Batch);
            } else if (account.Id == 'xxxxxxxxxx101'){
                System.assertEquals('Batch3',account.Batch);
            } else {
                // Expect to see one of the IDs above
                System.assert(false);
            }
        }
    }

    /*************
    *** MOCKS ***
    *************/
    public class MockAccountsSelector implements StubProvider {
        public MockAccountsSelector() {
        }
        // StubProvider requires the excessive parameters
        @SuppressWarnings('PMD.ExcessiveParameterList')
        public Object handleMethodCall(Object stubbedObject, String stubbedMethodName, System.Type returnType,
            List<System.Type> listOfParamTypes, List<String> listOfParamNames, List<Object> listOfArgs) {
            switch on stubbedMethodName {
                when 'selectAccountsWithUASBs' {
                    Map<Id, Integer> accountIdsWithUASBs = new Map<Id, Integer>();
                    accountIdsWithUASBs.put('001j0000013wv8i', 3);
                    accountIdsWithUASBs.put('001j0000013wv8j', 1);
                    accountIdsWithUASBs.put('001j0000013wv8k', 2);
                    return accountIdsWithUASBs;
                }
            }
            return null;
        }
    }

    public class MockZuoraAccountSelector implements StubProvider {
        public MockZuoraAccountSelector() {}
        @SuppressWarnings('PMD.ExcessiveParameterList')
        public Object handleMethodCall(Object stubbedObject, String stubbedMethodName, System.Type returnType,
            List<System.Type> listOfParamTypes, List<String> listOfParamNames, List<Object> listOfArgs) {
            switch on stubbedMethodName {
                when 'getAllBillingAccounts' {
                    List<Zuora__CustomerAccount__c> zuoraBillingAccounts = new List<Zuora__CustomerAccount__c>();
                    Zuora__CustomerAccount__c acctOne = new Zuora__CustomerAccount__c(
                        Id = Util.getFakeId(Zuora__CustomerAccount__c.SObjectType),
                        Zuora__Account__c = '001j0000013wv8iAAA',
                        Zuora__Zuora_Id__c = 'xxxxxxxxxx123',
                        Zuora__Batch__c = 'Batch1'
                    );
                    Zuora__CustomerAccount__c acctTwo = new Zuora__CustomerAccount__c(
                        Id = Util.getFakeId(Zuora__CustomerAccount__c.SObjectType),
                        Zuora__Account__c = '001j0000013wv8jAAA',
                        Zuora__Zuora_Id__c = 'xxxxxxxxxx456',
                        Zuora__Batch__c = 'Batch2'
                    );
                    Zuora__CustomerAccount__c acctThree = new Zuora__CustomerAccount__c(
                        Id = Util.getFakeId(Zuora__CustomerAccount__c.SObjectType),
                        Zuora__Account__c = '001j0000013wv8kAAA',
                        Zuora__Zuora_Id__c = 'xxxxxxxxxx789',
                        Zuora__Batch__c = 'Batch3'
                    );
                    Zuora__CustomerAccount__c acctFour = new Zuora__CustomerAccount__c(
                        Id = Util.getFakeId(Zuora__CustomerAccount__c.SObjectType),
                        Zuora__Account__c = '001j0000013wv8lAAA',
                        Zuora__Zuora_Id__c = 'xxxxxxxxxx101',
                        Zuora__Batch__c = 'Batch2'
                    );
                    zuoraBillingAccounts.add(acctOne);
                    zuoraBillingAccounts.add(acctTwo);
                    zuoraBillingAccounts.add(acctThree);
                    zuoraBillingAccounts.add(acctFour);
                    return zuoraBillingAccounts;
                }
            }
            return null;
        }
    }
}