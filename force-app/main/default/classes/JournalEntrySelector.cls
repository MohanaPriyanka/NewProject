// Tested By: JournalEntrySelectorTest, PartnerCommissionServiceTest, ZuoraGLServiceTest

@SuppressWarnings('PMD.ApexCRUDViolation')
public inherited sharing class JournalEntrySelector {
    public List<Journal_Entry__c> getSFJournalEntries(Date startDate, Date endDate, String queryType) {
        List<Journal_Entry__c> journalEntries = [
            SELECT Id, External_Id__c, Date__c, Amount__c, Project__c, Client__c, Customer_Account__c,
                Paid_To_Client__c, Deposit_Account__c
            FROM Journal_Entry__c
            WHERE Date__c >= :startDate
            AND Date__c < :endDate
            AND Query_Type__c = :queryType
        ];
        return journalEntries;
    }

    public List<AggregateResultProxy> getCommissionEntriesByAccount(Set<String> accountNumber) {
        List<AggregateResultProxy> groupedResultProxies = new List<AggregateResultProxy>();
        for (AggregateResult result : [
            SELECT Customer_Account__c,Object_Type__c,Project__c
            FROM Journal_Entry__c
            WHERE Customer_Account__c IN :accountNumber
            AND (Object_Type__c = 'InvoiceItem' OR Object_Type__c = 'PaymentPart')
            AND Amount__c != 0
            GROUP BY Customer_Account__c, Object_Type__c, Project__c
        ]) {
            groupedResultProxies.add(new AggregateResultProxy().withAggregateResult(result));
        }
        return groupedResultProxies;
    }

    public List<Journal_Entry__c> getSFJournalEntriesFromExternalId(Set<String> externalIds) {
        List<Journal_Entry__c> journalEntries = [
            SELECT Id, External_Id__c, Date__c, Amount__c, Project__c, Client__c, Customer_Account__c,
                Paid_To_Client__c, Deposit_Account__c, Object_Type__c, Query_Type__c, Applied_Record_Id__c
            FROM Journal_Entry__c
            WHERE External_Id__c IN :externalIds
        ];
        return journalEntries;
    }

    public List<Journal_Entry__c> getEntriesWithoutProductionDetail(List<String> objectTypes, Integer batchSize) {
        List<Journal_Entry__c> journalEntries = [
            SELECT Id, Name, External_Id__c, Date__c, Amount__c, Project__c, Client__c, Customer_Account__c, Paid_To_Client__c,
                Deposit_Account__c, Applied_Record_Id__c, Reason_Code__c, Object_Type__c, Returned_PaymentPart_Id__c,
                CreatedDate, (SELECT Id FROM Transfer_Parts__r)
            FROM Journal_Entry__c
            WHERE Object_Type__c IN :objectTypes
            AND Ready_for_Production_Detail__c = TRUE
            ORDER BY Date__c, Name
            LIMIT :batchSize
        ];
        return journalEntries;
    }

    public Map<String, Journal_Entry__c> getEntriesMapByIds(Set<String> externalIds) {
        Map<String, Journal_Entry__c> entryMap = new Map<String, Journal_Entry__c>();
        for (Journal_Entry__c entry : [SELECT Id, Applied_Record_Id__c, External_Id__c FROM Journal_Entry__c WHERE External_Id__c IN :externalIds]) {
            entryMap.put(entry.External_Id__c, entry);
        }
        return entryMap;
    }

    public List<Journal_Entry__c> getCommissionableEntriesFromToday() {
        return [
            SELECT Customer_Lookup__c, Project__c, Date__c, Object_Type__c, Customer_Account__c
            FROM Journal_Entry__c
            WHERE CreatedDate = TODAY
            AND (Object_Type__c = 'InvoiceItem' OR Object_Type__c = 'PaymentPart')
            AND Amount__c != 0
            ORDER BY Date__c ASC
        ];
    }

    public List<AggregateResultProxy> selectForReconciliation(List<Journal_Entry__c> journalEntriesToReconcile) {
        List<AggregateResultProxy> groupedResultProxies = new List<AggregateResultProxy>();
        for (AggregateResult result : [
            SELECT Journal_Entry__c, Journal_Entry__r.Reason_Code__c, Journal_Entry__r.Object_Type__c, SUM(Amount__c) AMOUNT
            FROM Transfer_Part__c
            WHERE Journal_Entry__c IN :journalEntriesToReconcile
            GROUP BY Journal_Entry__c, Journal_Entry__r.Reason_Code__c, Journal_Entry__r.Object_Type__c
        ]) {
            groupedResultProxies.add(new AggregateResultProxy().withAggregateResult(result));
        }
        return groupedResultProxies;
    }
}