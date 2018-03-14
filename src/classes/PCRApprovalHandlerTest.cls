@isTest
private class PCRApprovalHandlerTest {
    @testSetup public static void setupTestData() {
        LoanTestRecordWarehouse.partnerSetup();
        insert LoanTestRecordWarehouse.getLoanProductsVariableInterestRatesandTerms();
    }

    static testMethod void testNonDOERPCRApproval() {
        Partner__c partner = [SELECT Id FROM Partner__c WHERE Name = 'Bluewave Inside Sales' LIMIT 1];
        Product2 bwsl1 = LoanTestRecordWarehouse.getDefaultProduct('MA', 5.99, 10, null, '681', '999', null);
        Product2 mslp1 = LoanTestRecordWarehouse.getDefaultProduct('MA', 5.99, 10, null, '681', '999', null);
        mslp1.Program__c = 'MSLP';
        mslp1.IBLS_Category__c = 'Category 1';
        Product2 mslp2 = LoanTestRecordWarehouse.getDefaultProduct('MA', 4.99, 10, null, '681', '999', null);
        mslp2.Program__c = 'MSLP';
        mslp2.IBLS_Category__c = 'Category 2';
        insert new List<Product2>{bwsl1, mslp1, mslp2};

        String applicationJSON =
            '{"application":[ ' +
                '  {"income":20000, "loan":65000, "doer":false, "fico":680, "debt":500, "balance":10000, "expectedSLAStatus":"Declined"}, ' +
                '  {"income":1000,  "loan":65000, "doer":false, "fico":402, "debt":500, "balance":10000, "expectedSLAStatus":"Approved"}, ' +
                '  {"income":90000, "loan":20000, "doer":false, "fico":801, "debt":1000, "expectedSLAStatus":"Approved"}, ' +
                '  {"income":90000, "loan":20000, "doer":false, "fico":805, "debt":200}, ' +
                '  {"income":90000, "loan":20000, "doer":false, "fico":810, "debt":200, "expectedStatus":"Unqualified"}, ' +
                '  {"income":90000, "loan":20000, "doer":false, "fico":815, "debt":200, "expectedStatus":"Pending Credit Review"}, ' +
                '  {"income":100000,"loan":30000, "doer":false, "fico":678, "debt":200, "denialSent":true}, ' +
                '  {"income":100000,"loan":30000, "doer":false, "fico":null, "expectedStatus":"Pending Credit Review", "denialSent":false} ' +
                ']}';
        ApplicationSet applicationSet = parse(applicationJSON);
        applicationSet.insertLeads(partner.Id);
        applicationSet.insertPCRs();
        Test.startTest();
        applicationSet.insertTradeAccounts();
        applicationSet.insertCreditReportLogs();

        LASERCA__Personal_Credit_Report__c pcrAA = applicationSet.getPCR(402);
        pcrAA.Solar_Loan_Manual_Approval__c = true;
        LASERCA__Personal_Credit_Report__c pcrAF = applicationSet.getPCR(810);
        pcrAF.Avidia_Review_Status__c = 'Reviewed - Declined';
        LASERCA__Personal_Credit_Report__c pcrAG = applicationSet.getPCR(815);
        pcrAG.Avidia_Review_Status__c = 'Pending Review';
        PCRApprovalHandler.noDelay = true;
        update new List<LASERCA__Personal_Credit_Report__c>{pcrAA, pcrAF, pcrAG};

        Test.stopTest();

        Map<Id, LASERCA__Personal_Credit_Report__c> pcrMap = new Map<Id, LASERCA__Personal_Credit_Report__c>([
            SELECT Id, Name, Solar_Loan_Approval_Status__c, LASERCA__Credit_Score_TransUnion__c, DTI_Before__c, DTI_After__c,
                LASERCA__Lead__r.Status, Credit_Denial_Email_Sent__c
            FROM LASERCA__Personal_Credit_Report__c
        ]);

        for (Application app : ApplicationSet.application) {
            app.assert(pcrMap.get(app.pcrId));
        }
    }

