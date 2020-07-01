// Tested by ProductionDetailSelectorTest
@SuppressWarnings('PMD.ApexCRUDViolation')
public inherited sharing class ProductionDetailSelector {
    public Map<Id, List<Transfer_Part__c>> getTransferPartMap(Set<Id> transferIds) {
        Map<Id, List<Transfer_Part__c>> partsMap = new Map<Id, List<Transfer_Part__c>>();
        List<Transfer_Part__c> parts = [
            SELECT Id, Transfer__c, Amount__c, Transfer__r.Transfer_Amount__c,
                Production__c, Production__r.Name, Transfer__r.Billing_Method__c,
                kWh_Amount__c, Transfer__r.Transfer_kWh__c
            FROM Transfer_Part__c
            WHERE Transfer__c IN : transferIds
            AND Type__c = 'Transfer'
        ];

        for (Transfer_Part__c part : parts){
            Id keyValue = part.Transfer__c;
            if (partsMap.containsKey(keyValue)){
                List<Transfer_Part__c> partsList = partsMap.get(keyValue);
                partsList.add(part);
            } else {
                partsMap.put(keyValue, new List<Transfer_Part__c>{part});
            }
        }
        return partsMap;
    }

    public List<Transfer_Part__c> getPartsFromTransfer(Set<Id> transferIds) {
        List<Transfer_Part__c> parts = [
            SELECT Id, Transfer__c,
                Main_Transfer_Default_Credit_Value__c,
                Transfer__r.Default_Credit_Value__c
            FROM Transfer_Part__c
            WHERE Transfer__c IN : transferIds
            AND Type__c = 'Transfer'
        ];
        return parts;
    }

    public Map<String, List<Transfer_Part__c>> getInvoicePartMap(Set<String> invoiceEntries) {
        Map<String, List<Transfer_Part__c>> partsMap = new Map<String, List<Transfer_Part__c>>();
        List<Transfer_Part__c> parts = [
            SELECT Id, Transfer__c, Amount__c, Transfer__r.Transfer_Amount__c, Transfer__r.Billing_Method__c,
                Production__c, Production__r.Name, Journal_Entry__c, Journal_Entry__r.External_Id__c
            FROM Transfer_Part__c
            WHERE Journal_Entry__r.External_Id__c IN : invoiceEntries
            AND Type__c = 'Bill'
        ];

        for (Transfer_Part__c part : parts){
            String keyValue = part.Journal_Entry__r.External_Id__c;
            if (partsMap.containsKey(keyValue)){
                List<Transfer_Part__c> partsList = partsMap.get(keyValue);
                partsList.add(part);
                partsMap.put(keyValue, partsList);
            } else {
                partsMap.put(keyValue, new List<Transfer_Part__c>{part});
            }
        }
        return partsMap;
    }

    public Map<Id,Decimal> getPaymentSum(Set<String> invoiceEntries) {
        Map<Id,Decimal> paymentSumMap = new Map<Id,Decimal>();
        List<AggregateResult> payments = [
            SELECT SUM(Amount__c) sumPayments, Bill_Part__c
            FROM Transfer_Part__c
            WHERE Bill_Part__r.Journal_Entry__r.External_Id__c IN : invoiceEntries
            AND Type__c = 'Payment'
            GROUP BY Bill_Part__c
        ];
        for (AggregateResult payment : payments){
            paymentSumMap.put((Id)payment.get('Bill_Part__c'), (Decimal)payment.get('sumPayments'));
        }
        return paymentSumMap;
    }

    public static List<Transfer_Part__c> getDetailsForDeletion(Map<Id, Transfer_Part__c> details) {
        List<Transfer_Part__c> detailList = [
            SELECT Id, Production__r.Verification_Status__c
            FROM Transfer_Part__c
            WHERE Id IN :details.keySet()
        ];
        return detailList;
    }
}