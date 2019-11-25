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
            LASERCA__Personal_Credit_Report__c = lead.Personal_Credit_Report__c
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
            LASERCA__Personal_Credit_Report__c = lead.Personal_Credit_Report__c
        ));

        // automotive trade account with Remaining_Term = null left should be excluded from rollup
        tradeAccounts.add(new LASERCA__Trade_Accounts__c(
            LASERCA__Name_of_the_Institution__c = 'null remaining term',
            LASERCA__Account_Ownership_Type__c = 'Individual',
            LASERCA__Credit_Loan_Type__c = 'Automotive',
            LASERCA__Account_Balance__c = 1200.00,
            LASERCA__Monthly_Payment__c = 100,
            LASERCA__Open_Date__c = Date.newInstance(2011, 4, 1),
            LASERCA__Personal_Credit_Report__c = lead.Personal_Credit_Report__c
        ));
        insert tradeAccounts;

        Map<Id, LASERCA__Trade_Accounts__c> tradeAccountsFromDB = new Map<Id, LASERCA__Trade_Accounts__c>([
            SELECT Id, LASERCA__Account_Ownership_Type__c, LASERCA__Account_Status_Type__c, LASERCA__Account_Type__c,
                LASERCA__Open_Date__c, LASERCA__Name_of_the_Institution__c, LASERCA__Last_Activity_Date__c,
                LASERCA__Payment_Pattern_Data__c, LASERCA__Remaining_Term__c, LASERCA__Credit_Text__c,
                LASERCA__Account_Balance__c, LASERCA__Personal_Credit_Report__c, Exclude_From_Rollup__c,
                LASERCA__Credit_Loan_Type__c, LASERCA__Monthly_Payment__c
            FROM LASERCA__Trade_Accounts__c
            WHERE LASERCA__Personal_Credit_Report__c = : lead.Personal_Credit_Report__c
            OR LASERCA__Personal_Credit_Report__c = : lead.Personal_Credit_Report_Co_Applicant__c
        ]);

        PCRTradeAccountHandler.makeTradeAccountAdjustments(tradeAccountsFromDB, lead, null);

        Test.stopTest();

        lead = getLeadForTest();
        tradeAccounts = [
            SELECT Id, Exclude_From_Rollup__c, LASERCA__Personal_Credit_Report__c, LASERCA__Name_of_the_Institution__c
            FROM LASERCA__Trade_Accounts__c
        ];
        // trade account on the primary PCR should be counted
        System.assertEquals(212, lead.Personal_Credit_Report__r.Adjusted_Monthly_Personal_Debt__c);

        for (LASERCA__Trade_Accounts__c tradeAccount : tradeAccounts) {
            if (tradeAccount.LASERCA__Name_of_the_Institution__c == 'More than 6 remaining term') {
                System.assertEquals(false, tradeAccount.Exclude_From_Rollup__c);
            } else if (tradeAccount.LASERCA__Name_of_the_Institution__c == 'Less than 6 remaining term') {
                System.assertEquals(true, tradeAccount.Exclude_From_Rollup__c);
            } else if (tradeAccount.LASERCA__Name_of_the_Institution__c == 'null remaining term') {
                System.assertEquals(false, tradeAccount.Exclude_From_Rollup__c);
            }
        }
    }

    @isTest static void testMonthlyPaymentCreation() {
        Test.startTest();
        Lead lead = getLeadForTest();

        List<LASERCA__Personal_Credit_Report__c> pcrs = getPCRsForLead(lead);

        List<LASERCA__Trade_Accounts__c> tradeAccounts = new List<LASERCA__Trade_Accounts__c>();

        tradeAccounts.add(new LASERCA__Trade_Accounts__c(
            LASERCA__Name_of_the_Institution__c = 'More than 6 remaining term',
            LASERCA__Account_Ownership_Type__c = 'Individual',
            LASERCA__Credit_Loan_Type__c = 'InstallmentLoan',
            LASERCA__Account_Type__c = 'Installment',
            LASERCA__Account_Balance__c = 1200.00,
            LASERCA__Monthly_Payment__c = null,
            LASERCA__Open_Date__c = Date.newInstance(2011, 4, 1),
            LASERCA__Remaining_Term__c = '12',
            Exclude_From_Rollup__c = false,
            LASERCA__Personal_Credit_Report__c = lead.Personal_Credit_Report__c
        ));

        tradeAccounts.add(new LASERCA__Trade_Accounts__c(
            LASERCA__Name_of_the_Institution__c = 'Less than 6 remaining term',
            LASERCA__Account_Ownership_Type__c = 'Individual',
            LASERCA__Credit_Loan_Type__c = 'CreditCard',
            LASERCA__Account_Type__c = 'Revolving',
            LASERCA__Account_Balance__c = 2000.00,
            LASERCA__Monthly_Payment__c = null,
            LASERCA__Open_Date__c = Date.newInstance(2011, 4, 1),
            LASERCA__Remaining_Term__c = '6',
            Exclude_From_Rollup__c = false,
            LASERCA__Personal_Credit_Report__c = lead.Personal_Credit_Report__c
        ));

        tradeAccounts.add(new LASERCA__Trade_Accounts__c(
            LASERCA__Name_of_the_Institution__c = 'null remaining term',
            LASERCA__Account_Ownership_Type__c = 'Individual',
            LASERCA__Credit_Loan_Type__c = 'CreditCard',
            LASERCA__Account_Type__c = 'Revolving',
            LASERCA__Account_Balance__c = 1000.00,
            LASERCA__Monthly_Payment__c = 1000.00,
            LASERCA__Open_Date__c = Date.newInstance(2011, 4, 1),
            Exclude_From_Rollup__c = false,
            LASERCA__Personal_Credit_Report__c = lead.Personal_Credit_Report__c
        ));

        tradeAccounts.add(new LASERCA__Trade_Accounts__c(
            LASERCA__Name_of_the_Institution__c = 'Less than 6 remaining term',
            LASERCA__Account_Ownership_Type__c = 'Individual',
            LASERCA__Credit_Loan_Type__c = 'CreditCard',
            LASERCA__Account_Type__c = 'Revolving',
            LASERCA__Account_Balance__c = 1200.00,
            LASERCA__Monthly_Payment__c = 112.00,
            LASERCA__Open_Date__c = Date.newInstance(2011, 4, 1),
            Exclude_From_Rollup__c = false,
            LASERCA__Personal_Credit_Report__c = lead.Personal_Credit_Report__c
        ));

        tradeAccounts.add(new LASERCA__Trade_Accounts__c(
            LASERCA__Name_of_the_Institution__c = 'More than 6 remaining term',
            LASERCA__Account_Ownership_Type__c = 'Individual',
            LASERCA__Credit_Loan_Type__c = 'InstallmentLoan',
            LASERCA__Account_Type__c = 'Installment',
            LASERCA__Account_Balance__c = 1000.00,
            LASERCA__Monthly_Payment__c = 50.00,
            LASERCA__Open_Date__c = Date.newInstance(2011, 4, 1),
            Exclude_From_Rollup__c = false,
            LASERCA__Personal_Credit_Report__c = lead.Personal_Credit_Report__c
        ));
        insert tradeAccounts;

        Test.stopTest();

        lead = getLeadForTest();
        tradeAccounts = [
            SELECT Id, Exclude_From_Rollup__c, LASERCA__Account_Balance__c, LASERCA__Monthly_Payment__c,
                LASERCA__Name_of_the_Institution__c, LASERCA__Account_Ownership_Type__c, LASERCA__Open_Date__c,
                LASERCA__Personal_Credit_Report__c, LASERCA__Credit_Loan_Type__c, LASERCA__Account_Type__c
            FROM LASERCA__Trade_Accounts__c ORDER BY Id ASC
        ];

        // 'Installment' Tradeline Accounts are unaffected
        System.assertEquals(null, tradeAccounts[0].LASERCA__Monthly_Payment__c);
        System.assertEquals(0, PCRTradeAccountHandler.calculateMonthlyPayment(tradeAccounts[0], null));
        System.assertEquals(50.00, tradeAccounts[4].LASERCA__Monthly_Payment__c);
        System.assertEquals(50.00, PCRTradeAccountHandler.calculateMonthlyPayment(tradeAccounts[4], null));

        /* 'Revolving' Tradeline Accounts have their monthly payment set to 3% of the balance only if
        the monthly payment is non existent or equal to to the balance. */

        // null payment
        System.assertEquals(2000, tradeAccounts[1].LASERCA__Account_Balance__c);
        System.assertEquals(null, tradeAccounts[1].LASERCA__Monthly_Payment__c);
        System.assertEquals(2000*0.03, PCRTradeAccountHandler.calculateMonthlyPayment(tradeAccounts[1], null));

        // payment equal to the monthly balance
        System.assertEquals(1000.00, tradeAccounts[2].LASERCA__Account_Balance__c);
        System.assertEquals(1000.00, tradeAccounts[2].LASERCA__Monthly_Payment__c);
        System.assertEquals(1000*0.03, PCRTradeAccountHandler.calculateMonthlyPayment(tradeAccounts[2], null));

        // unaffected payment
        System.assertEquals(1200.00, tradeAccounts[3].LASERCA__Account_Balance__c);
        System.assertEquals(112.00, tradeAccounts[3].LASERCA__Monthly_Payment__c);
        System.assertEquals(112.00, PCRTradeAccountHandler.calculateMonthlyPayment(tradeAccounts[3], null));

        // Total of all monthly payments with adjustments across all trade accounts
        Decimal monthlyDebt = PCRTradeAccountHandler.calculateHouseholdMonthlyDebt(lead, tradeAccounts);
        System.assertEquals(252.00, monthlyDebt);
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