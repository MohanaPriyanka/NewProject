@isTest
public class LoanTestRecordWarehouse {

    public static List<Product2> getLoanProductsVariableInterestRatesandTerms () { 

        Loan_Data__c capitalPool = new Loan_Data__c(Name = 'Revolving Credit Line',
                                                Total_Capital__c = 10000000,
                                                Investor__c = 'The Bank',
                                                Pool_Type__c = 'Revolving Credit Line');
        insert capitalPool;

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
                                                            Program__c = null,
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
                                                            Program__c = null,
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
                                                            Program__c = null,
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
                                                            Program__c = null,
                                                            isActive = TRUE);
        Product2 productLoanMATerm20Rate699 = new Product2(Name = 'BlueWave Solar Loan - MA - 20 Year Term - 6.99%',
                                                            Family = 'Solar Loan',
                                                            Product_Type__c = 'Residential Loan',
                                                            State__c = 'MA',
                                                            Loan_Interest_Rate__c = .0699,
                                                            Loan_Term__c = 20,
                                                            Loan_Interest_Only_Period__c = 12,
                                                            Loan_Financing_Fee_Terms__c = 'Maximum (5%, $1,250)',
                                                            Disbursal_Terms__c = '30% Contract Signature, 60% Mechanical Installation, 10% Interconnection',
                                                            ProductCode = 'BlueWave Solar Loan - MA - 20 Year Term - 6.99%',
                                                            Loan_base_rate__c = .0625,
                                                            Loan_Internal_Lender_rate__c = .0499,
                                                            Credit_Maximum__c = '749',
                                                            Credit_Minimum__c = '700',
                                                            Loan_Capital_Pool__c = capitalPool.Id,
                                                            Loan_Tranche_Type__c = 'Standard',
                                                            Program__c = null,
                                                            isActive = TRUE);
        Product2 productLoanMATerm20Rate725 = new Product2(Name = 'BlueWave Solar Loan - MA - 20 Year Term - 7.25%',
                                                            Family = 'Solar Loan',
                                                            Product_Type__c = 'Residential Loan',
                                                            State__c = 'MA',
                                                            Loan_Interest_Rate__c = .0725,
                                                            Loan_Term__c = 20,
                                                            Loan_Interest_Only_Period__c = 12,
                                                            Loan_Financing_Fee_Terms__c = 'Maximum (5%, $1,250)',
                                                            Disbursal_Terms__c = '30% Contract Signature, 60% Mechanical Installation, 10% Interconnection',
                                                            ProductCode = 'BlueWave Solar Loan - MA - 20 Year Term - 7.25%',
                                                            Loan_base_rate__c = .0625,
                                                            Loan_Internal_Lender_rate__c = .0499,
                                                            Credit_Maximum__c = '699',
                                                            Credit_Minimum__c = '680',
                                                            Loan_Capital_Pool__c = capitalPool.Id,
                                                            Loan_Tranche_Type__c = 'Standard',
                                                            Program__c = null,
                                                            IsActive = TRUE);

