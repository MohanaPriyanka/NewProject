/*************************************************************************************
 * Description: 
 * Tested By: PCRApprovalHandlerTest
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
            SELECT Id, LASERCA__Lead__c, LASERCA__Lead__r.Personal_Credit_Report__c, Approval_Status__c,
                LASERCA__Contact__c, LASERCA__Sum_of_monthly_Personal_Debt__c, Lead_from_Contact__c,
                Maximum_Disbursement_Monthly__c
            FROM LASERCA__Personal_Credit_Report__c
            WHERE Id = :pcrIds
        ];

        List<String> leadIds = new List<String>();
        List<String> contactIds = new List<String>();
        Map<Id, Lead> leadUpdateMap = new Map<Id, Lead>();

        for (LASERCA__Personal_Credit_Report__c pcr : completedPCRs) {
            if (pcr.LASERCA__Lead__c != null) {
                leadIds.add(pcr.LASERCA__Lead__c);
            } else if (pcr.Lead_from_Contact__c != null) {
                // If the PCR is from a Contact, it's updated with the Lead only after the Credit Report Log is
                // set to complete
                leadIds.add(pcr.Lead_from_Contact__c);
            }
            if (pcr.LASERCA__Contact__c != null) {
                contactIds.add(pcr.LASERCA__Contact__c);
            }
        }

        if (leadIds.isEmpty()) {
            return;
        }
            
        Map<Id, Lead> leadMap = 
            new Map<Id, Lead>([SELECT Id, Product_line__c, Personal_Credit_Report__c
                               FROM Lead
                               WHERE Id IN :leadIds]);

        for (LASERCA__Personal_Credit_Report__c pcr : completedPCRs) {
            String contactid = pcr.LASERCA__Contact__c;
            Lead lead = leadMap.get(pcr.LASERCA__Lead__c);
            Lead leadFromContact = leadMap.get(pcr.Lead_from_Contact__c);

            if (lead != null && contactid == null &&
                lead.Product_line__c == 'Residential Loan' &&
                lead.Personal_Credit_Report__c != pcr.Id) {
                lead.Personal_Credit_Report__c = pcr.Id;
                lead.Maximum_monthly_Disbursement__c = pcr.Maximum_Disbursement_Monthly__c;
                lead.debt_income_status__c = pcr.Approval_Status__c;
                leadUpdateMap.put(lead.Id, lead);
            }

            if (lead != null && contactid == null && 
                lead.Product_line__c == 'Community Solar' &&
                lead.Personal_Credit_Report__c != pcr.Id) {

                lead.Personal_Credit_Report__c = pcr.Id;
                lead.FICO_Score_Approval__c = pcr.Approval_Status__c;
                leadUpdateMap.put(lead.Id, lead);
            }

            if (leadFromContact != null && contactid != null) {
                leadFromContact.Personal_Credit_Report_Co_Applicant__c = pcr.Id;
                leadUpdateMap.put(leadFromContact.Id, leadFromContact);
            }
        }

        if (leadUpdateMap.size()>0) {
            update leadUpdateMap.values();
        }
    }
}