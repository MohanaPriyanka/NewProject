@isTest
public class LoanTestRecordWarehouse {
    public static List<String> partnerSetup() {           
        List<String> partnerSetupList = new List<String>();   
        Partner__c partner = new Partner__c(Name = 'Bluewave Inside Sales');
        insert partner;
        partnerSetupList.add(partner.Id);

        BSST__c salesRep = new BSST__c(Name = 'BlueWave User', Partner__c = partner.Id, Custom_ID__c = 'test', Email__c = 'SalesRep@Sales.com');
        insert salesRep;
        partnerSetupList.add(salesRep.Id);
        
        BSST__c salesRepExec = new BSST__c(Name = 'BlueWave Executive', Partner__c = partner.Id, Custom_ID__c = 'test', Email__c = 'executive@Sales.com');
        insert salesRepExec;  
        partnerSetupList.add(salesRepExec.Id);  

        return partnerSetupList;    
    }

    public static List<Product2> getLoanProductsVariableInterestRatesandTerms () { 

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
        Product2 productLoanMATerm10Rate725 = getDefaultProduct('MA', 7.25, 10, 0, '680', '699', capitalPool.Id);
        Product2 productLoanMATerm20Rate599 = getDefaultProduct('MA', 5.99, 20, 7, '750', '999', capitalPool.Id);
        Product2 productLoanMATerm20Rate699 = getDefaultProduct('MA', 6.99, 20, 7, '700', '749', capitalPool.Id);
        Product2 productLoanMATerm20Rate725 = getDefaultProduct('MA', 7.25, 20, 5, '680', '699', capitalPool.Id);
        productLoanMATerm20Rate725.Loan_Financing_Fee_Terms__c = 'No Financing Fee';
        productLoanMATerm20Rate725.Disbursal_Terms__c = '35% Contract Signature, 65% Interconnection';
        productLoanMATerm20Rate725.Program__c = 'MSLP';

        return new List<Product2>{productLoanMATerm10Rate599, productLoanMATerm10Rate699, 
                productLoanMATerm10Rate725, productLoanMATerm20Rate599, productLoanMATerm20Rate699, 
                productLoanMATerm20Rate725};
    }

