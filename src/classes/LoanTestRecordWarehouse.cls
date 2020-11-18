/*************************************************************************************
 * Description: Common methods used for test data setup
 * Used By: CAPControllerTest, DisbursalHandlerTest, LoanHandlerTestClass, LoanUnderwritingTest,
 *          PCRApprovalHandlerTest, SLPControllersTestclass,   others?
 *************************************************************************************/

@isTest
public class LoanTestRecordWarehouse {
    public static List<String> partnerSetup() {
        List<String> partnerSetupList = new List<String>();
        Account partnerAccount = new Account(
            Name = 'Bluewave Inside Sales',
            RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Partner_Account').getRecordTypeId()
        );
        insert partnerAccount;
        Partner__c partner = new Partner__c(
            Name = 'Bluewave Inside Sales',
            Account__c = partnerAccount.Id
        );
        insert partner;
        partnerAccount.Partner__c = partner.Id;
        update partnerAccount;
        partnerSetupList.add(partner.Id);

        BSST__c salesRep = new BSST__c(Name = 'BlueWave User', Partner__c = partner.Id, Custom_ID__c = 'test', Email__c = 'SalesRep@Sales.com');
        insert salesRep;
        partnerSetupList.add(salesRep.Id);

        BSST__c salesRepExec = new BSST__c(Name = 'BlueWave Executive', Partner__c = partner.Id, Custom_ID__c = 'exec', Email__c = 'executive@Sales.com');
        insert salesRepExec;
        partnerSetupList.add(salesRepExec.Id);

        return partnerSetupList;
    }

    public static List<Product2> getLoanProductsVariableInterestRatesandTerms () {
        if (System_Properties__c.getall().isEmpty()) {
            insert new System_Properties__c(Name = 'System',
                                            Flagged_Credit_Codes__c = '018,020,A06,021,022,031,034,040,039');
        }

        Loan_Data__c capitalPool = new Loan_Data__c(Name = 'Revolving Credit Line',
                                                Total_Capital__c = 10000000,
                                                Investor__c = 'The Bank',
                                                Pool_Type__c = 'Revolving Credit Line');
        insert capitalPool;

        Date myDate = Date.newInstance(2015, 2, 17);
        Date codDate = Date.newInstance(2015, 4, 17);
        Date codDateTwo = Date.newInstance(2015, 7, 17);

        Loan_Traunch__c loanTrancheMA = new Loan_Traunch__c(
            Name = 'Avidia 1',
            Tranche_Cap__c = 1000000,
            Tranche_Type__c = 'Standard',
            State__c = 'MA',
            Stage__c = 'Open',
            Loan_Data__c = capitalPool.id);
        insert loanTrancheMA;

        Loan_Traunch__c loanTranchePending = new Loan_Traunch__c(
            Name = 'Tranche Assignment Pending',
            Tranche_Type__c = 'Holding',
            Stage__c = 'Closed',
            Loan_Data__c = capitalPool.id);
        insert loanTranchePending;

        Product2 productLoanMATerm10Rate599 = getDefaultProduct('MA', 5.99, 10, 7, '750', '999', capitalPool.Id);
        Product2 productLoanMATerm10Rate699 = getDefaultProduct('MA', 6.99, 10, 5, '700', '749', capitalPool.Id);
        Product2 productLoanMATerm10Rate725 = getDefaultProduct('MA', 7.25, 10, 0, '681', '699', capitalPool.Id);
        Product2 productLoanMATerm20Rate599 = getDefaultProduct('MA', 5.99, 20, 7, '750', '999', capitalPool.Id);
        Product2 productLoanMATerm20Rate699 = getDefaultProduct('MA', 6.99, 20, 7, '700', '749', capitalPool.Id);
        Product2 productLoanMATerm20Rate725 = getDefaultProduct('MA', 7.25, 20, 5, '681', '699', capitalPool.Id);

        productLoanMATerm20Rate725.Loan_Financing_Fee_Terms__c = 'No Financing Fee';
        productLoanMATerm20Rate725.Disbursal_Terms__c = '35% Contract Signature, 65% Interconnection';
        productLoanMATerm20Rate725.Program__c = 'MSLP';
        productLoanMATerm20Rate725.IBLS_Category__c = 'Category 1';
        productLoanMATerm20Rate725.Lender_of_Record__c = 'Avidia';
        Product2 productLoanMATerm20Rate875 = getDefaultProduct('MA', 8.75, 20, 5, '681', '699', capitalPool.Id);

        productLoanMATerm20Rate875.Loan_Financing_Fee_Terms__c = 'No Financing Fee';
        productLoanMATerm20Rate875.Disbursal_Terms__c = '35% Contract Signature, 65% Interconnection';
        productLoanMATerm20Rate875.Program__c = 'MSLP';
        productLoanMATerm20Rate875.IBLS_Category__c = 'Category 2';
        productLoanMATerm20Rate875.Lender_of_Record__c = 'Avidia';

        Product2 productLoanRI = getDefaultProduct('RI', 6.49, 15, 5, '681', '699', capitalPool.Id);
        productLoanRI.Lender_of_Record__c = 'Avidia';
        Product2 productLoanNY = getDefaultProduct('NY', 1.23, 5, 5, '681', '699', capitalPool.Id);

        Product2 productNonLoan = getCSProduct();

        return new List<Product2>{productLoanMATerm10Rate599, productLoanMATerm10Rate699,
                productLoanMATerm10Rate725, productLoanMATerm20Rate599, productLoanMATerm20Rate699,
                productLoanMATerm20Rate725, productLoanRI, productLoanMATerm20Rate875, productLoanNY, productNonLoan,
                getJunctionRequired(productLoanMATerm10Rate599), getJunctionRequired(productLoanMATerm10Rate699),
                getJunctionRequired(productLoanMATerm10Rate725), getJunctionRequired(productLoanMATerm20Rate599),
                getJunctionRequired(productLoanMATerm20Rate699), getJunctionRequired(productLoanMATerm20Rate725),
                getJunctionRequired(productLoanMATerm20Rate875), getJunctionRequired(productLoanRI)};
    }

