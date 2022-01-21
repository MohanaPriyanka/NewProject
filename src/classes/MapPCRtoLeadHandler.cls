/*************************************************************************************
 * @description: Sets the Personal Credit Report lookup on Lead when a credit pull finishes
 * Tested By: LeadServiceTestclass, ZuoraAccountServiceTest, CSQualificationTestclass
 *************************************************************************************/
@SuppressWarnings('PMD.ApexCRUDViolation')
public without sharing class MapPCRtoLeadHandler {
    @TestVisible private static Boolean throwException = false;
    private static CreditReportSelector creditReportSelector = new CreditReportSelector();

    public static void mapPCRtoLeadAfterInsert(List<LASERCA__Credit_Report_Log__c> triggerNew) {
        Set<Id> pcrIds = new Set<Id>();
        for (LASERCA__Credit_Report_Log__c crl : triggerNew) {
            if (crl.LASERCA__Status__c == 'Completed' || (crl.LASERCA__Status__c == 'Error' && crl.LASERCA__Personal_Credit_Report__c != null)) {
                pcrIds.add(crl.LASERCA__Personal_Credit_Report__c);
            }
        }
        updateLeadsWithPCR(pcrIds);
    }

    public static void mapPCRtoLeadAfterUpdate(Map<Id, LASERCA__Credit_Report_Log__c> triggerNewMap,
        Map<Id, LASERCA__Credit_Report_Log__c> triggerOldMap) {
        Set<Id> pcrIds = new Set<Id>();
        for (Id oldId : triggerOldMap.keySet()) {
            if (triggerNewMap.get(oldId).LASERCA__Status__c == 'Completed' &&
                triggerOldMap.get(oldId).LASERCA__Status__c != 'Completed') {
                pcrIds.add(triggerNewMap.get(oldId).LASERCA__Personal_Credit_Report__c);
            }
        }
        updateLeadsWithPCR(pcrIds);
    }

    private static void updateLeadsWithPCR(Set<Id> pcrIds) {
        if (throwException) {
            throw new Util.BWException('Throwing exception to test error handling in CreditReportLogTrigger');
        }

        List<LASERCA__Personal_Credit_Report__c> completedPCRs = creditReportSelector.getCompletedPCRs(pcrIds);

        List<Lead> leadsToUpdateWithPCR = new List<Lead>();
        for (LASERCA__Personal_Credit_Report__c pcr : completedPCRs) {
            if (pcr.LASERCA__Lead__c != null && pcr.LASERCA__Lead__r.Personal_Credit_Report__c != pcr.Id) {
                Lead lead = new Lead(
                    Id = pcr.LASERCA__Lead__c,
                    Personal_Credit_Report__c = pcr.Id
                );
                leadsToUpdateWithPCR.add(lead);
            }
        }

        update leadsToUpdateWithPCR;
    }
}