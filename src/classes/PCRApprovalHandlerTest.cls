@isTest
private class PCRApprovalHandlerTest {
    @testSetup public static void setupTestData() {
        Test.startTest();
        LoanTestRecordWarehouse.partnerSetup();
        insert LoanTestRecordWarehouse.getLoanProductsVariableInterestRatesandTerms();
        Test.stopTest();
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
                '  {"key":1, "income":20000, "loan":65000, "doer":false, "fico":680, "debt":500, "balance":10000, "expectedSLAStatus":"Declined"}, ' +
                '  {"key":2, "income":1000,  "loan":65000, "doer":false, "fico":402, "debt":500, "balance":10000, "expectedSLAStatus":"Approved"}, ' +
                '  {"key":3, "income":90000, "loan":20000, "doer":false, "fico":801, "debt":1000, "expectedSLAStatus":"Approved"}, ' +
                '  {"key":4, "income":90000, "loan":20000, "doer":false, "fico":805, "debt":200}, ' +
                '  {"key":5, "income":90000, "loan":20000, "doer":false, "fico":810, "debt":200, "expectedStatus":"Unqualified"}, ' +
                '  {"key":6, "income":90000, "loan":20000, "doer":false, "fico":815, "debt":200, "expectedStatus":"Pending Credit Review"}, ' +
                '  {"key":7, "income":100000,"loan":30000, "doer":false, "fico":678, "debt":200, "sendEmails":true, "denialSent":true}, ' +
                '  {"key":8, "income":100000,"loan":30000, "doer":false, "fico":null, "expectedStatus":"Pending Credit Review", "sendEmails":true, "denialSent":false} ' +
                ']}';
        ApplicationSet applicationSet = parse(applicationJSON);
        applicationSet.insertLeads(partner.Id);
        applicationSet.insertPCRs();
        Test.startTest();
        applicationSet.insertTradeAccounts();
        applicationSet.insertCreditReportLogs();

        LASERCA__Personal_Credit_Report__c pcrAA = applicationSet.getPCR(2);
        pcrAA.Solar_Loan_Manual_Approval__c = true;
        LASERCA__Personal_Credit_Report__c pcrAF = applicationSet.getPCR(5);
        pcrAF.Avidia_Review_Status__c = 'Reviewed - Declined';
        LASERCA__Personal_Credit_Report__c pcrAG = applicationSet.getPCR(6);
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

    @isTest
    static void testCoSigners() {
        Partner__c partner = [SELECT Id FROM Partner__c WHERE Name = 'Bluewave Inside Sales' LIMIT 1];
        Account coApplicantAccount = new Account(Name = 'CoapplicantAccount');
        insert coApplicantAccount;

        Product2 bwsl1 = LoanTestRecordWarehouse.getDefaultProduct('MA', 5.99, 10, null, '681', '999', null);
        bwsl1.Disbursal_Terms__c = '35% Contract Signature, 65% Interconnection';
        bwsl1.Lender_of_Record__c = 'Avidia';

        Product2 mslp1 = LoanTestRecordWarehouse.getDefaultProduct('MA', 5.99, 10, null, '681', '999', null);
        mslp1.Disbursal_Terms__c = '35% Contract Signature, 65% Interconnection';
        mslp1.Lender_of_Record__c = 'Avidia';
        mslp1.Program__c = 'MSLP';
        mslp1.IBLS_Category__c = 'Category 1';

        Product2 mslp2 = LoanTestRecordWarehouse.getDefaultProduct('MA', 4.99, 10, null, '681', '999', null);
        mslp2.Disbursal_Terms__c = '35% Contract Signature, 65% Interconnection';
        mslp2.Lender_of_Record__c = 'Avidia';
        mslp2.Program__c = 'MSLP';
        mslp2.IBLS_Category__c = 'Category 2';
        insert new List<Product2>{bwsl1, mslp1, mslp2};

        String applicationJSON =
            '{"application":[ ' +
                '  {"key":1, "income":50000, "loan":45000, "doer":true,  "fico":570, "coAppFico":600, "ibls":"Category 1", "debt":400, "balance":2000, "coAppIncome":2000, "applicationType":"Joint Co-Sign", "expectedStatus":"Pending Credit Review", "expectedDTIBefore":9.60, "expectedDTIAfter":9.60}, ' +
                '  {"key":2, "income":50000, "loan":45000, "doer":true,  "fico":820, "coAppFico":600, "ibls":"Category 1", "debt":400, "balance":2000, "coAppIncome":2000, "applicationType":"Joint Co-Sign", "expectedStatus":"Pending Credit Review", "expectedDTIBefore":9.60, "expectedDTIAfter":21.58} ' +
                ']}';
        ApplicationSet applicationSet = parse(applicationJSON);
        applicationSet.insertLeads(partner.Id);
        applicationSet.insertPCRs();
        applicationSet.connectJointPCRs();
        applicationSet.insertTradeAccounts();
        applicationSet.insertCreditReportLogs();

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
        mslp1.Disbursal_Terms__c = '35% Contract Signature, 65% Interconnection';
        mslp1.Lender_of_Record__c = 'Avidia';
        mslp1.IBLS_Category__c = 'Category 2';

        Product2 mslp2 = LoanTestRecordWarehouse.getDefaultProduct('MA', 4.99, 10, null, '650', '680', null);
        mslp2.Disbursal_Terms__c = '35% Contract Signature, 65% Interconnection';
        mslp2.Lender_of_Record__c = 'Avidia';
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

    static testMethod void testMortgageTradeAccount() {
        //Test for both main applicant and Co-applicant
        Partner__c partner = [SELECT Id FROM Partner__c WHERE Name = 'Bluewave Inside Sales' LIMIT 1];

        String applicationJSON =
            '{"application":[ ' +
                '  {"key":1, "income":200003, "coAppIncome":1, "loan":65000, "applicationType":"Joint Co-App", "doer":false, "fico":700, "coAppFico":400, "debt":500, "balance":10000, "expectedStatus":"Pending Credit Review"}, ' +
                '  {"key":2, "income":14000, "loan":15000, "doer":true,  "fico":800, "ibls":"Category 1", "debt":500, "expectedSLAStatus":"Declined"} ' +
                + ']}';
        ApplicationSet applicationSet = parse(applicationJSON);
        applicationSet.insertLeads(partner.Id);
        applicationSet.insertPCRs();
        applicationSet.connectJointPCRs();
        applicationSet.insertTradeAccounts();
        applicationSet.insertCreditReportLogs();

        Test.startTest();

        List<LASERCA__Personal_Credit_Report__c> pcrList = [
            SELECT Id, LASERCA__Contact__c, LASERCA__Credit_Score_TransUnion__c,
            (SELECT LASERCA__Monthly_Payment__c, Exclude_From_Rollup__c
            FROM LASERCA__Trade_Accounts__r
            WHERE Name = 'Self-Reported Mortgage')
            FROM LASERCA__Personal_Credit_Report__c
        ];

        //How do I not have the SOQL in the loop?
        for (LASERCA__Personal_Credit_Report__c pcr : pcrList) {
            LASERCA__Trade_Accounts__c mortgage = [
                SELECT LASERCA__Monthly_Payment__c, Exclude_From_Rollup__c
                FROM LASERCA__Trade_Accounts__c
                WHERE LASERCA__Personal_Credit_Report__c = :pcr.Id AND Name = 'Self-Reported Mortgage'
                LIMIT 1
            ];

            if (pcr.LASERCA__Contact__c != null) {
                //Co-App's mortgage
                System.assertEquals(500, mortgage.LASERCA__Monthly_Payment__c);
                System.assertEquals(true, mortgage.Exclude_From_Rollup__c);
            } else {
                //Main applicant's mortgage
                System.assertEquals(1000, mortgage.LASERCA__Monthly_Payment__c);
                System.assertEquals(true, mortgage.Exclude_From_Rollup__c);
            }
        }
        Test.stopTest();
    }

    static testMethod void testPreQualified() {
        Partner__c partner = [SELECT Id FROM Partner__c WHERE Name = 'Bluewave Inside Sales' LIMIT 1];
        Product2 productVar = LoanTestRecordWarehouse.getDefaultProduct('MA', 5.99, 10, null, '681', '999',  null);
        productVar.Disbursal_Terms__c = '35% Contract Signature, 65% Interconnection';
        productVar.Lender_of_Record__c = 'Avidia';

        Product2 mslp = LoanTestRecordWarehouse.getDefaultProduct('MA', 5.99, 10, null, '681', '999',  null);
        mslp.Disbursal_Terms__c = '35% Contract Signature, 65% Interconnection';
        mslp.Lender_of_Record__c = 'Avidia';
        mslp.Program__c = 'MSLP';
        insert new List<Product2>{productVar, mslp};

        Lead leadAG = newLead(90000, 20000, productVar.Id, false, partner.Id);
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

    static testMethod void testPCRProductUpdate() {
        Partner__c partner = [SELECT Id FROM Partner__c WHERE Name = 'Bluewave Inside Sales' LIMIT 1];
        Product2 productVar = LoanTestRecordWarehouse.getDefaultProduct('MA', 5.99, 10, null, '681', '999',  null);
        productVar.Disbursal_Terms__c = '35% Contract Signature, 65% Interconnection';
        productVar.Lender_of_Record__c = 'Avidia';
        insert productVar;

        Lead leadAG = newLead(90000, 20000, null, false, partner.Id);
        insert leadAG;
        System.assertEquals(null, leadAG.Product__c);
        LoanHandlerTestClass.convertleads(new List<Lead>{leadAG});
        Opportunity opp = [SELECT Id, Product__c FROM Opportunity WHERE Lead__c = :leadAG.Id];
        System.assertEquals(null, opp.Product__c);
        leadAG.Status = 'Ready for Credit Check';
        update leadAG;
        Test.startTest();
        LASERCA__Personal_Credit_Report__c pcrAG = new LASERCA__Personal_Credit_Report__c(LASERCA__Lead__c = leadAG.Id,
            LASERCA__Credit_Score_TransUnion__c = '815');
        insert pcrAG;
        LASERCA__Trade_Accounts__c tradeacctAG = new LASERCA__Trade_Accounts__c(LASERCA__Personal_Credit_Report__c = pcrAG.id,
            LASERCA__Monthly_Payment__c = 200);
        insert tradeacctAG;
        insert getCRL(pcrAG);

        Test.stopTest();

        pcrAG = [
            SELECT Id, Solar_Loan_Approval_Status__c, LASERCA__Credit_Score_TransUnion__c, DTI_Before__c,
                LASERCA__Lead__r.Status, LASERCA__Contact__c, LASERCA__Lead__r.Product__c
            FROM LASERCA__Personal_Credit_Report__c
            WHERE LASERCA__Credit_Score_TransUnion__c = '815'
        ];

        System.assertEquals(false, pcrAG.LASERCA__Lead__r.Product__c==null);
        opp = [SELECT Id, Product__c FROM Opportunity WHERE Lead__c = :leadAG.Id];
        System.assertEquals(pcrAG.LASERCA__Lead__r.Product__c, opp.Product__c);
    }

    static testMethod void testPCRProductDoNotUpdate() {
        Util.disableTrigger('Disable_OpportunityTrigger__c');
        Partner__c partner = [SELECT Id FROM Partner__c WHERE Name = 'Bluewave Inside Sales' LIMIT 1];
        Product2 productVar = LoanTestRecordWarehouse.getDefaultProduct('MA', 5.99, 10, null, '681', '999',  null);
        productVar.Disbursal_Terms__c = '35% Contract Signature, 65% Interconnection';
        productVar.Lender_of_Record__c = 'Avidia';
        productVar.Debt_To_Income_Maximum__c = 1;

        insert productVar;

        Lead leadAG = newLead(90000, 20000, null, false, partner.Id);
        insert leadAG;
        System.assertEquals(null, leadAG.Product__c);
        LoanHandlerTestClass.convertleads(new List<Lead>{leadAG});
        leadAG.Status = 'Ready for Credit Check';
        update leadAG;
        LASERCA__Personal_Credit_Report__c pcrAG = new LASERCA__Personal_Credit_Report__c(
            LASERCA__Lead__c = leadAG.Id,
            LASERCA__Credit_Score_TransUnion__c = '815',
            CreatedDate = Datetime.now().addMinutes(-1)
        );
        insert pcrAG;
        LASERCA__Trade_Accounts__c tradeacctAG = new LASERCA__Trade_Accounts__c(LASERCA__Personal_Credit_Report__c = pcrAG.id,
            LASERCA__Monthly_Payment__c = 200);
        insert tradeacctAG;
        insert getCRL(pcrAG);

        Test.startTest();

        leadAg.Product__c = productVar.Id;
        update leadAG;

        tradeacctAG.Exclude_From_Rollup__c = true;
        update tradeacctAG;

        pcrAG.Avidia_Review_Status__c = 'Reviewed - PreApproved';
        update pcrAG;
        Test.stopTest();

        Lead updatedLead = [
            SELECT Id, Product__c, Personal_Credit_Report__r.DTI_After__c
            FROM Lead
            WHERE Id =: leadAG.Id
        ];

        System.assertNotEquals(pcrAG.DTI_After__c, updatedLead.Personal_Credit_Report__r.DTI_After__c);
        System.assertEquals(productVar.Id, updatedLead.Product__c);
    }

    static testMethod void testPCRProductDoesUpdate() {
        Util.disableTrigger('Disable_OpportunityTrigger__c');
        Partner__c partner = [SELECT Id FROM Partner__c WHERE Name = 'Bluewave Inside Sales' LIMIT 1];
        Product2 productVar = LoanTestRecordWarehouse.getDefaultProduct('MA', 5.99, 10, null, '681', '999',  null);
        productVar.Disbursal_Terms__c = '35% Contract Signature, 65% Interconnection';
        productVar.Lender_of_Record__c = 'Avidia';
        productVar.Debt_To_Income_Maximum__c = 1;

        insert productVar;

        Lead leadAG = newLead(90000, 20000, null, false, partner.Id);
        insert leadAG;
        System.assertEquals(null, leadAG.Product__c);
        LoanHandlerTestClass.convertleads(new List<Lead>{leadAG});
        leadAG.Status = 'Ready for Credit Check';
        update leadAG;
        LASERCA__Personal_Credit_Report__c pcrAG = new LASERCA__Personal_Credit_Report__c(
            LASERCA__Lead__c = leadAG.Id,
            LASERCA__Credit_Score_TransUnion__c = '815',
            CreatedDate = Datetime.now().addMinutes(-1)
        );
        insert pcrAG;
        LASERCA__Trade_Accounts__c tradeacctAG = new LASERCA__Trade_Accounts__c(LASERCA__Personal_Credit_Report__c = pcrAG.id,
            LASERCA__Monthly_Payment__c = 200);
        insert tradeacctAG;
        insert getCRL(pcrAG);

        Test.startTest();

        leadAg.Product__c = productVar.Id;
        update leadAG;

        tradeacctAG.Exclude_From_Rollup__c = true;
        update tradeacctAG;

        Lead updatedLead = [
            SELECT Id, Product__c, Personal_Credit_Report__r.DTI_After__c
            FROM Lead
            WHERE Id =: leadAG.Id
        ];

        Test.stopTest();

        System.assertNotEquals(pcrAG.DTI_After__c, updatedLead.Personal_Credit_Report__r.DTI_After__c);
        System.assertEquals(productVar.Id, updatedLead.Product__c);

        updatedLead.Product__c = null;
        update updatedLead;

        pcrAG.Avidia_Review_Status__c = 'Reviewed - PreApproved';
        update pcrAG;

        updatedLead = [
            SELECT Id, Product__c, Personal_Credit_Report__r.DTI_After__c
            FROM Lead
            WHERE Id =: leadAG.Id
        ];

        System.assertNotEquals(pcrAG.DTI_After__c, updatedLead.Personal_Credit_Report__r.DTI_After__c);
        System.assertNotEquals(productVar.Id, updatedLead.Product__c);
    }

    static testMethod void testExclude() {
        Partner__c partner = [SELECT Id FROM Partner__c WHERE Name = 'Bluewave Inside Sales' LIMIT 1];
        Product2 productVar = LoanTestRecordWarehouse.getDefaultProduct('MA', 5.99, 10, null, '681', '999',  null);
        productVar.Disbursal_Terms__c = '35% Contract Signature, 65% Interconnection';
        productVar.Lender_of_Record__c = 'Avidia';
        insert productVar;

        Test.startTest();
        Lead lead = newLead(50000, 45000, productVar.Id, true, partner.Id);
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
        Lead lead = newLead(50000, 1000000, null, false, partner.Id);
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
        Lead lead = newLead(81000, 10000, null, true, partner.Id);
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
        Lead lead = newLead(81000, 10000, null, false, partner.Id);
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
            SELECT Id, DOER_Solar_Loan__c, Status,
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
        Lead lead = newLead(81000, 10000, null, false, partner.Id);
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
            SELECT Id, DOER_Solar_Loan__c, Status,
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
        Lead lead = newLead(81000, 50000, null, false, partner.Id);
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
            SELECT Id, DOER_Solar_Loan__c, Status,
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
        Product2 mslp = LoanTestRecordWarehouse.getDefaultProduct('MA', 5.99, 10, null, '681', '999',  null);
        mslp.Disbursal_Terms__c = '35% Contract Signature, 65% Interconnection';
        mslp.Lender_of_Record__c = 'Avidia';
        mslp.Program__c = 'MSLP';
        insert mslp;

        Lead lead = newLead(60000, 10000, null, true, partner.Id);
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
            SELECT Id, DOER_Solar_Loan__c, Status,
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
        Lead lead = newLead(60000, 10000, arl.Id, false, partner.Id);
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
            SELECT Id, DOER_Solar_Loan__c, Status,
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

    static testMethod void testJointApplication() {
        Partner__c partner = [SELECT Id FROM Partner__c WHERE Name = 'Bluewave Inside Sales' LIMIT 1];
        Product2 bwsl1 = LoanTestRecordWarehouse.getDefaultProduct('MA', 5.99, 10, null, '681', '999', null);

        Product2 mslp1 = LoanTestRecordWarehouse.getDefaultProduct('MA', 5.99, 10, null, '681', '999', null);
        mslp1.Program__c = 'MSLP';
        mslp1.IBLS_Category__c = 'Category 1';

        Product2 mslp2 = LoanTestRecordWarehouse.getDefaultProduct('MA', 4.99, 10, null, '681', '999', null);
        mslp2.Program__c = 'MSLP';
        mslp2.IBLS_Category__c = 'Category 2';
        insert new List<Product2>{bwsl1, mslp1, mslp2};

        // should add tests that go off lead debt fields...
        String applicationJSON =
            '{"application":[ ' +
                '  {"key":1, "income":200001, "coAppIncome":1, "loan":65000, "applicationType":"Joint Co-App", "doer":false, "fico":401, "coAppFico":401, "debt":500, "balance":10000, "expectedStatus":"Unqualified"}, ' +
                '  {"key":2, "income":2, "coAppIncome":1, "loan":65000, "applicationType":"Joint Co-App", "doer":false, "fico":420, "coAppFico":401, "debt":500, "balance":10000, "expectedStatus":"Unqualified"}, ' +
                '  {"key":3, "income":200002, "coAppIncome":1, "loan":65000, "applicationType":"Joint Co-App", "doer":false, "fico":699, "coAppFico":699, "debt":500, "balance":10000, "expectedStatus":"Pre-Qualified"}, ' +
                '  {"key":4, "income":1, "coAppIncome":200002, "loan":65000, "applicationType":"Joint Co-App", "doer":false, "fico":699, "coAppFico":699, "debt":500, "balance":10000, "expectedStatus":"Pre-Qualified"}, ' +
                '  {"key":5, "income":10, "coAppIncome":200002, "loan":65000, "applicationType":"Joint Co-App", "doer":false, "fico":699, "coAppFico":699, "debt":500, "coAppDebt":10000, "balance":10000, "expectedStatus":"Pending Credit Review"}, ' +
                '  {"key":6, "income":200003, "coAppIncome":1, "loan":65000, "applicationType":"Joint Co-App", "doer":false, "fico":700, "coAppFico":400, "debt":500, "balance":10000, "expectedStatus":"Pending Credit Review"}, ' +
                '  {"key":7, "income":200004, "coAppIncome":1, "loan":65000, "applicationType":"Joint Co-App", "doer":false, "fico":400, "coAppFico":700, "debt":500, "balance":10000, "expectedStatus":"Pending Credit Review"}, ' +
                '  {"key":8, "income":6, "coAppIncome":1, "loan":65000, "applicationType":"Joint Co-App", "doer":false, "fico":700, "coAppFico":400, "debt":500, "balance":10000, "expectedStatus":"Pending Credit Review"}, ' +
                '  {"key":9, "income":5, "coAppIncome":1, "loan":65000, "applicationType":"Joint Co-App", "doer":false, "fico":400, "coAppFico":700, "debt":500, "balance":10000, "expectedStatus":"Pending Credit Review"} ' +
                ']}';

        ApplicationSet applicationSet = parse(applicationJSON);
        applicationSet.insertLeads(partner.Id);
        applicationSet.insertPCRs();
        Test.startTest();
        applicationSet.connectJointPCRs();
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

    private static Lead newLead(Integer annualIncome, Integer loanAmount, Id productId, Boolean doerLoan, Id partnerId) {
        RecordType solarLoanType = [
            SELECT Id
            FROM RecordType
            WHERE Name = 'BlueWave Solar Loan'
            AND SobjectType = 'Lead'
        ];
        return(new Lead(LastName = 'testcase',
            RecordTypeId = solarLoanType.Id,
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
            Unfinished_Lead__c = true));
    }

    private static LASERCA__Credit_Report_Log__c getCRL(LASERCA__Personal_Credit_Report__c pcr) {
        return new LASERCA__Credit_Report_Log__c(LASERCA__Personal_Credit_Report__c = pcr.Id,
            LASERCA__Status__c = 'Completed');
    }

    // Trade Accounts seem to be inserted in multiple transactions - we should make sure they're all 
    // committed before 
    static testMethod void testMultipleTradeAccountInserts() {
        Partner__c partner = [SELECT Id FROM Partner__c WHERE Name = 'Bluewave Inside Sales' LIMIT 1];
        Lead lead = newLead(50000, 1000000, null, false, partner.Id);
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
        productVar.Disbursal_Terms__c = '35% Contract Signature, 65% Interconnection';
        productVar.Lender_of_Record__c = 'Avidia';

        Product2 mslp = LoanTestRecordWarehouse.getDefaultProduct('MA', 5.99, 10, null, '681', '999',  null);
        mslp.Disbursal_Terms__c = '35% Contract Signature, 65% Interconnection';
        mslp.Lender_of_Record__c = 'Avidia';
        mslp.Program__c = 'MSLP';
        insert new List<Product2>{
            productVar, mslp
        };
        Lead leadAG = newLead(90000, 20000, productVar.Id, false, partner.Id);
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

    static testMethod void testCurrentBankruptcy() {
        Partner__c partner = [SELECT Id FROM Partner__c WHERE Name = 'Bluewave Inside Sales' LIMIT 1];
        Product2 bwsl1 = LoanTestRecordWarehouse.getDefaultProduct('MA', 5.99, 10, null, '681', '999', null);

        Product2 mslp1 = LoanTestRecordWarehouse.getDefaultProduct('MA', 5.99, 10, null, '681', '999', null);
        mslp1.Program__c = 'MSLP';
        mslp1.IBLS_Category__c = 'Category 1';

        Product2 mslp2 = LoanTestRecordWarehouse.getDefaultProduct('MA', 4.99, 10, null, '681', '999', null);
        mslp2.Program__c = 'MSLP';
        mslp2.IBLS_Category__c = 'Category 2';
        insert new List<Product2>{bwsl1, mslp1, mslp2};

        // should add tests that go off lead debt fields...
        String applicationJSON =
            '{"application":[ ' +
                '  {"key":1, "income":200001, "loan":65000, "fico":700, "publicRecord":"BankruptcyChapter7", "publicRecordStatus":"Filed", "debt":500, "balance":10000, "expectedStatus":"Unqualified"}, ' +
                '  {"key":2, "income":65112, "loan":28068, "fico":700, "publicRecord":"BankruptcyChapter13", "publicRecordStatus":"Filed", "debt":500, "balance":10000, "expectedStatus":"Unqualified"}, ' +
                '  {"key":3, "income":65112, "loan":28068, "fico":700, "publicRecord":"BankruptcyChapter7", "publicRecordStatus":"Discharged", "debt":500, "balance":10000, "expectedStatus":"Pre-Qualified"}, ' +
                '  {"key":4, "income":65112, "loan":28068, "fico":700, "publicRecord":"BankruptcyChapter7", "publicRecordStatus":"Dismissed", "debt":500, "balance":10000, "expectedStatus":"Pre-Qualified"}, ' +
                '  {"key":5, "income":65112, "loan":28068, "fico":700, "publicRecord":"BankruptcyChapter13", "publicRecordStatus":"Discharged", "debt":500, "balance":10000, "expectedStatus":"Pre-Qualified"}, ' +
                '  {"key":6, "income":65112, "loan":28068, "fico":700, "publicRecord":"BankruptcyChapter13", "publicRecordStatus":"Dismissed", "debt":500, "balance":10000, "expectedStatus":"Pre-Qualified"}, ' +
                '  {"key":7, "income":65112, "loan":28068, "fico":700, "publicRecord":"Foreclosure", "publicRecordStatus":"Unsatisfied", "debt":500, "balance":10000, "expectedStatus":"Pre-Qualified"} ' +
                ']}';

        ApplicationSet applicationSet = parse(applicationJSON);
        applicationSet.insertLeads(partner.Id);
        applicationSet.insertPCRs();

        Test.startTest();
        applicationSet.connectJointPCRs();
        applicationSet.insertTradeAccounts();
        applicationSet.insertPublicRecords();
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
    // fico+income is used as a unique key!

    static testMethod void testOppVoidStatusOnLeadDecline() {
        Partner__c partner = [SELECT Id FROM Partner__c WHERE Name = 'Bluewave Inside Sales' LIMIT 1];
        Product2 bwsl1 = LoanTestRecordWarehouse.getDefaultProduct('MA', 5.99, 10, null, '681', '999', null);

        Product2 mslp1 = LoanTestRecordWarehouse.getDefaultProduct('MA', 5.99, 10, null, '681', '999', null);
        mslp1.Program__c = 'MSLP';
        mslp1.IBLS_Category__c = 'Category 1';

        Product2 mslp2 = LoanTestRecordWarehouse.getDefaultProduct('MA', 4.99, 10, null, '681', '999', null);
        mslp2.Program__c = 'MSLP';
        mslp2.IBLS_Category__c = 'Category 2';
        insert new List<Product2>{
            bwsl1, mslp1, mslp2
        };

        String applicationJSON =
            '{"application":[ ' +
                '  {"key":1, "income":200001, "coAppIncome":0, "loan":65000, "applicationType":"Individual", "doer":false, "fico":450, "debt":500, "balance":10000, "expectedStatus":"Unqualified"}, ' +
                '  {"key":2, "income":2, "coAppIncome":0, "loan":65000, "applicationType":"Individual", "doer":false, "fico":450, "debt":500, "balance":10000, "expectedStatus":"Unqualified"}, ' +
                '  {"key":3, "income":200002, "coAppIncome":0, "loan":65000, "applicationType":"Individual", "doer":false, "fico":699, "debt":500, "balance":10000, "expectedStatus":"Pre-Qualified"} ' +
                ']}';
        ApplicationSet applicationSet = parse(applicationJSON);
        applicationSet.insertLeads(partner.Id);
        applicationSet.insertPCRs();
        PCRApprovalHandler.noDelay = true;
        LoanHandlerTestClass.convertleads(new List<Lead>{
            applicationSet.getLead(1),
            applicationSet.getLead(2),
            applicationSet.getLead(3)
        });
        Test.startTest();
        applicationSet.insertCreditReportLogs();
        Lead lead = applicationSet.getLead(1);
        Lead lead2 = applicationSet.getLead(2);
        Lead lead3 = applicationSet.getLead(3);

        Opportunity opp = [SELECT Id, StageName FROM Opportunity WHERE Lead__c = :lead.Id LIMIT 1];
        Opportunity opp2 = [SELECT Id, StageName FROM Opportunity WHERE Lead__c = :lead2.Id LIMIT 1];
        Opportunity opp3 = [SELECT Id, StageName FROM Opportunity WHERE Lead__c = :lead3.Id LIMIT 1];
        opp.StageName = 'Expired';
        update opp;

        System.assertEquals('Expired', opp.StageName);
        System.assertEquals('New', opp2.StageName);
        System.assertEquals('New', opp3.StageName);

        List<LASERCA__Personal_Credit_Report__c> pcrToUpdate = new List<LASERCA__Personal_Credit_Report__c>();
        LASERCA__Personal_Credit_Report__c pcr = applicationSet.getPCR(1);
        LASERCA__Personal_Credit_Report__c pcr2 = applicationSet.getPCR(2);
        LASERCA__Personal_Credit_Report__c pcr3 = applicationSet.getPCR(3);
        pcr.Avidia_Review_Status__c = 'Reviewed - Declined';
        pcr2.Avidia_Review_Status__c = 'Reviewed - Declined';
        pcr3.Avidia_Review_Status__c = 'Reviewed - Approved';
        pcrToUpdate.add(pcr);
        pcrToUpdate.add(pcr2);
        pcrToUpdate.add(pcr3);
        update pcrToUpdate;

        Opportunity updatedOpp = [SELECT Id, StageName FROM Opportunity WHERE Lead__c = :lead.Id LIMIT 1];
        Opportunity updatedOpp2 = [SELECT Id, StageName FROM Opportunity WHERE Lead__c = :lead2.Id LIMIT 1];
        Opportunity updatedOpp3 = [SELECT Id, StageName FROM Opportunity WHERE Lead__c = :lead3.Id LIMIT 1];
        Test.stopTest();
//      Asserts that the pcr trigger didn't change the 'Expired' opp status
        System.assertEquals('Expired', updatedOpp.StageName);
        System.assertEquals('Voided', updatedOpp2.StageName);
        System.assertEquals('New', updatedOpp3.StageName);
    }

    static testMethod void testZeroDebtPCRs() {
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
                '  {"key":1, "income":20000, "loan":65000, "doer":false, "fico":680, "debt":0, "balance":0, "expectedSLAStatus":"Approved"} ' +
                ']}';
        ApplicationSet applicationSet = parse(applicationJSON);
        applicationSet.insertLeads(partner.Id);
        applicationSet.insertPCRs();
        Test.startTest();
        applicationSet.insertTradeAccounts();
        applicationSet.insertCreditReportLogs();

        List<Lead> leads = [
            SELECT Id, Personal_Credit_Report__c, Personal_Credit_Report__r.LASERCA__Sum_of_monthly_Personal_Debt__c
            FROM Lead
            WHERE Partner_Lookup__c = :partner.Id
        ];
        for (Lead lead : leads) {
            // The PCR should be mapped to the lead even if there's no debt
            // "Self-Reported Mortgage" Trade Account is the only value that is being used to
            // calculate the Sum of monthly personal debt
            System.assertEquals(1000, lead.Personal_Credit_Report__r.LASERCA__Sum_of_monthly_Personal_Debt__c);
            System.assertNotEquals(null, lead.Personal_Credit_Report__c);
        }
    }

    static testMethod void testCoAppCreditCheck() {
        Contact jointContact = new Contact();
        jointContact.FirstName = 'JointCoApp';
        jointContact.LastName = 'Testcase';
        insert jointContact;

        jointContact.LASERCA__Pull_Credit_Report__c = true;
        update jointContact;

        // validates that the contact can be udpated without
    }

    // Sometimes we get Credit Report Logs with no PCR. In these cases, the credit pull shouldn't fail with an error like:
    // Apex script unhandled trigger exception by user/organization: 0050a00000HAYt1/00Dj0000001q7GO
    // CreditReportLogTrigger: execution of AfterInsert
    // caused by: System.ListException: List index out of bounds: 0
    // Class.PCRApprovalHandler.addMortgage: line 313, column 1
    // Trigger.CreditReportLogTrigger: line 13, column 1
    static testMethod void testFrozenPCR() {
        RecordType solarLoanType = [
            SELECT Id
            FROM RecordType
            WHERE Name = 'BlueWave Solar Loan'
            AND SobjectType = 'Lead'
        ];
        Lead newLead = new Lead(
            FirstName = 'test',
            LastName = 'FrozenPCRTest',
            RecordTypeId = solarLoanType.Id,
            Automatic_Product_Assignment__c = false,
            Email = 'test@email.com',
            Company = 'Cloud Jedi',
            Status = 'Ready for Credit Check',
            Product_line__c = 'Residential Loan',
            Monthly_Mortgage_Tax_and_Insurance__c = 1000,
            LASERCA__Home_State__c = 'MA',
            Unfinished_Lead__c = true);
        insert newLead;
        LASERCA__Credit_Report_Log__c crl = new LASERCA__Credit_Report_Log__c(
            LASERCA__Lead__c = newLead.Id,
            LASERCA__Status__c = 'Completed'
        );
        insert crl;
        List<Lead> leads = [
            SELECT Id, (
                SELECT Id FROM LASERCA__Credit_Report_Logs__r
            )
            FROM Lead
            WHERE LastName = 'FrozenPCRTest'
        ];
        System.assertEquals(1, leads.size());
        System.assertEquals(1, leads[0].LASERCA__Credit_Report_Logs__r.size());
    }

    public class Application {
        public Integer income, loan;
        public Id prodId;
        public Boolean doer;
        public String ibls, applicationType;
        public Integer coAppIncome, coAppFICO;
        public Integer fico, debt, balance;
        public Decimal coAppDebt, coAppBalance;
        public String code1, code2, code3, code4;
        public String coAppCode1, coAppCode2, coAppCode3, coAppCode4;
        public Id leadId, pcrId, coAppPCRId, contactId;
        public String expectedSLAStatus, expectedStatus;
        public String publicRecord, publicRecordStatus;
        public String coAppPublicRecord, coAppPublicRecordStatus;
        public Boolean denialSent;
        public Boolean sendEmails;
        public Boolean bankruptcy, coAppBankruptcy;
        public Decimal expectedDTIBefore, expectedDTIAfter;
        public Integer key;
        public void assert(LASERCA__Personal_Credit_Report__c pcr) {
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
    }
    public class ApplicationSet {
        public List<Application> application;
        public Map<Integer, Application> applicationMap;

        public void insertLeads(Id partnerId) {
            RecordType solarLoanType = [
                SELECT Id
                FROM RecordType
                WHERE Name = 'BlueWave Solar Loan'
                AND SobjectType = 'Lead'
            ];

            List<Lead> leads = new List<Lead>();
            for (Application app : application) {
                Boolean doer = app.doer==null?false:app.doer;
                Lead newLead = new Lead(LastName = 'Testcase',
                    RecordTypeId = solarLoanType.Id,
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
                    DOER_Solar_Loan__c = doer,
                    Product_Line__c = 'Residential Loan',
                    Product_Program__c = doer ? 'MSLP' : 'BlueWave Solar Loan',
                    Monthly_Mortgage_Tax_and_Insurance__c = 1000,
                    LASERCA__Home_State__c = 'MA',
                    Unfinished_Lead__c = true,
                    IBLS_Category__c = app.ibls,
                    Co_Applicant_Income__c = Util.nullToZero(app.coAppIncome),
                    // Just need a key to use later
                    AnnualRevenue = app.key);
                if (app.applicationType == 'Joint Co-App') {
                    newLead.Application_Type__c = 'Joint';
                    newLead.Joint_Applicant_Type__c = 'Co-Applicant';
                    newLead.Co_App_Monthly_Mortgage__c = 500;
                } else if (app.applicationType == 'Joint Co-Sign') {
                    newLead.Application_Type__c = 'Joint';
                    newLead.Joint_Applicant_Type__c = 'Co-Signer';
                    newLead.Co_App_Monthly_Mortgage__c = 500;
                }
                leads.add(newLead);
            }
            insert leads;
            Map<Integer, Id> incomeToLeadID = new Map<Integer, Id>();
            List<Contact> newContacts = new List<Contact>();
            for (Lead l : leads) {
                incomeToLeadID.put((Integer) l.AnnualRevenue, l.Id);
                if (l.Application_Type__c == 'Joint') {
                    Contact newContact = new Contact(
                        FirstName = 'CoApplicant',
                        LastName = 'Contact',
                        Lead__c = l.Id,
                        Income__c = l.Co_Applicant_Income__c
                    );
                    newContacts.add(newContact);
                }
            }
            insert newContacts;
            Map<Id, Contact> contactsByLead = new Map<Id, Contact>();
            for (Contact contact : newContacts) {
                contactsByLead.put(contact.Lead__c, contact);
            }
            for (Application app : application) {
                Id leadId = incomeToLeadID.get(app.key);
                app.leadId = leadId;
                if (contactsByLead.containsKey(leadId)) {
                    app.contactId = contactsByLead.get(leadId).Id;
                }
            }

        }

        public void insertPCRs() {
            List<LASERCA__Personal_Credit_Report__c> pcrs = new List<LASERCA__Personal_Credit_Report__c>();
            List<LASERCA__Personal_Credit_Report__c> coAppPCRs = new List<LASERCA__Personal_Credit_Report__c>();
            for (Application app : application) {
                pcrs.add(new LASERCA__Personal_Credit_Report__c(
                    LASERCA__Lead__c = app.leadId,
                    LASERCA__Code__c = app.code1,
                    LASERCA__Code_2__c = app.code2,
                    LASERCA__Code_3__c = app.code3,
                    LASERCA__Code_4__c = app.code4,
                    LASERCA__Bankruptcy__c = (app.bankruptcy != null)?app.bankruptcy:false,
                    LASERCA__Credit_Score_TransUnion__c = (app.fico!=null?String.valueOf(app.fico):null),
                    Credit_Denial_Email_Sent__c = (app.sendEmails!=null?!app.sendEmails:true),
                    Credit_PreApproval_Email_Sent__c = (app.sendEmails!=null?!app.sendEmails:true)
                ));
                if (app.applicationType != null && app.applicationType.contains('Joint')) {
                    coAppPCRs.add(new LASERCA__Personal_Credit_Report__c(
                        LASERCA__Contact__c = app.contactId,
                        LASERCA__Code__c = app.coAppCode1,
                        LASERCA__Code_2__c = app.coAppCode2,
                        LASERCA__Code_3__c = app.coAppCode3,
                        LASERCA__Code_4__c = app.coAppCode4,
                        LASERCA__Bankruptcy__c = (app.coAppBankruptcy != null)?app.coAppBankruptcy:false,
                        LASERCA__Credit_Score_TransUnion__c = (app.coAppFICO!=null?String.valueOf(app.coAppFICO):null),
                        Credit_Denial_Email_Sent__c = (app.sendEmails!=null?!app.sendEmails:true),
                        Credit_PreApproval_Email_Sent__c = (app.sendEmails!=null?!app.sendEmails:true)
                    ));
                }
            }
            insert pcrs;
            insert coAppPCRs;
            Map<Id, Id> leadIdToPCRId = new Map<Id, Id>();
            Map<Id, Id> leadIdToCoAppPCRId = new Map<Id, Id>();
            List<Id> coAppPCRIds = new List<Id>();
            for (LASERCA__Personal_Credit_Report__c pcr : pcrs) {
                leadIdToPCRId.put(pcr.LASERCA__Lead__c, pcr.Id);
            }
            for (LASERCA__Personal_Credit_Report__c pcr : coAppPCRs) {
                coAppPCRIds.add(pcr.Id);
            }
            coAppPCRs = [
                SELECT Id, Lead_from_Contact__c
                FROM LASERCA__Personal_Credit_Report__c
                WHERE Id IN : coAppPCRIds
            ];
            for (LASERCA__Personal_Credit_Report__c pcr : coAppPCRs) {
                leadIdToCoAppPCRId.put(pcr.Lead_from_Contact__c, pcr.Id);
            }
            for (Application app : application) {
                app.pcrId = leadIdToPCRId.get(app.leadId);
                app.coAppPCRId = leadIdToCoAppPCRId.get(app.leadId);
                applicationMap.put(app.key, app);
            }
        }

        public void insertPublicRecords() {
            List<LASERCA__Public_Records__c> publicRecords = new List<LASERCA__Public_Records__c>();
            Date myDateJan = Date.newInstance(2016, 1, 1);
            Date myDateMarch = Date.newInstance(2016, 3, 1);
            for (Application app : application) {
                if (app.publicRecord != null) {
                    publicRecords.add(new LASERCA__Public_Records__c(
                        Name = app.publicRecord,
                        LASERCA__Type__c = app.publicRecord,
                        LASERCA__Disposition__c = app.publicRecordStatus,
                        LASERCA__Date_Filed__c = myDateJan,
                        LASERCA__Disposition_Date__c = app.publicRecordStatus == 'Filed'?null:myDateMarch,
                        LASERCA__Personal_Credit_Report__c = app.pcrId
                    ));
                }
                if (app.applicationType != null
                    && app.applicationType.contains('Joint')
                    && app.coAppPublicRecord != null) {
                    publicRecords.add(new LASERCA__Public_Records__c(
                        Name = app.coAppPublicRecord,
                        LASERCA__Type__c = app.coAppPublicRecord,
                        LASERCA__Disposition__c = app.coAppPublicRecordStatus,
                        LASERCA__Date_Filed__c = myDateJan,
                        LASERCA__Disposition_Date__c = app.publicRecordStatus == 'Filed'?null:myDateMarch,
                        LASERCA__Personal_Credit_Report__c = app.coAppPCRId
                    ));
                }
            }
            insert publicRecords;
        }

        public void insertTradeAccounts() {
            List<LASERCA__Trade_Accounts__c> tradeAccts = new List<LASERCA__Trade_Accounts__c>();
            for (Application app : application) {
                tradeAccts.add(new LASERCA__Trade_Accounts__c(
                    LASERCA__Personal_Credit_Report__c = app.pcrId,
                    LASERCA__Name_of_the_Institution__c = 'primary trade account',
                    LASERCA__Account_Ownership_Type__c = 'Individual',
                    LASERCA__Open_Date__c = Date.today(),
                    LASERCA__Monthly_Payment__c = Util.nullToZero(app.debt),
                    LASERCA__Account_Balance__c = Util.nullToZero(app.balance)
                ));
                if (app.applicationType != null && app.applicationType.contains('Joint')) {
                    tradeAccts.add(new LASERCA__Trade_Accounts__c(
                        LASERCA__Personal_Credit_Report__c = app.coAppPCRId,
                        LASERCA__Name_of_the_Institution__c = 'co app trade account',
                        LASERCA__Account_Ownership_Type__c = 'Individual',
                        LASERCA__Open_Date__c = Date.today(),
                        LASERCA__Monthly_Payment__c = Util.nullToZero(app.coAppDebt),
                        LASERCA__Account_Balance__c = Util.nullToZero(app.coAppBalance)
                    ));
                }
            }
            insert tradeAccts;
        }

        public void insertCreditReportLogs() {
            List<LASERCA__Credit_Report_Log__c> crls = new List<LASERCA__Credit_Report_Log__c>();
            for (Application app : application) {
                crls.add(new LASERCA__Credit_Report_Log__c(
                    LASERCA__Personal_Credit_Report__c = app.pcrId,
                    LASERCA__Status__c = 'Pending'));
                if (app.coAppPCRId != null) {
                    crls.add(new LASERCA__Credit_Report_Log__c(
                        LASERCA__Personal_Credit_Report__c = app.coAppPCRId,
                        LASERCA__Status__c = 'Pending'));
                }
            }
            insert crls;
            for (LASERCA__Credit_Report_Log__c crl : crls) {
                crl.LASERCA__Status__c = 'Completed';
            }
            update crls;
        }

        public void connectJointPCRs() {
            List<LASERCA__Personal_Credit_Report__c> contactPCRs = [
                SELECT Id, LASERCA__Contact__c, Lead_from_Contact__c
                FROM LASERCA__Personal_Credit_Report__c
                WHERE LASERCA__Contact__c != null
            ];
            Map<Id, Id> relatedLeads = new Map<Id, Id>();

            for (LASERCA__Personal_Credit_Report__c pcr : contactPCRs) {
                relatedLeads.put(pcr.Lead_from_Contact__c, pcr.Id);
            }

            List<Lead> contactLeads = [
                SELECT Id, Personal_Credit_Report_Co_Applicant__c
                FROM Lead
                WHERE Id IN : relatedLeads.keySet()
            ];

            for (Lead lead : contactLeads) {
                lead.Personal_Credit_Report_Co_Applicant__c = relatedLeads.get(lead.Id);
            }

            update contactLeads;
        }

        public LASERCA__Personal_Credit_Report__c getPCR(Integer key) {
            return(new LASERCA__Personal_Credit_Report__c(Id = applicationMap.get(key).pcrId));
        }

        public Lead getLead(Integer key) {
            return(new Lead(Id = applicationMap.get(key).leadId));
        }
    }
    public static ApplicationSet parse(String json) {
        ApplicationSet appSet = (ApplicationSet) System.JSON.deserialize(json, ApplicationSet.class);
        appSet.applicationMap = new Map<Integer, Application>();
        return appSet;
    }
}