    public static List<Lead> getLoanLeadswithVariableFICOsandTerms () {
        Map<String, Id> productMap = new Map<String, Id>();
        List<Product2> productsToInsert = getLoanProductsVariableInterestRatesandTerms();
        insert productsToInsert;

        for (Product2 product : productsToInsert) {
            if (product.Product_Type__c == 'Residential Loan') {
                if (product.Loan_Term__c/12 == 10 && product.Loan_Interest_Rate__c == 5.99) {
                    productMap.put('productLoanMATerm10Rate599', product.Id);
                } else if (product.Loan_Term__c/12 == 10 && product.Loan_Interest_Rate__c == 6.99) {
                    productMap.put('productLoanMATerm10Rate699', product.Id);
                } else if (product.Loan_Term__c/12 == 10 && product.Loan_Interest_Rate__c == 7.25) {
                    productMap.put('productLoanMATerm10Rate725', product.Id);
                } else if (product.Loan_Term__c/12 == 20 && product.Loan_Interest_Rate__c == 5.99) {
                    productMap.put('productLoanMATerm20Rate599', product.Id);
                } else if (product.Loan_Term__c/12 == 20 && product.Loan_Interest_Rate__c == 6.99) {
                    productMap.put('productLoanMATerm20Rate699', product.Id);
                } else if (product.Loan_Term__c/12 == 20 && product.Loan_Interest_Rate__c == 7.25) {
                    productMap.put('productLoanMATerm20Rate725', product.Id);
                } else if (product.Loan_Interest_Rate__c == 1.23) {
                    productMap.put('productNY', product.Id);
                }
            }
        }

        Partner__c partner = new Partner__c(Name = 'Partner');
        insert partner;

        BSST__c salesRep = new BSST__c(Name = 'SalesRep', Partner__c = partner.Id, Custom_ID__c = 'test', Email__c = 'SalesRep@Sales.com');
        insert salesRep;


        List<Lead> leadList = new List<Lead>();
        Lead leadMALoanTerm10Rate699 = new lead(FirstName = 'leadMALoanTerm10Rate699',
            LastName = 'Test',
            Email = 'cole.swain@yahoo.com',
            Loan_Amount__c = 35000,
            Company = 'Cole Swain',
            Product_Line__c = 'Residential Loan',
            LASERCA__Home_State__c = 'MA',
            Requested_Loan_Amount__c = 35000,
            Custom_Id__c = 'test',
            Partner_Lookup__c = partner.Id,
            Bs_Sales_ID__c = salesRep.Id,
            Annual_Income_Currency__c = 150000,
            Product__c = productMap.get('productLoanMATerm10Rate699'),
            Product_Program__c = 'BlueWave Solar Loan',
            Unfinished_Lead__c = true,
            Automatic_Product_Assignment__c = true,
            Status = 'Ready for Credit Check');
        Lead leadMALoanTerm10Rate725 = new lead(FirstName = 'leadMALoanTerm10Rate725',
            LastName = 'Test',
            Loan_Amount__c = 35000,
            Company = 'Cole Swain',
            Product_Line__c = 'Residential Loan',
            LASERCA__Home_State__c = 'MA',
            Requested_Loan_Amount__c = 35000,
            Custom_Id__c = 'test',
            Partner_Lookup__c = partner.Id,
            Bs_Sales_ID__c = salesRep.Id,
            Annual_Income_Currency__c = 150000,
            Product__c = productMap.get('productLoanMATerm10Rate725'),
            Product_Program__c = 'BlueWave Solar Loan',
            Unfinished_Lead__c = true,
            Automatic_Product_Assignment__c = true,
            Status = 'Ready for Credit Check');
        Lead leadMALoanTerm20Rate699 = new lead(FirstName = 'leadMALoanTerm20Rate699',
            LastName = 'Test',
            Loan_Amount__c = 35000,
            Company = 'Cole Swain',
            Product_Line__c = 'Residential Loan',
            LASERCA__Home_State__c = 'MA',
            Requested_Loan_Amount__c = 35000,
            Custom_Id__c = 'test',
            Partner_Lookup__c = partner.Id,
            Bs_Sales_ID__c = salesRep.Id,
            Other_Bank_Executive__c = true,
            Annual_Income_Currency__c = 150000,
            Product__c = productMap.get('productLoanMATerm20Rate699'),
            Product_Program__c = 'BlueWave Solar Loan',
            Automatic_Product_Assignment__c = true,
            Status = 'Ready for Credit Check');
        Lead leadMALoanTerm20Rate725 = new lead(FirstName = 'leadMALoanTerm20Rate725',
            LastName = 'Test',
            Loan_Amount__c = 35000,
            DOER_Solar_Loan__c = true,
            Company = 'Cole Swain',
            Product_Line__c = 'Residential Loan',
            LASERCA__Home_State__c = 'MA',
            Requested_Loan_Amount__c = 35000,
            Custom_Id__c = 'test',
            Partner_Lookup__c = partner.Id,
            Bs_Sales_ID__c = salesRep.Id,
            Product_Program__c = 'MSLP',
            Unfinished_Lead__c = true,
            Annual_Income_Currency__c = 150000,
            Product__c = productMap.get('productLoanMATerm20Rate725'),
            Automatic_Product_Assignment__c = true,
            Status = 'Ready for Credit Check');
        Lead coApplicantLead = new lead(FirstName = 'coApplicantLead',
            LastName = 'Test',
            Loan_Amount__c = 35000,
            Partner_Email__c = 'jpentaleri@bluewave-capital.com',
            DOER_Solar_Loan__c = false,
            Company = 'CoApplicantLead Test',
            Product_Line__c = 'Residential Loan',
            LASERCA__Home_State__c = 'MA',
            Requested_Loan_Amount__c = 35000,
            Application_Type__c = 'Joint',
            Custom_Id__c = 'test',
            Co_Applicant_Income__c = 2000,
            Partner_Lookup__c = partner.Id,
            Bs_Sales_ID__c = salesRep.Id,
            Product_Program__c = 'BlueWave Solar Loan',
            Unfinished_Lead__c = true,
            Annual_Income_Currency__c = 1000,
            Product__c = productMap.get('productLoanMATerm10Rate699'),
            Automatic_Product_Assignment__c = false,
            Status = 'Ready for Credit Check');
        Insert new List<Lead>{leadMALoanTerm10Rate699, leadMALoanTerm10Rate725,
            leadMALoanTerm20Rate699, leadMALoanTerm20Rate725, coApplicantLead};

        Account coApplicantAccount = new Account( Name = 'CoapplicantAccount');
        insert coApplicantAccount;

        Contact coApplicantContact = new Contact(
            FirstName = 'Cole',
            LastName = 'Swain',
            AccountId = coApplicantAccount.Id,
            Lead__c = coApplicantLead.Id,
            Income__c = 2000,
            LASERCA__Social_Security_Number__c = '000000002');
        insert coApplicantContact;

        //NOTE: CoApplicantLead does not have CoApplicant_Contact__c populated with CoApplicantContact;
        //  Must update lead with coApp contact for testing


        LASERCA__Personal_Credit_Report__c pcr10710 = new LASERCA__Personal_Credit_Report__c(
            Name = 'Personal Credit Report 1',
            LASERCA__Code__c ='001',
            LASERCA__Code_2__c ='001',
            LASERCA__Code_3__c = '001',
            LASERCA__Code_4__c = '001',
            LASERCA__Credit_Score_TransUnion__c = '710',
            LASERCA__Lead__c = leadMALoanTerm10Rate699.Id);
        LASERCA__Personal_Credit_Report__c pcr10690 = new LASERCA__Personal_Credit_Report__c(
            Name = 'Personal Credit Report 3',
            LASERCA__Code__c ='001',
            LASERCA__Code_2__c ='001',
            LASERCA__Code_3__c = '001',
            LASERCA__Code_4__c = '001',
            LASERCA__Credit_Score_TransUnion__c = '690',
            LASERCA__Lead__c = leadMALoanTerm10Rate725.Id);
        LASERCA__Personal_Credit_Report__c pcr20710 = new LASERCA__Personal_Credit_Report__c(
            Name = 'Personal Credit Report 4',
            LASERCA__Code__c ='001',
            LASERCA__Code_2__c ='001',
            LASERCA__Code_3__c = '001',
            LASERCA__Code_4__c = '001',
            LASERCA__Credit_Score_TransUnion__c = '710',
            Adjusted_DTI_Notes__c = 'Notes',
            LASERCA__TransUnion_Score_Factor__c =
                '039 - SERIOUS DELINQUENCY\n' +
                    '014 - LENGTH OF TIME ACCOUNTS HAVE BEEN ESTABLISHED\n' +
                    '027 - TOO FEW ACCOUNTS CURRENTLY PAID AS AGREED\n' +
                    '003 - PROPORTION OF LOAN BALANCES TO LOAN AMOUNTS IS TOO HIGH\n' +
                    'FA - INQUIRIES IMPACTED THE CREDIT SCORE\n',
            LASERCA__Lead__c = leadMALoanTerm20Rate699.Id);
        LASERCA__Personal_Credit_Report__c pcr20690 = new LASERCA__Personal_Credit_Report__c(
            Name = 'Personal Credit Report 6',
            LASERCA__Code__c ='001',
            LASERCA__Code_2__c ='001',
            LASERCA__Code_3__c = '001',
            LASERCA__Code_4__c = '001',
            LASERCA__Credit_Score_TransUnion__c = '690',
            LASERCA__Lead__c = leadMALoanTerm20Rate725.Id);
        LASERCA__Personal_Credit_Report__c pcrPrimaryApplicant = new LASERCA__Personal_Credit_Report__c(
            Name = 'Personal Credit Report 7',
            LASERCA__Code__c ='001',
            LASERCA__Code_2__c ='001',
            LASERCA__Code_3__c = '001',
            LASERCA__Code_4__c = '001',
            LASERCA__Credit_Score_TransUnion__c = '760',
            LASERCA__Confirming_Social_Security_Number__c = '000000001',
            LASERCA__Lead__c = coApplicantLead.Id);
        LASERCA__Personal_Credit_Report__c pcrCoApplicant = new LASERCA__Personal_Credit_Report__c(
            Name = 'Personal Credit Report 8',
            LASERCA__Code__c ='001',
            LASERCA__Code_2__c ='001',
            LASERCA__Code_3__c = '001',
            LASERCA__Code_4__c = '001',
            LASERCA__Credit_Score_TransUnion__c = '760',
            LASERCA__Contact__c = coApplicantContact.Id,
            LASERCA__Confirming_Social_Security_Number__c = '000000002',
            LASERCA__Lead__c = coApplicantLead.Id);
        List<LASERCA__Personal_Credit_Report__c> pcrs =
            new List<LASERCA__Personal_Credit_Report__c>{pcr10710, pcr10690, pcr20710, pcr20690, pcrPrimaryApplicant, pcrCoApplicant};
        insert pcrs;

        LASERCA__Trade_Accounts__c pcr10710Trade = new LASERCA__Trade_Accounts__c(
            Name = 'Personal Credit Report Trade 1',
            LASERCA__Personal_Credit_Report__c = pcr10710.Id,
            LASERCA__Monthly_Payment__c = 100);
        LASERCA__Trade_Accounts__c pcr10690Trade = new LASERCA__Trade_Accounts__c(
            Name = 'Personal Credit Report Trade 3',
            LASERCA__Personal_Credit_Report__c = pcr10690.Id,
            LASERCA__Monthly_Payment__c = 100);
        LASERCA__Trade_Accounts__c pcr20710Trade = new LASERCA__Trade_Accounts__c(
            Name = 'Personal Credit Report Trade 4',
            LASERCA__Personal_Credit_Report__c = pcr20710.Id,
            LASERCA__Monthly_Payment__c = 100,
            LASERCA__Account_Balance__c = 10000);
        LASERCA__Trade_Accounts__c pcr20690Trade = new LASERCA__Trade_Accounts__c(
            Name = 'Personal Credit Report Trade 5',
            LASERCA__Personal_Credit_Report__c = pcr20690.Id,
            LASERCA__Monthly_Payment__c = 100);
        LASERCA__Trade_Accounts__c pcrPrimaryApplicantTrade = new LASERCA__Trade_Accounts__c(
            Name = 'Personal Credit Report Trade 6',
            LASERCA__Name_of_the_Institution__c = 'Trade 6',
            LASERCA__Personal_Credit_Report__c = pcrPrimaryApplicant.Id,
            LASERCA__Monthly_Payment__c = 500);
        LASERCA__Trade_Accounts__c pcrCoApplicantTrade = new LASERCA__Trade_Accounts__c(
            Name = 'Personal Credit Report Trade 7',
            LASERCA__Name_of_the_Institution__c = 'Trade 7',
            LASERCA__Personal_Credit_Report__c = pcrCoApplicant.Id,
            LASERCA__Monthly_Payment__c = 250);
        insert new List<LASERCA__Trade_Accounts__c>{pcr10710Trade, pcr10690Trade, pcr20710Trade, pcr20690Trade, pcrPrimaryApplicantTrade, pcrCoApplicantTrade};

        List<LASERCA__Credit_Report_Log__c> crls = new List<LASERCA__Credit_Report_Log__c>();
        for (LASERCA__Personal_Credit_Report__c pcr : pcrs) {
            crls.add(new LASERCA__Credit_Report_Log__c(
                LASERCA__Personal_Credit_Report__c = pcr.Id,
                LASERCA__Status__c = 'Completed'
            ));
        }
        insert crls;
        return leadList;
    }

