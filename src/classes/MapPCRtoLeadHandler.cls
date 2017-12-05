/*************************************************************************************
 * Description: 
 * Tested By: PCRApprovalHandlerTest
 *************************************************************************************/

public without sharing class MapPCRtoLeadHandler {
    private boolean m_isExecuting = false;
    private Integer BatchSize = 0;

    public MapPCRtoLeadHandler (boolean isExecuting, Integer size) {
        m_isExecuting = isExecuting;
        BatchSize = size;
    }

    public void OnBeforeUpdate (List<LASERCA__Personal_Credit_Report__c> newPCR) {
        MapPCRtoLead(newPCR);
    }

    private void MapPCRtoLead (List<LASERCA__Personal_Credit_Report__c> newPCR) {
        Integer j;
        Integer k;
        Integer i;
        Integer h;
        Integer l;
        List<String> leadids = new List<String>();
        List<String> contactids = new List<String>();
        List<Lead> leadupdatelist = new List<Lead>();

        for (j = 0; j < newPCR.size(); j++) {
            Decimal monthlydebt = newPCR.get(j).LASERCA__Sum_of_monthly_Personal_Debt__c;

            if (newPCR.get(j).LASERCA__Lead__c != null && (monthlydebt != NULL || monthlydebt != 0)) {
                leadids.add(newPCR.get(j).LASERCA__Lead__c);
            }

            if (newPCR.get(j).LASERCA__Contact__c != null && (monthlydebt != NULL || monthlydebt != 0)) {
                contactids.add(newPCR.get(j).LASERCA__Contact__c);
            }
        }

        if (leadids.isEmpty()) {
            return;
        }
            
        Map<Id, Lead> leadMap = 
            new Map<Id, Lead>([SELECT id, Product_Line__c, Personal_Credit_Report__c
                               FROM Lead
                               WHERE id IN : leadids
                               AND IsConverted = false]);

        for (LASERCA__Personal_Credit_Report__c pcr : newPCR) {
            String contactid = pcr.LASERCA__Contact__c;
            Decimal monthlydebt = pcr.LASERCA__Sum_of_monthly_Personal_Debt__c;
            Lead lead = leadMap.get(pcr.LASERCA__Lead__c);
            Lead leadFromContact = leadMap.get(pcr.Lead_from_Contact__c);

            if (monthlydebt == NULL || monthlydebt == 0) {
                continue;
            }

            if (lead != null && contactid == null && 
                lead.Product_Line__c == 'Residential Loan' && 
                lead.Personal_Credit_Report__c != pcr.Id) {
                lead.Personal_Credit_Report__c = pcr.Id;
                lead.Maximum_monthly_Disbursement__c = pcr.Maximum_Disbursement_Monthly__c;
                lead.Debt_income_status__c = pcr.Approval_Status__c;
                leadupdatelist.add(lead);
            }

            if (lead != null && contactid == null && 
                lead.Product_Line__c == 'Community Solar' && 
                lead.Personal_Credit_Report__c != pcr.Id) {

                lead.Personal_Credit_Report__c = pcr.Id;
                lead.FICO_score_approval__c = pcr.Approval_Status__c;
                leadupdatelist.add(lead);

            }

            if (leadFromContact != null && contactid != null) {
                leadFromContact.Personal_Credit_Report_Co_Applicant__c = pcr.id;
                leadupdatelist.add(leadFromContact);
            }
        }

        if (leadupdatelist.size()>0) {
            update leadupdatelist;
        }
    }
}