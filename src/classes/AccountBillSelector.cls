/**
 * Created by mstackhouse on 1/16/2019.
 * Description: 
 * Test: AccountBillSelectorTest
 */


public without sharing class AccountBillSelector {
    public static List<Account_Bill__c> getAccountBillsReadyToBeSent(Set<Id> idsToGet) {
        String query = 'SELECT Id, Parent_Account__r.Name, Parent_Account__r.BillingStreet, ' +
            'Parent_Account__r.BillingCity, Parent_Account__r.BillingState, Parent_Account__r.BillingPostalCode, ' +
            'Bill_PDF_Page_Count__c, Calendar_Month__c, Year__c, Bill_Attach_Document__c ' +
            'FROM Account_Bill__c ' +
            'WHERE Published__c = TRUE ' +
            'AND Ready_For_Paper_Bill_Queue__c = TRUE ' +
            'AND Bill_Attach_Document__c != NULL ';

        if (idsToGet != null && !idsToGet.isEmpty()) {
            query += '\n AND Id IN : idsToGet ';
        }

        return Database.query(query);
    }

    public static List<AggregateResult> getAccountBillSummary(Integer billMonth, String billYear) {
        List<AggregateResult> accountBillSummary = [
            SELECT COUNT(Id) numberOfRecords,
                Ready_for_Email_Send__c, Ready_For_Paper_Bill_Queue__c, Published__c CompletedBills, Added_To_Paper_Bill_Queue__c
            FROM Account_Bill__c
            WHERE Month__c = : billMonth
            AND Year__c = : billYear
            GROUP BY Ready_for_Email_Send__c, Ready_For_Paper_Bill_Queue__c, Published__c, Added_To_Paper_Bill_Queue__c
        ];
        return accountBillSummary;
    }
}