    private static void getLoanHandlerProductRecords () {

        Loan_Data__c capitalPool = new Loan_Data__c(Name = 'Revolving Credit Line',
            Total_Capital__c = 10000000,
            Investor__c = 'The Bank',
            Pool_Type__c = 'Revolving Credit Line');
        insert capitalPool;

        Loan_Traunch__c loanTrancheMA = new Loan_Traunch__c(
            Name = 'Avidia 1',
            Tranche_Cap__c = 1000000,
            Tranche_Type__c = 'Standard',
            State__c = 'MA',
            Stage__c = 'Open',
            Loan_Data__c = capitalPool.id);
        insert loanTrancheMA;

        Loan_Traunch__c loanTranchePending = new Loan_Traunch__c(
            Name = 'Tranche Assignment Pending',
            Tranche_Type__c = 'Holding',
            Stage__c = 'Closed',
            Loan_Data__c = capitalPool.id);
        insert loanTranchePending;

        Product2 productRecord = getDefaultProduct('MA', 5.99, 10, 7, '750', '999', capitalPool.Id);
        Product2 productRecordMSLP = getDefaultProduct('MA', 5.99, 10, 7, '750', '999', capitalPool.Id);
        productRecordMSLP.Disbursal_Terms__c = '35% Contract Signature, 65% Interconnection';
        productRecordMSLP.Program__c = 'MSLP';
        Product2 nyLoan = getDefaultProduct('NY', 1.23, 1, 7, '750', '999', capitalPool.Id);
        System.debug(LoggingLevel.ERROR, new List<Product2>{productRecord, productRecordMSLP, nyLoan});
        insert new List<Product2>{productRecord, productRecordMSLP, nyLoan};
    }

