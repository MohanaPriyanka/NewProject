@IsTest
public with sharing class DocuSignSelectorTest {
    @TestSetup
    public static void testSetup() {
        Account acct = new Account(
            Name = 'Account'
        );
        insert acct;

        Opportunity opp = new Opportunity(
            StageName = 'New',
            Name = 'Opp Name',
            AccountId = acct.Id,
            CloseDate = System.today().addDays(-4)
        );
        insert opp;

        dsfs__DocuSign_Status__c statusOne = new dsfs__DocuSign_Status__c(
            dsfs__Opportunity__c = opp.Id,
            dsfs__Envelope_Status__c = 'Completed'
        );
        dsfs__DocuSign_Status__c statusTwo = new dsfs__DocuSign_Status__c(
            dsfs__Opportunity__c = opp.Id,
            dsfs__Envelope_Status__c = 'Sent'
        );
        insert new List<dsfs__DocuSign_Status__c>{statusOne, statusTwo};
    }

    @IsTest
    public static void testGetDocusignStatuses() {
        Map<Id, Opportunity> oppMap = new Map<Id, Opportunity>([
            SELECT Id
            FROM Opportunity
        ]);

        DocuSignSelector selector = new DocuSignSelector();
        Map<Id, dsfs__DocuSign_Status__c> dsStatuses = selector.getDocusignStatuses(oppMap.keySet());
        List<dsfs__DocuSign_Status__c> dsList = dsStatuses.values();
        System.assertEquals(1,dsList.size());
    }
}