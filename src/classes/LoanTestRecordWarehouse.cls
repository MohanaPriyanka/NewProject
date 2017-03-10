@isTest
public class LoanTestRecordWarehouse {

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

        Product2 productLoanMATerm10Rate599 = new Product2(Name = 'BlueWave Solar Loan - MA - 10 Year Term - 5.99%',
                                                            Family = 'Solar Loan',
                                                            Product_Type__c = 'Residential Loan',
                                                            State__c = 'MA',
                                                            Loan_Interest_Rate__c = .0599,
                                                            Loan_Term__c = 10,
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
        Product2 productLoanMATerm10Rate699 = new Product2(Name = 'BlueWave Solar Loan - MA - 10 Year Term - 6.99%',
                                                            Family = 'Solar Loan',
                                                            Product_Type__c = 'Residential Loan',
                                                            State__c = 'MA',
                                                            Loan_Interest_Rate__c = .0699,
                                                            Loan_Term__c = 10,
                                                            Loan_Interest_Only_Period__c = 12,
                                                            Loan_Financing_Fee_Terms__c = 'Maximum (5%, $1,250)',
                                                            Disbursal_Terms__c = '30% Contract Signature, 60% Mechanical Installation, 10% Interconnection',
                                                            ProductCode = 'BlueWave Solar Loan - MA - 10 Year Term - 6.99%',
                                                            Loan_base_rate__c = .0625,
                                                            Loan_Internal_Lender_rate__c = .0499,
                                                            Credit_Maximum__c = '749',
                                                            Credit_Minimum__c = '700',
                                                            Loan_Capital_Pool__c = capitalPool.Id,
                                                            Loan_Tranche_Type__c = 'Standard',
                                                            Program__c = 'BlueWave Solar Loan',
                                                            isActive = TRUE);
        Product2 productLoanMATerm10Rate725 = new Product2(Name = 'BlueWave Solar Loan - MA - 10 Year Term - 7.25%',
                                                            Family = 'Solar Loan',
                                                            Product_Type__c = 'Residential Loan',
                                                            State__c = 'MA',
                                                            Loan_Interest_Rate__c = .0725,
                                                            Loan_Term__c = 10,
                                                            Loan_Interest_Only_Period__c = 12,
                                                            Loan_Financing_Fee_Terms__c = 'Maximum (5%, $1,250)',
                                                            Disbursal_Terms__c = '30% Contract Signature, 60% Mechanical Installation, 10% Interconnection',
                                                            ProductCode = 'BlueWave Solar Loan - MA - 10 Year Term - 7.25%',
                                                            Loan_base_rate__c = .0625,
                                                            Loan_Internal_Lender_rate__c = .0499,
                                                            Credit_Maximum__c = '699',
                                                            Credit_Minimum__c = '680',
                                                            Loan_Capital_Pool__c = capitalPool.Id,
                                                            Loan_Tranche_Type__c = 'Standard',
                                                            Program__c = 'BlueWave Solar Loan',
                                                            isActive = TRUE);
        Product2 productLoanMATerm20Rate599 = new Product2(Name = 'BlueWave Solar Loan - MA - 20 Year Term - 5.99%',
                                                            Family = 'Solar Loan',
                                                            Product_Type__c = 'Residential Loan',
                                                            State__c = 'MA',
                                                            Loan_Interest_Rate__c = .0599,
                                                            Loan_Term__c = 20,
                                                            Loan_Interest_Only_Period__c = 12,
                                                            Loan_Financing_Fee_Terms__c = 'Maximum (5%, $1,250)',
                                                            Disbursal_Terms__c = '30% Contract Signature, 60% Mechanical Installation, 10% Interconnection',
                                                            ProductCode = 'BlueWave Solar Loan - MA - 20 Year Term - 5.99%',
                                                            Loan_base_rate__c = .0625,
                                                            Loan_Internal_Lender_rate__c = .0499,
                                                            Credit_Maximum__c = '999',
                                                            Credit_Minimum__c = '750',
                                                            Loan_Capital_Pool__c = capitalPool.Id,
                                                            Loan_Tranche_Type__c = 'Standard',
                                                            Program__c = 'BlueWave Solar Loan',
                                                            isActive = TRUE);
        Product2 productLoanMATerm20Rate699 = new Product2(Name = 'BlueWave Solar Loan - MA - 20 Year Term - 6.99%',
                                                            Family = 'Solar Loan',
                                                            Product_Type__c = 'Residential Loan',
                                                            State__c = 'MA',
                                                            Loan_Interest_Rate__c = .0699,
                                                            Loan_Term__c = 20,
                                                            Loan_Interest_Only_Period__c = 12,
                                                            Loan_Financing_Fee_Terms__c = 'Maximum (7%, $1,250)',
                                                            Disbursal_Terms__c = '30% Contract Signature, 60% Mechanical Installation, 10% Interconnection',
                                                            ProductCode = 'BlueWave Solar Loan - MA - 20 Year Term - 6.99%',
                                                            Loan_base_rate__c = .0625,
                                                            Loan_Internal_Lender_rate__c = .0499,
                                                            Credit_Maximum__c = '749',
                                                            Credit_Minimum__c = '700',
                                                            Loan_Capital_Pool__c = capitalPool.Id,
                                                            Loan_Tranche_Type__c = 'Standard',
                                                            Program__c = 'BlueWave Solar Loan',
                                                            isActive = TRUE);
        Product2 productLoanMATerm20Rate725 = new Product2(Name = 'BlueWave Solar Loan - MA - 20 Year Term - 7.25%',
                                                            Family = 'Solar Loan',
                                                            Product_Type__c = 'Residential Loan',
                                                            State__c = 'MA',
                                                            Loan_Interest_Rate__c = .0725,
                                                            Loan_Term__c = 20,
                                                            Loan_Interest_Only_Period__c = 12,
                                                            Loan_Financing_Fee_Terms__c = 'No Financing Fee',
                                                            Disbursal_Terms__c = '35% Contract Signature, 65% Interconnection',
                                                            ProductCode = 'BlueWave Solar Loan - MA - 20 Year Term - 7.25%',
                                                            Loan_base_rate__c = .0625,
                                                            Loan_Internal_Lender_rate__c = .0499,
                                                            Credit_Maximum__c = '699',
                                                            Credit_Minimum__c = '680',
                                                            Loan_Capital_Pool__c = capitalPool.Id,
                                                            Loan_Tranche_Type__c = 'Standard',
                                                            Program__c = 'MSLP',
                                                            IsActive = TRUE);

        return new List<Product2>{productLoanMATerm10Rate599, productLoanMATerm10Rate699, productLoanMATerm10Rate725, productLoanMATerm20Rate599, productLoanMATerm20Rate699, productLoanMATerm20Rate725};                                                                                                                                                             
    }
    public static List<Lead> getLoanLeadswithVariableFICOsandTerms () {         
        Partner__c partner = new Partner__c(Name = 'Partner');
        insert partner;

        BSST__c salesRep = new BSST__c(Name = 'SalesRep', Partner__c = partner.Id, Custom_ID__c = 'test', Email__c = 'SalesRep@Sales.com');
        insert salesRep;

        List<Lead> leadList = new List<Lead>();
        Lead leadMALoanTerm10Rate699 = new lead(FirstName = 'leadMALoanTerm10Rate699',
                                                LastName = 'Test',
                                                Loan_Amount__c = 35000,
                                                Company = 'Cole Swain',
                                                Product_Line__c = 'Residential Loan',
                                                LASERCA__Home_State__c = 'MA',
                                                System_Cost__c = 35000,
                                                Custom_Id__c = 'test',
                                                Partner_Lookup__c = partner.Id,
                                                //Personal_Credit_Report__c = pcr10710.Id,
                                                Loan_Term__c = 10,
                                                Annual_Income_Currency__c = 150000,
                                                Product__c = null,
                                                Product_Program__c = 'BlueWave Solar Loan',
                                                Pre_Approval_Form__c = true,
                                                Unfinished_Lead__c = true,
                                                Automatic_Product_Assignment__c = true,
                                                Status = 'Ready for Credit Check');
        Lead leadMALoanTerm10Rate599 = new lead(FirstName = 'leadMALoanTerm10Rate599',
                                                LastName = 'Test',
                                                Loan_Amount__c = 35000,
                                                Company = 'Cole Swain',
                                                Product_Line__c = 'Residential Loan',
                                                LASERCA__Home_State__c = 'MA',
                                                System_Cost__c = 35000,
                                                Custom_Id__c = 'test',
                                                Partner_Lookup__c = partner.Id,
                                                //Personal_Credit_Report__c = pcr10780.Id,
                                                Loan_Term__c = 10,
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
                                                System_Cost__c = 35000,
                                                Custom_Id__c = 'test',
                                                Partner_Lookup__c = partner.Id,
                                                //Personal_Credit_Report__c = pcr10690.Id,
                                                Loan_Term__c = 10,
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
                                                System_Cost__c = 35000,
                                                Custom_Id__c = 'test',
                                                Partner_Lookup__c = partner.Id,
                                                //Personal_Credit_Report__c = pcr20710.Id,
                                                Loan_Term__c = 20,
                                                Annual_Income_Currency__c = 150000,
                                                Product__c = null,
                                                Product_Program__c = 'BlueWave Solar Loan',
                                                Automatic_Product_Assignment__c = true,
                                                Status = 'Ready for Credit Check');
        Lead leadMALoanTerm20Rate599 = new lead(FirstName = 'leadMALoanTerm20Rate599',
                                                LastName = 'Test',
                                                Loan_Amount__c = 35000,
                                                Company = 'Cole Swain',
                                                Product_Line__c = 'Residential Loan',
                                                LASERCA__Home_State__c = 'MA',
                                                System_Cost__c = 35000,
                                                Custom_Id__c = 'test',
                                                Partner_Lookup__c = partner.Id,
                                                //Personal_Credit_Report__c = pcr20780.Id,
                                                Loan_Term__c = 20,
                                                Product_Program__c = 'BlueWave Solar Loan',
                                                Pre_Approval_Form__c = true,
                                                Unfinished_Lead__c = true,
                                                Annual_Income_Currency__c = 150000,
                                                Product__c = null,
                                                Automatic_Product_Assignment__c = true,
                                                Status = 'Ready for Credit Check');                                                         
        Lead leadMALoanTerm20Rate725 = new lead(FirstName = 'leadMALoanTerm20Rate725',
                                                LastName = 'Test',
                                                Loan_Amount__c = 35000,
                                                DOER_Solar_Loan__c = true,
                                                Company = 'Cole Swain',
                                                Product_Line__c = 'Residential Loan',
                                                LASERCA__Home_State__c = 'MA',
                                                System_Cost__c = 35000,
                                                Custom_Id__c = 'test',
                                                Partner_Lookup__c = partner.Id,
                                                //Personal_Credit_Report__c = pcr20690.Id,
                                                Loan_Term__c = 20,
                                                Product_Program__c = 'MSLP',
                                                Pre_Approval_Form__c = true,
                                                Unfinished_Lead__c = true,
                                                Annual_Income_Currency__c = 150000,
                                                Product__c = null,
                                                Automatic_Product_Assignment__c = true,
                                                Status = 'Ready for Credit Check'); 
        Insert new List<Lead>{leadMALoanTerm10Rate699, /*leadMALoanTerm10Rate599,*/ leadMALoanTerm10Rate725, 
                                leadMALoanTerm20Rate699, /*leadMALoanTerm20Rate599,*/ leadMALoanTerm20Rate725}; 
        //
        LASERCA__Personal_Credit_Report__c pcr10710 = new LASERCA__Personal_Credit_Report__c(
                                                                                            Name = 'Personal Credit Report 1',
                                                                                            LASERCA__Code__c ='001',
                                                                                            LASERCA__Code_2__c ='001',
                                                                                            LASERCA__Code_3__c = '001',
                                                                                            LASERCA__Code_4__c = '001',
                                                                                            LASERCA__Credit_Score_TransUnion__c = '710',
                                                                                            LASERCA__Lead__c = leadMALoanTerm10Rate699.Id);
        LASERCA__Personal_Credit_Report__c pcr10780 = new LASERCA__Personal_Credit_Report__c(
                                                                                            Name = 'Personal Credit Report 2',
                                                                                            LASERCA__Code__c ='001',
                                                                                            LASERCA__Code_2__c ='001',
                                                                                            LASERCA__Code_3__c = '001',
                                                                                            LASERCA__Code_4__c = '001',                                                                                                                    
                                                                                            LASERCA__Credit_Score_TransUnion__c = '750',
                                                                                            LASERCA__Lead__c = leadMALoanTerm10Rate599.Id);
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
        LASERCA__Personal_Credit_Report__c pcr20780 = new LASERCA__Personal_Credit_Report__c(
                                                                                            Name = 'Personal Credit Report 5',
                                                                                            LASERCA__Code__c ='001',
                                                                                            LASERCA__Code_2__c ='001',
                                                                                            LASERCA__Code_3__c = '001',
                                                                                            LASERCA__Code_4__c = '001',                                                                                                                    
                                                                                            LASERCA__Credit_Score_TransUnion__c = '750',
                                                                                            LASERCA__Lead__c = leadMALoanTerm20Rate599.Id);
        LASERCA__Personal_Credit_Report__c pcr20690 = new LASERCA__Personal_Credit_Report__c(           
                                                                                            Name = 'Personal Credit Report 6',
                                                                                            LASERCA__Code__c ='001',
                                                                                            LASERCA__Code_2__c ='001',
                                                                                            LASERCA__Code_3__c = '001',
                                                                                            LASERCA__Code_4__c = '001',                                                                                                                    
                                                                                            LASERCA__Credit_Score_TransUnion__c = '690',
                                                                                            LASERCA__Lead__c = leadMALoanTerm20Rate725.Id);        
        insert new List<LASERCA__Personal_Credit_Report__c>{pcr10710, /*pcr10780,*/ pcr10690, pcr20710, /*pcr20780,*/ pcr20690};

        LASERCA__Trade_Accounts__c pcr10710Trade = new LASERCA__Trade_Accounts__c(
                                                                                Name = 'Personal Credit Report Trade 1',
                                                                                LASERCA__Personal_Credit_Report__c = pcr10710.Id,
                                                                                LASERCA__Monthly_Payment__c = 100);
        LASERCA__Trade_Accounts__c pcr10780Trade = new LASERCA__Trade_Accounts__c(
                                                                                Name = 'Personal Credit Report Trade 2',
                                                                                LASERCA__Personal_Credit_Report__c = pcr10780.Id,
                                                                                LASERCA__Monthly_Payment__c = 100);
        LASERCA__Trade_Accounts__c pcr10690Trade = new LASERCA__Trade_Accounts__c(
                                                                                Name = 'Personal Credit Report Trade 3',
                                                                                LASERCA__Personal_Credit_Report__c = pcr10690.Id,
                                                                                LASERCA__Monthly_Payment__c = 100);
        LASERCA__Trade_Accounts__c pcr20710Trade = new LASERCA__Trade_Accounts__c(
                                                                                Name = 'Personal Credit Report Trade 4',
                                                                                LASERCA__Personal_Credit_Report__c = pcr20710.Id,
                                                                                LASERCA__Monthly_Payment__c = 100);
        LASERCA__Trade_Accounts__c pcr20780Trade = new LASERCA__Trade_Accounts__c(
                                                                                Name = 'Personal Credit Report Trade 5',
                                                                                LASERCA__Personal_Credit_Report__c = pcr20780.Id,
                                                                                LASERCA__Monthly_Payment__c = 100);
        LASERCA__Trade_Accounts__c pcr20690Trade = new LASERCA__Trade_Accounts__c(
                                                                                Name = 'Personal Credit Report Trade 6',
                                                                                LASERCA__Personal_Credit_Report__c = pcr20690.Id,
                                                                                LASERCA__Monthly_Payment__c = 100);
        insert new List<LASERCA__Trade_Accounts__c>{pcr10710Trade,/* pcr10780Trade,*/ pcr10690Trade, pcr20710Trade, /*pcr20780Trade, */pcr20690Trade};        
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
                                                Loan_Interest_Rate__c = .0599,
                                                Loan_Term__c = 120,
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


        return new List<Product2>{productRecord};                                                                                                                                                             
    }

