/**
 * Created by SarahRenfro on 5/22/2019.
 *
 * Test: CSQualificationTestclass
 */

public without sharing class CSQualificationService {


    public static void checkCSQualification(
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
                Maximum_Disbursement_Monthly__c, LASERCA__Credit_Score__c, LASERCA__Credit_Score_TransUnion__c
            FROM LASERCA__Personal_Credit_Report__c
            WHERE Id = :pcrIds
        ];

        List<String> leadIds = new List<String>();

        for (LASERCA__Personal_Credit_Report__c pcr : completedPCRs) {
            if (pcr.LASERCA__Lead__c != null) {
                leadIds.add(pcr.LASERCA__Lead__c);
            }
        }

        if (leadIds.isEmpty()) {
            return;
        }


        Map<Id, Lead> leadMap =
            new Map<Id, Lead>([SELECT Id, Utility_relationship__r.Id, Utility_relationship__r.Name, Utility_relationship__c, LoadZone__c, Partner_Name__c, Status,
                Company, Product_line__c, Electricity_Provider__c, LASERCA__Home_Address__c, LASERCA__Home_City__c,
                LASERCA__Home_State__c, LASERCA__Home_Zip__c, OwnerId, Product__c, Partner_Lookup__r.Name
            FROM Lead
            WHERE Id IN :leadIds
            AND Product_line__c = 'Community Solar']);

        if (leadMap.isEmpty()){
            return;
        }

        //Query for all the Shared Solar Systems
        List<Shared_Solar_System__c> sharedSolarSystems = [
            SELECT Id, Credit_Score_Requirement__c, Product__r.Id, Product__c, Public__c, Utility__c, Service_Territories__c,
                Sales_Partners__c
            FROM Shared_Solar_System__c
            WHERE Open__c = true
            AND Capacity_Available_to_be_Reserved__c > 0
            ORDER BY Credit_Score_Requirement__c ASC
        ];

        List<Lead> updateLeads = new List<Lead>();
        List<LASERCA__Personal_Credit_Report__c> updatePCRs = new List<LASERCA__Personal_Credit_Report__c>();

        for (LASERCA__Personal_Credit_Report__c pcr : completedPCRs) {
            Lead lead = leadMap.get(pcr.LASERCA__Lead__c);

            String result = 'Unqualified';
            Decimal creditScore = 0;

            //Handle No Match Leads and set credit score to 9999
            if (pcr.LASERCA__Credit_Score__c != null){
                creditScore = Decimal.valueOf(pcr.LASERCA__Credit_Score__c);
            } else {
                pcr.LASERCA__Credit_Score_TransUnion__c = '9999';
                pcr.LASERCA__Credit_Score__c = '9999';
                creditScore = 9999;
                updatePCRs.add(pcr);
            }

            //Check if lead is qualified
            for (Shared_Solar_System__c sss : sharedSolarSystems) {
                if (sss.Utility__c == lead.Utility_relationship__c &&
                    (sss.Service_Territories__c != null && sss.Service_Territories__c.contains(lead.LoadZone__c)) &&
                    ((sss.Sales_Partners__c != null &&
                        (sss.Sales_Partners__c.contains('All') || sss.Sales_Partners__c.contains(lead.Partner_Lookup__r.Name))) ||
                        sss.Public__c == true) &&
                    sss.Product__c == lead.Product__c &&
                    creditScore > sss.Credit_Score_Requirement__c
                    ) {
                    result = 'Qualified';
                    break;
                }
            }

            lead.Status = result;
            updateLeads.add(lead);

        }

        update updatePCRs;
        update updateLeads;


    }
}