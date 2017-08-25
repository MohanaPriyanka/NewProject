@isTest
private class PCRApprovalHandlerTest {
    @testSetup public static void setupTestData() {
        LoanTestRecordWarehouse.partnerSetup();
        insert LoanTestRecordWarehouse.getLoanProductsVariableInterestRatesandTerms();
    }

    static testMethod void testPCRapproval() {
        Partner__c partner = [SELECT Id from Partner__c where Name = 'Bluewave Inside Sales' LIMIT 1];
        List<Lead> insertleads = new List<Lead>();
        List<LASERCA__Personal_Credit_Report__c> insertpcrlist = new List<LASERCA__Personal_Credit_Report__c>();
        List<LASERCA__Trade_Accounts__c> inserttradeacct = new List<LASERCA__Trade_Accounts__c>();

        Product2 productVar = new Product2( name = 'BlueWave Solar Loan - MA',
                                            State__c = 'MA',
                                            Family = 'Solar Loan',
                                            Product_Type__c = 'Residential Loan',
                                            Program__c = 'BlueWave Solar Loan',
                                            IsActive = TRUE,
                                            ProductCode = 'x',
                                            Loan_Term__c = 120,
                                            Loan_Interest_Rate__c = 5.99,
                                            Loan_Interest_Only_Period__c = 12,
                                            Loan_Base_Rate__c = .0625,
                                            Debt_To_Income_Maximum__c = 50,
                                            Credit_Minimum__c = '681',
                                            Credit_Maximum__c = '999',
                                            Disbursal_Terms__c = '30% Contract Signature, 60% Mechanical Installation, 10% Interconnection',
                                            Loan_Financing_Fee_Terms__c ='Maximum (5%, $1,250)');
        Product2 mslp = new Product2( name = 'BlueWave Solar Loan - MA',
                                            State__c = 'MA',
                                            Family = 'Solar Loan',
                                            Product_Type__c = 'Residential Loan',
                                            Program__c = 'MSLP',
                                            IsActive = TRUE,
                                            ProductCode = 'x',
                                            Loan_Term__c = 120,
                                            Loan_Interest_Rate__c = 5.99,
                                            Loan_Interest_Only_Period__c = 12,
                                            Loan_Base_Rate__c = .0625,
                                            Debt_To_Income_Maximum__c = 50,
                                            Credit_Minimum__c = '681',
                                            Credit_Maximum__c = '999',
                                            Disbursal_Terms__c = '30% Contract Signature, 60% Mechanical Installation, 10% Interconnection',
                                            Loan_Financing_Fee_Terms__c ='Maximum (5%, $1,250)');
        insert new List<Product2>{productVar, mslp};

        Lead lead = getLead(50000, 45000, productVar.Id, true, true, partner.Id);
        insertleads.add(lead);
        Lead leadA = getLead(20000, 65000, productVar.Id, false, true, partner.Id);
        insertleads.add(leadA);
        Lead leadAA = getLead(1000, 65000, productVar.Id, false, false, partner.Id);
        insertleads.add(leadAA);
        Lead leadAB = getLead(14000, 15000, productVar.Id, true, false, partner.Id);
        insertleads.add(leadAB);
        Lead leadAC = getLead(14000, 46000, productVar.Id, true, false, partner.Id);
        insertleads.add(leadAC);
        Lead leadAD = getLead(90000, 20000, productVar.Id, false, true, partner.Id);
        insertleads.add(leadAD);
        Lead leadAE = getLead(90000, 20000, productVar.Id, false, true, partner.Id);
        insertleads.add(leadAE);
        Lead leadAF = getLead(90000, 20000, productVar.Id, false, true, partner.Id);
        insertleads.add(leadAF);
        Lead leadAG = getLead(90000, 20000, productVar.Id, false, true, partner.Id);
        insertleads.add(leadAG);
        Lead leadAH = getLead(50000, 45000, productVar.Id, true, true, partner.Id);
        insertleads.add(leadAH);
        Lead leadAI = getLead(null, 45000, productVar.Id, true, true, partner.Id);
        insertleads.add(leadAI);
        Lead leadAJ = getLead(100000, 30000, productVar.Id, false, true, partner.Id);
        insertleads.add(leadAJ);
        Lead coAppLead = getLead(50000, 45000, productVar.Id, true, true, partner.Id);
        coAppLead.Co_Applicant_Income__c = 2000;
        insertleads.add(coAppLead);
        insert insertleads;
        Account coApplicantAccount = new Account(Name = 'CoapplicantAccount');
        insert coApplicantAccount;

        Contact coApplicantContact = new Contact(FirstName = 'Cole',
                                                 LastName = 'Swain',
                                                 AccountId = coApplicantAccount.Id,
                                                 Lead__c = coAppLead.Id,
                                                 Income__c = 2000,
                                                 LASERCA__Social_Security_Number__c = '000000002');
        insert coApplicantContact;

        LASERCA__Personal_Credit_Report__c pcr = new LASERCA__Personal_Credit_Report__c(LASERCA__Lead__c = lead.Id,
                                                                                        LASERCA__Code__c = '039',
                                                                                        LASERCA__Code_2__c = '034',
                                                                                        LASERCA__Code_3__c = '040',
                                                                                        LASERCA__Code_4__c = '022',
                                                                                        LASERCA__Credit_Score_TransUnion__c = '681');
        insertpcrlist.add(pcr);
        LASERCA__Personal_Credit_Report__c pcrA = new LASERCA__Personal_Credit_Report__c(LASERCA__Lead__c = leadA.Id,
                                                                                         LASERCA__Credit_Score_TransUnion__c = '680');
        insertpcrlist.add(pcrA);
        LASERCA__Personal_Credit_Report__c pcrAA = new LASERCA__Personal_Credit_Report__c(LASERCA__Lead__c = leadAA.Id,
                                                                                          LASERCA__Credit_Score_TransUnion__c = '402');
        insertpcrlist.add(pcrAA);
        LASERCA__Personal_Credit_Report__c pcrAB = new LASERCA__Personal_Credit_Report__c(LASERCA__Lead__c = leadAB.Id,
                                                                                          LASERCA__Credit_Score_TransUnion__c = '800');
        insertpcrlist.add(pcrAB);
        LASERCA__Personal_Credit_Report__c pcrAC = new LASERCA__Personal_Credit_Report__c(LASERCA__Lead__c = leadAC.Id,
                                                                                          LASERCA__Credit_Score_TransUnion__c = '701');
        insertpcrlist.add(pcrAC);
        LASERCA__Personal_Credit_Report__c pcrAD = new LASERCA__Personal_Credit_Report__c(LASERCA__Lead__c = leadAD.Id,
                                                                                          LASERCA__Credit_Score_TransUnion__c = '801');
        insertpcrlist.add(pcrAD);
        LASERCA__Personal_Credit_Report__c pcrAE = new LASERCA__Personal_Credit_Report__c(LASERCA__Lead__c = leadAE.Id,
                                                                                          LASERCA__Credit_Score_TransUnion__c = '805');
        insertpcrlist.add(pcrAE);
        LASERCA__Personal_Credit_Report__c pcrAF = new LASERCA__Personal_Credit_Report__c(LASERCA__Lead__c = leadAF.Id,
                                                                                          LASERCA__Credit_Score_TransUnion__c = '810');
        insertpcrlist.add(pcrAF);
        LASERCA__Personal_Credit_Report__c pcrAG = new LASERCA__Personal_Credit_Report__c(LASERCA__Lead__c = leadAG.Id,
                                                                                          LASERCA__Credit_Score_TransUnion__c = '815');
        insertpcrlist.add(pcrAG);
        LASERCA__Personal_Credit_Report__c pcrAH = new LASERCA__Personal_Credit_Report__c(LASERCA__Lead__c = leadAH.Id,
                                                                                          LASERCA__Credit_Score_TransUnion__c = '682');
        insertpcrlist.add(pcrAH);
        LASERCA__Personal_Credit_Report__c pcrAI = new LASERCA__Personal_Credit_Report__c(LASERCA__Lead__c = leadAI.Id,
                                                                                          LASERCA__Credit_Score_TransUnion__c = '700');
        insertpcrlist.add(pcrAI);
        LASERCA__Personal_Credit_Report__c pcrAJ = new LASERCA__Personal_Credit_Report__c(LASERCA__Lead__c = leadAJ.Id,
                                                                                          LASERCA__Credit_Score_TransUnion__c = '678');
        insertpcrlist.add(pcrAJ);
        LASERCA__Personal_Credit_Report__c pcrCoAppLead =
            new LASERCA__Personal_Credit_Report__c(Name = 'PCR Primary with Co App',
                                                   LASERCA__Lead__c = coAppLead.Id);
        insertpcrlist.add(pcrCoAppLead);
        insert insertpcrlist;

        LASERCA__Personal_Credit_Report__c pcrCoAppContact =
            new LASERCA__Personal_Credit_Report__c(Name = 'PCR Co App',
                                                   LASERCA__Lead__c = coAppLead.Id,
                                                   LASERCA__Contact__c = coApplicantContact.Id);
        insert pcrCoAppContact;

        Test.startTest();

        LASERCA__Trade_Accounts__c  tradeacctA = new LASERCA__Trade_Accounts__c(LASERCA__Personal_Credit_Report__c = pcrA.id,
                                                                                LASERCA__Monthly_Payment__c = 500,
                                                                                LASERCA__Account_Balance__c = 10000);
        inserttradeacct.add(tradeacctA);
        LASERCA__Trade_Accounts__c  tradeacctAA = new LASERCA__Trade_Accounts__c(LASERCA__Personal_Credit_Report__c = pcrAA.id,
                                                                                 LASERCA__Monthly_Payment__c = 500,
                                                                                 LASERCA__Account_Balance__c = 10000);
        inserttradeacct.add(tradeacctAA);
        LASERCA__Trade_Accounts__c  tradeacct = new LASERCA__Trade_Accounts__c(LASERCA__Personal_Credit_Report__c = pcr.id,
                                                                               LASERCA__Monthly_Payment__c = 500,
                                                                               LASERCA__Account_Balance__c = 10000);
        inserttradeacct.add(tradeacct);
        LASERCA__Trade_Accounts__c  tradeacctAB = new LASERCA__Trade_Accounts__c(LASERCA__Personal_Credit_Report__c = pcrAB.id,
                                                                                 LASERCA__Monthly_Payment__c = 500);
        inserttradeacct.add(tradeacctAB);
        LASERCA__Trade_Accounts__c  tradeacctAC = new LASERCA__Trade_Accounts__c(LASERCA__Personal_Credit_Report__c = pcrAC.id,
                                                                                 LASERCA__Monthly_Payment__c = 1000);
        inserttradeacct.add(tradeacctAC);
        LASERCA__Trade_Accounts__c  tradeacctAD = new LASERCA__Trade_Accounts__c(LASERCA__Personal_Credit_Report__c = pcrAD.id,
                                                                                 LASERCA__Monthly_Payment__c = 200);
        inserttradeacct.add(tradeacctAD);
        LASERCA__Trade_Accounts__c  tradeacctAE = new LASERCA__Trade_Accounts__c(LASERCA__Personal_Credit_Report__c = pcrAE.id,
                                                                                 LASERCA__Monthly_Payment__c = 200);
        inserttradeacct.add(tradeacctAE);
        LASERCA__Trade_Accounts__c  tradeacctAF = new LASERCA__Trade_Accounts__c(LASERCA__Personal_Credit_Report__c = pcrAF.id,
                                                                                 LASERCA__Monthly_Payment__c = 200);
        inserttradeacct.add(tradeacctAF);
        LASERCA__Trade_Accounts__c  tradeacctAG = new LASERCA__Trade_Accounts__c(LASERCA__Personal_Credit_Report__c = pcrAG.id,
                                                                                 LASERCA__Monthly_Payment__c = 200);
        inserttradeacct.add(tradeacctAG);
        LASERCA__Trade_Accounts__c  tradeacctAH = new LASERCA__Trade_Accounts__c(LASERCA__Personal_Credit_Report__c = pcrAH.id,
                                                                                 LASERCA__Monthly_Payment__c = 200);
        inserttradeacct.add(tradeacctAH);
        LASERCA__Trade_Accounts__c  tradeacctAI = new LASERCA__Trade_Accounts__c(LASERCA__Personal_Credit_Report__c = pcrAI.id,
                                                                                 LASERCA__Monthly_Payment__c = 200);
        inserttradeacct.add(tradeacctAI);
        LASERCA__Trade_Accounts__c  tradeacctAJ = new LASERCA__Trade_Accounts__c(LASERCA__Personal_Credit_Report__c = pcrAJ.id,
                                                                                 LASERCA__Monthly_Payment__c = 200);
        inserttradeacct.add(tradeacctAJ);
        LASERCA__Trade_Accounts__c  tradeacctcoAppLead1 =
            new LASERCA__Trade_Accounts__c(LASERCA__Personal_Credit_Report__c = pcrCoAppLead.id,
                                           LASERCA__Monthly_Payment__c = 200,
                                           LASERCA__Account_Balance__c = 1000);
        inserttradeacct.add(tradeacctcoAppLead1);
        LASERCA__Trade_Accounts__c  tradeacctcoAppLead2 =
            new LASERCA__Trade_Accounts__c(LASERCA__Personal_Credit_Report__c = pcrCoAppLead.id,
                                           LASERCA__Monthly_Payment__c = 200,
                                           LASERCA__Account_Balance__c = 1000);
        inserttradeacct.add(tradeacctcoAppLead2);
        insert inserttradeacct;

        System.debug(LoggingLevel.ERROR, '5. SOQL Queries: ' + Limits.getQueries());
        LASERCA__Trade_Accounts__c  tradeacctcoAppContact1 =
            new LASERCA__Trade_Accounts__c(LASERCA__Personal_Credit_Report__c = pcrCoAppContact.id,
                                           LASERCA__Monthly_Payment__c = 200,
                                           LASERCA__Account_Balance__c = 1000);
        LASERCA__Trade_Accounts__c  tradeacctcoAppContact2 =
            new LASERCA__Trade_Accounts__c(LASERCA__Personal_Credit_Report__c = pcrCoAppContact.id,
                                           LASERCA__Monthly_Payment__c = 200,
                                           LASERCA__Account_Balance__c = 1000);
        insert new List<LASERCA__Trade_Accounts__c>{tradeacctcoAppContact1,tradeacctcoAppContact2};

        pcrAB.Solar_Loan_Manual_Decline__c = True;
        pcrAA.Solar_Loan_Manual_Approval__c = True;
        pcrAF.Avidia_Review_Status__c = 'Reviewed - Declined';
        pcrAG.Avidia_Review_Status__c = 'Pending Review';

        update new List<LASERCA__Personal_Credit_Report__c>{pcrAB, pcrAA, pcrAF, pcrAG};

        System.debug(LoggingLevel.ERROR, '6. SOQL Queries: ' + Limits.getQueries());

        List<LASERCA__Personal_Credit_Report__c> pcrlist =
            [SELECT Id, Name, Solar_Loan_Approval_Status__c, LASERCA__Credit_Score_TransUnion__c, DTI_Before__c,
             LASERCA__Lead__r.Status, Credit_Denial_Email_Sent__c
             FROM LASERCA__Personal_Credit_Report__c];

        for (LASERCA__Personal_Credit_Report__c creditreport : pcrlist) {
            if (creditreport.LASERCA__Credit_Score_TransUnion__c == '681') {
                System.assertEquals('Pending Review', creditreport.Solar_Loan_Approval_Status__c);
            } else if (creditreport.LASERCA__Credit_Score_TransUnion__c == '682') {
                System.assertEquals('Approved', creditreport.Solar_Loan_Approval_Status__c);
            } else if (creditreport.LASERCA__Credit_Score_TransUnion__c == '700') {
                System.assertEquals(null, creditreport.Solar_Loan_Approval_Status__c);
                System.assertEquals(FALSE, creditreport.Credit_Denial_Email_Sent__c);
            } else if (creditreport.LASERCA__Credit_Score_TransUnion__c == '680') {
                System.assertEquals('Declined', creditreport.Solar_Loan_Approval_Status__c);
            } else if (creditreport.LASERCA__Credit_Score_TransUnion__c == '402') {
                System.assertEquals('Approved', creditreport.Solar_Loan_Approval_Status__c);
            } else if (creditreport.LASERCA__Credit_Score_TransUnion__c == '678') {
                System.assertEquals(TRUE, creditreport.Credit_Denial_Email_Sent__c);
            } else if (creditreport.LASERCA__Credit_Score_TransUnion__c == '800') {
                System.assertEquals('Declined', creditreport.Solar_Loan_Approval_Status__c);
            } else if (creditreport.LASERCA__Credit_Score_TransUnion__c == '701') {
                System.assertEquals('Pending Review', creditreport.Solar_Loan_Approval_Status__c);
            } else if (creditreport.LASERCA__Credit_Score_TransUnion__c == '801') {
                System.assertEquals('Approved', creditreport.Solar_Loan_Approval_Status__c);
            } else if (creditreport.LASERCA__Credit_Score_TransUnion__c == '810') {
                System.assertEquals('Unqualified', creditreport.LASERCA__Lead__r.Status);
            } else if (creditreport.LASERCA__Credit_Score_TransUnion__c == '815') {
                System.assertEquals('Pending Credit Review', creditreport.LASERCA__Lead__r.Status);
            } else if (creditreport.Name == 'PCR Primary with Co App.Joey') {
                System.debug(LoggingLevel.ERROR,
                             creditreport.Name +
                             ' DTI Before: ' + creditreport.DTI_Before__c +
                             ' FICO: ' + creditreport.LASERCA__Credit_Score_TransUnion__c);
                System.assertEquals(9.6, creditreport.DTI_Before__c.setScale(1));
            } else if (creditreport.Name == 'PCR Co App.Joey') {
                System.debug(LoggingLevel.ERROR,
                             creditreport.Name +
                             ' DTI Before: ' + creditreport.DTI_Before__c +
                             ' FICO: ' + creditreport.LASERCA__Credit_Score_TransUnion__c);
                System.assertEquals(240, creditreport.DTI_Before__c.setScale(1));
            }

        }

        pcrAG.Avidia_Review_Status__c = 'Reviewed - PreApproved';
        update pcrAG;

        System.debug(LoggingLevel.ERROR, '7. SOQL Queries: ' + Limits.getQueries());

        tradeacctcoAppContact1.Exclude_From_Rollup__c = true;
        tradeacctcoAppContact2.Exclude_From_Rollup__c = true;
        update new List<LASERCA__Trade_Accounts__c>{tradeacctcoAppContact1,tradeacctcoAppContact2};

        pcrlist =
            [SELECT Id, Solar_Loan_Approval_Status__c, LASERCA__Credit_Score_TransUnion__c, DTI_Before__c,
             LASERCA__Lead__r.Status, LASERCA__Contact__c
             FROM LASERCA__Personal_Credit_Report__c
             WHERE LASERCA__Credit_Score_TransUnion__c = '815' OR LASERCA__Credit_Score_TransUnion__c = null];

        System.assertEquals(3, pcrlist.size());
        for (LASERCA__Personal_Credit_Report__c creditreport : pcrlist) {
            if (creditreport.LASERCA__Credit_Score_TransUnion__c == '815') {
                System.assertEquals('Pre-Qualified', creditreport.LASERCA__Lead__r.Status);
            } else if (creditreport.LASERCA__Contact__c != null) {
                system.assertEquals(0, creditreport.DTI_Before__c);
            }
        }

        Test.stopTest();
    }

