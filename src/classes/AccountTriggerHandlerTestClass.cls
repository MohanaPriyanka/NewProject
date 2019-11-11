@isTest
public class AccountTriggerHandlerTestClass {
    @testSetup public static void setupTestData(){
        List<String> partnerSetupList = new List<String>();
        Partner__c partner = new Partner__c(Name = 'Bluewave Inside Sales');
        insert partner;

        BSST__c salesRep = new BSST__c(Name = 'BlueWave User', Partner__c = partner.Id, Custom_ID__c = 'test', Email__c = 'SalesRep@Sales.com');
        insert salesRep;

        Account accountRecord = new Account(Name='Test');
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
}