    static testMethod void testDOERPCRApproval() {
        Partner__c partner = [SELECT Id FROM Partner__c WHERE Name = 'Bluewave Inside Sales' LIMIT 1];
        Account coApplicantAccount = new Account(Name = 'CoapplicantAccount');
        insert coApplicantAccount;
        Product2 bwsl1 = LoanTestRecordWarehouse.getDefaultProduct('MA', 5.99, 10, null, '681', '999', null);
        Product2 mslp1 = LoanTestRecordWarehouse.getDefaultProduct('MA', 5.99, 10, null, '681', '999', null);
        mslp1.Program__c = 'MSLP';
        mslp1.IBLS_Category__c = 'Category 1';
        Product2 mslp2 = LoanTestRecordWarehouse.getDefaultProduct('MA', 4.99, 10, null, '681', '999', null);
        mslp2.Program__c = 'MSLP';
        mslp2.IBLS_Category__c = 'Category 2';
        insert new List<Product2>{bwsl1, mslp1, mslp2};

        String applicationJSON =
            '{"application":[ ' +
                '  {"income":50000, "loan":45000, "doer":true,  "fico":681, "ibls":"Category 1", "debt":500, "balance":10000, "code1":"039", "code2":"034", "code3":"040", "code4":"022", "expectedSLAStatus":"Pending Review"}, ' +
                '  {"income":14000, "loan":15000, "doer":true,  "fico":800, "ibls":"Category 1", "debt":500, "expectedSLAStatus":"Declined"}, ' +
                '  {"income":14000, "loan":46000, "doer":true,  "fico":701, "ibls":"Category 1", "debt":1000, "expectedSLAStatus":"Pending Review"}, ' +
                '  {"income":50000, "loan":45000, "doer":true,  "fico":682, "ibls":"Category 1", "debt":200, "expectedSLAStatus":"Approved"}, ' +
                '  {"income":null,  "loan":45000, "doer":true,  "fico":700, "ibls":"Category 1", "debt":200, "denialSent":false}, ' +
                '  {"income":50000, "loan":45000, "doer":true,  "fico":820, "ibls":"Category 1", "debt":400, "balance":2000, "coAppIncome":2000, "applicationType":"Joint", "expectedStatus":"Pending Credit Review", "expectedDTIBefore":9.60, "expectedDTIAfter":21.58}, ' +
                '  {"income":75560, "loan":28068, "doer":true,  "fico":645, "ibls":"Category 2", "debt":2410, "expectedStatus":"Unqualified"}, ' +
                '  {"income":75560, "loan":28068, "doer":true,  "fico":680, "ibls":"Category 2", "debt":2410, "expectedStatus":"Unqualified"}, ' +
                '  {"income":72202, "loan":28068, "doer":true,  "fico":686, "ibls":"Category 2", "debt":2410, "expectedStatus":"Pending Credit Review", "expectedDTIAfter":45.00}, ' +
                '  {"income":85502, "loan":28068, "doer":true,  "fico":686, "ibls":"Category 2", "debt":2410, "expectedStatus":"Pre-Qualified", "expectedDTIAfter":38.00}, ' +
                '  {"income":72202, "loan":28068, "doer":true,  "fico":696, "ibls":"Category 2", "debt":2410, "expectedStatus":"Pre-Qualified", "expectedDTIAfter":45.00}, ' +
                '  {"income":67689, "loan":28068, "doer":true,  "fico":696, "ibls":"Category 2", "debt":2410, "expectedStatus":"Pending Credit Review", "expectedDTIAfter":48.00}, ' +
                '  {"income":65112, "loan":28068, "doer":true,  "fico":700, "ibls":"Category 2", "debt":2410, "expectedStatus":"Pre-Qualified", "expectedDTIAfter":49.90}, ' +
                '  {"income":63708, "loan":28068, "doer":true,  "fico":700, "ibls":"Category 2", "debt":2410, "expectedStatus":"Pending Credit Review", "expectedDTIAfter":51.00}, ' +
                '  {"income":65000, "loan":28068, "doer":true,  "fico":686, "ibls":"Category 2", "debt":2410, "expectedStatus":"Pending Credit Review", "expectedDTIAfter":49.99} ' +
                ']}';
        ApplicationSet applicationSet = parse(applicationJSON);
        applicationSet.insertLeads(partner.Id);
        applicationSet.insertPCRs();
        Contact coApplicantContact = new Contact(FirstName = 'Cole',
            LastName = 'Swain',
            AccountId = coApplicantAccount.Id,
            Lead__c = applicationSet.getLead(820).Id,
            Income__c = 2000,
            LASERCA__Social_Security_Number__c = '000000002');
        insert coApplicantContact;
        LASERCA__Personal_Credit_Report__c coAppPCR =
            new LASERCA__Personal_Credit_Report__c(Name = 'PCR Co App',
                LASERCA__Lead__c = applicationSet.getLead(820).Id,
                LASERCA__Credit_Score_TransUnion__c = '821',
                LASERCA__Contact__c = coApplicantContact.Id);
        insert coAppPCR;

        Test.startTest();
        LASERCA__Trade_Accounts__c coAppTradeAccount =
            new LASERCA__Trade_Accounts__c(
                LASERCA__Personal_Credit_Report__c = coAppPCR.id,
                LASERCA__Monthly_Payment__c = 400,
                LASERCA__Account_Balance__c = 2000);
        insert coAppTradeAccount;
        applicationSet.insertTradeAccounts();
        applicationSet.insertCreditReportLogs();

        LASERCA__Personal_Credit_Report__c pcrAB = applicationSet.getPCR(800);
        pcrAB.Solar_Loan_Manual_Decline__c = true;
        PCRApprovalHandler.noDelay = true;
        update new List<LASERCA__Personal_Credit_Report__c>{pcrAB};

        Test.stopTest();

        Map<Id, LASERCA__Personal_Credit_Report__c> pcrMap = new Map<Id, LASERCA__Personal_Credit_Report__c>([
            SELECT Id, Name, Solar_Loan_Approval_Status__c, LASERCA__Credit_Score_TransUnion__c, DTI_Before__c, DTI_After__c,
                LASERCA__Lead__r.Status, Credit_Denial_Email_Sent__c
            FROM LASERCA__Personal_Credit_Report__c
        ]);

        for (Application app : ApplicationSet.application) {
            app.assert(pcrMap.get(app.pcrId));
        }
    }