        return new List<Product2>{productLoanMATerm10Rate599, productLoanMATerm10Rate699, productLoanMATerm10Rate725, productLoanMATerm20Rate599, productLoanMATerm20Rate699, productLoanMATerm20Rate725};                                                                                                                                                             
    }
    public static List<Lead> getLoanLeadswithVariableFICOsandTerms () {         
    
        List<Lead> leadList = new List<Lead>();
        Lead leadMALoanTerm10Rate699 = new lead(FirstName = 'leadMALoanTerm10Rate699',
                                                LastName = 'Test',
                                                Loan_Amount__c = 35000,
                                                Company = 'Cole Swain',
                                                Product_Line__c = 'Residential Loan',
                                                LASERCA__Home_State__c = 'MA',
                                                System_Cost__c = 35000,
                                                //Personal_Credit_Report__c = pcr10710.Id,
                                                Loan_Term__c = 10,
                                                Annual_Income_Currency__c = 150000,
                                                Product__c = null,
                                                Automatic_Product_Assignment__c = true,
                                                Status = 'Ready for Credit Check');
        Lead leadMALoanTerm10Rate599 = new lead(FirstName = 'leadMALoanTerm10Rate599',
                                                LastName = 'Test',
                                                Loan_Amount__c = 35000,
                                                Company = 'Cole Swain',
                                                Product_Line__c = 'Residential Loan',
                                                LASERCA__Home_State__c = 'MA',
                                                System_Cost__c = 35000,
                                                //Personal_Credit_Report__c = pcr10780.Id,
                                                Loan_Term__c = 10,
                                                Annual_Income_Currency__c = 150000,
                                                Product__c = null,
                                                Automatic_Product_Assignment__c = true,
                                                Status = 'Ready for Credit Check');                                                       
        Lead leadMALoanTerm10Rate725 = new lead(FirstName = 'leadMALoanTerm10Rate725',
                                                LastName = 'Test',
                                                Loan_Amount__c = 35000,
                                                Company = 'Cole Swain',
                                                Product_Line__c = 'Residential Loan',
                                                LASERCA__Home_State__c = 'MA',
                                                System_Cost__c = 35000,
                                                //Personal_Credit_Report__c = pcr10690.Id,
                                                Loan_Term__c = 10,
                                                Annual_Income_Currency__c = 150000,
                                                Product__c = null,
                                                Automatic_Product_Assignment__c = true,
                                                Status = 'Ready for Credit Check');
        Lead leadMALoanTerm20Rate699 = new lead(FirstName = 'leadMALoanTerm20Rate699',
                                                LastName = 'Test',
                                                Loan_Amount__c = 35000,
                                                Company = 'Cole Swain',
                                                Product_Line__c = 'Residential Loan',
                                                LASERCA__Home_State__c = 'MA',
                                                System_Cost__c = 35000,
                                                //Personal_Credit_Report__c = pcr20710.Id,
                                                Loan_Term__c = 20,
                                                Annual_Income_Currency__c = 150000,
                                                Product__c = null,
                                                Automatic_Product_Assignment__c = true,
                                                Status = 'Ready for Credit Check');
        Lead leadMALoanTerm20Rate599 = new lead(FirstName = 'leadMALoanTerm20Rate599',
                                                LastName = 'Test',
                                                Loan_Amount__c = 35000,
                                                Company = 'Cole Swain',
                                                Product_Line__c = 'Residential Loan',
                                                LASERCA__Home_State__c = 'MA',
                                                System_Cost__c = 35000,
                                                //Personal_Credit_Report__c = pcr20780.Id,
                                                Loan_Term__c = 20,
                                                Annual_Income_Currency__c = 150000,
                                                Product__c = null,
                                                Automatic_Product_Assignment__c = true,
                                                Status = 'Ready for Credit Check');                                                         
        Lead leadMALoanTerm20Rate725 = new lead(FirstName = 'leadMALoanTerm20Rate725',
                                                LastName = 'Test',
                                                Loan_Amount__c = 35000,
                                                Company = 'Cole Swain',
                                                Product_Line__c = 'Residential Loan',
                                                LASERCA__Home_State__c = 'MA',
                                                System_Cost__c = 35000,
                                                //Personal_Credit_Report__c = pcr20690.Id,
                                                Loan_Term__c = 20,
                                                Annual_Income_Currency__c = 150000,
                                                Product__c = null,
                                                Automatic_Product_Assignment__c = true,
                                                Status = 'Ready for Credit Check'); 
        Insert new List<Lead>{leadMALoanTerm10Rate699, leadMALoanTerm10Rate599, leadMALoanTerm10Rate725, leadMALoanTerm20Rate699, leadMALoanTerm20Rate599, leadMALoanTerm20Rate725}; 
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
        insert new List<LASERCA__Personal_Credit_Report__c>{pcr10710, pcr10780, pcr10690, pcr20710, pcr20780, pcr20690};
        //

        //leadMALoanTerm10Rate699.Personal_Credit_Report__c = pcr10710.Id;
        //leadList.add(leadMALoanTerm10Rate699);
        //update leadList;
        //leadMALoanTerm10Rate599.Personal_Credit_Report__c = pcr10780.Id;
        //leadList.add(leadMALoanTerm10Rate599);
        //leadMALoanTerm10Rate725.Personal_Credit_Report__c = pcr10690.Id;
        //leadList.add(leadMALoanTerm10Rate725);
        //leadMALoanTerm20Rate699.Personal_Credit_Report__c = pcr20710.Id;
        //leadList.add(leadMALoanTerm20Rate699);
        //leadMALoanTerm20Rate599.Personal_Credit_Report__c = pcr20780.Id;
        //leadList.add(leadMALoanTerm20Rate599);
        //leadMALoanTerm20Rate725.Personal_Credit_Report__c = pcr20690.Id;
        //leadList.add(leadMALoanTerm20Rate725);
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
        insert new List<LASERCA__Trade_Accounts__c>{pcr10710Trade, pcr10780Trade, pcr10690Trade, pcr20710Trade, pcr20780Trade, pcr20690Trade};        
        //
       
        return leadList;

    }
}