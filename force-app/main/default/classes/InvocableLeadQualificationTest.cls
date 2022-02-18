/**
 * @description Created by: Kristin White on 12/17/2020
 */
@IsTest
public with sharing class InvocableLeadQualificationTest {

    @TestSetup
    public static void testSetup() {
        Product2 product1 = new Product2(
            Name = 'testProduct1',
            Ignore_Load_Zones_When_Qualifying__c = true
        );
        insert product1;

        Utility__c utility1 = new Utility__c(
            Name = 'testUtility1'
        );
        insert utility1;

        LASERCA__Personal_Credit_Report__c pcr1 = new LASERCA__Personal_Credit_Report__c(
            LASERCA__Credit_Score__c = '100',
            LASERCA__Date_of_Credit_Report__c = Date.today(),
            LASERCA__Code__c = '014',
            LASERCA__Detail_1__c = 'Detail1',
            LASERCA__Detail_2__c = 'Detail2',
            LASERCA__Detail_3__c = 'Detail3',
            LASERCA__Detail_4__c = 'Detail4',
            LASERCA__Experian_Indicator__c = true
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
            Product__c = product1.Id,
            Underwriting_Criteria__c = 'Financial Review'
        );
        insert lead1;

        Shared_Solar_System__c sss1 = new Shared_Solar_System__c(
            RiskCalc_Minimum__c = 'Ba3',
            Open__c = true,
            Name = 'testSSS1',
            Utility__c = utility1.Id,
            Product__c = product1.Id,
            Service_Territories__c = 'SEMA',
            Public__c = true,
            Credit_Score_Requirement__c = 650,
            Capacity_Committed_kW_DC__c = 100,
            Pending_Small_CS_Capacity__c = 100,
            Anchor_Capacity_Reserved__c = 10,
            Reserved_Anchor_Capacity__c = 10,
            Total_System_Size_kWh_DC__c = 500,
            Perch_Acq_Reserved_Small_CS_Capacity__c = 500,
            Available_SMB_Underwriting_Method_Docs__c = true,
            Available_SMB_Underwriting_Method_FICO__c = true
        );
        insert sss1;
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
        List<Id> leadList = new List<Id>();
        // Passing an empty list
        InvocableLeadQualification.runLeadQualificationCheck(leadList);
        Lead updatedLead1 = getTestLead('testLead1');
        System.assertEquals('New', updatedLead1.Status, 'The lead.Status should still be New because ' +
            'the list passed was empty, so the lead.Status was not updated.');

        // Passing a null list
        InvocableLeadQualification.runLeadQualificationCheck(null);
        Lead updatedLead2 = getTestLead('testLead1');
        System.assertEquals('New', updatedLead2.Status, 'The lead.Status should still be New because ' +
            'the list passed was null, so the lead.Status was not updated.');

        //Passing a valid list
        Lead lead = getTestLead('testLead1');
        leadList.add(lead.Id);
        InvocableLeadQualification.runLeadQualificationCheck(leadList);
        Lead updatedLead3 = getTestLead('testLead1');
        System.assertEquals('Qualified', updatedLead3.Status, 'The lead.Status should update to Qualified because ' +
            'the Moody score is above the RiskCalc Min.');

        lead.Underwriting_Criteria__c = 'FICO';
        lead.Status = 'Sales Qualified';
        update lead;
        InvocableLeadQualification.runLeadQualificationCheck(leadList);
        Lead updatedLead4 = getTestLead('testLead1');
        System.assertEquals('Unqualified', updatedLead4.Status, 'Lead should not be qualified since the FICO score is too low');
    }
}