    static testMethod void testDOERLowFICOPCRApproval() {
        Partner__c partner = [SELECT Id FROM Partner__c WHERE Name = 'Bluewave Inside Sales' LIMIT 1];
        Product2 mslp1 = LoanTestRecordWarehouse.getDefaultProduct('MA', 4.99, 10, null, '681', '999', null);
        mslp1.Program__c = 'MSLP';
        mslp1.IBLS_Category__c = 'Category 2';
        Product2 mslp2 = LoanTestRecordWarehouse.getDefaultProduct('MA', 4.99, 10, null, '650', '680', null);
        mslp2.Program__c = 'MSLP';
        mslp2.IBLS_Category__c = 'Category 2';
        insert new List<Product2>{mslp1, mslp2};

        String applicationJSON =
            '{"application":[ ' +
                '  {"income":75560, "loan":28068, "doer":true,  "fico":680, "ibls":"Category 2", "debt":2410, "expectedStatus":"Pre-Qualified", "expectedDTIAfter":43.00} ' +
                ']}';
        ApplicationSet applicationSet = parse(applicationJSON);
        applicationSet.insertLeads(partner.Id);
        applicationSet.insertPCRs();
        Test.startTest();
        applicationSet.insertTradeAccounts();
        applicationSet.insertCreditReportLogs();
        Test.stopTest();

        Map<Id, LASERCA__Personal_Credit_Report__c> pcrMap = new Map<Id, LASERCA__Personal_Credit_Report__c>([
            SELECT Id, Name, Solar_Loan_Approval_Status__c, LASERCA__Credit_Score_TransUnion__c, DTI_Before__c, DTI_After__c,
                LASERCA__Lead__r.Status, Credit_Denial_Email_Sent__c
            FROM LASERCA__Personal_Credit_Report__c
        ]);

        for (Application app : ApplicationSet.application) {
            app.assert(pcrMap.get(app.pcrId));
        }
    }

    static testMethod void testPreQualified() {
        Partner__c partner = [SELECT Id FROM Partner__c WHERE Name = 'Bluewave Inside Sales' LIMIT 1];
        Product2 productVar = LoanTestRecordWarehouse.getDefaultProduct('MA', 5.99, 10, null, '681', '999', null);
        Product2 mslp = LoanTestRecordWarehouse.getDefaultProduct('MA', 5.99, 10, null, '681', '999', null);
        mslp.Program__c = 'MSLP';
        insert new List<Product2>{productVar, mslp};
        Lead leadAG = getLead(90000, 20000, productVar.Id, false, true, partner.Id);
        insert leadAG;

        Test.startTest();
        LASERCA__Personal_Credit_Report__c pcrAG = new LASERCA__Personal_Credit_Report__c(LASERCA__Lead__c = leadAG.Id,
            LASERCA__Credit_Score_TransUnion__c = '815');
        insert pcrAG;
        LASERCA__Trade_Accounts__c tradeacctAG = new LASERCA__Trade_Accounts__c(LASERCA__Personal_Credit_Report__c = pcrAG.id,
            LASERCA__Monthly_Payment__c = 200);
        insert tradeacctAG;
        insert getCRL(pcrAG);

        pcrAG.Avidia_Review_Status__c = 'Pending Review';
        update pcrAG;
        Test.stopTest();

        pcrAG.Avidia_Review_Status__c = 'Reviewed - PreApproved';
        PCRApprovalHandler.alreadyRan = false;
        PCRApprovalHandler.noDelay = true;
        update pcrAG;

        pcrAG = [
            SELECT Id, Solar_Loan_Approval_Status__c, LASERCA__Credit_Score_TransUnion__c, DTI_Before__c,
                LASERCA__Lead__r.Status, LASERCA__Contact__c
            FROM LASERCA__Personal_Credit_Report__c
            WHERE LASERCA__Credit_Score_TransUnion__c = '815'
        ];

        System.assertEquals('Pre-Qualified', pcrAG.LASERCA__Lead__r.Status);

        System.assertEquals(3, SLPCreditStatus.getCustomerProducts(leadAG.Id).size());
        // This product should show up in the SLPCreditStatus.getCustomerProducts
        leadAG.Product__c = mslp.id;
        update leadAG;
        System.assertEquals(4, SLPCreditStatus.getCustomerProducts(leadAG.Id).size());
    }

    static testMethod void testExclude() {
        Partner__c partner = [SELECT Id FROM Partner__c WHERE Name = 'Bluewave Inside Sales' LIMIT 1];
        Product2 productVar = LoanTestRecordWarehouse.getDefaultProduct('MA', 5.99, 10, null, '681', '999', null);
        insert productVar;

        Test.startTest();
        Lead lead = getLead(50000, 45000, productVar.Id, true, true, partner.Id);
        insert lead;
        LASERCA__Personal_Credit_Report__c pcr = new LASERCA__Personal_Credit_Report__c(LASERCA__Lead__c = lead.Id,
            LASERCA__Credit_Score_TransUnion__c = '888');
        insert pcr;
        LASERCA__Trade_Accounts__c tradeacctA = new LASERCA__Trade_Accounts__c(LASERCA__Personal_Credit_Report__c = pcr.id,
            LASERCA__Monthly_Payment__c = 500,
            LASERCA__Account_Balance__c = 10000);
        LASERCA__Trade_Accounts__c tradeacctAA = new LASERCA__Trade_Accounts__c(LASERCA__Personal_Credit_Report__c = pcr.id,
            LASERCA__Monthly_Payment__c = 500,
            LASERCA__Account_Balance__c = 10000);
        insert new List<LASERCA__Trade_Accounts__c>{
            tradeacctA, tradeacctAA
        };
        insert getCRL(pcr);
        Test.stopTest();

        pcr = [
            SELECT Id, Solar_Loan_Approval_Status__c, LASERCA__Credit_Score_TransUnion__c, DTI_Before__c,
                LASERCA__Lead__r.Status, LASERCA__Contact__c
            FROM LASERCA__Personal_Credit_Report__c
            WHERE LASERCA__Credit_Score_TransUnion__c = '888'
        ];
        System.assertEquals(24, pcr.DTI_Before__c);

        tradeacctA.Exclude_From_Rollup__c = true;
        tradeacctAA.Exclude_From_Rollup__c = true;
        PCRApprovalHandler.alreadyRan = false;
        PCRApprovalHandler.noDelay = true;
        update new List<LASERCA__Trade_Accounts__c>{
            tradeacctA, tradeacctAA
        };

        pcr = [
            SELECT Id, Solar_Loan_Approval_Status__c, LASERCA__Credit_Score_TransUnion__c, DTI_Before__c,
                LASERCA__Lead__r.Status, LASERCA__Contact__c
            FROM LASERCA__Personal_Credit_Report__c
            WHERE LASERCA__Credit_Score_TransUnion__c = '888'
        ];
        System.assertEquals(0, pcr.DTI_Before__c);
    }


