@isTest
public class AccountTriggerHandlerTestClass {
    @testSetup public static void setupTestData(){
        Partner__c partner = new Partner__c(Name = 'Bluewave Inside Sales');
        insert partner;

        BSST__c salesRep = new BSST__c(Name = 'BlueWave User', Partner__c = partner.Id, Custom_ID__c = 'test', Email__c = 'SalesRep@Sales.com');
        insert salesRep;

        Id propertyRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Property').getRecordTypeId();
        Account accountRecord = new Account(Name='Test', RecordTypeId = propertyRecordTypeId);
        insert accountRecord;

        accountRecord.Custom_ID__c = 'test';
        update accountRecord;
    }	
    @IsTest static void testCustomIdSwapAccount() {
		Account account = [SELECT Id, Sales_Representative__r.Id, Partner__r.Id FROM Account WHERE Name = 'Test'];
		Partner__c partner = [SELECT Id FROM Partner__c WHERE Name = 'BlueWave Inside Sales'];
		BSST__c salesRep = [SELECT Id FROM BSST__c WHERE Name = 'BlueWave User'];

		account.Custom_ID__c = 'test';
		update account;

        System.assertEquals(account.Sales_Representative__r.Id, salesRep.Id);
        System.assertEquals(account.Partner__r.Id, partner.Id);
    }

    @IsTest
    private static void testPreventDeletion() {
        Account accountA = new Account(
            Name = 'Test',
            Zuora_Id__c = '2c92a0ff6e3f9d59016e411e1efa6e15'
        );
        insert accountA;
        Account accountB = new Account(
            Name = 'TestB'
        );
        insert accountB;

        Boolean caughtException = false;
        try {
            Database.merge(accountB, accountA);
        } catch (DmlException de) {
            System.assert(de.getMessage().contains('Zuora'));
            caughtException = true;
        }
        System.assert(caughtException, 'Expected the merge to fail because the Zuora account is being deleted');

        caughtException = false;
        Database.MergeResult mergeResult;
        try {
            mergeResult = Database.merge(accountA, accountB);
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, e.getMessage());
            System.assert(false, 'Expected the merge to work because the Zuora account is not deleted');
        }
        System.assert(mergeResult.isSuccess());
        System.assert(!caughtException);
    }

    @IsTest
    private static void testZuoraAccountCreation() {
        Id propertyRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Property').getRecordTypeId();
        Id parentRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Parent Account').getRecordTypeId();
        List<Account> accounts = new List<Account>();
        Account propertyAccountCreateOnUpdate = new Account(
            Name = 'propertyAccountCreateOnUpdate',
            RecordTypeId = propertyRecordTypeId
        );
        accounts.add(propertyAccountCreateOnUpdate);
        Account propertyAccountOneCreateOnInsert = new Account(
            Name = 'propertyAccountOneCreateOnInsert',
            RecordTypeId = propertyRecordTypeId,
            Create_Zuora_Account__c = true
        );
        accounts.add(propertyAccountOneCreateOnInsert);
        Account propertyAccountTwoCreateOnInsert = new Account(
            Name = 'propertyAccountTwoCreateOnInsert',
            RecordTypeId = propertyRecordTypeId,
            Create_Zuora_Account__c = true
        );
        accounts.add(propertyAccountTwoCreateOnInsert);
        Account parentAccountDontCreate = new Account(
            Name = 'parentAccountDontCreate',
            RecordTypeId = parentRecordTypeId,
            Create_Zuora_Account__c = true
        );
        accounts.add(parentAccountDontCreate);

        Test.startTest();
        insert accounts;
        Test.stopTest();

        System.assertEquals(3, ZuoraAPIHelper.endpointsCalled.size(), 'Expected three callouts: Account creation, Contact creation and Account update');
        for (ZuoraAPIHelper.EndpointCall endpointCall : ZuoraAPIHelper.endpointsCalled) {
            if (endpointCall.endpoint.contains('action/create') && endpointCall.jsonBody.contains('"type":"Account"')) {
                System.assert(endpointCall.jsonBody.contains('propertyAccountOneCreateOnInsert'), 'Expected to find property account one create');
                System.assert(endpointCall.jsonBody.contains('propertyAccountTwoCreateOnInsert'), 'Expected to find property account two create');
            } else if (endpointCall.endpoint.contains('action/create')) {
                System.assert(endpointCall.jsonBody.contains('"type":"Contact"'), 'Expected a contact create callout');
            }
        }

        List<Account> accountsAfterTriggerRun = [SELECT Id FROM Account WHERE Create_Zuora_Account__c = TRUE];
        System.assertEquals(0, accountsAfterTriggerRun.size(), 'Expected no accounts to have the create flag set');
    }

    @IsTest
    private static void testZuoraAccountCreationViaUpdate() {
        List<Account> accountsCreatedInSetupTestData = [SELECT Id FROM Account WHERE Name = 'Test'];
        System.assertEquals(1, accountsCreatedInSetupTestData.size());
        accountsCreatedInSetupTestData[0].Create_Zuora_Account__c = true;

        Test.startTest();
        update accountsCreatedInSetupTestData;
        Test.stopTest();

        System.assertEquals(3, ZuoraAPIHelper.endpointsCalled.size(), 'Expected three callouts: Account creation, Contact creation and Account update');
        for (ZuoraAPIHelper.EndpointCall endpointCall : ZuoraAPIHelper.endpointsCalled) {
            if (endpointCall.endpoint.contains('action/create') && endpointCall.jsonBody.contains('"type":"Account"')) {
                System.assert(endpointCall.jsonBody.contains('Test'), 'Expected to find property account one create');
            } else if (endpointCall.endpoint.contains('action/create')) {
                System.assert(endpointCall.jsonBody.contains('"type":"Contact"'), 'Expected a contact create callout');
            }
        }

        List<Account> accountsAfterTriggerRun = [SELECT Id FROM Account WHERE Create_Zuora_Account__c = TRUE];
        System.assertEquals(0, accountsAfterTriggerRun.size(), 'Expected no accounts to have the create flag set');
    }
}