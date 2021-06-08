@IsTest
public class LeadTriggerHandlerTest {

    @SuppressWarnings('PMD.AvoidDmlStatementsInLoops')
  

    @IsTest static void testLeadUpdateAfterConversion() {
        LoanTestRecordWarehouse.partnerSetup();
        List<Lead> leads = new List<Lead>();
        leads.add(new Lead(
            FirstName = 'Test',
            LastName = 'Testcase',
            Company = 'Testtest',
            Loan_Amount__c = 30000,
            Requested_Loan_Amount__c = 30000,
            Email = 'test@test.com',
            Product_Line__c = 'Residential Loan',
            LASERCA__Home_State__c = 'MA'
        ));
        leads.add(new Lead(
            FirstName = 'Tester',
            LastName = 'Testcase',
            Company = 'Testtest',
            Loan_Amount__c = 30000,
            Requested_Loan_Amount__c = 30000,
            Email = 'tester@test.com',
            Product_Line__c = 'Residential Loan',
            LASERCA__Home_State__c = 'MA'
        ));
        insert leads;
        List<Database.LeadConvert> leadConverts = new List<Database.LeadConvert>();
        for (Lead l :leads){
            Database.LeadConvert lc = new Database.LeadConvert();
            lc.setLeadId(l.Id);
            lc.setConvertedStatus('Interested');
            leadConverts.add(lc);
        }
        List<Database.LeadConvertResult> lcrs = Database.convertLead(leadConverts, false);
        Set<Id> oppIds = new Set<Id>();
        for (Database.LeadConvertResult lcr : lcrs)  {
            System.assert(lcr.isSuccess(), 'Lead should have converted successfully');
            oppIds.add(lcr.getOpportunityId());
        }

        Account coApplicantAccount = new Account( Name = 'CoapplicantAccount');
        insert coApplicantAccount;

        Contact coApplicantContact = new Contact(
            FirstName = 'Cole',
            LastName = 'Swain',
            AccountId = coApplicantAccount.Id,
            Lead__c = leads[0].Id,
            Income__c = 2000,
            LASERCA__Social_Security_Number__c = '000000002');
        insert coApplicantContact;
        leads[0].Co_Applicant_First_Name__c = coApplicantContact.FirstName;
        leads[0].Co_Applicant_Last_Name__c = coApplicantContact.LastName;
        leads[0].Co_Applicant_Income__c = coApplicantContact.Income__c;
        leads[0].LASERCA__Co_Applicant_Social_Security_Number__c = coApplicantContact.LASERCA__Social_Security_Number__c;

        leads[1].System_Cost__c = 32000;
        update leads;
        Map<Id, Lead> leadMap = new Map<Id, Lead>(leads);

        List<Opportunity> opps = [
            SELECT Id, Personal_Credit_Report2__c, Loan_Principle__c,
                Co_Applicant_First_Name__c, Co_Applicant_Last_Name__c, Co_Applicant_Income__c,
                Co_Applicant_Social_Security__c, Lead__c
            FROM Opportunity
            WHERE Id = :oppIds];
        for (Opportunity opp : opps) {
            System.assertEquals(leadMap.get(opp.Lead__c).Personal_Credit_Report__c, opp.Personal_Credit_Report2__c, 'Opp should have Personal Credit Report from converted Lead');
            System.assertEquals(leadMap.get(opp.Lead__c).System_Cost__c, opp.Loan_Principle__c, 'Opp should have same loan principle as converted Lead\'s system cost');
            System.assertEquals(leadMap.get(opp.Lead__c).Co_Applicant_First_Name__c, opp.Co_Applicant_First_Name__c, 'Opp should have same Co_Applicant_First_Name__c as converted Lead');
            System.assertEquals(leadMap.get(opp.Lead__c).Co_Applicant_Last_Name__c, opp.Co_Applicant_Last_Name__c, 'Opp should have Co_Applicant_Last_Name__c as converted Lead');
        }
    }

   

    @SuppressWarnings('PMD.AvoidDmlStatementsInLoops')
    public static Shared_Solar_System__c getSharedSolarSystem(Utility_NMC_Tariff__c nmcRate, Product2 csProduct,
        Utility__c utility, String name) {
        Shared_Solar_System__c sss1 = new Shared_Solar_System__c(
            Name = name,
            Service_Territories__c = 'WCMA; SEMA',
            Open__c = true,
            Reserved_Capacity_kW_DC__c = '0',
            Capacity_Committed_kW_DC__c = 0,
            Total_System_Size_kWh_DC__c = 1445.86,
            Total_System_Size_kW_AC__c = 996,
            Utility__c = utility.Id,
            Credit_Score_Requirement__c = 700,
            Assignment_Order__c = '1',
            Utility_NMC_Tariff__c = nmcRate.Id,
            Product__c = csProduct.Id,
            Expected_Yield_kWh_kW__c = 1300,
            Assemblage_Count__c = 1,
            Maximum_Subscription_Capacity_kWDC__c = 25,
            Available_SMB_Underwriting_Method_Docs__c = true,
            Available_SMB_Underwriting_Method_FICO__c = true
        );
        return sss1;
    }
}