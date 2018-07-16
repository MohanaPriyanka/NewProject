/**
 * Created by mstackhouse on 7/10/2018.
 * Description: 
 * Test: 
 */

@isTest
public with sharing class PCRTradeAccountHandlerTest {
    @TestSetup public static void testSetup() {
        LoanTestRecordWarehouse.partnerSetup();
        insert LoanTestRecordWarehouse.getLoanProductsVariableInterestRatesandTerms();

        RecordType solarLoanType = [
            SELECT Id
            FROM RecordType
            WHERE Name = 'BlueWave Solar Loan'
            AND SobjectType = 'Lead'
        ];

        Partner__c partner = [SELECT Id FROM Partner__c WHERE Name = 'Bluewave Inside Sales' LIMIT 1];


        Lead newLead = new Lead(
            LastName = 'PCRTradeAccountHandlerTest',
            RecordTypeId = solarLoanType.Id,
            FirstName = 'test',
            Automatic_Product_Assignment__c = false,
            Email = 'test@email.com',
            Company = 'Cloud Jedi',
            Status = 'Ready for Credit Check',
            Partner_Lookup__c = partner.Id,
            Annual_Income_Currency__c = 100000,
            Loan_Amount__c = 20000,
            Requested_Loan_Amount__c = 20000,
            Product_Line__c = 'Residential Loan',
            Product_Program__c = 'BlueWave Solar Loan',
            LASERCA__Home_State__c = 'MA',
            Application_Type__c = 'Joint',
            Joint_Applicant_Type__c = 'Co-Applicant',
            Unfinished_Lead__c = true,
            Co_Applicant_Income__c = 60000
        );
        insert newLead;

        Contact newContact = new Contact(
            FirstName = 'CoApplicant',
            LastName = 'Contact',
            Lead__c = newLead.Id,
            Income__c = newLead.Co_Applicant_Income__c
        );
        insert newContact;

        LASERCA__Personal_Credit_Report__c leadPCR = new LASERCA__Personal_Credit_Report__c(
            LASERCA__Lead__c = newLead.Id,
            LASERCA__Credit_Score_TransUnion__c = '700'
        );

        LASERCA__Personal_Credit_Report__c contactPCR = new LASERCA__Personal_Credit_Report__c(
            LASERCA__Contact__c = newContact.Id,
            LASERCA__Credit_Score_TransUnion__c = '700'
        );

        insert new List<LASERCA__Personal_Credit_Report__c>{leadPCR, contactPCR};

        newLead.Personal_Credit_Report__c = leadPCR.Id;
        newLead.Personal_Credit_Report_Co_Applicant__c = contactPCR.Id;
        update newLead;
    }

    @isTest static void testDeduplicateTradeAccounts() {
        Test.startTest();
        Lead lead = getLeadForTest();

        List<LASERCA__Personal_Credit_Report__c> pcrs = getPCRsForLead(lead);

        List<LASERCA__Trade_Accounts__c> tradeAccounts = new List<LASERCA__Trade_Accounts__c>();
        List<String> tradeAccountStrings = new List<String>();

        // add duplicate trade lines
        for (LASERCA__Personal_Credit_Report__c pcr : pcrs) {
            LASERCA__Trade_Accounts__c newTradeAccount = new LASERCA__Trade_Accounts__c(
                LASERCA__Name_of_the_Institution__c = 'JC Pennys',
                LASERCA__Account_Ownership_Type__c = 'JointContractualLiability',
                LASERCA__Account_Balance__c = 3402.12,
                LASERCA__Monthly_Payment__c = 123.45,
                LASERCA__Open_Date__c = Date.newInstance(2016, 1, 1),
                LASERCA__Personal_Credit_Report__c = pcr.Id
            );
            tradeAccounts.add(newTradeAccount);
            tradeAccountStrings.add(PCRTradeAccountHandler.matchAccountCriteria(newTradeAccount));
        }

        // add non-duplicate trade line for Co applicant
        tradeAccounts.add(new LASERCA__Trade_Accounts__c(
            LASERCA__Name_of_the_Institution__c = 'US Bank',
            LASERCA__Account_Ownership_Type__c = 'Individual',
            LASERCA__Account_Balance__c = 1200.00,
            LASERCA__Monthly_Payment__c = 100,
            LASERCA__Open_Date__c = Date.newInstance(2011, 4, 1),
            LASERCA__Personal_Credit_Report__c = lead.Personal_Credit_Report_Co_Applicant__c
        ));
        insert tradeAccounts;

        PCRTradeAccountHandler.makeTradeAccountAdjustments(lead);

        Test.stopTest();

        lead = getLeadForTest();
        System.assertEquals(tradeAccountStrings[0], tradeAccountStrings[1]);
        // only one trade account on the primary PCR it is a duplcate, but we keep the primary's trade account
        System.assertEquals(123.45, lead.Personal_Credit_Report__r.Adjusted_Monthly_Personal_Debt__c);
        // the JC Penny trade account gets excluded, so only the US Bank account counts
        System.assertEquals(100, lead.Personal_Credit_Report_Co_Applicant__r.Adjusted_Monthly_Personal_Debt__c);
        for (LASERCA__Trade_Accounts__c tradeAccount : [
            SELECT Id, Exclude_From_Rollup__c, LASERCA__Personal_Credit_Report__c, LASERCA__Name_of_the_Institution__c
            FROM LASERCA__Trade_Accounts__c
        ]) {
            if (tradeAccount.LASERCA__Personal_Credit_Report__c == lead.Personal_Credit_Report__c) {
                System.assertEquals(false, tradeAccount.Exclude_From_Rollup__c);
            } else {
                if (tradeAccount.LASERCA__Name_of_the_Institution__c == 'US Bank') {
                    System.assertEquals(false, tradeAccount.Exclude_From_Rollup__c);
                } else {
                    System.assertEquals(true, tradeAccount.Exclude_From_Rollup__c);
                }
            }
        }
    }

    @isTest static void testAutoTradeAccountAdjustments() {
        Test.startTest();
        Lead lead = getLeadForTest();

        List<LASERCA__Personal_Credit_Report__c> pcrs = getPCRsForLead(lead);

        List<LASERCA__Trade_Accounts__c> tradeAccounts = new List<LASERCA__Trade_Accounts__c>();
        List<String> tradeAccountStrings = new List<String>();

        // automotive trade account with more than 6 payments left should be included in rollup
        tradeAccounts.add(new LASERCA__Trade_Accounts__c(
            LASERCA__Name_of_the_Institution__c = 'More than 6 remaining term',
            LASERCA__Account_Ownership_Type__c = 'Individual',
            LASERCA__Credit_Loan_Type__c = 'Automotive',
            LASERCA__Account_Balance__c = 1200.00,
            LASERCA__Monthly_Payment__c = 112,
            LASERCA__Open_Date__c = Date.newInstance(2011, 4, 1),
            LASERCA__Remaining_Term__c = '12',
            LASERCA__Personal_Credit_Report__c = lead.Personal_Credit_Report_Co_Applicant__c
        ));

        // automotive trade account with 6 payments left should be excluded from rollup
        tradeAccounts.add(new LASERCA__Trade_Accounts__c(
            LASERCA__Name_of_the_Institution__c = 'Less than 6 remaining term',
            LASERCA__Account_Ownership_Type__c = 'Individual',
            LASERCA__Credit_Loan_Type__c = 'Automotive',
            LASERCA__Account_Balance__c = 1200.00,
            LASERCA__Monthly_Payment__c = 106,
            LASERCA__Open_Date__c = Date.newInstance(2011, 4, 1),
            LASERCA__Remaining_Term__c = '6',
            LASERCA__Personal_Credit_Report__c = lead.Personal_Credit_Report_Co_Applicant__c
        ));

        // automotive trade account with less than 6 payments left should be excluded from rollup
        tradeAccounts.add(new LASERCA__Trade_Accounts__c(
            LASERCA__Name_of_the_Institution__c = 'null remaining term',
            LASERCA__Account_Ownership_Type__c = 'Individual',
            LASERCA__Credit_Loan_Type__c = 'Automotive',
            LASERCA__Account_Balance__c = 1200.00,
            LASERCA__Monthly_Payment__c = 100,
            LASERCA__Open_Date__c = Date.newInstance(2011, 4, 1),
            LASERCA__Remaining_Term__c = null,
            LASERCA__Personal_Credit_Report__c = lead.Personal_Credit_Report_Co_Applicant__c
        ));
        insert tradeAccounts;

        PCRTradeAccountHandler.makeTradeAccountAdjustments(lead);

        Test.stopTest();

        lead = getLeadForTest();
        // only one trade account on the primary PCR should be counted
        System.assertEquals(112, lead.Personal_Credit_Report__r.Adjusted_Monthly_Personal_Debt__c);
        for (LASERCA__Trade_Accounts__c tradeAccount : [
            SELECT Id, Exclude_From_Rollup__c, LASERCA__Personal_Credit_Report__c, LASERCA__Name_of_the_Institution__c
            FROM LASERCA__Trade_Accounts__c
        ]) {
            if (tradeAccount.LASERCA__Name_of_the_Institution__c == 'More than 6 remaining term') {
                System.assertEquals(false, tradeAccount.Exclude_From_Rollup__c);
            } else if (tradeAccount.LASERCA__Name_of_the_Institution__c == 'Less than 6 remaining term') {
                System.assertEquals(true, tradeAccount.Exclude_From_Rollup__c);
            } else if (tradeAccount.LASERCA__Name_of_the_Institution__c == 'null remaining term') {
                System.assertEquals(true, tradeAccount.Exclude_From_Rollup__c);
            }
        }
    }

    static Lead getLeadForTest() {
        Lead lead = [
            SELECT Id, Application_Type__c, Personal_Credit_Report__c, Personal_Credit_Report_Co_Applicant__c,
                Personal_Credit_Report__r.Adjusted_Monthly_Personal_Debt__c,
                Personal_Credit_Report_Co_Applicant__r.Adjusted_Monthly_Personal_Debt__c
            FROM Lead
            WHERE LastName = 'PCRTradeAccountHandlerTest'
        ];
        return lead;
    }

    static List<LASERCA__Personal_Credit_Report__c> getPCRsForLead(Lead lead) {
        List<LASERCA__Personal_Credit_Report__c> pcrs = [
            SELECT Id
            FROM LASERCA__Personal_Credit_Report__c
            WHERE Id = : lead.Personal_Credit_Report__c
            OR Id = : lead.Personal_Credit_Report_Co_Applicant__c
        ];
        return pcrs;
    }
}