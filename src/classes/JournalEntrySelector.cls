// Tested By: JournalEntrySelectorTest, PartnerCommissionServiceTest, ZuoraGLServiceTest

@SuppressWarnings('PMD.ApexCRUDViolation')
public inherited sharing class JournalEntrySelector {
    public List<Journal_Entry__c> getSFJournalEntries(Date startDate, Date endDate, String queryType){
        List<Journal_Entry__c> journalEntries = [
            SELECT Id, External_Id__c, Date__c, Amount__c, Project__c, Client__c, Customer_Account__c,
                Paid_To_Client__c, Deposit_Account__c
            FROM Journal_Entry__c
            WHERE Date__c > : startDate
            AND Date__c < : endDate
            AND Query_Type__c = : queryType
        ];
        return journalEntries;
    }

    public List<AggregateResult> getCommissionEntriesByAccount(Set<String> accountNumber){
        List<AggregateResult> entries = [
            SELECT Customer_Account__c,
                Object_Type__c,
                Project__c
            FROM Journal_Entry__c
            WHERE Customer_Account__c IN : accountNumber
            AND (Object_Type__c = 'InvoiceItem' OR Object_Type__c = 'PaymentPart')
            GROUP BY Customer_Account__c, Object_Type__c, Project__c
        ];
        return entries;
    }

    public List<Journal_Entry__c> getSFJournalEntriesFromExternalId(Set<String> externalIds){
        List<Journal_Entry__c> journalEntries = [
            SELECT Id, External_Id__c, Date__c, Amount__c, Project__c, Client__c, Customer_Account__c,
                Paid_To_Client__c, Deposit_Account__c, Object_Type__c, Query_Type__c
            FROM Journal_Entry__c
            WHERE External_Id__c IN : externalIds
        ];
        return journalEntries;
    }
}