    // This lead should not find any products because additional loan monthly payments puts them over DTI
    static testMethod void testDTIAfterOverLimit() {
        Test.startTest();
        Partner__c partner = [SELECT Id FROM Partner__c WHERE Name = 'Bluewave Inside Sales' LIMIT 1];
        Lead lead = getLead(50000, 1000000, null, false, false, partner.Id);
        insert lead;

        LASERCA__Personal_Credit_Report__c pcr =
            new LASERCA__Personal_Credit_Report__c(LASERCA__Lead__c = lead.Id,
                LASERCA__Credit_Score_TransUnion__c = '700');
        insert pcr;
        LASERCA__Trade_Accounts__c tradeacct =
            new LASERCA__Trade_Accounts__c(LASERCA__Personal_Credit_Report__c = pcr.id,
                LASERCA__Monthly_Payment__c = 1970);
        insert tradeacct;
        insert getCRL(pcr);

        Test.stopTest();

        pcr = [
            SELECT Id, Solar_Loan_Approval_Status__c, LASERCA__Credit_Score_TransUnion__c,
                DTI_After_Notes__c
            FROM LASERCA__Personal_Credit_Report__c
            WHERE LASERCA__Lead__c = :lead.Id
            LIMIT 1
        ];
        System.assertEquals(PCRApprovalHandler.PENDINGREVIEW, pcr.Solar_Loan_Approval_Status__c);
    }

    // This lead should not find any DOER products because additional loan monthly payments puts them over DTI
    static testMethod void testCreditLowDTIAfterOverLimit() {
        Test.startTest();
        Partner__c partner = [SELECT Id FROM Partner__c WHERE Name = 'Bluewave Inside Sales' LIMIT 1];
        Lead lead = getLead(81000, 10000, null, true, false, partner.Id);
        insert lead;

        LASERCA__Personal_Credit_Report__c pcr =
            new LASERCA__Personal_Credit_Report__c(LASERCA__Lead__c = lead.Id,
                LASERCA__Credit_Score_TransUnion__c = '700');
        insert pcr;
        LASERCA__Trade_Accounts__c tradeacct =
            new LASERCA__Trade_Accounts__c(LASERCA__Personal_Credit_Report__c = pcr.id,
                LASERCA__Monthly_Payment__c = 3300);
        insert tradeacct;
        insert getCRL(pcr);

        Test.stopTest();

        pcr = [
            SELECT Id, Solar_Loan_Approval_Status__c, LASERCA__Credit_Score_TransUnion__c
            FROM LASERCA__Personal_Credit_Report__c
            WHERE LASERCA__Lead__c = :lead.Id
            LIMIT 1
        ];
        System.assertEquals(PCRApprovalHandler.DECLINED, pcr.Solar_Loan_Approval_Status__c);
    }

    static testMethod void testProductRepo() {
        Partner__c partner = [SELECT Id FROM Partner__c WHERE Name = 'Bluewave Inside Sales' LIMIT 1];
        Product2 product = [
            SELECT Id, Name, Product_Type__c, Program__c, State__c, DTI_After_Rate_Gross_Up__c,
                Credit_Minimum__c, Credit_Maximum__c, Loan_Interest_Rate__c, Loan_Term__c
            FROM Product2
            WHERE Name = 'BlueWave Solar Loan - MA - 10 Year Term - 5.99%'
            LIMIT 1
        ];
        Lead lead = getLead(81000, 10000, null, false, false, partner.Id);
        insert lead;

        lead.Status = 'Pending Information';
        update lead;

        Test.startTest();
        LASERCA__Personal_Credit_Report__c pcr =
            new LASERCA__Personal_Credit_Report__c(LASERCA__Lead__c = lead.Id,
                LASERCA__Credit_Score_TransUnion__c = '700');
        insert pcr;
        LASERCA__Trade_Accounts__c tradeacct =
            new LASERCA__Trade_Accounts__c(LASERCA__Personal_Credit_Report__c = pcr.id,
                LASERCA__Monthly_Payment__c = 3300);
        insert tradeacct;
        insert getCRL(pcr);

        Test.stopTest();

        lead = [
            SELECT Id, DOER_Solar_Loan__c, Pre_Approval_Form__c, Status,
                Personal_Credit_Report__r.LASERCA__Sum_of_monthly_Personal_Debt__c,
                Personal_Credit_Report__r.DTI_After__c,
                Product_Line__c, Product_Program__c, LASERCA__Home_State__c, Loan_Principal__c,
                Income_Support__c, Partner_Lookup__c
            FROM Lead
            WHERE Id = :lead.Id
        ];

        PCRApprovalHandler.ProductRepo productRepo = new PCRApprovalHandler.ProductRepo(new List<Lead>{
            lead
        });
        System.assertEquals('Pending Information', lead.Status);
        System.assertEquals(lead.Personal_Credit_Report__r.LASERCA__Sum_of_monthly_Personal_Debt__c, 3300);
        System.assertEquals(2, productRepo.getApplicableProducts(lead, 700).size());
        System.assertEquals(50.53,
            productRepo.calcDTIAfter(product, lead, 6750, 3300).dtiAfter);
        System.assertEquals(50.61,
            lead.Personal_Credit_Report__r.DTI_After__c);
    }