    // This lead should not find any products because additional loan monthly payments puts them over DTI
    static testMethod void testDTIAfterOverLimit() {
        Partner__c partner = [SELECT Id from Partner__c where Name = 'Bluewave Inside Sales' LIMIT 1];
        Lead lead = getLead(50000, 1000000, null, false, false, partner.Id);
        insert lead;

        LASERCA__Personal_Credit_Report__c pcr =
            new LASERCA__Personal_Credit_Report__c(LASERCA__Lead__c = lead.Id,
                                                   LASERCA__Credit_Score_TransUnion__c = '700');
        insert pcr;
        LASERCA__Trade_Accounts__c  tradeacct =
            new LASERCA__Trade_Accounts__c(LASERCA__Personal_Credit_Report__c = pcr.id,
                                           LASERCA__Monthly_Payment__c = 1970);
        insert tradeacct;
        update tradeacct;

        pcr =
            [SELECT Id, Solar_Loan_Approval_Status__c, LASERCA__Credit_Score_TransUnion__c,
             DTI_After_Notes__c
             FROM LASERCA__Personal_Credit_Report__c
             WHERE LASERCA__Lead__c = :lead.Id
             LIMIT 1];
        System.debug(LoggingLevel.ERROR, pcr.DTI_After_Notes__c);
        System.assertEquals(PCRApprovalHandler.PENDINGREVIEW, pcr.Solar_Loan_Approval_Status__c);
    }

