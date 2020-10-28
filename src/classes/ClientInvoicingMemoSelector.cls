@SuppressWarnings('PMD.ApexCRUDViolation,PMD.ApexDoc')
public inherited sharing class ClientInvoicingMemoSelector {
    public List<Client_Invoicing_Memo__c> selectByIds(Set<Id> cimIds) {
        return [
            SELECT Id,
                Amount__c,
                Invoice_Line_Item__c,
                Subscription_Order__c,
                Type__c,
                Subscription_Order__r.Client_Assignment_Agreement__c,
                Subscription_Order__r.Approved_Change_in_Subscription__c,
                Subscription_Order__r.Utility_Account_Subscription__r.Shared_Solar_System__c,
                Subscription_Order__r.Contract_Fee_Detail__c,
                Subscription_Order__r.Contract_Fee_Detail__r.Fee__c
            FROM Client_Invoicing_Memo__c
            WHERE Id IN :cimIds
            ORDER BY CreatedDate
        ];
    }

    public MultiMap getWaivedFeesBySSS(Set<Id> sssIds) {
        List<Client_Invoicing_Memo__c> clientInvoicingMemoSObjects = [
            SELECT Id, Type__c, Effective_Date__c,
                Subscription_Order__r.Approved_Change_in_Subscription__c,
                Subscription_Order__r.Utility_Account_Subscription__r.Shared_Solar_System__c
            FROM Client_Invoicing_Memo__c
            WHERE Subscription_Order__r.Utility_Account_Subscription__r.Shared_Solar_System__c IN : sssIds
            AND Type__c = 'Waived Acquisition / Reacquisition Fee'
        ];
        MultiMap clientInvoicingMemosBySSS = MultiMap.newListInstance();
        for (Client_Invoicing_Memo__c clientInvoicingMemo : clientInvoicingMemoSObjects) {
            ClientInvoicingMemo cim = new ClientInvoicingMemo(clientInvoicingMemo);
            clientInvoicingMemosBySSS.putValue(cim.sharedSolarSystemId, cim);
        }
        return clientInvoicingMemosBySSS;
    }

    public List<AggregateResult> getUninvoicedByClientAccounts(List<Id> clientAccounts, Datetime effectiveDatetime) {
        Date effectiveDate = Date.newInstance(effectiveDatetime.year(), effectiveDatetime.month(), effectiveDatetime.day());
        return [
            SELECT Subscription_Order__r.Utility_Account_Subscription__r.Shared_Solar_System__c Id,
                Subscription_Order__r.Utility_Account_Subscription__r.Shared_Solar_System__r.Name SSSNAME,
                Subscription_Order__r.Utility_Account_Subscription__r.Shared_Solar_System__r.Contract_Assignment_Entity__r.Name ENTITYNAME,
                Subscription_Order__r.Client_Assignment_Agreement__c ASSIGNMENTAGREEMENT,
                SUM(Amount__c) TOTAL,
                COUNT(Id) NUM
            FROM Client_Invoicing_Memo__c
            WHERE Subscription_Order__r.Utility_Account_Subscription__r.Shared_Solar_System__r.Client_Account__c IN :clientAccounts
            AND Subscription_Order__r.Utility_Account_Subscription__r.Opportunity__r.StageName = 'Complete'
            AND Effective_Date__c <= :effectiveDate
            AND Invoice_Line_Item__c = NULL
            GROUP BY Subscription_Order__r.Utility_Account_Subscription__r.Shared_Solar_System__c,
                Subscription_Order__r.Utility_Account_Subscription__r.Shared_Solar_System__r.Name,
                Subscription_Order__r.Utility_Account_Subscription__r.Shared_Solar_System__r.Contract_Assignment_Entity__r.Name,
                Subscription_Order__r.Client_Assignment_Agreement__c
        ];
    }

    public List<Client_Invoicing_Memo__c> getUninvoicedBySSS(List<Shared_Solar_System__c> sharedSolarSystems, Datetime effectiveDatetime) {
        Date effectiveDate = Date.newInstance(effectiveDatetime.year(), effectiveDatetime.month(), effectiveDatetime.day());
        return [
            SELECT Id, Amount__c, Subscription_Order__c, Subscription_Order__r.Client_Assignment_Agreement__c,
                Subscription_Order__r.Utility_Account_Subscription__r.Shared_Solar_System__c, Subscription_Order__r.Approved_Change_in_Subscription__c,
                Subscription_Order__r.Contract_Fee_Detail__r.Fee__c, Subscription_Order__r.Contract_Fee_Detail__c, Type__c
            FROM Client_Invoicing_Memo__c
            WHERE Subscription_Order__r.Utility_Account_Subscription__r.Shared_Solar_System__c IN :sharedSolarSystems
            AND Subscription_Order__r.Utility_Account_Subscription__r.Opportunity__r.StageName = 'Complete'
            AND Effective_Date__c <= :effectiveDate
            AND Invoice_Line_Item__c = NULL
        ];
    }
}