@SuppressWarnings('PMD.ApexCRUDViolation')
public inherited sharing class ClientInvoicingMemoSelector {

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
}