    // This lead should not find any DOER products because additional loan monthly payments puts them over DTI
    static testMethod void testCreditLowDTIAfterOverLimit() {
        Partner__c partner = [SELECT Id from Partner__c where Name = 'Bluewave Inside Sales' LIMIT 1];
        Lead lead = getLead(81000, 10000, null, true, false, partner.Id);
        insert lead;

        LASERCA__Personal_Credit_Report__c pcr =
            new LASERCA__Personal_Credit_Report__c(LASERCA__Lead__c = lead.Id,
                                                   LASERCA__Credit_Score_TransUnion__c = '700');
        insert pcr;
        LASERCA__Trade_Accounts__c  tradeacct =
            new LASERCA__Trade_Accounts__c(LASERCA__Personal_Credit_Report__c = pcr.id,
                                           LASERCA__Monthly_Payment__c = 3300);
        insert tradeacct;
        update tradeacct;

        pcr =
            [SELECT Id, Solar_Loan_Approval_Status__c, LASERCA__Credit_Score_TransUnion__c
             FROM LASERCA__Personal_Credit_Report__c
             WHERE LASERCA__Lead__c = :lead.Id
             LIMIT 1];
        System.assertEquals(PCRApprovalHandler.DECLINED, pcr.Solar_Loan_Approval_Status__c);
    }

