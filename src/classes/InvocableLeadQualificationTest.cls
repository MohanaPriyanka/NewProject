/**
 * Created by: Kristin White on 12/17/2020
 * 
 */
@IsTest
public with sharing class InvocableLeadQualificationTest {
    
    @TestSetup 
    public static void testSetup() {
        Product2 product1 = new Product2(
            Name = 'testProduct1',
            Ignore_Load_Zones_When_Qualifying__c = True
        );
        insert product1;
        
        Utility__c utility1 = new Utility__c(
            Name = 'testUtility1'
        );
        Utility__c utility2 = new Utility__c(
            Name = 'testUtility2'
        );
        Utility__c utility3 = new Utility__c(
            Name = 'testUtility3'
        );
        Utility__c utility4 = new Utility__c(
            Name = 'testUtility4'
        );
        Utility__c utility5 = new Utility__c(
            Name = 'testUtility5'
        );
        Utility__c utility6 = new Utility__c(
            Name = 'testUtility6'
        );
        Utility__c utility7 = new Utility__c(
            Name = 'testUtility7'
        );
        Utility__c utility8 = new Utility__c(
            Name = 'testUtility8'
        );
        insert new List<Utility__c>{utility1, utility2, utility3, utility4, utility5, utility6, utility7, utility8};
        
        LASERCA__Personal_Credit_Report__c pcr1 = new LASERCA__Personal_Credit_Report__c(
            LASERCA__Credit_Score_TransUnion__c = '100'
        );        
        LASERCA__Personal_Credit_Report__c pcr2 = new LASERCA__Personal_Credit_Report__c(
            LASERCA__Credit_Score_TransUnion__c = '500'
        );
        insert new List<LASERCA__Personal_Credit_Report__c>{pcr1, pcr2};
        
        Lead lead1 = new Lead (
            Customer_type__c = 'Commercial',
            LastName = 'testLead1',
            Referral_Name__c = 'testLead1',
            Company = 'testBlueWave1',
            Status = 'New',
            Moody_s_Risk_Calc__c = 'Aaa',
            Personal_Credit_Report__c = pcr1.Id,
            Utility_relationship__c = utility1.Id,
            LoadZone__c = 'SEMA',
            Product__c = null,
            Underwriting_Criteria__c = 'FICO'
        );
        Lead lead2 = new Lead(
            Customer_type__c = 'Commercial',
            LastName = 'testLead2',
            Referral_Name__c = 'testLead2',
            Company = 'testBlueWave1',
            Status = 'New',
            Moody_s_Risk_Calc__c = 'Ba1',
            Personal_Credit_Report__c = pcr2.Id,
            Utility_relationship__c = utility2.Id,
            LoadZone__c = 'SEMA',
            Product__c = null, 
            Underwriting_Criteria__c = 'FICO'
        ); 
        Lead lead3 = new Lead(
            Customer_type__c = 'Commercial',
            LastName = 'testLead3',
            Referral_Name__c = 'testLead3',
            Company = 'testBlueWave1',
            Status = 'New',
            Moody_s_Risk_Calc__c = null,
            Utility_relationship__c = utility3.Id,
            LoadZone__c = 'NEMA',
            Product__c = null,
            Underwriting_Criteria__c = 'Financial Review'
        ); 
        Lead lead4 = new Lead(
            Customer_type__c = 'Commercial',
            LastName = 'testLead4',
            Referral_Name__c = 'testLead4',
            Company = 'testBlueWave1',
            Status = 'New',
            Moody_s_Risk_Calc__c = 'B3',
            Utility_relationship__c = utility4.Id,
            LoadZone__c = 'NEMA',
            Product__c = null,
            Underwriting_Criteria__c = 'Financial Review'
        ); 
        Lead lead5 = new Lead(
            Customer_type__c = 'Commercial',
            LastName = 'testLead5',
            Referral_Name__c = 'testLead5',
            Company = 'testBlueWave1',
            Status = 'New',
            Moody_s_Risk_Calc__c = 'Aa3',
            Utility_relationship__c = utility5.Id,
            LoadZone__c = 'NEMA',
            Product__c = null,
            Underwriting_Criteria__c = 'Financial Review'
        ); 
        Lead lead6 = new Lead(
            Customer_type__c = 'Commercial',
            LastName = 'testLead6',
            Referral_Name__c = 'testLead6',
            Company = 'testBlueWave1',
            Status = 'New',
            Moody_s_Risk_Calc__c = 'Aaa',
            Utility_relationship__c = utility6.Id,
            LoadZone__c = 'NEMA',
            Product__c = null,
            Underwriting_Criteria__c = 'Financial Review'
        ); 
        Lead lead7 = new Lead(
            Customer_type__c = 'Commercial',
            LastName = 'testLead7',
            Referral_Name__c = 'testLead7',
            Company = 'testBlueWave1',
            Status = 'New',
            Moody_s_Risk_Calc__c = 'Baa1',
            Utility_relationship__c = utility7.Id,
            LoadZone__c = 'NEMA',
            Product__c = null,
            Underwriting_Criteria__c = 'Financial Review'
        ); 
        Lead lead8 = new Lead(
            Customer_type__c = 'Commercial',
            LastName = 'testLead8',
            Referral_Name__c = 'testLead8',
            Company = 'testBlueWave1',
            Status = 'New',
            Moody_s_Risk_Calc__c = 'Caa2',
            Utility_relationship__c = utility8.Id,
            LoadZone__c = 'NEMA',
            Product__c = null,
            Underwriting_Criteria__c = 'Financial Review'
        ); 
        insert new List<Lead>{lead1, lead2, lead3, lead4, lead5, lead6, lead7, lead8};
        
        Shared_Solar_System__c sss1 = new Shared_Solar_System__c(
            RiskCalc_Minimum__c = 'Ba3', 
            Open__c = True, 
            Name = 'testSSS1',
            Utility__c = utility1.Id,
            Product__c = product1.Id,
            Service_Territories__c = 'SEMA',
            Public__c = True,
            Credit_Score_Requirement__c = 10,
            Capacity_Committed_kW_DC__c = 100,
            Reserved_Capacity_kW_DC__c = '100',
            Anchor_Capacity_Reserved__c = 10,
            Reserved_Anchor_Capacity__c = 10,
            Total_System_Size_kWh_DC__c = 500,
            Available_SMB_Underwriting_Method_Docs__c = True,
            Available_SMB_Underwriting_Method_FICO__c = True
        ); 
        Shared_Solar_System__c sss2 = new Shared_Solar_System__c(
            RiskCalc_Minimum__c = 'Aa1', 
            Open__c = True, 
            Name = 'testSSS2',
            Utility__c = utility2.Id,
            Product__c = product1.Id,
            Service_Territories__c = 'NEMA',
            Public__c = True,
            Credit_Score_Requirement__c = 20,
            Capacity_Committed_kW_DC__c = 100,
            Reserved_Capacity_kW_DC__c = '100',
            Anchor_Capacity_Reserved__c = 10,
            Reserved_Anchor_Capacity__c = 10,
            Total_System_Size_kWh_DC__c = 500,
            Available_SMB_Underwriting_Method_Docs__c = True,
            Available_SMB_Underwriting_Method_FICO__c = False
        ); 
        Shared_Solar_System__c sss3 = new Shared_Solar_System__c(
            RiskCalc_Minimum__c = 'C', 
            Open__c = True, 
            Name = 'testSSS3',
            Utility__c = utility3.Id,
            Product__c = product1.Id,
            Service_Territories__c = 'NEMA',
            Public__c = True,
            Credit_Score_Requirement__c = 30,
            Capacity_Committed_kW_DC__c = 100,
            Reserved_Capacity_kW_DC__c = '100',
            Anchor_Capacity_Reserved__c = 10,
            Reserved_Anchor_Capacity__c = 10,
            Total_System_Size_kWh_DC__c = 500,
            Available_SMB_Underwriting_Method_Docs__c = True,
            Available_SMB_Underwriting_Method_FICO__c = True
        ); 
        Shared_Solar_System__c sss4 = new Shared_Solar_System__c(
            RiskCalc_Minimum__c = null, 
            Open__c = True, 
            Name = 'testSSS4',
            Utility__c = utility4.Id,
            Product__c = product1.Id,
            Service_Territories__c = 'NEMA',
            Public__c = True,
            Credit_Score_Requirement__c = 40,
            Capacity_Committed_kW_DC__c = 100,
            Reserved_Capacity_kW_DC__c = '100',
            Anchor_Capacity_Reserved__c = 10,
            Reserved_Anchor_Capacity__c = 10,
            Total_System_Size_kWh_DC__c = 500,
            Available_SMB_Underwriting_Method_Docs__c = True,
            Available_SMB_Underwriting_Method_FICO__c = True
        ); 
        Shared_Solar_System__c sss5 = new Shared_Solar_System__c(
            RiskCalc_Minimum__c = 'C', 
            Open__c = True, 
            Name = 'testSSS5',
            Utility__c = utility5.Id,
            Product__c = product1.Id,
            Service_Territories__c = 'NEMA',
            Public__c = True,
            Credit_Score_Requirement__c = 50,
            Capacity_Committed_kW_DC__c = 100,
            Reserved_Capacity_kW_DC__c = '100',
            Anchor_Capacity_Reserved__c = 10,
            Reserved_Anchor_Capacity__c = 10,
            Total_System_Size_kWh_DC__c = 500,
            Available_SMB_Underwriting_Method_Docs__c = False,
            Available_SMB_Underwriting_Method_FICO__c = False
        ); 
        Shared_Solar_System__c sss6 = new Shared_Solar_System__c(
            RiskCalc_Minimum__c = 'B1', 
            Open__c = True, 
            Name = 'testSSS6',
            Utility__c = utility6.Id,
            Product__c = product1.Id,
            Service_Territories__c = 'NEMA',
            Public__c = True,
            Credit_Score_Requirement__c = 60,
            Capacity_Committed_kW_DC__c = 100,
            Reserved_Capacity_kW_DC__c = '100',
            Anchor_Capacity_Reserved__c = 10,
            Reserved_Anchor_Capacity__c = 10,
            Total_System_Size_kWh_DC__c = 500,
            Available_SMB_Underwriting_Method_Docs__c = True,
            Available_SMB_Underwriting_Method_FICO__c = True
        ); 
        Shared_Solar_System__c sss7 = new Shared_Solar_System__c(
            RiskCalc_Minimum__c = 'Baa1', 
            Open__c = True, 
            Name = 'testSSS7',
            Utility__c = utility7.Id,
            Product__c = product1.Id,
            Service_Territories__c = 'NEMA',
            Public__c = True,
            Credit_Score_Requirement__c = 70,
            Capacity_Committed_kW_DC__c = 100,
            Reserved_Capacity_kW_DC__c = '100',
            Anchor_Capacity_Reserved__c = 10,
            Reserved_Anchor_Capacity__c = 10,
            Total_System_Size_kWh_DC__c = 500,
            Available_SMB_Underwriting_Method_Docs__c = True,
            Available_SMB_Underwriting_Method_FICO__c = True
        ); 
        Shared_Solar_System__c sss8 = new Shared_Solar_System__c(
            RiskCalc_Minimum__c = 'Caa1', 
            Open__c = True, 
            Name = 'testSSS8',
            Utility__c = utility8.Id,
            Product__c = product1.Id,
            Service_Territories__c = 'NEMA',
            Public__c = True,
            Credit_Score_Requirement__c = 80,
            Capacity_Committed_kW_DC__c = 100,
            Reserved_Capacity_kW_DC__c = '100',
            Anchor_Capacity_Reserved__c = 10,
            Reserved_Anchor_Capacity__c = 10,
            Total_System_Size_kWh_DC__c = 500,
            Available_SMB_Underwriting_Method_Docs__c = True,
            Available_SMB_Underwriting_Method_FICO__c = True
        ); 
        insert new List<Shared_Solar_System__c>{sss1, sss2, sss3, sss4, sss5, sss6, sss7, sss8};
    }
    
    private static Lead getTestLead(String referralName) {
        return [
            SELECT Id, Referral_Name__c, Moody_s_Risk_Calc__c, Status, LASER_Credit_Score__c
            FROM Lead
            WHERE Referral_Name__c = :referralName
        ];
    }
    
    @IsTest
    static void testRunLeadQualificationCheck() {        
        
        List<Id> leadList1 = new List<Id>();
        Lead lead1 = getTestLead('testLead1');
        leadList1.add(lead1.Id);
        InvocableLeadQualification.runLeadQualificationCheck(leadList1);
        Lead updatedLead1 = getTestLead('testLead1');
        System.assertEquals('Qualified', updatedLead1.Status, 'The lead.Status should update from New to Qualified');
        
        List<Id> leadList2 = new List<Id>();
        Lead lead2 = getTestLead('testLead2');
        leadList2.add(lead2.Id);
        InvocableLeadQualification.runLeadQualificationCheck(leadList2);
        Lead updatedLead2 = getTestLead('testLead2');
        System.assertEquals('Unqualified', updatedLead2.Status, 'The lead.Status should update from New to Unqualified');
        
        List<Id> leadList3 = new List<Id>();
        Lead lead3 = getTestLead('testLead3');
        leadList3.add(lead3.Id);
        InvocableLeadQualification.runLeadQualificationCheck(leadList3);
        Lead updatedLead3 = getTestLead('testLead3');
        System.assertEquals('Unqualified', updatedLead3.Status, 'The lead.Status should update from New to Unqualified');
        
        List<Id> leadList4 = new List<Id>();
        Lead lead4 = getTestLead('testLead4');
        leadList4.add(lead4.Id);
        InvocableLeadQualification.runLeadQualificationCheck(leadList4);
        Lead updatedLead4 = getTestLead('testLead4');
        System.assertEquals('Unqualified', updatedLead4.Status, 'The lead.Status should update from New to Unqualified');
        
        List<Id> leadList5 = new List<Id>();
        Lead lead5 = getTestLead('testLead5');
        leadList5.add(lead5.Id);
        InvocableLeadQualification.runLeadQualificationCheck(leadList5);
        Lead updatedLead5 = getTestLead('testLead5');
        System.assertEquals('Unqualified', updatedLead5.Status, 'The lead.Status should update from New to Unqualified');
        
        List<Id> leadList6 = new List<Id>();
        Lead lead6 = getTestLead('testLead6');
        leadList6.add(lead6.Id);
        InvocableLeadQualification.runLeadQualificationCheck(leadList6);
        Lead updatedLead6 = getTestLead('testLead6');
        System.assertEquals('Qualified', updatedLead6.Status, 'The lead.Status should update from New to Qualified');
        
        List<Id> leadList7 = new List<Id>();
        Lead lead7 = getTestLead('testLead7');
        leadList7.add(lead7.Id);
        InvocableLeadQualification.runLeadQualificationCheck(leadList7);
        Lead updatedLead7 = getTestLead('testLead7');
        System.assertEquals('Qualified', updatedLead7.Status, 'The lead.Status should update from New to Qualified');
        
        List<Id> leadList8 = new List<Id>();
        Lead lead8 = getTestLead('testLead8');
        leadList8.add(lead8.Id);
        InvocableLeadQualification.runLeadQualificationCheck(leadList8);
        Lead updatedLead8 = getTestLead('testLead8');
        System.assertEquals('Unqualified', updatedLead8.Status, 'The lead.Status should update from New to Unqualified');
    }
    
}