    public static List<Lead> getLoanHandlerLeadRecords () {         
        Partner__c partner = new Partner__c(Name = 'BlueWave Customer Care');
        insert partner;

        BSST__c salesRep = new BSST__c(Name = 'Cole Swain', Partner__c = partner.Id, Custom_ID__c = 'test', Email__c = 'SalesRep@Sales.com');
        insert salesRep;

        List<Lead> leadList = new List<Lead>();
        Lead leadRecordRetired = new lead(FirstName = 'Retired',
                                    LastName = 'Test',
                                    Loan_Amount__c = 25000,
                                    Company = 'Cole Swain',
                                    Retired__c = true,
                                    LASERCA__Social_Security_Number__c = '000000001',
                                    Product_Line__c = 'Residential Loan',
                                    LASERCA__Home_State__c = 'MA',
                                    System_Cost__c = 25000,
                                    Custom_Id__c = 'test',
                                    Loan_Term__c = 120,
                                    Unfinished_Lead__c = true,                                     
                                    Partner_Lookup__c = partner.Id,
                                    //Personal_Credit_Report__c = creditReportRecord.Id,
                                    Annual_Income_Currency__c = 150000,
                                    Product__c = null,
                                    Product_Program__c = 'BlueWave Solar Loan',
                                    Automatic_Product_Assignment__c = true,
                                    Status = 'Ready for Credit Check');
        Lead leadRecordSelfEmployed = new lead(FirstName = 'SelfEmployed',
                                    LastName = 'Test',
                                    Loan_Amount__c = 25000,
                                    Company = 'Cole Swain',
                                    LASERCA__Social_Security_Number__c = '000000001',
                                    Retired__c = false,
                                    Self_Employed__c = true,
                                    Product_Line__c = 'Residential Loan',
                                    LASERCA__Home_State__c = 'MA',
                                    System_Cost__c = 25000,
                                    Custom_Id__c = 'test',
                                    Unfinished_Lead__c = true, 
                                    Partner_Lookup__c = partner.Id,
                                    //Personal_Credit_Report__c = creditReportRecord.Id,
                                    Loan_Term__c = 120,
                                    Annual_Income_Currency__c = 150000,
                                    Product__c = null,
                                    Product_Program__c = 'BlueWave Solar Loan',
                                    Automatic_Product_Assignment__c = true,
                                    Status = 'Ready for Credit Check');        
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
                                       System_Cost__c = 25000,
                                       Custom_Id__c = 'test',
                                       Unfinished_Lead__c = true, 
                                       Partner_Lookup__c = partner.Id,
                                       Loan_Term__c = 120,
                                       Annual_Income_Currency__c = 150000,
                                       Product__c = null,
                                       Automatic_Product_Assignment__c = true,
                                       Status = 'Credit not Checked',
                                       Technical_Approval_Verified__c = true,
                                       Income_Verified__c = true,
                                       Is_there_a_Partner_Record__c = true);
        leadList.add(leadRecordRetired);
        leadList.add(leadRecordSelfEmployed);
        leadList.add(leadRecordDOER);
        Insert leadList;