    public static List<Lead> getLoanHandlerLeadRecords () {
        Map<String, Id> productMap = new Map<String, Id>();
        getLoanHandlerProductRecords();
        for (Product2 product : [SELECT Id, Name, Disbursal_Terms__c, Program__c, State__c, Family, Loan_Interest_Rate__c, Loan_Term__c, Loan_Interest_Only_Period__c, Technology_Platform_Fee__c, External_Name__c, Credit_Minimum__c, Credit_Maximum__c FROM Product2]) {
             if (product.Program__c == 'BlueWave Solar Loan' && product.State__c == 'MA') {
                 productMap.put('BWSL', product.Id);
             } else if (product.Program__c == 'BlueWave Solar Loan' && product.State__c == 'NY') {
                 productMap.put('NY', product.Id);
             } else if (product.Program__c == 'MSLP') {
                 productMap.put('MSLP', product.Id);
             }
        }
        Partner__c partner = [SELECT Id FROM Partner__c WHERE Name = 'BlueWave Inside Sales' LIMIT 1];
        BSST__c salesRep = [SELECT Id FROM BSST__c WHERE Name = 'BlueWave User' LIMIT 1];

        List<Lead> leadList = new List<Lead>();
        Lead leadRecordRetired = new lead(FirstName = 'Retired',
            LastName = 'Test',
            Loan_Amount__c = 25000,
            Company = 'Cole Swain',
            Retired__c = true,
            Self_Employed__c = false,
            LASERCA__Social_Security_Number__c = '000000001',
            Product_Line__c = 'Residential Loan',
            LASERCA__Home_State__c = 'MA',
            Requested_Loan_Amount__c = 25000,
            DOER_Solar_Loan__c = false,
            Custom_Id__c = 'test',
            Unfinished_Lead__c = true,
            Partner_Lookup__c = partner.Id,
            Bs_Sales_ID__c = salesRep.Id,
            Annual_Income_Currency__c = 150000,
            Product__c = productMap.get('BWSL'),
            Product_Program__c = 'BlueWave Solar Loan',
            Application_Type__c = 'Individual',
            Automatic_Product_Assignment__c = true,
            Status = 'Ready for Credit Check',
            Loan_System_Information__c = '{"number_of_modules__c":"10","module_manufacturer__c":"SWorld","module_model_number__c":"Sw500","number_of_inverters__c":"1","inverter_manufacturer__c":"Enphase","inverter_model_number__c":"EN300","commencement_datee__c":"02/21/2018","generator_nameplate_capacity__c":"35"}',
            Viewed_by_Partner_Admin__c = false,
            Viewed_by_Partner_Agent__c = false);
        Lead leadRecordSelfEmployed = new lead(FirstName = 'SelfEmployed',
            LastName = 'Test',
            Loan_Amount__c = 25000,
            Company = 'Cole Swain',
            LASERCA__Social_Security_Number__c = '000000001',
            Retired__c = false,
            DOER_Solar_Loan__c = false,
            Self_Employed__c = true,
            Product_Line__c = 'Residential Loan',
            LASERCA__Home_State__c = 'MA',
            Requested_Loan_Amount__c = 25000,
            Custom_Id__c = 'test',
            Unfinished_Lead__c = true,
            Partner_Lookup__c = partner.Id,
            Bs_Sales_ID__c = salesRep.Id,
            Annual_Income_Currency__c = 150000,
            Product__c = productMap.get('BWSL'),
            Product_Program__c = 'BlueWave Solar Loan',
            Application_Type__c = 'Individual',
            Automatic_Product_Assignment__c = true,
            Status = 'Ready for Credit Check',
            Loan_System_Information__c = '{"number_of_modules__c":"10","module_manufacturer__c":"SWorld","module_model_number__c":"Sw500","number_of_inverters__c":"1","inverter_manufacturer__c":"Enphase","inverter_model_number__c":"EN300","commencement_datee__c":"02/21/2018","generator_nameplate_capacity__c":"35"}',
            Viewed_by_Partner_Admin__c = false,
            Viewed_by_Partner_Agent__c = false);
        Lead leadRecordDOER = new Lead(FirstName = 'DOER',
            LastName = 'Test',
            Loan_Amount__c = 25000,
            Company = 'Cole Swain',
            LASERCA__Social_Security_Number__c = '000000001',
            Retired__c = false,
            Self_Employed__c = true,
            Product_Line__c = 'Residential Loan',
            DOER_Solar_Loan__c = true,
            LASERCA__Home_State__c = 'MA',
            Requested_Loan_Amount__c = 25000,
            Custom_Id__c = 'test',
            Unfinished_Lead__c = true,
            Partner_Lookup__c = partner.Id,
            Bs_Sales_ID__c = salesRep.Id,
            Annual_Income_Currency__c = 150000,
            Product__c = productMap.get('MSLP'),
            Automatic_Product_Assignment__c = true,
            Product_Program__c = 'MSLP',
            Status = 'Ready for Credit Check',
            Application_Type__c = 'Individual',
            Technical_Approval_Verified__c = true,
            Income_Verified__c = true,
            Is_there_a_Partner_Record__c = true,
            Loan_System_Information__c = '{"number_of_modules__c":"10","module_manufacturer__c":"SWorld","module_model_number__c":"Sw500","number_of_inverters__c":"1","inverter_manufacturer__c":"Enphase","inverter_model_number__c":"EN300","commencement_datee__c":"02/21/2018","generator_nameplate_capacity__c":"35"}',
            Viewed_by_Partner_Admin__c = false,
            Viewed_by_Partner_Agent__c = false);
        Lead leadRecordNY = new Lead(FirstName = 'NY',
            LastName = 'Test',
            Loan_Amount__c = 25000,
            Company = 'Cole Swain',
            LASERCA__Social_Security_Number__c = '000000001',
            Retired__c = false,
            Self_Employed__c = true,
            Product_Line__c = 'Residential Loan',
            DOER_Solar_Loan__c = false,
            LASERCA__Home_State__c = 'NY',
            System_Cost__c = 25000,
            Requested_Loan_Amount__c = 25000,
            Custom_Id__c = 'test',
            Unfinished_Lead__c = true,
            Partner_Lookup__c = partner.Id,
            Bs_Sales_ID__c = salesRep.Id,
            Annual_Income_Currency__c = 150000,
            Product__c = productMap.get('NY'),
            Automatic_Product_Assignment__c = true,
            Product_Program__c = 'BlueWave Solar Loan',
            Status = 'Ready for Credit Check',
            Application_Type__c = 'Individual',
            Technical_Approval_Verified__c = true,
            Income_Verified__c = true,
            Is_there_a_Partner_Record__c = true,
            Viewed_by_Partner_Admin__c = false,
            Viewed_by_Partner_Agent__c = false);
        Lead leadCoApp = new Lead(FirstName = 'CoApp',
            LastName = 'Test',
            Loan_Amount__c = 25000,
            Company = 'CoApp Test',
            LASERCA__Social_Security_Number__c = '000000001',
            Retired__c = false,
            Self_Employed__c = true,
            Product_Line__c = 'Residential Loan',
            DOER_Solar_Loan__c = false,
            LASERCA__Home_State__c = 'MA',
            System_Cost__c = 25000,
            Requested_Loan_Amount__c = 25000,
            Application_Type__c = 'Joint',
            Custom_Id__c = 'test',
            Unfinished_Lead__c = true,
            Partner_Lookup__c = partner.Id,
            Bs_Sales_ID__c = salesRep.Id,
            Annual_Income_Currency__c = 150000,
            Product__c = productMap.get('BWSL'),
            Automatic_Product_Assignment__c = true,
            Product_Program__c = 'BlueWave Solar Loan',
            Status = 'Ready for Credit Check',
            Loan_System_Information__c = '{"number_of_modules__c":"10","module_manufacturer__c":"SWorld","module_model_number__c":"Sw500","number_of_inverters__c":"1","inverter_manufacturer__c":"Enphase","inverter_model_number__c":"EN300","commencement_datee__c":"02/21/2018","generator_nameplate_capacity__c":"35"}',
            Technical_Approval_Verified__c = true,
            Income_Verified__c = true,
            Is_there_a_Partner_Record__c = true,
            Viewed_by_Partner_Admin__c = false,
            Viewed_by_Partner_Agent__c = false);
        leadList.add(leadRecordRetired);
        leadList.add(leadRecordSelfEmployed);
        leadList.add(leadRecordDOER);
        leadList.add(leadCoApp);
        leadList.add(leadRecordNY);
        insert leadList;

        LASERCA__Personal_Credit_Report__c creditReportRecordRetired = new LASERCA__Personal_Credit_Report__c(
            Name = 'Personal Credit Report 1',
            LASERCA__Code__c ='001',
            LASERCA__Code_2__c ='001',
            LASERCA__Code_3__c = '001',
            LASERCA__Code_4__c = '001',
            LASERCA__Credit_Score_TransUnion__c = '790',
            LASERCA__Lead__c = leadRecordRetired.Id);
        LASERCA__Personal_Credit_Report__c creditReportRecordSelfEmployed = new LASERCA__Personal_Credit_Report__c(
            Name = 'Personal Credit Report 1',
            LASERCA__Code__c ='001',
            LASERCA__Code_2__c ='001',
            LASERCA__Code_3__c = '001',
            LASERCA__Code_4__c = '001',
            LASERCA__Credit_Score_TransUnion__c = '790',
            LASERCA__Lead__c = leadRecordSelfEmployed.Id);
        LASERCA__Personal_Credit_Report__c creditReportRecordMSLP = new LASERCA__Personal_Credit_Report__c(
            Name = 'Personal Credit Report 1',
            LASERCA__Code__c ='001',
            LASERCA__Code_2__c ='001',
            LASERCA__Code_3__c = '001',
            LASERCA__Code_4__c = '001',
            LASERCA__Credit_Score_TransUnion__c = '790',
            LASERCA__Lead__c = leadRecordDOER.Id);
        LASERCA__Personal_Credit_Report__c creditReportCoApp = new LASERCA__Personal_Credit_Report__c(
            Name = 'Personal Credit Report 1',
            LASERCA__Code__c ='001',
            LASERCA__Code_2__c ='001',
            LASERCA__Code_3__c = '001',
            LASERCA__Code_4__c = '001',
            LASERCA__Credit_Score_TransUnion__c = '790',
            LASERCA__Lead__c = leadCoApp.Id);
        LASERCA__Personal_Credit_Report__c creditReportRecordNY = new LASERCA__Personal_Credit_Report__c(
            Name = 'Personal Credit Report 4',
            LASERCA__Code__c ='001',
            LASERCA__Code_2__c ='001',
            LASERCA__Code_3__c = '001',
            LASERCA__Code_4__c = '001',
            LASERCA__Credit_Score_TransUnion__c = '790',
            LASERCA__Lead__c = leadRecordNY.Id);

        List<LASERCA__Personal_Credit_Report__c> pcrs =
            new List<LASERCA__Personal_Credit_Report__c>{creditReportRecordRetired, creditReportRecordSelfEmployed, creditReportRecordMSLP, creditReportCoApp, creditReportRecordNY};
        insert pcrs;

        LASERCA__Trade_Accounts__c tradeAccountRecordRetired = new LASERCA__Trade_Accounts__c(
            Name = 'Personal Credit Report Trade 1',
            LASERCA__Personal_Credit_Report__c = creditReportRecordRetired.Id,
            LASERCA__Monthly_Payment__c = 100);
        LASERCA__Trade_Accounts__c tradeAccountRecordSelfEmployed = new LASERCA__Trade_Accounts__c(
            Name = 'Personal Credit Report Trade 1',
            LASERCA__Personal_Credit_Report__c = creditReportRecordSelfEmployed.Id,
            LASERCA__Monthly_Payment__c = 100);
        LASERCA__Trade_Accounts__c tradeAccountRecordMSLP = new LASERCA__Trade_Accounts__c(
            Name = 'Personal Credit Report Trade 1',
            LASERCA__Personal_Credit_Report__c = creditReportRecordMSLP.Id,
            LASERCA__Monthly_Payment__c = 100);
        LASERCA__Trade_Accounts__c tradeAccountCoApp = new LASERCA__Trade_Accounts__c(
            Name = 'Personal Credit Report Trade 1',
            LASERCA__Personal_Credit_Report__c = creditReportCoApp.Id,
            LASERCA__Monthly_Payment__c = 100);
        LASERCA__Trade_Accounts__c tradeAccountRecordNY = new LASERCA__Trade_Accounts__c(
            Name = 'Personal Credit Report Trade 4',
            LASERCA__Personal_Credit_Report__c = creditReportRecordNY.Id,
            LASERCA__Monthly_Payment__c = 100);
        insert new List<LASERCA__Trade_Accounts__c>{tradeAccountRecordRetired, tradeAccountRecordSelfEmployed, tradeAccountRecordMSLP, tradeAccountCoApp, tradeAccountRecordNY};

        List<LASERCA__Credit_Report_Log__c> crls = new List<LASERCA__Credit_Report_Log__c>();
        for (LASERCA__Personal_Credit_Report__c pcr : pcrs) {
            crls.add(new LASERCA__Credit_Report_Log__c(
                LASERCA__Personal_Credit_Report__c = pcr.Id,
                LASERCA__Status__c = 'Completed'
            ));
        }
        insert crls;

        return leadList;

    }