    static testMethod void testProductRepoForJunctions() {
        Partner__c partner = [SELECT Id FROM Partner__c WHERE Name = 'Bluewave Inside Sales' LIMIT 1];
        Product2 product = [
            SELECT Id, Name, Product_Type__c, Program__c, State__c,
                Credit_Minimum__c, Credit_Maximum__c, Loan_Interest_Rate__c, Loan_Term__c
            FROM Product2
            WHERE Name = 'BlueWave Solar Loan - MA - 10 Year Term - 6.49% (Low FICO)'
            AND Require_Junctions_to_Enable__c = TRUE
            LIMIT 1
        ];
        // Let the product be seen by getActiveProducts below...
        product.Hide_in_Requested_Product__c = false;
        update product;
        Partner_Product_Junction__c ppj = new Partner_Product_Junction__c(Enabled_Product__c = product.Id,
            Partner__c = partner.Id);
        Product2 bwsl = [
            SELECT Id
            FROM Product2
            WHERE Name = 'BlueWave Solar Loan - MA - 10 Year Term - 5.99%'
            LIMIT 1
        ];
        insert ppj;
        Lead lead = getLead(81000, 10000, null, false, false, partner.Id);
        lead.Product__c = bwsl.Id;
        insert lead;

        lead.Status = 'Ready for Credit Check';
        update lead;

        Test.startTest();
        LASERCA__Personal_Credit_Report__c pcr =
            new LASERCA__Personal_Credit_Report__c(LASERCA__Lead__c = lead.Id,
                LASERCA__Credit_Score_TransUnion__c = '650');
        insert pcr;
        LASERCA__Trade_Accounts__c tradeacct =
            new LASERCA__Trade_Accounts__c(LASERCA__Personal_Credit_Report__c = pcr.id,
                LASERCA__Monthly_Payment__c = 300);
        insert tradeacct;
        insert getCRL(pcr);

        Test.stopTest();

        lead = [
            SELECT Id, DOER_Solar_Loan__c, Pre_Approval_Form__c, Status,
                Personal_Credit_Report__r.LASERCA__Sum_of_monthly_Personal_Debt__c,
                Personal_Credit_Report__r.DTI_After__c,
                Product_Line__c, Product_Program__c, LASERCA__Home_State__c, Loan_Principal__c,
                Income_Support__c, Partner_Lookup__c, Product__r.Name
            FROM Lead
            WHERE Id = :lead.Id
        ];

        System.assertEquals('BlueWave Solar Loan - MA - 10 Year Term - 6.49% (Low FICO)', lead.Product__r.Name);
        PCRApprovalHandler.ProductRepo productRepo = new PCRApprovalHandler.ProductRepo(new List<Lead>{
            lead
        });
        System.assertEquals('Pre-Qualified', lead.Status);
        System.assertEquals(1, productRepo.getApplicableProducts(lead, 650).size());
        System.assertEquals(10, productRepo.products.size());
        System.debug(LoggingLevel.ERROR, productRepo.products);
        System.assertEquals(8, Util.getActiveProducts(new List<String>{
            'MA'
        }, partner.Id, 'Residential Loan').size());
    }

    static testMethod void testProductRepoFor40k() {
        Partner__c partner = [SELECT Id FROM Partner__c WHERE Name = 'Bluewave Inside Sales' LIMIT 1];
        Product2 product = [
            SELECT Id, Name, Product_Type__c, Program__c, State__c,
                Credit_Minimum__c, Credit_Maximum__c, Loan_Interest_Rate__c, Loan_Term__c
            FROM Product2
            WHERE Name = 'BlueWave Solar Loan - MA - 10 Year Term - 6.49% (Low FICO)'
            AND Require_Junctions_to_Enable__c = TRUE
            LIMIT 1
        ];
        Partner_Product_Junction__c ppj = new Partner_Product_Junction__c(Enabled_Product__c = product.Id,
            Partner__c = partner.Id);
        insert ppj;
        Lead lead = getLead(81000, 50000, null, false, false, partner.Id);
        insert lead;

        lead.Status = 'Ready for Credit Check';
        update lead;

        Test.startTest();
        LASERCA__Personal_Credit_Report__c pcr =
            new LASERCA__Personal_Credit_Report__c(LASERCA__Lead__c = lead.Id,
                LASERCA__Credit_Score_TransUnion__c = '650');
        insert pcr;
        LASERCA__Trade_Accounts__c tradeacct =
            new LASERCA__Trade_Accounts__c(LASERCA__Personal_Credit_Report__c = pcr.id,
                LASERCA__Monthly_Payment__c = 300);
        insert tradeacct;
        insert getCRL(pcr);

        Test.stopTest();

        lead = [
            SELECT Id, DOER_Solar_Loan__c, Pre_Approval_Form__c, Status,
                Personal_Credit_Report__r.LASERCA__Sum_of_monthly_Personal_Debt__c,
                Personal_Credit_Report__r.DTI_After__c,
                Product_Line__c, Product_Program__c, LASERCA__Home_State__c, Loan_Principal__c,
                Income_Support__c, Partner_Lookup__c
            FROM Lead
            WHERE Id = :lead.Id
        ];

        PCRApprovalHandler.ProductRepo productRepo = new PCRApprovalHandler.ProductRepo(new List<Lead>{
            lead
        });
        System.assertEquals('Unqualified', lead.Status);
        System.assertEquals(0, productRepo.getApplicableProducts(lead, 650).size());
    }