        Residential_Equipment__c equipmentRecordRetired = new Residential_Equipment__c(Name = 'equipmentRecordRetired',
                                                                                Lead__c = leadRecordRetired.Id,
                                                                                Generator_Nameplate_Capacity__c = 5,
                                                                                Type_of_Module__c = 'SolarWorld',
                                                                                Type_of_Inverter__c = 'Enphase',
                                                                                Number_of_Inverters__c = 1,
                                                                                Module_Manufacturer__c = 'SolarWorld',
                                                                                Inverter_Manufacturer__c = 'SolarEdge',
                                                                                Inverter_Model_Number__c = 'IX500',
                                                                                Module_Model_Number__c = 'SW300',                                                                                
                                                                                Number_of_Modules__c = 5);        
        Residential_Equipment__c equipmentRecordSelfEmployed = new Residential_Equipment__c(Name = 'equipmentRecordSelfEmployed',
                                                                                Lead__c = leadRecordSelfEmployed.Id,
                                                                                Generator_Nameplate_Capacity__c = 5,
                                                                                Type_of_Module__c = 'SolarWorld',
                                                                                Type_of_Inverter__c = 'Enphase',
                                                                                Number_of_Inverters__c = 1,
                                                                                Module_Manufacturer__c = 'SolarWorld',
                                                                                Inverter_Manufacturer__c = 'SolarEdge',
                                                                                Inverter_Model_Number__c = 'IX500',
                                                                                Module_Model_Number__c = 'SW300',        
                                                                                Number_of_Modules__c = 5);        
        Residential_Equipment__c equipmentRecordDOER = new Residential_Equipment__c(Name = 'equipmentRecordDOER',
                                                                                Lead__c = leadRecordDOER.Id,
                                                                                Generator_Nameplate_Capacity__c = 5,
                                                                                Type_of_Module__c = 'SolarWorld',
                                                                                Type_of_Inverter__c = 'Enphase',
                                                                                Module_Manufacturer__c = 'SolarWorld',
                                                                                Inverter_Manufacturer__c = 'SolarEdge',
                                                                                Inverter_Model_Number__c = 'IX500',
                                                                                Module_Model_Number__c = 'SW300',        
                                                                                Number_of_Inverters__c = 1,
                                                                                Number_of_Modules__c = 5);       
                                                                                 
        Insert new List<Residential_Equipment__c>{equipmentRecordRetired, equipmentRecordSelfEmployed, equipmentRecordDOER};  

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

        insert new List<LASERCA__Personal_Credit_Report__c>{creditReportRecordRetired, creditReportRecordSelfEmployed};

        LASERCA__Trade_Accounts__c tradeAccountRecordRetired = new LASERCA__Trade_Accounts__c(
                                                                                Name = 'Personal Credit Report Trade 1',
                                                                                LASERCA__Personal_Credit_Report__c = creditReportRecordRetired.Id,
                                                                                LASERCA__Monthly_Payment__c = 100);
        LASERCA__Trade_Accounts__c tradeAccountRecordSelfEmployed = new LASERCA__Trade_Accounts__c(
                                                                                Name = 'Personal Credit Report Trade 1',
                                                                                LASERCA__Personal_Credit_Report__c = creditReportRecordSelfEmployed.Id,
                                                                                LASERCA__Monthly_Payment__c = 100);        

        insert new List<LASERCA__Trade_Accounts__c>{tradeAccountRecordRetired, tradeAccountRecordSelfEmployed};                 
       
        return leadList;

    }    
}