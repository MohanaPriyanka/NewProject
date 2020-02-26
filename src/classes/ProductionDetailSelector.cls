// Tested by ProductionDetailSelectorTest

public without sharing class ProductionDetailSelector {
    public Map<Id, List<Transfer_Part__c>> getTransferPartMap(Set<Id> transferIds) {
        Map<Id, List<Transfer_Part__c>> partsMap = new Map<Id, List<Transfer_Part__c>>();
        List<Transfer_Part__c> parts = [
            SELECT Id, Transfer__c, Amount__c, Transfer__r.Transfer_Amount__c, Production__c, Production__r.Name
            FROM Transfer_Part__c
            WHERE Transfer__c IN : transferIds
            AND Type__c = 'Transfer'
        ];

        for (Transfer_Part__c part : parts){
            Id keyValue = part.Transfer__c;
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
}