    public static List<Lead> getLoanLeadswithVariableFICOsandTerms () {         
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
                                                Loan_Term__c = 120,
                                                Annual_Income_Currency__c = 150000,
                                                Product__c = null,
                                                Product_Program__c = 'BlueWave Solar Loan',
                                                Pre_Approval_Form__c = true,
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
                                                Loan_Term__c = 120,
                                                Annual_Income_Currency__c = 150000,
                                                Product__c = null,
                                                Product_Program__c = 'BlueWave Solar Loan',
                                                Pre_Approval_Form__c = true,
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
                                                Loan_Term__c = 240,
                                                Annual_Income_Currency__c = 150000,
                                                Product__c = null,
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
                                                Loan_Term__c = 240,
                                                Product_Program__c = 'MSLP',
                                                Pre_Approval_Form__c = true,
                                                Unfinished_Lead__c = true,
                                                Annual_Income_Currency__c = 150000,
                                                Product__c = null,
                                                Automatic_Product_Assignment__c = true,
                                                Status = 'Ready for Credit Check'); 
        Lead coApplicantLead = new lead(FirstName = 'coApplicantLead',
                                                LastName = 'Test',
                                                Loan_Amount__c = 35000,
                                                DOER_Solar_Loan__c = false,
                                                Company = 'Cole Swain',
                                                Product_Line__c = 'Residential Loan',
                                                LASERCA__Home_State__c = 'MA',
                                                Requested_Loan_Amount__c = 35000,
                                                Custom_Id__c = 'test',
                                                Co_Applicant_Income__c = 200000,
                                                Partner_Lookup__c = partner.Id,
                                                Bs_Sales_ID__c = salesRep.Id,
                                                Loan_Term__c = 240,
                                                Product_Program__c = 'BlueWave Solar Loan',
                                                Pre_Approval_Form__c = true,
                                                Unfinished_Lead__c = true,
                                                Annual_Income_Currency__c = 10000,
                                                Product__c = null,
                                                Automatic_Product_Assignment__c = true,
                                                Status = 'Ready for Credit Check');         
        Insert new List<Lead>{leadMALoanTerm10Rate699, leadMALoanTerm10Rate725, 
                                leadMALoanTerm20Rate699, leadMALoanTerm20Rate725, coApplicantLead}; 
        //
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
                                                                                            LASERCA__Credit_Score_TransUnion__c = '690',
                                                                                            LASERCA__Lead__c = coApplicantLead.Id);  
        LASERCA__Personal_Credit_Report__c pcrCoApplicant = new LASERCA__Personal_Credit_Report__c(           
                                                                                            Name = 'Personal Credit Report 8',
                                                                                            LASERCA__Code__c ='001',
                                                                                            LASERCA__Code_2__c ='001',
                                                                                            LASERCA__Code_3__c = '001',
                                                                                            LASERCA__Code_4__c = '001',                                                                                                                    
                                                                                            LASERCA__Credit_Score_TransUnion__c = '750',
                                                                                            LASERCA__Lead__c = coApplicantLead.Id);                                                                                                                                                                                                                                                                           
        insert new List<LASERCA__Personal_Credit_Report__c>{pcr10710, pcr10690, pcr20710, pcr20690, pcrPrimaryApplicant};
        insert pcrCoApplicant;

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
                                                                                LASERCA__Monthly_Payment__c = 100);
        LASERCA__Trade_Accounts__c pcr20690Trade = new LASERCA__Trade_Accounts__c(
                                                                                Name = 'Personal Credit Report Trade 6',
                                                                                LASERCA__Personal_Credit_Report__c = pcr20690.Id,
                                                                                LASERCA__Monthly_Payment__c = 100);
        LASERCA__Trade_Accounts__c pcrPrimaryApplicantTrade = new LASERCA__Trade_Accounts__c(
                                                                                Name = 'Personal Credit Report Trade 6',
                                                                                LASERCA__Personal_Credit_Report__c = pcr20690.Id,
                                                                                LASERCA__Monthly_Payment__c = 100);
        LASERCA__Trade_Accounts__c pcrCoApplicantTrade = new LASERCA__Trade_Accounts__c(
                                                                                Name = 'Personal Credit Report Trade 6',
                                                                                LASERCA__Personal_Credit_Report__c = pcr20690.Id,
                                                                                LASERCA__Monthly_Payment__c = 100);                                                                                        
        insert new List<LASERCA__Trade_Accounts__c>{pcr10710Trade, pcr10690Trade, pcr20710Trade, pcr20690Trade, pcrPrimaryApplicantTrade, pcrCoApplicantTrade};        
        //
       
        return leadList;
    }

    public static List<Product2> getLoanHandlerProductRecords () { 

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

        Product2 productRecord = new Product2(Name = 'BlueWave Solar Loan - MA - 10 Year Term - 5.99%',
                                                Family = 'Solar Loan',
                                                Product_Type__c = 'Residential Loan',
                                                State__c = 'MA',
                                                Loan_Interest_Rate__c = 5.99,
                                                Loan_Term__c = 120,
                                                Loan_Interest_Only_Period__c = 12,
                                                Loan_Financing_Fee_Terms__c = 'Maximum (5%, $1,250)',
                                                Technology_Platform_Fee__c = 7,
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
        Product2 productRecordMSLP = new Product2(Name = 'BlueWave Solar Loan - MA - 10 Year Term - 5.99%',
                                                Family = 'Solar Loan',
                                                Product_Type__c = 'Residential Loan',
                                                State__c = 'MA',
                                                Loan_Interest_Rate__c = 5.99,
                                                Loan_Term__c = 120,
                                                Loan_Interest_Only_Period__c = 12,
                                                Loan_Financing_Fee_Terms__c = 'Maximum (5%, $1,250)',
                                                Technology_Platform_Fee__c = 7,
                                                Disbursal_Terms__c = '35% Contract Signature, 65% Interconnection',
                                                ProductCode = 'BlueWave Solar Loan - MA - 10 Year Term - 5.99%',
                                                Loan_base_rate__c = .0625,
                                                Loan_Internal_Lender_rate__c = .0499,
                                                Credit_Maximum__c = '999',
                                                Credit_Minimum__c = '750',
                                                Loan_Capital_Pool__c = capitalPool.Id,
                                                Loan_Tranche_Type__c = 'Standard',
                                                Program__c = 'MSLP',
                                                isActive = TRUE);        


        return new List<Product2>{productRecord, productRecordMSLP};                                                                                                                                                             
    }

    public static List<Lead> getLoanHandlerLeadRecords () { 
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
                                    Loan_Term__c = 120,
                                    Unfinished_Lead__c = true,                                     
                                    Partner_Lookup__c = partner.Id,  
                                    Bs_Sales_ID__c = salesRep.Id,                                  
                                    Annual_Income_Currency__c = 150000,
                                    Product__c = null,
                                    Product_Program__c = 'BlueWave Solar Loan',
                                    Automatic_Product_Assignment__c = true,
                                    Status = 'Ready for Credit Check',
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
                                    Loan_Term__c = 120,
                                    Annual_Income_Currency__c = 150000,
                                    Product__c = null,
                                    Product_Program__c = 'BlueWave Solar Loan',
                                    Automatic_Product_Assignment__c = true,
                                    Status = 'Ready for Credit Check',
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
                                       Loan_Term__c = 120,
                                       Annual_Income_Currency__c = 150000,
                                       Product__c = null,
                                       Automatic_Product_Assignment__c = true,
                                       Product_Program__c = 'MSLP',
                                       Status = 'Ready for Credit Check',
                                       Technical_Approval_Verified__c = true,
                                       Income_Verified__c = true,
                                       Is_there_a_Partner_Record__c = true,
                                       Viewed_by_Partner_Admin__c = false,
                                       Viewed_by_Partner_Agent__c = false);
        leadList.add(leadRecordRetired);
        leadList.add(leadRecordSelfEmployed);
        leadList.add(leadRecordDOER);
        Insert leadList;

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

        insert new List<LASERCA__Personal_Credit_Report__c>{creditReportRecordRetired, creditReportRecordSelfEmployed, creditReportRecordMSLP};

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
        insert new List<LASERCA__Trade_Accounts__c>{tradeAccountRecordRetired, tradeAccountRecordSelfEmployed, tradeAccountRecordMSLP};                 
       
        return leadList;

    }
    
    private static Product2 getDefaultProduct(String state, Decimal interestRate, Integer term, Integer platformFee, 
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
                            isActive = TRUE);
    }
}