    static testMethod void testNoIBLSInDTI() {
        Test.startTest();
        Partner__c partner = [SELECT Id FROM Partner__c WHERE Name = 'Bluewave Inside Sales' LIMIT 1];
        Product2 mslp = LoanTestRecordWarehouse.getDefaultProduct('MA', 5.99, 10, null, '681', '999', null);
        mslp.Program__c = 'MSLP';
        insert mslp;
        Lead lead = getLead(60000, 10000, null, true, false, partner.Id);
        insert lead;

        lead.Status = 'Pending Information';
        update lead;

        LASERCA__Personal_Credit_Report__c pcr =
            new LASERCA__Personal_Credit_Report__c(LASERCA__Lead__c = lead.Id,
                LASERCA__Credit_Score_TransUnion__c = '700');
        insert pcr;
        LASERCA__Trade_Accounts__c tradeacct =
            new LASERCA__Trade_Accounts__c(LASERCA__Personal_Credit_Report__c = pcr.id,
                LASERCA__Monthly_Payment__c = 1000);
        insert tradeacct;
        insert getCRL(pcr);

        Test.stopTest();

        lead = [
            SELECT Id, DOER_Solar_Loan__c, Pre_Approval_Form__c, Status,
                Personal_Credit_Report__r.LASERCA__Sum_of_monthly_Personal_Debt__c,
                Personal_Credit_Report__r.DTI_After__c,
                Product_Line__c, Product_Program__c, LASERCA__Home_State__c, Loan_Principal__c,
                Income_Support__c, Partner_Lookup__c, IBLS_Category__c
            FROM Lead
            WHERE Id = :lead.Id
        ];

        PCRApprovalHandler.ProductRepo productRepo = new PCRApprovalHandler.ProductRepo(new List<Lead>{
            lead
        });
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

    static testMethod void testGrossedUpDTIforAdjustable() {
        Index_Rate__c ir = new Index_Rate__c(
            Index_Rate_Type__c = 'WSJ Prime Rate',
            Index_Rate__c = 8
        );
        insert ir;

        Test.startTest();
        Partner__c partner = [SELECT Id FROM Partner__c WHERE Name = 'Bluewave Inside Sales' LIMIT 1];
        Product2 arl = new Product2(name = 'BlueWave Solar Loan - MA',
            State__c = 'NJ',
            Family = 'Solar Loan',
            Product_Type__c = 'Residential Loan',
            Program__c = 'BlueWave Solar Loan',
            IsActive = TRUE,
            ProductCode = 'x',
            Loan_Term__c = 120,
            Loan_Interest_Rate__c = 5.99,
            Loan_Interest_Only_Period__c = 12,
            Debt_To_Income_Maximum__c = 50,
            Credit_Minimum__c = '681',
            Credit_Maximum__c = '999',
            Disbursal_Terms__c = '30% Contract Signature, 60% Mechanical Installation, 10% Interconnection',
            Loan_Financing_Fee_Terms__c = 'Maximum (5%, $1,250)',
            First_Adjustment__c = 61,
            Floor_Rate__c = 1,
            Ceiling_Rate__c = 10,
            Index_Rate_for_Adjustment__c = 'WSJ Prime Rate',
            Margin_Over_Index_Rate__c = .5,
            Maximum_Adjustment__c = 1,
            Months_Between_Adjustment__c = 12,
            DTI_After_Rate_Gross_Up__c = 2
        );
        insert arl;
        Lead lead = getLead(60000, 10000, arl.Id, false, false, partner.Id);
        lead.LASERCA__Home_State__c = 'NJ';
        insert lead;

        lead.Status = 'Pending Information';
        update lead;

        LASERCA__Personal_Credit_Report__c pcr =
            new LASERCA__Personal_Credit_Report__c(LASERCA__Lead__c = lead.Id,
                LASERCA__Credit_Score_TransUnion__c = '700');
        insert pcr;
        LASERCA__Trade_Accounts__c tradeacct =
            new LASERCA__Trade_Accounts__c(LASERCA__Personal_Credit_Report__c = pcr.id,
                LASERCA__Monthly_Payment__c = 1000);
        insert tradeacct;
        insert getCRL(pcr);

        Test.stopTest();

        lead = [
            SELECT Id, DOER_Solar_Loan__c, Pre_Approval_Form__c, Status,
                Personal_Credit_Report__r.LASERCA__Sum_of_monthly_Personal_Debt__c,
                Personal_Credit_Report__r.DTI_After__c,
                Product_Line__c, Product_Program__c, LASERCA__Home_State__c, Loan_Principal__c,
                Income_Support__c, Partner_Lookup__c, IBLS_Category__c
            FROM Lead
            WHERE Id = :lead.Id
        ];

        PCRApprovalHandler.ProductRepo productRepo = new PCRApprovalHandler.ProductRepo(new List<Lead>{lead});
        System.assertEquals(lead.Personal_Credit_Report__r.LASERCA__Sum_of_monthly_Personal_Debt__c, 1000);
        // DTI After with IBLS is 21.55, non-grossed up DTI After is 22.22
        System.assertEquals(22.43,
            productRepo.calcDTIAfter(arl, lead, 5000, 1000).dtiAfter);
        System.assertEquals(22.43,
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
            Product_Program__c = doerLoan ? 'MSLP' : 'BlueWave Solar Loan',
            LASERCA__Home_State__c = 'MA',
            Unfinished_Lead__c = true,
            Pre_Approval_Form__c = preApproval));
    }