    static testMethod void testProductRepo() {
        Partner__c partner = [SELECT Id from Partner__c where Name = 'Bluewave Inside Sales' LIMIT 1];
        Product2 product = [SELECT Id, Name, Product_Type__c, Program__c, State__c,
                            Credit_Minimum__c, Credit_Maximum__c, Loan_Interest_Rate__c, Loan_Term__c
                            FROM Product2
                            WHERE Name = 'BlueWave Solar Loan - MA - 10 Year Term - 5.99%' LIMIT 1];
        Lead lead = getLead(81000, 10000, null, false, false, partner.Id);
        insert lead;

        lead.Status = 'Pending Information';
        update lead;

        LASERCA__Personal_Credit_Report__c pcr =
            new LASERCA__Personal_Credit_Report__c(LASERCA__Lead__c = lead.Id,
                                                   LASERCA__Credit_Score_TransUnion__c = '700');
        insert pcr;
        LASERCA__Trade_Accounts__c  tradeacct =
            new LASERCA__Trade_Accounts__c(LASERCA__Personal_Credit_Report__c = pcr.id,
                                           LASERCA__Monthly_Payment__c = 3300);
        insert tradeacct;
        update tradeacct;

        lead = [SELECT Id, DOER_Solar_Loan__c, Pre_Approval_Form__c, Status,
                Personal_Credit_Report__r.LASERCA__Sum_of_monthly_Personal_Debt__c,
                Personal_Credit_Report__r.DTI_After__c,
                Product_Line__c, Product_Program__c, LASERCA__Home_State__c, Loan_Principal__c,
                Income_Support__c
                FROM Lead
                WHERE Id = :lead.Id];

        PCRApprovalHandler.ProductRepo productRepo = new PCRApprovalHandler.ProductRepo(new List<Lead>{lead});
        System.assertEquals('Pending Information', lead.Status);
        System.assertEquals(lead.Personal_Credit_Report__r.LASERCA__Sum_of_monthly_Personal_Debt__c, 3300);
        System.assertEquals(2, productRepo.getApplicableProducts(lead, 700).size());
        System.assertEquals(50.53,
                            productRepo.calcDTIAfter(product, lead, 6750, 3300).dtiAfter);
        System.assertEquals(50.61,
                            lead.Personal_Credit_Report__r.DTI_After__c);
    }

