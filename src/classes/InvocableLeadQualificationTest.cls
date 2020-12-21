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
        insert utility1;
        
        LASERCA__Personal_Credit_Report__c pcr1 = new LASERCA__Personal_Credit_Report__c(
            LASERCA__Credit_Score_TransUnion__c = '100'
        );        
        insert pcr1;
        
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
            Underwriting_Criteria__c = 'Financial Review'
        ); 
        insert lead1;
        
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
        insert SSS1;
    }
    
    private static Shared_Solar_System__c getTestSSS(String name) {
        return [
            SELECT Id, Name, Open__c, RiskCalc_Minimum__c, Utility__c, Product__c, Public__c, 
            Credit_Score_Requirement__c, Capacity_Committed_kW_DC__c, Reserved_Capacity_kW_DC__c, 
            Anchor_Capacity_Reserved__c, Reserved_Anchor_Capacity__c, Total_System_Size_kWh_DC__c, 
            Available_SMB_Underwriting_Method_Docs__c, Available_SMB_Underwriting_Method_FICO__c 
            FROM Shared_Solar_System__c
            WHERE Name = :name
        ];
    }
    
    private static Lead getTestLead(String referralName) {
        return [
            SELECT Id, Referral_Name__c, Moody_s_Risk_Calc__c, Status, LASER_Credit_Score__c
            FROM Lead
            WHERE Referral_Name__c = :referralName
        ];
    }
    
    @IsTest
    static void testQualifiedFICOLead() {
        List<Id> leadList = new List<Id>();
        Lead lead = getTestLead('testLead1');
        lead.Underwriting_Criteria__c = 'FICO';
        update lead;
        leadList.add(lead.Id);
        InvocableLeadQualification.runLeadQualificationCheck(leadList);
        Lead updatedLead = getTestLead('testLead1');
        System.assertEquals('Qualified', updatedLead.Status, 'The lead.Status should update to Qualified becuase ' + 
                            'the lead.LASER_Credit_Score__c is greater than the sss.Credit_Score_Requirement__c');
    }
    
    @IsTest
    static void testUnqualifiedFICOLead() {
        List<Id> leadList = new List<Id>();
        Lead lead = getTestLead('testLead1');
        lead.Underwriting_Criteria__c = 'FICO';
        update lead;
        Shared_Solar_System__c sss = getTestSSS('testSSS1');
        sss.Available_SMB_Underwriting_Method_FICO__c = False;
        update sss;
        leadList.add(lead.Id);
        InvocableLeadQualification.runLeadQualificationCheck(leadList);
        Lead updatedLead = getTestLead('testLead1');
        System.assertEquals('Unqualified', updatedLead.Status, 'The lead.Status should update to Qualified becuase ' + 
                            'the Available_SMB_Underwriting_Method_FICO__c is false.');
    }
    
    @IsTest
    static void testNullMoodysFinReviewLead() {
        List<Id> leadList = new List<Id>();
        Lead lead = getTestLead('testLead1');
        lead.Moody_s_Risk_Calc__c = null;
        update lead;
        leadList.add(lead.Id);
        InvocableLeadQualification.runLeadQualificationCheck(leadList);
        Lead updatedLead = getTestLead('testLead1');
        System.assertEquals('Unqualified', updatedLead.Status, 'The lead.Status should update to Unqualified because ' + 
                            'the Moody RiskCalc is null.');
    }
    
    @IsTest
    static void testNullRiskCalcMinFinReviewLead() {
        List<Id> leadList = new List<Id>();
        Lead lead = getTestLead('testLead1');
        Shared_Solar_System__c sss = getTestSSS('testSSS1');
        sss.RiskCalc_Minimum__c = null;
        update sss;
        leadList.add(lead.Id);
        InvocableLeadQualification.runLeadQualificationCheck(leadList);
        Lead updatedLead = getTestLead('testLead1');
        System.assertEquals('Unqualified', updatedLead.Status, 'The lead.Status should update to Unqualified becuase ' + 
                            'the RiskCalc Minimum is null.');
    }
    
    @IsTest
    static void testFalseAvailableSMBFinReviewLead() {
        List<Id> leadList = new List<Id>();
        Lead lead = getTestLead('testLead1');
        Shared_Solar_System__c sss = getTestSSS('testSSS1');
        sss.Available_SMB_Underwriting_Method_Docs__c = False;
        update sss;
        leadList.add(lead.Id);
        InvocableLeadQualification.runLeadQualificationCheck(leadList);
        Lead updatedLead = getTestLead('testLead1');
        System.assertEquals('Unqualified', updatedLead.Status, 'The lead.Status should update to Unqualified becuase ' + 
                            'the Available_SMB_Underwriting_Method_Docs__c is false.');
    }
    
    @IsTest
    static void testMoodyScoresFinReviewLead() {
        List<Id> leadList = new List<Id>();
        Lead lead = getTestLead('testLead1');
        leadList.add(lead.Id);
        InvocableLeadQualification.runLeadQualificationCheck(leadList);
        Lead updatedLead1 = getTestLead('testLead1');
        System.assertEquals('Qualified', updatedLead1.Status, 'The lead.Status should update to Qualified becuase ' + 
                            'the Moody score is above the RiskCalc Min.');
        
        lead.Moody_s_Risk_Calc__c = 'Ba3';
        update lead;
        InvocableLeadQualification.runLeadQualificationCheck(leadList);
        Lead updatedLead2 = getTestLead('testLead1');
        System.assertEquals('Qualified', updatedLead2.Status, 'The lead.Status should update to Qualified becuase ' + 
                            'the Moody score is equal to the RiskCalc Min.');
        
        lead.Moody_s_Risk_Calc__c = 'Caa1';
        update lead;
        InvocableLeadQualification.runLeadQualificationCheck(leadList);
        Lead updatedLead3 = getTestLead('testLead1');
        System.assertEquals('Unqualified', updatedLead3.Status, 'The lead.Status should update to Unqualified becuase ' + 
                            'the Moody score is less than the RiskCalc Min.');
    }
    
    
    
}