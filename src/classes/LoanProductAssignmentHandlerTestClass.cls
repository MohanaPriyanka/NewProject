@isTest
public class LoanProductAssignmentHandlerTestClass {
    @testSetup public static void setupTestData(){

        List<Product2> productList = new List<Product2>(LoanTestRecordWarehouse.getLoanProductsVariableInterestRatesandTerms());
        insert productList;
        System.debug(productList);

        List<lead> leadList = new List<lead>(LoanTestRecordWarehouse.getLoanLeadswithVariableFICOsandTerms());
        //insert leadList;
        System.debug(leadList);     

    }
    @isTest static void testLoanProductAssignment() {
 
        Test.startTest();
        
        //List<LASERCA__Personal_Credit_Report__c> pcrList = [SELECT Id, Name FROM LASERCA__Personal_Credit_Report__c];
        //System.debug('pcrlist' + ' ' + pcrList);    
        //update pcrList;

        List<Lead> qualifiedLeadList = new list<Lead>();
        Map<String, lead> qualifiedLeadMap = new Map<String,Lead>();        
        for(lead leadRecord : [SELECT Id, Name, Status, FirstName, Product__c, Product__r.Id FROM Lead]){
            leadRecord.Status = 'Qualified';
            System.debug('The Product ID is ' + leadRecord.Product__r.Id);
            qualifiedLeadMap.put(leadRecord.FirstName, leadRecord);
        }
        update qualifiedLeadMap.values();
        System.debug('The updated qualifiedLeadMap is' + qualifiedLeadMap.values());
        
        Map<String, lead> updatedLeadMap = new Map<String,Lead>();        
        for(lead leadRecord : [SELECT Id, Name, Status, FirstName, Product__c, Product__r.Id, Technology_Platform_Fee__c
                               FROM Lead]){

            updatedLeadMap.put(leadRecord.FirstName, leadRecord);
            System.debug('The updatedLeadMap is ' + updatedLeadMap);
        }        

        Map<String, Product2> productMap = new Map<String,Product2>();                
        for(Product2 productRecord : [SELECT Id, Name FROM Product2]){
            productMap.put(productRecord.Name, productRecord);
        }     

        Lead verifyLeadMALoanTerm10Rate699 = updatedLeadMap.get('leadMALoanTerm10Rate699');
        System.debug(verifyleadMALoanTerm10Rate699.Product__r.Id);
        System.debug(productMap.get('BlueWave Solar Loan - MA - 10 Year Term - 6.99%').Id);
        System.assert(verifyleadMALoanTerm10Rate699.Product__r.Id == productMap.get('BlueWave Solar Loan - MA - 10 Year Term - 6.99%').Id);
        System.debug('Assertion 1 passed');
        Lead verifyLeadMALoanTerm10Rate599 = updatedLeadMap.get('leadMALoanTerm10Rate599');
        System.assert(verifyleadMALoanTerm10Rate699.Technology_Platform_Fee__c == 1750); // should be 5%

        //System.debug(verifyleadMALoanTerm10Rate599.Product__r.Id);
        //System.debug(productMap.get('BlueWave Solar Loan - MA - 10 Year Term - 5.99%').Id);
        //System.assert(verifyleadMALoanTerm10Rate599.Product__r.Id == productMap.get('BlueWave Solar Loan - MA - 10 Year Term - 5.99%').Id);

        Lead verifyLeadMALoanTerm10Rate725 = updatedLeadMap.get('leadMALoanTerm10Rate725');
        System.debug(verifyleadMALoanTerm10Rate725.Product__r.Id);
        System.debug(productMap.get('BlueWave Solar Loan - MA - 10 Year Term - 7.25%').Id);
        System.assert(verifyleadMALoanTerm10Rate725.Product__r.Id == productMap.get('BlueWave Solar Loan - MA - 10 Year Term - 7.25%').Id);
        System.assert(verifyleadMALoanTerm10Rate725.Technology_Platform_Fee__c == 0);  // should be 0%  

        Lead verifyLeadMALoanTerm20Rate699 = updatedLeadMap.get('leadMALoanTerm20Rate699');
        System.debug(verifyleadMALoanTerm20Rate699.Product__r.Id);
        System.debug(productMap.get('BlueWave Solar Loan - MA - 20 Year Term - 6.99%').Id);
        System.assert(verifyleadMALoanTerm20Rate699.Product__r.Id == productMap.get('BlueWave Solar Loan - MA - 20 Year Term - 6.99%').Id);
        System.assert(verifyleadMALoanTerm20Rate699.Technology_Platform_Fee__c == 2450); // should be 7%

        //Lead verifyLeadMALoanTerm20Rate599 = updatedLeadMap.get('leadMALoanTerm20Rate599');
        //System.debug(verifyleadMALoanTerm20Rate599.Product__r.Id);
        //System.debug(productMap.get('BlueWave Solar Loan - MA - 20 Year Term - 5.99%').Id);
        //System.assert(verifyleadMALoanTerm20Rate599.Product__r.Id == productMap.get('BlueWave Solar Loan - MA - 20 Year Term - 5.99%').Id);

        Lead verifyLeadMALoanTerm20Rate725 = updatedLeadMap.get('leadMALoanTerm20Rate725');
        System.debug(verifyleadMALoanTerm20Rate725.Product__r.Id);
        System.debug(productMap.get('BlueWave Solar Loan - MA - 20 Year Term - 7.25%').Id);
        System.assert(verifyleadMALoanTerm20Rate725.Product__r.Id == productMap.get('BlueWave Solar Loan - MA - 20 Year Term - 7.25%').Id);   
        System.assert(verifyleadMALoanTerm20Rate725.Technology_Platform_Fee__c == 1750); // should be 5%

        Test.stopTest();
    }
}
/*@isTest
private class LoanProductAssignmentHandlerTestClass {
    
    @isTest static void test_method_one() {

        Loan_Data__c capitalPool = (Loan_Data__c)TestFactory.createSObject(new Loan_Data__c(Name = 'Revolving Credit Line',
                                                                                                Total_Capital__c = 10000000,
                                                                                                Investor__c = 'The Bank',
                                                                                                Pool_Type__c = 'Revolving Credit Line'));
        insert capitalPool;

        Product2 productLoanMATerm10Rate599 = (Product2)TestFactory.createSObject(new Product2(Name = 'BlueWave Solar Loan - MA - 10 Year Term - 5.99%',
                                                                            Family = 'Solar Loan',
                                                                            Product_Type__c = 'Residential Loan',
                                                                            State__c = 'MA',
                                                                            Loan_Interest_Rate__c = .0599,
                                                                            Loan_Term__c = 10,
                                                                            Loan_Interest_Only_Period__c = 12,
                                                                            Loan_Financing_Fee_Terms__c = 'Maximum (5%, $1,250)',
                                                                            Disbursal_Terms__c = '30% Contract Signature, 60% Mechanical Installation, 10% PTO',
                                                                            ProductCode = 'BlueWave Solar Loan - MA - 10 Year Term - 5.99%',
                                                                            Loan_base_rate__c = .0625,
                                                                            Loan_Internal_Lender_rate__c = .0499,
                                                                            Credit_Maximum__c = '999',
                                                                            Credit_Minimum__c = '750',
                                                                            Loan_Capital_Pool__c = capitalPool.Id,
                                                                            Loan_Tranche_Type__c = 'Standard',
                                                                            isActive = TRUE));
        Product2 productLoanMATerm10Rate699 = (Product2)TestFactory.createSObject(new Product2(Name = 'BlueWave Solar Loan - MA - 10 Year Term - 6.99%',
                                                                            Family = 'Solar Loan',
                                                                            Product_Type__c = 'Residential Loan',
                                                                            State__c = 'MA',
                                                                            Loan_Interest_Rate__c = .0699,
                                                                            Loan_Term__c = 10,
                                                                            Loan_Interest_Only_Period__c = 12,
                                                                            Loan_Financing_Fee_Terms__c = 'Maximum (5%, $1,250)',
                                                                            Disbursal_Terms__c = '30% Contract Signature, 60% Mechanical Installation, 10% PTO',
                                                                            ProductCode = 'BlueWave Solar Loan - MA - 10 Year Term - 6.99%',
                                                                            Loan_base_rate__c = .0625,
                                                                            Loan_Internal_Lender_rate__c = .0499,
                                                                            Credit_Maximum__c = '749',
                                                                            Credit_Minimum__c = '700',
                                                                            Loan_Capital_Pool__c = capitalPool.Id,
                                                                            Loan_Tranche_Type__c = 'Standard',
                                                                            isActive = TRUE));
        Product2 productLoanMATerm10Rate725 = (Product2)TestFactory.createSObject(new Product2(Name = 'BlueWave Solar Loan - MA - 10 Year Term - 7.25%',
                                                                            Family = 'Solar Loan',
                                                                            Product_Type__c = 'Residential Loan',
                                                                            State__c = 'MA',
                                                                            Loan_Interest_Rate__c = .0725,
                                                                            Loan_Term__c = 10,
                                                                            Loan_Interest_Only_Period__c = 12,
                                                                            Loan_Financing_Fee_Terms__c = 'Maximum (5%, $1,250)',
                                                                            Disbursal_Terms__c = '30% Contract Signature, 60% Mechanical Installation, 10% PTO',
                                                                            ProductCode = 'BlueWave Solar Loan - MA - 10 Year Term - 7.25%',
                                                                            Loan_base_rate__c = .0625,
                                                                            Loan_Internal_Lender_rate__c = .0499,
                                                                            Credit_Maximum__c = '699',
                                                                            Credit_Minimum__c = '680',
                                                                            Loan_Capital_Pool__c = capitalPool.Id,
                                                                            Loan_Tranche_Type__c = 'Standard',
                                                                            isActive = TRUE));
        Product2 productLoanMATerm20Rate599 = (Product2)TestFactory.createSObject(new Product2(Name = 'BlueWave Solar Loan - MA - 20 Year Term - 5.99%',
                                                                            Family = 'Solar Loan',
                                                                            Product_Type__c = 'Residential Loan',
                                                                            State__c = 'MA',
                                                                            Loan_Interest_Rate__c = .0599,
                                                                            Loan_Term__c = 20,
                                                                            Loan_Interest_Only_Period__c = 12,
                                                                            Loan_Financing_Fee_Terms__c = 'Maximum (5%, $1,250)',
                                                                            Disbursal_Terms__c = '30% Contract Signature, 60% Mechanical Installation, 10% PTO',
                                                                            ProductCode = 'BlueWave Solar Loan - MA - 20 Year Term - 5.99%',
                                                                            Loan_base_rate__c = .0625,
                                                                            Loan_Internal_Lender_rate__c = .0499,
                                                                            Credit_Maximum__c = '999',
                                                                            Credit_Minimum__c = '750',
                                                                            Loan_Capital_Pool__c = capitalPool.Id,
                                                                            Loan_Tranche_Type__c = 'Standard',
                                                                            isActive = TRUE));
        Product2 productLoanMATerm20Rate699 = (Product2)TestFactory.createSObject(new Product2(Name = 'BlueWave Solar Loan - MA - 20 Year Term - 6.99%',
                                                                            Family = 'Solar Loan',
                                                                            Product_Type__c = 'Residential Loan',
                                                                            State__c = 'MA',
                                                                            Loan_Interest_Rate__c = .0699,
                                                                            Loan_Term__c = 20,
                                                                            Loan_Interest_Only_Period__c = 12,
                                                                            Loan_Financing_Fee_Terms__c = 'Maximum (5%, $1,250)',
                                                                            Disbursal_Terms__c = '30% Contract Signature, 60% Mechanical Installation, 10% PTO',
                                                                            ProductCode = 'BlueWave Solar Loan - MA - 20 Year Term - 6.99%',
                                                                            Loan_base_rate__c = .0625,
                                                                            Loan_Internal_Lender_rate__c = .0499,
                                                                            Credit_Maximum__c = '749',
                                                                            Credit_Minimum__c = '700',
                                                                            Loan_Capital_Pool__c = capitalPool.Id,
                                                                            Loan_Tranche_Type__c = 'Standard',
                                                                            isActive = TRUE));
        Product2 productLoanMATerm20Rate725 = (Product2)TestFactory.createSObject(new Product2(Name = 'BlueWave Solar Loan - MA - 20 Year Term - 7.25%',
                                                                            Family = 'Solar Loan',
                                                                            Product_Type__c = 'Residential Loan',
                                                                            State__c = 'MA',
                                                                            Loan_Interest_Rate__c = .0725,
                                                                            Loan_Term__c = 20,
                                                                            Loan_Interest_Only_Period__c = 12,
                                                                            Loan_Financing_Fee_Terms__c = 'Maximum (5%, $1,250)',
                                                                            Disbursal_Terms__c = '30% Contract Signature, 60% Mechanical Installation, 10% PTO',
                                                                            ProductCode = 'BlueWave Solar Loan - MA - 20 Year Term - 7.25%',
                                                                            Loan_base_rate__c = .0625,
                                                                            Loan_Internal_Lender_rate__c = .0499,
                                                                            Credit_Maximum__c = '699',
                                                                            Credit_Minimum__c = '680',
                                                                            Loan_Capital_Pool__c = capitalPool.Id,
                                                                            Loan_Tranche_Type__c = 'Standard',
                                                                            isActive = TRUE));                                                                                
        insert new List<Product2>{productLoanMATerm10Rate599, productLoanMATerm10Rate699, productLoanMATerm10Rate725, productLoanMATerm20Rate599, productLoanMATerm20Rate699, productLoanMATerm20Rate725};                                                                                                                                                             
        
        LASERCA__Personal_Credit_Report__c pcr710 = (LASERCA__Personal_Credit_Report__c)TestFactory.createSObject(new LASERCA__Personal_Credit_Report__c(Name = 'Personal Credit Report 1',
                                                                                                                    LASERCA__Credit_Score_TransUnion__c = '730'));
        LASERCA__Personal_Credit_Report__c pcr780 = (LASERCA__Personal_Credit_Report__c)TestFactory.createSObject(new LASERCA__Personal_Credit_Report__c(Name = 'Personal Credit Report 2',
                                                                                                                    LASERCA__Credit_Score_TransUnion__c = '750'));
        LASERCA__Personal_Credit_Report__c pcr690 = (LASERCA__Personal_Credit_Report__c)TestFactory.createSObject(new LASERCA__Personal_Credit_Report__c(Name = 'Personal Credit Report 3',
                                                                                                                    LASERCA__Credit_Score_TransUnion__c = '690'));
        insert new List<LASERCA__Personal_Credit_Report__c>{pcr710, pcr780, pcr690};        
        

        Lead leadMALoanTerm10Rate699 = (Lead)TestFactory.createSObject(new lead(FirstName = 'leadMALoanTerm10Rate710',
                                                                            LastName = 'Test',
                                                                            Company = 'Cole Swain',
                                                                            Product_Line__c = 'Residential Loan',
                                                                            LASERCA__Home_State__c = 'MA',
                                                                            Requested_Loan_Amount__c = 35000,
                                                                            Personal_Credit_Report__c = pcr710.Id,
                                                                            Loan_Term__c = 10,
                                                                            Annual_Income_Currency__c = 150000,
                                                                            Status = 'Ready for Credit Check'));
        Lead leadMALoanTerm10Rate599 = (Lead)TestFactory.createSObject(new lead(FirstName = 'leadMALoanTerm10Rate780',
                                                                            LastName = 'Test',
                                                                            Company = 'Cole Swain',
                                                                            Product_Line__c = 'Residential Loan',
                                                                            LASERCA__Home_State__c = 'MA',
                                                                            Requested_Loan_Amount__c = 35000,
                                                                            Personal_Credit_Report__c = pcr780.Id,
                                                                            Loan_Term__c = 10,
                                                                            Annual_Income_Currency__c = 150000,
                                                                            Status = 'Ready for Credit Check'));        
        Lead leadMALoanTerm10Rate725 = (Lead)TestFactory.createSObject(new lead(FirstName = 'leadMALoanTerm10Rate690',
                                                                            LastName = 'Test',
                                                                            Company = 'Cole Swain',
                                                                            Product_Line__c = 'Residential Loan',
                                                                            LASERCA__Home_State__c = 'MA',
                                                                            Requested_Loan_Amount__c = 35000,
                                                                            Personal_Credit_Report__c = pcr690.Id,
                                                                            Loan_Term__c = 10,
                                                                            Annual_Income_Currency__c = 150000,
                                                                            Status = 'Ready for Credit Check'));
        Lead leadMALoanTerm20Rate699 = (Lead)TestFactory.createSObject(new lead(FirstName = 'leadMALoanTerm10Rate710',
                                                                            LastName = 'Test',
                                                                            Company = 'Cole Swain',
                                                                            Product_Line__c = 'Residential Loan',
                                                                            LASERCA__Home_State__c = 'MA',
                                                                            Requested_Loan_Amount__c = 35000,
                                                                            Personal_Credit_Report__c = pcr710.Id,
                                                                            Loan_Term__c = 20,
                                                                            Annual_Income_Currency__c = 150000,
                                                                            Status = 'Ready for Credit Check'));
        Lead leadMALoanTerm20Rate599 = (Lead)TestFactory.createSObject(new lead(FirstName = 'leadMALoanTerm10Rate780',
                                                                            LastName = 'Test',
                                                                            Company = 'Cole Swain',
                                                                            Product_Line__c = 'Residential Loan',
                                                                            LASERCA__Home_State__c = 'MA',
                                                                            Requested_Loan_Amount__c = 35000,
                                                                            Personal_Credit_Report__c = pcr780.Id,
                                                                            Loan_Term__c = 20,
                                                                            Annual_Income_Currency__c = 150000,
                                                                            Status = 'Ready for Credit Check'));        
        Lead leadMALoanTerm20Rate725 = (Lead)TestFactory.createSObject(new lead(FirstName = 'leadMALoanTerm10Rate690',
                                                                            LastName = 'Test',
                                                                            Company = 'Cole Swain',
                                                                            Product_Line__c = 'Residential Loan',
                                                                            LASERCA__Home_State__c = 'MA',
                                                                            Requested_Loan_Amount__c = 35000,
                                                                            Personal_Credit_Report__c = pcr690.Id,
                                                                            Loan_Term__c = 20,
                                                                            Annual_Income_Currency__c = 150000,
                                                                            Status = 'Ready for Credit Check'));

        insert new List<Lead>{leadMALoanTerm10Rate699, leadMALoanTerm10Rate599, leadMALoanTerm10Rate725, leadMALoanTerm20Rate699, leadMALoanTerm20Rate599, leadMALoanTerm20Rate725}; 

        Test.startTest();

        List<Lead> qualifiedLeadList = new list<lead>();
        for(lead leadRecord : [SELECT Id, Name, Status FROM lead WHERE Product_Line__c = 'Residential Loan']){
            leadRecord.Status = 'Qualified';
            qualifiedLeadList.add(leadRecord);
        }
        update qualifiedLeadList;

        Test.stopTest();

        Lead verifyLeadMALoanTerm10Rate699 = [Select Id, Name, Product__c, Product__r.Id  From Lead Where Id = :leadMALoanTerm10Rate699.Id];
        System.debug(leadMALoanTerm10Rate699);
        System.debug(verifyleadMALoanTerm10Rate699);
        System.debug(productLoanMATerm10Rate699.Id);
        System.assert(verifyleadMALoanTerm10Rate699.Product__r.Id == productLoanMATerm10Rate699.Id);

        Lead verifyLeadMALoanTerm10Rate599 = [Select Id, Name, Product__c, Product__r.Id  From Lead Where Id = :leadMALoanTerm10Rate599.Id];
        System.debug(leadMALoanTerm10Rate599);
        System.debug(verifyleadMALoanTerm10Rate599);
        System.debug(productLoanMATerm10Rate599.Id);        
        System.assert(verifyleadMALoanTerm10Rate599.Product__r.Id == productLoanMATerm10Rate599.Id);        

        Lead verifyLeadMALoanTerm10Rate725 = [Select Id, Name, Product__c, Product__r.Id  From Lead Where Id = :leadMALoanTerm10Rate725.Id];
        System.debug(leadMALoanTerm10Rate725);
        System.debug(verifyleadMALoanTerm10Rate725);
        System.debug(productLoanMATerm10Rate725.Id); 
        System.assert(verifyleadMALoanTerm10Rate725.Product__r.Id == productLoanMATerm10Rate725.Id);

        Lead verifyLeadMALoanTerm20Rate699 = [Select Id, Name, Product__c, Product__r.Id  From Lead Where Id = :leadMALoanTerm20Rate699.Id];
        System.debug(leadMALoanTerm20Rate699);
        System.debug(verifyleadMALoanTerm20Rate699);
        System.debug(productLoanMATerm20Rate699.Id); 
        System.assert(verifyleadMALoanTerm20Rate699.Product__r.Id == productLoanMATerm20Rate699.Id);        

        Lead verifyLeadMALoanTerm20Rate599 = [Select Id, Name, Product__c, Product__r.Id  From Lead Where Id = :leadMALoanTerm20Rate599.Id];
        System.debug(leadMALoanTerm20Rate599);
        System.debug(verifyleadMALoanTerm20Rate599);
        System.debug(productLoanMATerm20Rate599.Id); 
        System.assert(verifyleadMALoanTerm20Rate599.Product__r.Id == productLoanMATerm20Rate599.Id);
        
        Lead verifyLeadMALoanTerm20Rate725 = [Select Id, Name, Product__c, Product__r.Id  From Lead Where Id = :leadMALoanTerm20Rate725.Id];
        System.debug(leadMALoanTerm20Rate725);
        System.debug(verifyleadMALoanTerm20Rate725);
        System.debug(productLoanMATerm20Rate725.Id);     
        System.assert(verifyleadMALoanTerm20Rate725.Product__r.Id == productLoanMATerm20Rate725.Id);

    }
}*/