    static testMethod void testNoIBLSInDTI() {
        Partner__c partner = [SELECT Id from Partner__c where Name = 'Bluewave Inside Sales' LIMIT 1];
        Product2 mslp = new Product2( name = 'BlueWave Solar Loan - MA',
                                            State__c = 'MA',
                                            Family = 'Solar Loan',
                                            Product_Type__c = 'Residential Loan',
                                            Program__c = 'MSLP',
                                            IsActive = TRUE,
                                            ProductCode = 'x',
                                            Loan_Term__c = 120,
                                            Loan_Interest_Rate__c = 5.99,
                                            Loan_Interest_Only_Period__c = 12,
                                            Loan_Base_Rate__c = .0625,
                                            Debt_To_Income_Maximum__c = 50,
                                            Credit_Minimum__c = '681',
                                            Credit_Maximum__c = '999',
                                            Disbursal_Terms__c = '30% Contract Signature, 60% Mechanical Installation, 10% Interconnection',
                                            Loan_Financing_Fee_Terms__c ='Maximum (5%, $1,250)');
        insert mslp;
        Lead lead = getLead(60000, 10000, null, true, false, partner.Id);
        insert lead;
        
        lead.Status = 'Pending Information';
        update lead;

        LASERCA__Personal_Credit_Report__c pcr = 
            new LASERCA__Personal_Credit_Report__c(LASERCA__Lead__c = lead.Id,
                                                   LASERCA__Credit_Score_TransUnion__c = '700');
        insert pcr;
        LASERCA__Trade_Accounts__c  tradeacct = 
            new LASERCA__Trade_Accounts__c(LASERCA__Personal_Credit_Report__c = pcr.id,
                                           LASERCA__Monthly_Payment__c = 1000);
        insert tradeacct;
        update tradeacct;

        lead = [SELECT Id, DOER_Solar_Loan__c, Pre_Approval_Form__c, Status, 
                Personal_Credit_Report__r.LASERCA__Sum_of_monthly_Personal_Debt__c,
                Personal_Credit_Report__r.DTI_After__c, 
                Product_Line__c, Product_Program__c, LASERCA__Home_State__c, Loan_Principal__c,
                Income_Support__c
                FROM Lead 
                WHERE Id = :lead.Id];

        PCRApprovalHandler.ProductRepo productRepo = new PCRApprovalHandler.ProductRepo(new List<Lead>{lead});
        System.assertEquals('Pending Information', lead.Status);
        System.assertEquals(lead.Personal_Credit_Report__r.LASERCA__Sum_of_monthly_Personal_Debt__c, 1000);
        System.assertEquals(1, productRepo.getApplicableProducts(lead, 700).size());
        System.assertEquals('Category 1', lead.Income_Support__c);
        // DTI After with IBLS is 21.55
        System.assertEquals(22.22,
                            productRepo.calcDTIAfter(mslp, lead, 5000, 1000).dtiAfter);
        System.assertEquals(22.22,
                            lead.Personal_Credit_Report__r.DTI_After__c);
    }    

    private static Lead getLead(Integer annualIncome, Integer loanAmount, Id productId,
                                Boolean doerLoan, Boolean preApproval, Id partnerId) {
        return(new Lead(LastName = 'testcase',
                        FirstName = 'test',
                        Automatic_Product_Assignment__c = false,
                        Email = 'test@email.com',
                        Company = 'Cloud Jedi',
                        Status = 'Ready for Credit Check',
                        Partner_Lookup__c = partnerId,
                        Annual_Income_Currency__c = annualIncome,
                        Loan_Amount__c = loanAmount,
                        Requested_Loan_Amount__c = loanAmount,
                        Product__c = productId,
                        DOER_Solar_Loan__c = doerLoan,
                        Product_Line__c = 'Residential Loan',
                        Product_Program__c = doerLoan?'MSLP':'BlueWave Solar Loan',
                        LASERCA__Home_State__c = 'MA',
                        Unfinished_Lead__c = true,
                        Pre_Approval_Form__c = preApproval));
    }
}