/*************************************************************************************
 * Description: 
 * Tested By: PCRApprovalHandlerTest
 *************************************************************************************/

public with sharing class MapPCRtoLeadHandler {
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

        if (leadids.size()>0) {
            List<Lead> listleads = [SELECT id, Product_Line__c, Personal_Credit_Report__c, IsConverted
                                    FROM Lead
                                    WHERE id IN : leadids];

            for (i = 0; i < newPCR.size(); i++) {
                String leadid = newPCR.get(i).LASERCA__Lead__c;
                String contactid = newPCR.get(i).LASERCA__Contact__c;
                Decimal monthlydebt = newPCR.get(i).LASERCA__Sum_of_monthly_Personal_Debt__c;

                if (listleads.size()> 0) {
                    if (newPCR.get(i).LASERCA__Lead__c != null && (monthlydebt != NULL || monthlydebt != 0)) {
                        for (k = 0; k < listleads.size(); k++) {
                            if (listleads.get(k).id == leadid && !listleads.get(k).IsConverted && contactid == null && 
                                listleads.get(k).Product_Line__c == 'Residential Loan' && 
                                listleads.get(k).Personal_Credit_Report__c != newPCR.get(i).Id) {
                                listleads.get(k).Personal_Credit_Report__c = newPCR.get(i).Id;
                                listleads.get(k).Maximum_monthly_Disbursement__c = newPCR.get(i).Maximum_Disbursement_Monthly__c;
                                listleads.get(k).Debt_income_status__c = newPCR.get(i).Approval_Status__c;
                                leadupdatelist.add(listleads.get(k));
                            }

                            if (listleads.get(k).id == leadid && !listleads.get(k).IsConverted && contactid == null && 
                                listleads.get(k).Product_Line__c == 'Community Solar' && 
                                listleads.get(k).Personal_Credit_Report__c != newPCR.get(i).Id) {
                                listleads.get(k).Personal_Credit_Report__c = newPCR.get(i).Id;
                                listleads.get(k).FICO_score_approval__c = newPCR.get(i).Approval_Status__c;
                                leadupdatelist.add(listleads.get(k));

                            }

                            if (listleads.get(k).id == newPCR.get(i).Lead_from_Contact__c && !listleads.get(k).IsConverted && 
                                contactid != null) {
                                listleads.get(k).Personal_Credit_Report_Co_Applicant__c = newPCR.get(i).id;
                                leadupdatelist.add(listleads.get(k));
                            }
                        }
                    }
                }

                if (leadupdatelist.size()>0) {
                    update leadupdatelist;
                }
            }
        }
    }
}