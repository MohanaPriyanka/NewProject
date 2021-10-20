/*************************************************************************************
 * Description: 
 * Tested By: CSAPControllerTest
 *************************************************************************************/

public without sharing class MapPCRtoLeadHandler {
    public static void mapPCRtoLead(
        Map<Id, LASERCA__Credit_Report_Log__c> triggerNewMap,
        Map<Id, LASERCA__Credit_Report_Log__c> triggerOldMap) {
        Set<Id> pcrIds = new Set<Id>();
        if (triggerOldMap == null) {
            for (LASERCA__Credit_Report_Log__c crl : triggerNewMap.values()) {
                if (crl.LASERCA__Status__c == 'Completed' || (crl.LASERCA__Status__c == 'Error' && crl.LASERCA__Personal_Credit_Report__c != null)) {
                    pcrIds.add(crl.LASERCA__Personal_Credit_Report__c);
                }
            }

        } else {
            for (Id oldId : triggerOldMap.keySet()) {
                if (triggerNewMap.get(oldId).LASERCA__Status__c == 'Completed' &&
                    triggerOldMap.get(oldId).LASERCA__Status__c != 'Completed') {
                    pcrIds.add(triggerNewMap.get(oldId).LASERCA__Personal_Credit_Report__c);
                }
            }
        }

        List<LASERCA__Personal_Credit_Report__c> completedPCRs = [
            SELECT Id, LASERCA__Lead__c, LASERCA__Lead__r.Personal_Credit_Report__c
            FROM LASERCA__Personal_Credit_Report__c
            WHERE Id = :pcrIds
        ];

        List<String> leadIds = new List<String>();
        Map<Id, Lead> leadUpdateMap = new Map<Id, Lead>();

        for (LASERCA__Personal_Credit_Report__c pcr : completedPCRs) {
            if (pcr.LASERCA__Lead__c != null) {
                leadIds.add(pcr.LASERCA__Lead__c);
            }
        }

        if (leadIds.isEmpty()) {
            return;
        }

        Map<Id, Lead> leadMap =
            new Map<Id, Lead>([
                SELECT Id, Personal_Credit_Report__c
                FROM Lead
                WHERE Id IN :leadIds
            ]);

        for (LASERCA__Personal_Credit_Report__c pcr : completedPCRs) {
            Lead lead = leadMap.get(pcr.LASERCA__Lead__c);

            if (lead != null &&
                lead.Personal_Credit_Report__c != pcr.Id) {
                lead.Personal_Credit_Report__c = pcr.Id;
                leadUpdateMap.put(lead.Id, lead);
            }

        }

        if (leadUpdateMap.size() > 0) {
            update leadUpdateMap.values();
        }
    }
}