    private static LASERCA__Credit_Report_Log__c getCRL(LASERCA__Personal_Credit_Report__c pcr) {
        return new LASERCA__Credit_Report_Log__c(LASERCA__Personal_Credit_Report__c = pcr.Id,
            LASERCA__Status__c = 'Completed');
    }

    // Trade Accounts seem to be inserted in multiple transactions - we should make sure they're all 
    // committed before 
    static testMethod void testMultipleTradeAccountInserts() {
        Partner__c partner = [SELECT Id FROM Partner__c WHERE Name = 'Bluewave Inside Sales' LIMIT 1];
        Lead lead = getLead(50000, 1000000, null, false, false, partner.Id);
        insert lead;

        Test.startTest();
        LASERCA__Personal_Credit_Report__c pcr =
            new LASERCA__Personal_Credit_Report__c(LASERCA__Lead__c = lead.Id,
                LASERCA__Credit_Score_TransUnion__c = '700');
        insert pcr;
        LASERCA__Trade_Accounts__c tradeacct =
            new LASERCA__Trade_Accounts__c(LASERCA__Personal_Credit_Report__c = pcr.id,
                LASERCA__Monthly_Payment__c = 1970);
        insert tradeacct;

        pcr = [
            SELECT Id, Solar_Loan_Approval_Status__c, LASERCA__Credit_Score_TransUnion__c,
                DTI_After__c, DTI_After_Notes__c, LASERCA__Sum_of_monthly_Personal_Debt__c
            FROM LASERCA__Personal_Credit_Report__c
            WHERE LASERCA__Lead__c = :lead.Id
            LIMIT 1
        ];

        System.assertEquals(1970, pcr.LASERCA__Sum_of_monthly_Personal_Debt__c);
        System.assertEquals(null, pcr.DTI_After__c);

        LASERCA__Trade_Accounts__c tradeacct2 =
            new LASERCA__Trade_Accounts__c(LASERCA__Personal_Credit_Report__c = pcr.id,
                LASERCA__Monthly_Payment__c = 1970);
        insert tradeacct2;

        pcr = [
            SELECT Id, Solar_Loan_Approval_Status__c, LASERCA__Credit_Score_TransUnion__c,
                DTI_After__c, DTI_After_Notes__c, LASERCA__Sum_of_monthly_Personal_Debt__c
            FROM LASERCA__Personal_Credit_Report__c
            WHERE LASERCA__Lead__c = :lead.Id
            LIMIT 1
        ];

        System.assertEquals(3940, pcr.LASERCA__Sum_of_monthly_Personal_Debt__c);

        System.assertEquals(null, pcr.DTI_After__c);

        insert getCRL(pcr);
        Test.stopTest();

        pcr = [
            SELECT Id, Solar_Loan_Approval_Status__c, LASERCA__Credit_Score_TransUnion__c,
                DTI_After__c, DTI_After_Notes__c, LASERCA__Sum_of_monthly_Personal_Debt__c
            FROM LASERCA__Personal_Credit_Report__c
            WHERE LASERCA__Lead__c = :lead.Id
            LIMIT 1
        ];

        System.assertEquals(373.10, pcr.DTI_After__c);
        System.assertEquals(PCRApprovalHandler.PENDINGREVIEW, pcr.Solar_Loan_Approval_Status__c);
    }

    static testMethod void testRegO() {
        Partner__c partner = [SELECT Id FROM Partner__c WHERE Name = 'Bluewave Inside Sales' LIMIT 1];
        List<Lead> insertleads = new List<Lead>();
        List<LASERCA__Personal_Credit_Report__c> insertpcrlist = new List<LASERCA__Personal_Credit_Report__c>();
        List<LASERCA__Trade_Accounts__c> inserttradeacct = new List<LASERCA__Trade_Accounts__c>();

        Product2 productVar = LoanTestRecordWarehouse.getDefaultProduct('MA', 5.99, 10, null, '681', '999', null);
        Product2 mslp = LoanTestRecordWarehouse.getDefaultProduct('MA', 5.99, 10, null, '681', '999', null);
        mslp.Program__c = 'MSLP';
        insert new List<Product2>{
            productVar, mslp
        };
        Lead leadAG = getLead(90000, 20000, productVar.Id, false, true, partner.Id);
        leadAG.Avidia_Service_Provider__c = true;
        leadAG.Avidia_Executive__c = true;
        insert leadAG;

        Test.startTest();
        LASERCA__Personal_Credit_Report__c pcrAG = new LASERCA__Personal_Credit_Report__c(LASERCA__Lead__c = leadAG.Id,
            LASERCA__Credit_Score_TransUnion__c = '815');
        insert pcrAG;
        LASERCA__Trade_Accounts__c tradeacctAG = new LASERCA__Trade_Accounts__c(LASERCA__Personal_Credit_Report__c = pcrAG.id,
            LASERCA__Monthly_Payment__c = 200);
        insert tradeacctAG;
        insert getCRL(pcrAG);
        Test.stopTest();

        PCRApprovalHandler.alreadyRan = false;
        PCRApprovalHandler.noDelay = true;
        update pcrAG;

        pcrAG = [
            SELECT Id, Solar_Loan_Approval_Status__c, LASERCA__Credit_Score_TransUnion__c, DTI_Before__c,
                LASERCA__Lead__r.Status, LASERCA__Contact__c
            FROM LASERCA__Personal_Credit_Report__c
            WHERE LASERCA__Credit_Score_TransUnion__c = '815'
        ];

        System.assertEquals('Pending Credit Review', pcrAG.LASERCA__Lead__r.Status);
    }

