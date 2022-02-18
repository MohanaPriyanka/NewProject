// Tested By: AllocationScheduleSelectorTest

public inherited sharing class AllocationScheduleSelector {
    @SuppressWarnings('PMD.ApexCRUDViolation')
    public Schedule_Z__c selectOne(Id alsId) {
        List<Schedule_Z__c> alsList = this.selectAll(new Set<Id>{alsId});
        if (alsList.isEmpty()) {
            return null;
        }
        return alsList[0];
    }

    @SuppressWarnings('PMD.ApexCRUDViolation')
    public List<Schedule_Z__c> selectAll(Set<Id> alsIds) {
        return [
            SELECT Id, Status__c, Date_Enacted_by_Utility__c, Date_Schedule_Z_Retired_by_Utility__c
            FROM Schedule_Z__c
            WHERE Id IN :alsIds
        ];
    }

    @SuppressWarnings('PMD.ApexCRUDViolation')
    public Map<Id,List<Schedule_Z__c>> getEnactedAndBillingALSFromSSS(Set<Id> sssIds) {
        Map<Id,List<Schedule_Z__c>> sssMap = new Map<Id,List<Schedule_Z__c>>();
        List<Schedule_Z__c> szList = [
            SELECT Id, Status__c, Shared_Solar_System__c, Date_Enacted_by_Utility__c
            FROM Schedule_Z__c
            WHERE Shared_Solar_System__c IN : sssIds
            AND (Status__c = 'Enacted By Utility'
            OR Status__c = 'Billing')
            AND Date_Enacted_by_Utility__c != null
            ORDER BY Date_Enacted_by_Utility__c DESC
        ];

        for (Schedule_Z__c sz : szList) {
            Id sssKey = sz.Shared_Solar_System__c;
            if (sssMap.containsKey(sssKey)){
                List<Schedule_Z__c> sssSZList = sssMap.get(sssKey);
                sssSZList.add(sz);
                sssMap.put(sssKey, sssSZList);
            } else {
                sssMap.put(sssKey, new List<Schedule_Z__c>{sz});
            }
        }
        return sssMap;
    }
}