    public static Product2 getDefaultProduct(String state, Decimal interestRate, Integer term, Integer platformFee,
                                       String creditMin, String creditMax, Id capitalPool) {
        String interestRateString = interestRate.stripTrailingZeros() + '%';
        return new Product2(Name = 'BlueWave Solar Loan - ' + state + ' - ' + term + ' Year Term - ' + interestRateString,
                            Family = 'Solar Loan',
                            Product_Type__c = 'Residential Loan',
                            State__c = state,
                            Loan_Interest_Rate__c = interestRate,
                            Loan_Term__c = term*12,
                            Loan_Interest_Only_Period__c = 12,
                            Loan_Financing_Fee_Terms__c = 'Maximum (5%, $1,250)',
                            Technology_Platform_Fee__c = platformFee,
                            Disbursal_Terms__c = '30% Contract Signature, 60% Mechanical Installation, 10% Interconnection',
                            ProductCode = 'BlueWave Solar Loan - ' + state + ' - ' + term + ' Year Term - ' + interestRateString,
                            Loan_base_rate__c = .0625,
                            Loan_Internal_Lender_rate__c = .0499,
                            Credit_Maximum__c = creditMax,
                            Credit_Minimum__c = creditMin,
                            Loan_Capital_Pool__c = capitalPool,
                            Loan_Tranche_Type__c = 'Standard',
                            Program__c = 'BlueWave Solar Loan',
                            Debt_To_Income_Maximum__c = 50,
                            Lender_of_Record__c = 'BlueWave',
                            isActive = TRUE);
    }