    // fico+income is used as a unique key!
    public class Application {
        public Integer income, loan;
        public Id prodId;
        public Boolean doer;
        public String ibls, applicationType;
        public Integer coAppIncome;
        public Integer fico, debt, balance;
        public String code1, code2, code3, code4;
        public Id leadId, pcrId;
        public String expectedSLAStatus, expectedStatus;
        public Boolean denialSent;
        public Decimal expectedDTIBefore, expectedDTIAfter;
        public void assert(LASERCA__Personal_Credit_Report__c pcr) {
            System.debug(LoggingLevel.ERROR, 'Assertions for FICO ' + fico);
            if (expectedSLAStatus != null) {
                System.assertEquals(expectedSLAStatus, pcr.Solar_Loan_Approval_Status__c);
            }
            if (expectedStatus != null) {
                System.assertEquals(expectedStatus, pcr.LASERCA__Lead__r.Status);
            }
            if (denialSent != null) {
                System.assertEquals(denialSent, pcr.Credit_Denial_Email_Sent__c);
            }
            if (expectedDTIBefore != null) {
                System.assertEquals(expectedDTIBefore, pcr.DTI_Before__c.setScale(2));
            }
            if (expectedDTIAfter != null) {
                System.assertEquals(expectedDTIAfter, pcr.DTI_After__c.setScale(2));
            }
        }
        public Integer getKey() {
            return ((Integer) (Util.nullToZero(fico) + Util.nullToZero(income)));
        }
    }
    public class ApplicationSet {
        public List<Application> application;
        public Map<Integer, Application> applicationMap;

        public void insertLeads(Id partnerId) {
            List<Lead> leads = new List<Lead>();
            for (Application app : application) {
                leads.add(new Lead(LastName = 'Testcase',
                    FirstName = 'test',
                    Automatic_Product_Assignment__c = false,
                    Email = 'test@email.com',
                    Company = 'Cloud Jedi',
                    Status = 'Ready for Credit Check',
                    Partner_Lookup__c = partnerId,
                    Annual_Income_Currency__c = app.income,
                    Loan_Amount__c = app.loan,
                    Requested_Loan_Amount__c = app.loan,
                    Product__c = app.prodId,
                    DOER_Solar_Loan__c = app.doer,
                    Product_Line__c = 'Residential Loan',
                    Product_Program__c = app.doer ? 'MSLP' : 'BlueWave Solar Loan',
                    LASERCA__Home_State__c = 'MA',
                    Unfinished_Lead__c = true,
                    Pre_Approval_Form__c = true,
                    IBLS_Category__c = app.ibls,
                    Application_Type__c = app.applicationType,
                    Co_Applicant_Income__c = app.coAppIncome,
                    // Just need a key to use later
                    AnnualRevenue = app.getKey()));
            }
            insert leads;
            Map<Integer, Id> incomeToLeadID = new Map<Integer, Id>();
            for (Lead l : leads) {
                incomeToLeadID.put((Integer) l.AnnualRevenue, l.Id);
            }
            for (Application app : application) {
                app.leadId = incomeToLeadID.get(app.getKey());
            }
        }

        public void insertPCRs() {
            List<LASERCA__Personal_Credit_Report__c> pcrs = new List<LASERCA__Personal_Credit_Report__c>();
            for (Application app : application) {
                pcrs.add(new LASERCA__Personal_Credit_Report__c(
                    LASERCA__Lead__c = app.leadId,
                    LASERCA__Code__c = app.code1,
                    LASERCA__Code_2__c = app.code2,
                    LASERCA__Code_3__c = app.code3,
                    LASERCA__Code_4__c = app.code4,
                    LASERCA__Credit_Score_TransUnion__c = (app.fico!=null?String.valueOf(app.fico):null)));
            }
            insert pcrs;
            Map<Id, Id> leadIdToPCRId = new Map<Id, Id>();
            for (LASERCA__Personal_Credit_Report__c pcr : pcrs) {
                leadIdToPCRId.put(pcr.LASERCA__Lead__c, pcr.Id);
            }
            for (Application app : application) {
                app.pcrId = leadIdToPCRId.get(app.leadId);
                applicationMap.put(app.fico, app);
            }
        }

        public void insertTradeAccounts() {
            List<LASERCA__Trade_Accounts__c> tradeAccts = new List<LASERCA__Trade_Accounts__c>();
            for (Application app : application) {
                tradeAccts.add(new LASERCA__Trade_Accounts__c(
                    LASERCA__Personal_Credit_Report__c = app.pcrId,
                    LASERCA__Monthly_Payment__c = app.debt,
                    LASERCA__Account_Balance__c = app.balance
                ));
            }
            insert tradeAccts;
        }

        public void insertCreditReportLogs() {
            List<LASERCA__Credit_Report_Log__c> crls = new List<LASERCA__Credit_Report_Log__c>();
            for (Application app : application) {
                crls.add(new LASERCA__Credit_Report_Log__c(
                    LASERCA__Personal_Credit_Report__c = app.pcrId,
                    LASERCA__Status__c = 'Completed'));
            }
            insert crls;
        }

        public LASERCA__Personal_Credit_Report__c getPCR(Integer fico) {
            return(new LASERCA__Personal_Credit_Report__c(Id = applicationMap.get(fico).pcrId));
        }

        public Lead getLead(Integer fico) {
            return(new Lead(Id = applicationMap.get(fico).leadId));
        }
    }
    public static ApplicationSet parse(String json) {
        ApplicationSet appSet = (ApplicationSet) System.JSON.deserialize(json, ApplicationSet.class);
        appSet.applicationMap = new Map<Integer, Application>();
        return appSet;
    }
}