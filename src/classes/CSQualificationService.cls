/**
 * Created by SarahRenfro on 5/22/2019.
 *
 * Test: CSQualificationTestclass
 */

@SuppressWarnings('PMD.ApexCRUDViolation')
public without sharing class CSQualificationService {

    public static void underwriteWithFICO(
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

        Map<Id, Lead> leadMap = getLeadMap(leadIds);

        if (leadMap.isEmpty()) {
            return;
        }

        //Query for all the Shared Solar Systems
        List<Shared_Solar_System__c> sharedSolarSystems = getSharedSolarSystems();

        List<Lead> updateLeads = new List<Lead>();
        List<LASERCA__Personal_Credit_Report__c> updatePCRs = new List<LASERCA__Personal_Credit_Report__c>();
        for (LASERCA__Personal_Credit_Report__c pcr : completedPCRs) {
            Lead lead = leadMap.get(pcr.LASERCA__Lead__c);
            Decimal creditScore = 0;

            //Handle No Match Leads and set credit score to 9999
            if (pcr.LASERCA__Credit_Score__c != null) {
                creditScore = Decimal.valueOf(pcr.LASERCA__Credit_Score__c);
                closeReportMissingCases(lead);
            } else {
                pcr.LASERCA__Credit_Score_TransUnion__c = '9999';
                pcr.LASERCA__Credit_Score__c = '9999';
                creditScore = 9999;
                updatePCRs.add(pcr);
                CaseFactory noMatchFactory  = new CaseFactory();
                noMatchFactory.setLead(lead);
                System.enqueueJob(noMatchFactory);
            }


            //Check if lead is qualified
            lead.Status = checkCSQualification(lead, sharedSolarSystems, creditScore);
            updateLeads.add(lead);

        }

        update updatePCRs;
        update updateLeads;
    }

    public String underwriteWithFinancialReview(Lead lead) {
        if (lead == null) {
            return null;
        }

        Set<Id> financialUnderwritingIds = new Set<Id>();
        if (lead.Underwrite_Financial_Documents__r != null) {
            for (Financial_Underwriting_Document__c fud : lead.Underwrite_Financial_Documents__r) {
                financialUnderwritingIds.add(fud.Id);
            }
        }

        List<ContentDocumentLink> contentDocLinks = new List<ContentDocumentLink>();
        if (!financialUnderwritingIds.isEmpty()) {
            contentDocLinks = [SELECT Id, LinkedEntityId FROM ContentDocumentLink WHERE LinkedEntityId = :financialUnderwritingIds];
        }
        List<Shared_Solar_System__c> sharedSolarSystems = getSharedSolarSystems();

        String result = 'Unqualified';
        if (!contentDocLinks.isEmpty()) {
            result = CSQualificationService.checkCSQualification(lead, sharedSolarSystems, null);
        }
        return result;
    }

    private static String checkCSQualification(Lead lead, List<Shared_Solar_System__c> sharedSolarSystems, Decimal creditScore) {
        for (Shared_Solar_System__c sss : sharedSolarSystems) {
            if (sss.Utility__c == lead.Utility_relationship__c &&
                (sss.Service_Territories__c != null && sss.Service_Territories__c.contains(lead.LoadZone__c)) &&
                ((sss.Sales_Partners__c != null &&
                    (sss.Sales_Partners__c.contains('All') || sss.Sales_Partners__c.contains(lead.Partner_Lookup__r.Name))) ||
                    sss.Public__c == true) &&
                sss.Product__c == lead.Product__c &&
                (creditScore == null || creditScore > sss.Credit_Score_Requirement__c)
                ) {
                return 'Qualified';
            }
        }

        return 'Unqualified';
    }

    private static Map<Id, Lead> getLeadMap(List<Id> leadIds) {
        return new Map<Id, Lead>(
        [
            SELECT Id, Utility_relationship__r.Id, Utility_relationship__r.Name, Utility_relationship__c, LoadZone__c, Partner_Name__c, Status,
                Company, Product_line__c, Electricity_Provider__c, LASERCA__Home_Address__c, LASERCA__Home_City__c,
                LASERCA__Home_State__c, LASERCA__Home_Zip__c, OwnerId, Product__c, Partner_Lookup__r.Name
            FROM Lead
            WHERE Id IN :leadIds
            AND Product_line__c = 'Community Solar'
        ]);
    }

    private static List<Shared_Solar_System__c> getSharedSolarSystems() {
        return [
            SELECT Id, Credit_Score_Requirement__c, Product__r.Id, Product__c, Public__c, Utility__c, Service_Territories__c,
                Sales_Partners__c
            FROM Shared_Solar_System__c
            WHERE Open__c = true
            AND Capacity_Available_to_be_Reserved__c > 0
            ORDER BY Credit_Score_Requirement__c ASC
        ];
    }


    public virtual class QualificationMatch {
        @AuraEnabled
        public Shared_Solar_System__c sss;
        @AuraEnabled
        public Boolean completeMatch = false;
        @AuraEnabled
        public Boolean isOpen = false;
        @AuraEnabled
        public Boolean hasCapacity = false;
        @AuraEnabled
        public Boolean hasLZ = false;
        @AuraEnabled
        public Boolean hasPartner = false;
        @AuraEnabled
        public Boolean minFICO = false;
    }

    public class QualificationInput {
        public List<QualificationMatch> qualificationMatches = new List<QualificationMatch>();
        private List<Id> utilityIds = new List<Id>();
        private String loadZone;
        private Id productId;
        private String partner;
        private Integer fico;
        private Partner__c partnerSobj;

        public QualificationInput(String product, String partner, String zipCode, String fico, String utility) {
            this.productId = (Id) product;

            partnerSobj = PartnerSelector.selectPartnerByPartnerId(partner);
            this.partner = partnerSobj.Name;

            if (fico != null) {
                this.fico = Integer.valueOf(fico);
            }

            List<ZipCode_Utility_Junction__c> zipCodeUtilityJunctions = ZipcodeUtilitiesSelector.selectZipcodeUtilitiesAndLoadzones(zipCode);
            this.loadZone = zipCodeUtilityJunctions[0].Load_Zone_Utility__r.LZ__c;

            if (utility == null) {
                for (ZipCode_Utility_Junction__c junction : zipCodeUtilityJunctions) {
                    this.utilityIds.add(junction.Utility__c);
                }
            } else {
                this.utilityIds.add(utility);
            }
        }

        public void createQualificationList() {
            SharedSolarSystemsSelector sssSelector = new SharedSolarSystemsSelector();
            List<Shared_Solar_System__c> sssList = sssSelector.selectSharedSolarSystemsForQualificationCheck(this.productId, this.utilityIds);

            for (Shared_Solar_System__c sss : sssList) {
                QualificationMatch matchResult = new QualificationMatch();
                matchResult.sss = sss;
                if (sss.Open__c) {
                    matchResult.isOpen = true;
                }
                if (sss.Capacity_Available_to_be_Reserved__c > 0) {
                    matchResult.hasCapacity = true;

                }
                if (sss.Service_Territories__c != null && sss.Service_Territories__c.contains(this.loadZone)) {
                    matchResult.hasLZ = true;
                }
                if (sss.Sales_Partners__c != null && (sss.Sales_Partners__c.contains('All') || sss.Sales_Partners__c.contains(this.partner))) {
                    matchResult.hasPartner = true;
                }
                if (this.fico == null || this.fico >= sss.Credit_Score_Requirement__c) {
                    matchResult.minFICO = true;
                }
                if (matchResult.isOpen &&
                    matchResult.hasCapacity &&
                    matchResult.hasLZ &&
                    matchResult.hasPartner &&
                    matchResult.minFICO
                    ) {
                    matchResult.completeMatch = true;
                }

                this.qualificationMatches.add(matchResult);
            }
        }
    }

    @SuppressWarnings('PMD.ExcessiveParameterList')
    @AuraEnabled
    public static List<QualificationMatch> getQualificationMatches(String product, String partner, String zipCode,
        String fico, String utility) {
        QualificationInput input = new QualificationInput(product, partner, zipCode, fico, utility);
        input.createQualificationList();
        return input.qualificationMatches;
    }

    public static void closeReportMissingCases(Lead lead) {
        List<Case> cases = new CaseSelector().selectOpenNoMatchCasesFromLead(lead);
        if (cases.size() > 0) {
            for (Case c : cases) {
                c.Status = 'Closed';
            }
            update cases;
        }
    }
}