    public static Product2 getCSProduct() {
        return new Product2( Name = 'BlueWave Community Solar',
                      Family = 'Community Solar',
                      Product_Type__c = 'Community Solar',
                      State__c = 'MA',
                      ProductCode = 'CS - BlueWave - 10%',
                      IsActive = True,
                      Lender_of_Record__c = 'BlueWave',
                      NMC_Discount__c = 10,
                      Annual_kWh_Maximum__c = 100000000,
                      NM_Rate_Floor__c = 0,
                      Monthly_Late_Fee__c = 1);
    }

    public static Product2 getJunctionRequired(Product2 prod) {
        return getJunctionRequired(prod, true);
    }

    public static Product2 getJunctionRequired(Product2 prod, Boolean isActive) {
        Product2 newProd = prod.clone(false, false, false, false);
        newProd.isActive = isActive;
        newProd.Hide_in_Requested_Product__c = true;
        newProd.Maximum_Loan_Size__c = 40000;
        newProd.Require_Junctions_to_Enable__c = true;
        newProd.Credit_Maximum__c = '680';
        newProd.Credit_Minimum__c = '650';
        newProd.Debt_To_Income_Maximum__c = 45;
        newProd.Loan_Interest_Rate__c = prod.Loan_Interest_Rate__c + .5;
        String oldRate = String.valueOf(prod.Loan_Interest_Rate__c);
        String newRate = String.valueOf(newProd.Loan_Interest_Rate__c);
        newProd.Name = prod.Name.replace(oldRate, newRate) + ' (Low FICO)';
        newProd.ProductCode = prod.ProductCode.replace(oldRate, newRate)  + ' (Low FICO)';
        if (prod.Description != null) {
            newProd.Description = prod.Description.replace(oldRate, newRate);
        }
        System.debug(newProd);
        return newProd;
    }
}