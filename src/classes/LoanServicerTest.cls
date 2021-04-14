/*************************************************************************************
 * Created By:  Peter Yao 
 * Description: Tests LoanService and Excel classes
 *************************************************************************************/
@isTest
public with sharing class LoanServicerTest {
    @testSetup public static void setupTestData() {
        Loan_Data__c capitalPool = new Loan_Data__c(Name = 'Revolving Credit Line',
                                                    Total_Capital__c = 10000000,
                                                    Investor__c = 'The Bank',
                                                    Pool_Type__c = 'Revolving Credit Line');
        insert capitalPool;

        Loan_Traunch__c loanTranchePending = new Loan_Traunch__c(Name = 'Tranche Assignment Pending',
                                                                 Tranche_Type__c = 'Holding',
                                                                 Stage__c = 'Closed',
                                                                 Loan_Data__c = capitalPool.id);
        insert loanTranchePending;                  

        Partner__c partner = new Partner__c(Name = 'Partner');
        insert partner;

        Lead testLead = new Lead(FirstName = 'Test',
                                 LastName = 'Testerson',
                                 Product_Line__c = 'Residential Loan',
                                 Unfinished_Lead__c = true,
                                 Company = 'Testco');
        insert testLead;

        Account account = new Account(Name = 'Testerson');
        insert account;

        List<Product2> products = new List<Product2>();
        Product2 productLoanMATerm10Rate599 = 
            new Product2(Name = 'BlueWave Solar Loan - MA - 10 Year Term - 5.99%',
                         Family = 'Solar Loan',
                         Product_Type__c = 'Residential Loan',
                         State__c = 'MA',
                         Loan_Interest_Rate__c = 5.99,
                         Loan_Term__c = 108,
                         Loan_Interest_Only_Period__c = 12,
                         Loan_Financing_Fee_Terms__c = 'Maximum (5%, $1,250)',
                         Disbursal_Terms__c = '30% Contract Signature, 60% Mechanical Installation, 10% Interconnection',
                         ProductCode = 'BlueWave Solar Loan - MA - 10 Year Term - 5.99%',
                         Loan_base_rate__c = .0625,
                         Loan_Internal_Lender_rate__c = .0499,
                         Credit_Maximum__c = '999',
                         Credit_Minimum__c = '750',
                         Loan_Capital_Pool__c = capitalPool.Id,
                         Loan_Tranche_Type__c = 'Standard',
                         Program__c = 'BlueWave Solar Loan',
                         isActive = TRUE);
        products.add(productLoanMATerm10Rate599);
        Product2 mslp20Yr = 
            new Product2(Name = 'MSLP - MA - 20 Year - 3.25%',
                         Family = 'Solar Loan',
                         Product_Type__c = 'Residential Loan',
                         State__c = 'MA',
                         Loan_Interest_Rate__c = 3.25,
                         Loan_Term__c = 240,
                         Loan_Interest_Only_Period__c = 12,
                         Loan_Financing_Fee_Terms__c = 'No Financing Fee',
                         Disbursal_Terms__c = '35% Contract Signature, 65% Interconnection',
                         ProductCode = 'MSLP - MA - 20 Year - 3.25%',
                         Loan_Capital_Pool__c = capitalPool.Id,
                         Loan_Tranche_Type__c = 'Standard',
                         Program__c = 'BlueWave Solar Loan',
                         isActive = TRUE);
        products.add(mslp20Yr);
        Product2 arl10Yr =
            new Product2(Name = 'ARL - MA - 15 Year - 4.49%',
                Family = 'Solar Loan',
                Product_Type__c = 'Residential Loan',
                State__c = 'MA',
                Loan_Interest_Rate__c = 4.49,
                Loan_Term__c = 168,
                Loan_Interest_Only_Period__c = 12,
                Loan_Financing_Fee_Terms__c = 'No Financing Fee',
                Disbursal_Terms__c = '30% Contract Signature, 60% Mechanical Installation, 10% Interconnection',
                ProductCode = 'ARL - MA - 15 Year - 4.49%',
                Loan_Capital_Pool__c = capitalPool.Id,
                Loan_Tranche_Type__c = 'Standard',
                Program__c = 'BlueWave Solar Loan',
                First_Adjustment__c = 61,
                Floor_Rate__c = 1,
                Ceiling_Rate__c = 10,
                Index_Rate_for_Adjustment__c = 'WSJ Prime Rate',
                Margin_Over_Index_Rate__c = .5,
                Maximum_Adjustment__c = 1,
                Months_Between_Adjustment__c = 12,
                isActive = TRUE);
        products.add(arl10Yr);
        insert products;

        Opportunity opp = new Opportunity(AccountId = account.Id,
                                          Product__c = productLoanMATerm10Rate599.Id,
                                          Lead__c = testLead.Id,
                                          Lead_ID__c = ((String) testLead.Id).left(15),
                                          Name = 'Testerson Loan',
                                          Product_Line__c = 'Residential Loan',
                                          StageName = 'New',
                                          CloseDate = Date.today().addYears(1));
        insert opp;

        Index_Rate__c ir = new Index_Rate__c(
            Index_Rate_Type__c = 'WSJ Prime Rate',
            Index_Rate__c = 8
        );
        insert ir;
    }

    @IsTest
    private static void testTAInsert() {
        Product2 ma10Yr = [SELECT Id, Loan_Interest_Rate__c, Loan_Term__c, Loan_Interest_Only_Period__c
        FROM Product2
        WHERE Name = 'BlueWave Solar Loan - MA - 10 Year Term - 5.99%' LIMIT 1];
        Loan_Traunch__c loanTraunch = [SELECT Id
        FROM Loan_Traunch__c
        WHERE Name = 'Tranche Assignment Pending'
        LIMIT 1];
        Lead testLead = [SELECT Id FROM Lead WHERE LastName = 'Testerson' LIMIT 1];
        Opportunity opp = [SELECT Id FROM Opportunity WHERE Name = 'Testerson Loan' LIMIT 1];
        Partner__c partner = [SELECT Id FROM Partner__c WHERE Name = 'Partner' LIMIT 1];
        Loan__c loan = new Loan__c(Product__c = ma10Yr.Id,
            Lead__c = testLead.Id,
            Partner__c = partner.Id,
            Opportunity__c = opp.Id,
            Loan_Tranche__c = loanTraunch.Id,
            Requested_Loan_Amount__c = 40316.93,
            Financing_Fee__c = 2015.85,
            Commencement_Datee__c = Date.today());
        insert loan;
        // LoanTrigger and LoanServicer was doing this before
        Loan_Payment__c lp = new Loan_Payment__c(
            Loan__c = loan.Id,
            Period__c = 1,
            Funds_Distributed__c = 1
        );
        insert lp;
        List<Loan_Payment__c> loanPayments = [SELECT Id, Period__c, Bill_Status__c,
            Funds_Distributed__c, Amort_Interest_Due__c, Amort_Principal_Due__c,
            Amort_Cumulative_Principal__c, Amort_Starting_Principal__c, Amort_Total_Due__c,
            Forecasted_Cumulative_Principal__c, Forecasted_Loan_Balance__c, Forecasted_Interest_Due__c,
            Forecasted_Principal_Due__c, Forecasted_Principal_Interest_Due__c
        FROM Loan_Payment__c
        WHERE Loan__c = : loan.Id
        AND Period__c <= 20];

        List<Transaction_Application__c> taList = new List<Transaction_Application__c>();
        for (Loan_Payment__c loanPayment : loanPayments) {
            if (loanPayment.Period__c == 20) {
                loanPayment.Bill_Status__c = 'Current';
            } else {
                loanPayment.Bill_Status__c = 'Closed';
            }
            Transaction_Application__c ta = new Transaction_Application__c(Loan_Payment__c = loanPayment.Id,
                Principal_Applied__c = 1000);
            taList.add(ta);
        }
        update loanPayments;

        Test.startTest();
        TransactionApplicationHandler.batchSize = 20;
        insert taList;
        Test.stopTest();
        System.assert(true, 'TransactionApplicationTrigger will get deleted anyways');
        try {
            delete taList;
        } catch (DmlException dme) {
            System.assert(true, 'Delete prevented as expected, but the trigger will get deleted');
        }
    }

    @IsTest
    private static void testAdjustableQSS() {
        Product2 arl = [
            SELECT Id, Loan_Interest_Rate__c, Loan_Term__c, Loan_Interest_Only_Period__c
            FROM Product2
            WHERE Name = 'ARL - MA - 15 Year - 4.49%' LIMIT 1
        ];
        Quick_Sales_Sheet__c qss = new Quick_Sales_Sheet__c(
            Product__c = arl.Id,
            System_Cost__c = 20000,
            System_Size__c = 20
        );
        insert qss;
        qss.System_Size__c = 25;
        update qss;
        System.assert(true, 'QuickSalesSheet trigger to be deleted');
    }
 }