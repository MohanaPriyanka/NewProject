/**
 * Created by: Kristin White on 9/29/2020
 * 
 */

@IsTest
private class UtilityDataRequestServiceTest {
    
    @TestVisible
    private static UtilityDataRequestPeriodSelector udrpSelector = new UtilityDataRequestPeriodSelector();
    
    @TestSetup
    public static void setupData() {
        
        Partner__c testPartner = new Partner__c(
    		Name = 'Default CS Partner',
    		Email__c = 'default@email.com'
		);
		insert testPartner;
		TestFactory.setDefaultCSPartner(testPartner.Id);
        
        Utility__c testUtility = new Utility__c(
            Name = 'testUtility',
            Utility_DUNS_Number__c = '1234567890',
            Utility_Data_Collection_Mechanism__c = 'EDI'
        );
        insert testUtility;
        
        State__c stateMA = new State__c(
        	Name = 'MA',
        	Avg_Annual_Resi_kWh__c = 165200
        );
        insert stateMA;
        
        Product2 testProduct = new Product2(
            Name = 'testProduct',
            X4_month_sizing_method__c = 'State Average Annual Usage'
        );
        insert testProduct;
        
        Lead nonResiLead = new Lead(
            Product__c = testProduct.Id,
        	Customer_type__c = 'Commercial',
            LastName = 'testLead1',
            Company = 'testBlueWave1',
            Partner_Lookup__c = testPartner.Id,
            Utility_relationship__c = testUtility.Id
        );
        
        Lead resiLead = new Lead(
            Product__c = testProduct.Id,
        	Customer_type__c = 'Residential',
            LastName = 'testLead2',
            Company = 'testBlueWave2',
            Partner_Lookup__c = testPartner.Id
        );
        
        List<Lead> testLeadList = new List<Lead>{nonResiLead, resiLead};
        insert testLeadList;
        
        Utility_Account_Log__c testUAL1 = new Utility_Account_Log__c(
            Lead__c = resiLead.Id,
            Utility_lookup__c = testUtility.Id,
            Username__c = 'testUAL1',
            Name_on_Account__c = 'Tom',
            Service_Address__c = '66 Mass Ave',
            Service_City__c = 'Boston',
            Service_State__c = 'MA',
            Service_Zip_Code__c = '02115'
        );
        
        Utility_Account_Log__c testUAL2 = new Utility_Account_Log__c(
            Lead__c = resiLead.Id,
            Username__c = 'testUAL2',
            Name_on_Account__c = 'Tim',
            Service_Address__c = '32 Quincy St, apt 20',
            Service_City__c = 'Cambridge',
            Service_State__c = 'ma',
            Service_Zip_Code__c = '02138'
        );
        
        Utility_Account_Log__c testUAL3 = new Utility_Account_Log__c(
            Lead__c = nonResiLead.Id,
            Username__c = 'testUAL3',
            Name_on_Account__c = 'Jim',
            Service_Address__c = '249 Pearl St.',
            Service_City__c = 'Somerville',
            Service_State__c = 'MA',
            Service_Zip_Code__c = '02145'
        );
        
        Utility_Account_Log__c testUAL4 = new Utility_Account_Log__c(
            Lead__c = resiLead.Id,
            Username__c = 'testUAL4',
            Name_on_Account__c = 'Bill',
            Service_Address__c = '459  Broadway',
            Service_City__c = 'Everett',
            Service_State__c = 'MA',
            Service_Zip_Code__c = '02149'
        );
        
        Utility_Account_Log__c testUAL5 = new Utility_Account_Log__c(
            Lead__c = resiLead.Id,
            Username__c = 'testUAL5',
            Name_on_Account__c = 'Bob',
            Service_Address__c = '1 brighton ave, 20',
            Service_City__c = 'Allston',
            Service_State__c = 'MA',
            Service_Zip_Code__c = '02134'
        );
        
        Utility_Account_Log__c testUAL6 = new Utility_Account_Log__c(	        
        Lead__c = resiLead.Id,	
        Username__c = 'testUAL6',	
        Name_on_Account__c = 'Kris',	
        Service_Address__c = '32 Quincy St, apt 20',	
        Service_City__c = 'Cambridge',	
        Service_State__c = 'ma',	
        Service_Zip_Code__c = '02138'	
    );	

        List<Utility_Account_Log__c> testUALList = new List<Utility_Account_Log__c>{testUAL1, testUAL2, testUAL3, testUAL4, testUAL5, testUAL6};
        insert testUALList;
        
        Utility_Data_Request__c testUDR1 = new Utility_Data_Request__c(
            Header_Status__c        = 'Pending',
            Detail_Status__c        = 'Pending',
            Old_Account_Number__c = 'testUDR1',
            Utility_Account_Log__c = testUAL1.Id,
            Utility__c = testUtility.Id,
            Government_Credit_Code__c = 'N',
            LDC_Customer_Eligibility__c = 'N',
            Customer_Name__c = 'Tom',
            Address_Line_1__c = '#66 Mass. Ave. ',
            Address_Line_2__c = '',
            City__c = 'boston ',
            State__c = 'Ma.',
            Zip_Code__c = '   02115  '
        );
        
        
        Utility_Data_Request__c testUDR2 = new Utility_Data_Request__c(
            Header_Status__c        = 'Complete',
            Detail_Status__c        = 'Complete',
            Old_Account_Number__c = 'testUDR2',
            Utility_Account_Log__c = testUAL2.Id,
            Utility__c = testUtility.Id,
            Government_Credit_Code__c = 'N',
            LDC_Customer_Eligibility__c = 'N',
            Customer_Name__c = 'Tim',
            Address_Line_1__c = '32 Quincy St,',
            Address_Line_2__c = 'Apt 20',
            City__c = 'Combridge',
            State__c = 'MA',
            Zip_Code__c = '02138 '
        );
        
        Utility_Data_Request__c testUDR3 = new Utility_Data_Request__c(
            Header_Status__c        = 'Pending',
            Detail_Status__c        = 'Pending',
            Old_Account_Number__c = 'testUDR3',
            Utility_Account_Log__c = testUAL3.Id,
            Utility__c = testUtility.Id,
            Government_Credit_Code__c = 'N',
            LDC_Customer_Eligibility__c = 'Y',
            Customer_Name__c = 'Jim',
            Address_Line_1__c = '249 Pearl St',
            Address_Line_2__c = '',
            City__c = 'Somerville',
            State__c = 'MA',
            Zip_Code__c = '02145'
        );
        
        Utility_Data_Request__c testUDR4 = new Utility_Data_Request__c(
            Header_Status__c        = 'Pending',
            Detail_Status__c        = 'Pending',
            Old_Account_Number__c = 'testUDR4',
            Utility_Account_Log__c = testUAL4.Id,
            Utility__c = testUtility.Id,
            Government_Credit_Code__c = 'Y',
            LDC_Customer_Eligibility__c = 'N',
            Customer_Name__c = 'Bill',
            Address_Line_1__c = '458 Broadway',
            Address_Line_2__c = '',
            City__c = 'Everett',
            State__c = 'MA',
            Zip_Code__c = '02149'
        );
        
        Utility_Data_Request__c testUDR5 = new Utility_Data_Request__c(
            Header_Status__c        = 'Pending',
            Detail_Status__c        = 'Pending',
            Old_Account_Number__c = 'testUDR5',
            Utility_Account_Log__c = testUAL5.Id,
            Utility__c = testUtility.Id,
            Government_Credit_Code__c = 'Y',
            LDC_Customer_Eligibility__c = 'Y',
            Customer_Name__c = 'Bob',
            Address_Line_1__c = '1 Brighton Ave',
            Address_Line_2__c = 'Unit 20',
            City__c = 'Allston',
            State__c = 'Ma',
            Zip_Code__c = '02134'
        );

        Utility_Data_Request__c testUDR6 = new Utility_Data_Request__c(
            Header_Status__c        = 'Pending',
            Detail_Status__c        = 'Pending',
            Old_Account_Number__c = 'testUDR6',	
            Utility_Account_Log__c = testUAL6.Id,	
            Utility__c = testUtility.Id,	
            Government_Credit_Code__c = 'N',	
            LDC_Customer_Eligibility__c = 'N',	
            Customer_Name__c = 'Kris',	
            Address_Line_1__c = '32 Quincy St,',	
            Address_Line_2__c = 'Apt 20',	
            City__c = 'Combridge',	
            State__c = 'MA',	
            Zip_Code__c = '02138 '	
        );	

        List<Utility_Data_Request__c> testUDRList = new List<Utility_Data_Request__c>{testUDR1, testUDR2, testUDR3, testUDR4, testUDR5, testUDR6};
        
        insert testUDRList;
        
        Rate_Class__c testRateClass1 = new Rate_Class__c(
            EDI_Rate_Class__c = 'Test EDI Rate Class 1',
            Name = 'testRateClass1',
            Utility__c = testUtility.Id
        );
        
        Rate_Class__c testRateClass2 = new Rate_Class__c(
            EDI_Rate_Class__c = 'Test EDI Rate Class 2',
            Name = 'testRateClass2',
            Utility__c = testUtility.Id
        );
        
        List<Rate_Class__c> testRateClassList = new List<Rate_Class__c>{testRateClass1, testRateClass2};
        insert testRateClassList;
        
        Utility_Data_Request_Period__c testUDRP1 = new Utility_Data_Request_Period__c(
            Utility_Data_Request__c = testUDR1.Id, 
            Rate_Class__c = 'Test EDI Rate Class 1',
            Rate_Subclass__c = 'Test EDI Rate Class 1',
            Load_Profile_Description__c = 'testUDRP1',
            Service_Start_Date__c = Date.newInstance(2020, 5, 10),
            Measurement_Unit__c ='KH',
            Quantity__c = 25,
            Used_In_Annual_kWh_Calculation__c = false,
            Measurement_Significance_Code__c = '51'
        );
        
        Utility_Data_Request_Period__c testUDRP2 = new Utility_Data_Request_Period__c(
            Utility_Data_Request__c = testUDR1.Id, 
            Rate_Class__c = 'Test EDI Rate Class 2',
            Rate_Subclass__c = 'Test EDI Rate Class 2',
            Load_Profile_Description__c = 'testUDRP2',
            Service_Start_Date__c = Date.newInstance(2020, 7, 7),
            Measurement_Unit__c ='KH',
            Quantity__c = 101,
            Used_In_Annual_kWh_Calculation__c = false,
            Measurement_Significance_Code__c = '51'
        );
        
        Utility_Data_Request_Period__c testUDRP3 = new Utility_Data_Request_Period__c(
            Utility_Data_Request__c = testUDR1.Id, 
            Rate_Class__c = 'Test EDI Rate Class 2',
            Rate_Subclass__c = 'Test EDI Rate Class 2',
            Load_Profile_Description__c = 'testUDRP3',
            Service_Start_Date__c = Date.newInstance(2020, 10, 12),
            Measurement_Unit__c ='KH',
            Quantity__c = 6914,
            Used_In_Annual_kWh_Calculation__c = false,
            Measurement_Significance_Code__c = '51'
        );
        
        Utility_Data_Request_Period__c testUDRP4 = new Utility_Data_Request_Period__c(
            Utility_Data_Request__c = testUDR1.Id, 
            Rate_Class__c = null,
            Rate_Subclass__c = null,
            Load_Profile_Description__c = 'testUDRP4',
            Service_Start_Date__c = Date.newInstance(2020, 9, 15),
            Measurement_Unit__c ='KH',
            Quantity__c = 50,
            Used_In_Annual_kWh_Calculation__c = false,
            Measurement_Significance_Code__c = '51'
        );
        
        Utility_Data_Request_Period__c testUDRP5 = new Utility_Data_Request_Period__c(
            Utility_Data_Request__c = testUDR1.Id, 
            Rate_Class__c = 'Nonexistent/Misspelled EDI',
            Rate_Subclass__c = 'Nonexistent/Misspelled EDI',
            Load_Profile_Description__c = 'testUDRP5',
            Service_Start_Date__c = Date.newInstance(2020, 2, 1),
            Measurement_Unit__c ='KH',
            Quantity__c = 7003,
            Used_In_Annual_kWh_Calculation__c = false,
            Measurement_Significance_Code__c = '51'
        );
        
        Utility_Data_Request_Period__c testUDRP6 = new Utility_Data_Request_Period__c(
            Utility_Data_Request__c = testUDR2.Id, 
            Rate_Class__c = 'Test EDI Rate Class 2',
            Rate_Subclass__c = 'Test EDI Rate Class 2',
            Load_Profile_Description__c = 'testUDRP6',
            Service_Start_Date__c = Date.newInstance(2020, 9, 14),
            Measurement_Unit__c ='KH',
            Quantity__c = 1234,
            Used_In_Annual_kWh_Calculation__c = false,
            Measurement_Significance_Code__c = '51'
        );
        
        Utility_Data_Request_Period__c testUDRP7 = new Utility_Data_Request_Period__c(
            Utility_Data_Request__c = testUDR3.Id, 
            Rate_Class__c = 'Test EDI Rate Class 1',
            Rate_Subclass__c = 'Test EDI Rate Class 1',
            Load_Profile_Description__c = 'testUDRP7',
            Service_Start_Date__c = Date.newInstance(2020, 9, 1),
            Measurement_Unit__c ='KH',
            Quantity__c = 12099,
            Used_In_Annual_kWh_Calculation__c = false,
            Measurement_Significance_Code__c = '51'
        );
        
        Utility_Data_Request_Period__c testUDRP8 = new Utility_Data_Request_Period__c(
            Utility_Data_Request__c = testUDR4.Id, 
            Rate_Class__c = 'Test EDI Rate Class 1',
            Rate_Subclass__c = 'Test EDI Rate Class 1',
            Load_Profile_Description__c = 'testUDRP8',
            Service_Start_Date__c = Date.newInstance(2019, 5, 20),
            Measurement_Unit__c ='KH',
            Quantity__c = 4387,
            Used_In_Annual_kWh_Calculation__c = false,
            Measurement_Significance_Code__c = '51'
        );
        
        Utility_Data_Request_Period__c testUDRP9 = new Utility_Data_Request_Period__c(
            Utility_Data_Request__c = testUDR4.Id, 
            Rate_Class__c = 'Test EDI Rate Class 1',
            Rate_Subclass__c = 'Test EDI Rate Class 1',
            Load_Profile_Description__c = 'testUDRP9',
            Service_Start_Date__c = Date.newInstance(2020, 5, 20),
            Measurement_Unit__c ='KH',
            Quantity__c = 999,
            Used_In_Annual_kWh_Calculation__c = false,
            Measurement_Significance_Code__c = '51'
        );
        
        Utility_Data_Request_Period__c testUDRP10 = new Utility_Data_Request_Period__c(
            Utility_Data_Request__c = testUDR4.Id, 
            Rate_Class__c = 'Test EDI Rate Class 1',
            Rate_Subclass__c = 'Test EDI Rate Class 1',
            Load_Profile_Description__c = 'testUDRP10',
            Service_Start_Date__c = Date.newInstance(2020, 8, 28),
            Measurement_Unit__c ='KH',
            Quantity__c = 9757,
            Used_In_Annual_kWh_Calculation__c = false,
            Measurement_Significance_Code__c = '51'
        );
        
        Utility_Data_Request_Period__c testUDRP11 = new Utility_Data_Request_Period__c(
            Utility_Data_Request__c = testUDR5.Id, 
            Rate_Class__c = 'Test EDI Rate Class 1',
            Rate_Subclass__c = 'Test EDI Rate Class 1',
            Load_Profile_Description__c = 'testUDRP11',
            Service_Start_Date__c = Date.newInstance(2020, 10, 3),
            Measurement_Unit__c ='KH',
            Quantity__c = 6789,
            Used_In_Annual_kWh_Calculation__c = false,
            Measurement_Significance_Code__c = '51'
        );
        
        Utility_Data_Request_Period__c testUDRP12 = new Utility_Data_Request_Period__c(
            Utility_Data_Request__c = testUDR5.Id, 
            Rate_Class__c = 'Test EDI Rate Class 1',
            Rate_Subclass__c = 'Test EDI Rate Class 1',
            Load_Profile_Description__c = 'testUDRP12',
            Service_Start_Date__c = Date.newInstance(2019, 2, 22),
            Measurement_Unit__c ='KH',
            Quantity__c = 8311,
            Used_In_Annual_kWh_Calculation__c = false,
            Measurement_Significance_Code__c = '51'
        );
        
        Utility_Data_Request_Period__c testUDRP13 = new Utility_Data_Request_Period__c(
            Utility_Data_Request__c = testUDR5.Id, 
            Rate_Class__c = 'Test EDI Rate Class 1',
            Rate_Subclass__c = 'Test EDI Rate Class 1',
            Load_Profile_Description__c = 'testUDRP13',
            Service_Start_Date__c = Date.newInstance(2020, 9, 10),
            Measurement_Unit__c ='KH',
            Quantity__c = 11111,
            Used_In_Annual_kWh_Calculation__c = false,
            Measurement_Significance_Code__c = '51'
        );
        
        Utility_Data_Request_Period__c testUDRP14 = new Utility_Data_Request_Period__c(
            Utility_Data_Request__c = testUDR5.Id, 
            Rate_Class__c = 'Test EDI Rate Class 1',
            Rate_Subclass__c = 'Test EDI Rate Class 1',
            Load_Profile_Description__c = 'testUDRP14',
            Service_Start_Date__c = Date.newInstance(2020, 8, 3),
            Measurement_Unit__c ='KH',
            Quantity__c = 53977,
            Used_In_Annual_kWh_Calculation__c = false,
            Measurement_Significance_Code__c = '51'
        );
        
        Utility_Data_Request_Period__c testUDRP15 = new Utility_Data_Request_Period__c(
            Utility_Data_Request__c = testUDR5.Id, 
            Rate_Class__c = 'Test EDI Rate Class 1',
            Rate_Subclass__c = 'Test EDI Rate Class 1',
            Load_Profile_Description__c = 'testUDRP15',
            Service_Start_Date__c = Date.newInstance(2020, 7, 10),
            Measurement_Unit__c ='KH',
            Quantity__c = 2525,
            Used_In_Annual_kWh_Calculation__c = false,
            Measurement_Significance_Code__c = '51'
        );
        
        Utility_Data_Request_Period__c testUDRP16 = new Utility_Data_Request_Period__c(
            Utility_Data_Request__c = testUDR5.Id, 
            Rate_Class__c = 'EDI Rate Class 1',
            Rate_Subclass__c = 'Test EDI Rate Class 1',
            Load_Profile_Description__c = 'testUDRP16',
            Service_Start_Date__c = Date.newInstance(2020, 6, 28),
            Measurement_Unit__c ='KH',
            Quantity__c = 9222,
            Used_In_Annual_kWh_Calculation__c = false,
            Measurement_Significance_Code__c = '51'
        );
        
        Utility_Data_Request_Period__c testUDRP17 = new Utility_Data_Request_Period__c(
            Utility_Data_Request__c = testUDR5.Id, 
            Rate_Class__c = 'Test EDI Rate Class 1',
            Rate_Subclass__c = 'Test EDI Rate Class 1',
            Load_Profile_Description__c = 'testUDRP17',
            Service_Start_Date__c = Date.newInstance(2020, 5, 2),
            Measurement_Unit__c ='KH',
            Quantity__c = 88,
            Used_In_Annual_kWh_Calculation__c = false,
            Measurement_Significance_Code__c = '51'
        );
        
        Utility_Data_Request_Period__c testUDRP18 = new Utility_Data_Request_Period__c(
            Utility_Data_Request__c = testUDR5.Id, 
            Rate_Class__c = 'Test EDI Rate Class 1',
            Rate_Subclass__c = 'Test EDI Rate Class 1',
            Load_Profile_Description__c = 'testUDRP18',
            Service_Start_Date__c = Date.newInstance(2020, 4, 17),
            Measurement_Unit__c ='KH',
            Quantity__c = 417,
            Used_In_Annual_kWh_Calculation__c = false,
            Measurement_Significance_Code__c = '51'
        );
        
        Utility_Data_Request_Period__c testUDRP19 = new Utility_Data_Request_Period__c(
            Utility_Data_Request__c = testUDR5.Id, 
            Rate_Class__c = 'Test EDI Rate Class 1',
            Rate_Subclass__c = 'Test EDI Rate Class 1',
            Load_Profile_Description__c = 'testUDRP19',
            Service_Start_Date__c = Date.newInstance(2020, 3, 20),
            Measurement_Unit__c ='KH',
            Quantity__c = 4399,
            Used_In_Annual_kWh_Calculation__c = false,
            Measurement_Significance_Code__c = '51'
        );
        
        Utility_Data_Request_Period__c testUDRP20 = new Utility_Data_Request_Period__c(
            Utility_Data_Request__c = testUDR5.Id, 
            Rate_Class__c = 'Test EDI Rate Class 1',
            Rate_Subclass__c = 'Test EDI Rate Class 1',
            Load_Profile_Description__c = 'testUDRP20',
            Service_Start_Date__c = Date.newInstance(2020, 2, 19),
            Measurement_Unit__c ='KH',
            Quantity__c = 2019,
            Used_In_Annual_kWh_Calculation__c = false,
            Measurement_Significance_Code__c = '51'
        );
        
        Utility_Data_Request_Period__c testUDRP21 = new Utility_Data_Request_Period__c(
            Utility_Data_Request__c = testUDR5.Id, 
            Rate_Class__c = 'EDI Rate Class 1',
            Rate_Subclass__c = 'Test EDI Rate Class 1',
            Load_Profile_Description__c = 'testUDRP21',
            Service_Start_Date__c = Date.newInstance(2020, 1, 1),
            Measurement_Unit__c ='KH',
            Quantity__c = 334455,
            Used_In_Annual_kWh_Calculation__c = false,
            Measurement_Significance_Code__c = '51'
        );
        
        Utility_Data_Request_Period__c testUDRP22 = new Utility_Data_Request_Period__c(
            Utility_Data_Request__c = testUDR5.Id, 
            Rate_Class__c = 'Test EDI Rate Class 1',
            Rate_Subclass__c = 'Test EDI Rate Class 1',
            Load_Profile_Description__c = 'testUDRP22',
            Service_Start_Date__c = Date.newInstance(2020, 1, 2),
            Measurement_Unit__c ='KH',
            Quantity__c = 19788,
            Used_In_Annual_kWh_Calculation__c = false,
            Measurement_Significance_Code__c = '51'
        );
        
        Utility_Data_Request_Period__c testUDRP23 = new Utility_Data_Request_Period__c(
            Utility_Data_Request__c = testUDR5.Id, 
            Rate_Class__c = 'Rate Class 1',
            Rate_Subclass__c = 'Test EDI Rate Class 1',
            Load_Profile_Description__c = 'testUDRP23',
            Service_Start_Date__c = Date.newInstance(2019, 2, 19),
            Measurement_Unit__c ='KH',
            Quantity__c = 764655,
            Used_In_Annual_kWh_Calculation__c = false,
            Measurement_Significance_Code__c = '51'
        );
        
        Utility_Data_Request_Period__c testUDRP24 = new Utility_Data_Request_Period__c(
            Utility_Data_Request__c = testUDR5.Id, 
            Rate_Class__c = 'Test EDI Rate Class 1',
            Rate_Subclass__c = 'Test EDI Rate Class 1',
            Load_Profile_Description__c = 'testUDRP24',
            Service_Start_Date__c = Date.newInstance(2020, 4, 27),
            Measurement_Unit__c ='KH',
            Quantity__c = 42789,
            Used_In_Annual_kWh_Calculation__c = false,
            Measurement_Significance_Code__c = '51'
        );
        
        Utility_Data_Request_Period__c testUDRP25 = new Utility_Data_Request_Period__c(
            Utility_Data_Request__c = testUDR1.Id, 
            Rate_Class__c = 'Test EDI Rate Class 1',
            Rate_Subclass__c = 'Test EDI Rate Class 1',
            Load_Profile_Description__c = 'testUDRP25',
            Service_Start_Date__c = Date.newInstance(2020, 5, 11),
            Measurement_Unit__c ='K1',
            Quantity__c = 3690,
            Used_In_Average_Demand_Calculation__c = false,
            Measurement_Significance_Code__c = '51'
        );
        
        Utility_Data_Request_Period__c testUDRP26 = new Utility_Data_Request_Period__c(
            Utility_Data_Request__c = testUDR1.Id, 
            Rate_Class__c = 'Test EDI Rate Class 1',
            Rate_Subclass__c = 'Test EDI Rate Class 1',
            Load_Profile_Description__c = 'testUDRP26',
            Service_Start_Date__c = Date.newInstance(2020, 7, 7),
            Measurement_Unit__c ='K1',
            Quantity__c = 923,
            Used_In_Average_Demand_Calculation__c = false,
            Measurement_Significance_Code__c = '51'
        );
        
        Utility_Data_Request_Period__c testUDRP27 = new Utility_Data_Request_Period__c(
            Utility_Data_Request__c = testUDR1.Id, 
            Rate_Class__c = 'Test EDI Rate Class 2',
            Rate_Subclass__c = 'Test EDI Rate Class 2',
            Load_Profile_Description__c = 'testUDRP27',
            Service_Start_Date__c = Date.newInstance(2020, 10, 12),
            Measurement_Unit__c ='K1',
            Quantity__c = 100,
            Used_In_Average_Demand_Calculation__c = false,
            Measurement_Significance_Code__c = '51'
        );
        
        Utility_Data_Request_Period__c testUDRP28 = new Utility_Data_Request_Period__c(
            Utility_Data_Request__c = testUDR1.Id, 
            Rate_Class__c = null,
            Rate_Subclass__c = null,
            Load_Profile_Description__c = 'testUDRP28',
            Service_Start_Date__c = Date.newInstance(2020, 9, 16),
            Measurement_Unit__c ='K1',
            Quantity__c = 51,
            Used_In_Average_Demand_Calculation__c = false,
            Measurement_Significance_Code__c = '51'
        );
        
        Utility_Data_Request_Period__c testUDRP29 = new Utility_Data_Request_Period__c(
            Utility_Data_Request__c = testUDR1.Id, 
            Rate_Class__c = 'Nonexistent/Misspelled EDI',
            Rate_Subclass__c = 'Nonexistent/Misspelled EDI',
            Load_Profile_Description__c = 'testUDRP29',
            Service_Start_Date__c = Date.newInstance(2020, 2, 1),
            Measurement_Unit__c ='K1',
            Quantity__c = 7000,
            Used_In_Average_Demand_Calculation__c = false,
            Measurement_Significance_Code__c = '51'
        );
        
        Utility_Data_Request_Period__c testUDRP30 = new Utility_Data_Request_Period__c(
            Utility_Data_Request__c = testUDR3.Id, 
            Rate_Class__c = 'Test EDI Rate Class 1',
            Rate_Subclass__c = 'Test EDI Rate Class 1',
            Load_Profile_Description__c = 'testUDRP30',
            Service_Start_Date__c = Date.newInstance(2020, 9, 2),
            Measurement_Unit__c ='K1',
            Quantity__c = 99,
            Used_In_Average_Demand_Calculation__c = false,
            Measurement_Significance_Code__c = '51'
        );
        
        Utility_Data_Request_Period__c testUDRP31 = new Utility_Data_Request_Period__c(
            Utility_Data_Request__c = testUDR3.Id, 
            Rate_Class__c = 'Test EDI Rate Class 1',
            Rate_Subclass__c = 'Test EDI Rate Class 1',
            Load_Profile_Description__c = 'testUDRP31',
            Service_Start_Date__c = Date.newInstance(2020, 9, 12),
            Measurement_Unit__c ='K1',
            Quantity__c = 999,
            Used_In_Average_Demand_Calculation__c = false,
            Measurement_Significance_Code__c = '51'
        );
        
        Utility_Data_Request_Period__c testUDRP32 = new Utility_Data_Request_Period__c(
            Utility_Data_Request__c = testUDR4.Id, 
            Rate_Class__c = 'Test EDI Rate Class 1',
            Rate_Subclass__c = 'Test EDI Rate Class 1',
            Load_Profile_Description__c = 'testUDRP32',
            Service_Start_Date__c = Date.newInstance(2019, 5, 20),
            Measurement_Unit__c ='K1',
            Quantity__c = 9122,
            Used_In_Average_Demand_Calculation__c = false,
            Measurement_Significance_Code__c = '51'
        );
        
        Utility_Data_Request_Period__c testUDRP33 = new Utility_Data_Request_Period__c(
            Utility_Data_Request__c = testUDR4.Id, 
            Rate_Class__c = 'Test EDI Rate Class 1',
            Rate_Subclass__c = 'Test EDI Rate Class 1',
            Load_Profile_Description__c = 'testUDRP33',
            Service_Start_Date__c = Date.newInstance(2020, 5, 20),
            Measurement_Unit__c ='K1',
            Quantity__c = 429,
            Used_In_Average_Demand_Calculation__c = false,
            Measurement_Significance_Code__c = '51'
        );
        
        Utility_Data_Request_Period__c testUDRP34 = new Utility_Data_Request_Period__c(
            Utility_Data_Request__c = testUDR4.Id, 
            Rate_Class__c = 'Test EDI Rate Class 1',
            Rate_Subclass__c = 'Test EDI Rate Class 1',
            Load_Profile_Description__c = 'testUDRP34',
            Service_Start_Date__c = Date.newInstance(2020, 8, 28),
            Measurement_Unit__c ='K1',
            Quantity__c = 832,
            Used_In_Average_Demand_Calculation__c = false,
            Measurement_Significance_Code__c = '51'
        );
        
        Utility_Data_Request_Period__c testUDRP35 = new Utility_Data_Request_Period__c(
            Utility_Data_Request__c = testUDR5.Id, 
            Rate_Class__c = 'Test EDI Rate Class 1',
            Rate_Subclass__c = 'Test EDI Rate Class 1',
            Load_Profile_Description__c = 'testUDRP35',
            Service_Start_Date__c = Date.newInstance(2020, 10, 3),
            Measurement_Unit__c ='K1',
            Quantity__c = 3322,
            Used_In_Average_Demand_Calculation__c = false,
            Measurement_Significance_Code__c = '51'
        );
        
        Utility_Data_Request_Period__c testUDRP36 = new Utility_Data_Request_Period__c(
            Utility_Data_Request__c = testUDR5.Id, 
            Rate_Class__c = 'Test EDI Rate Class 1',
            Rate_Subclass__c = 'Test EDI Rate Class 1',
            Load_Profile_Description__c = 'testUDRP36',
            Service_Start_Date__c = Date.newInstance(2019, 2, 22),
            Measurement_Unit__c ='K1',
            Quantity__c = 311,
            Used_In_Average_Demand_Calculation__c = false,
            Measurement_Significance_Code__c = '51'
        );
        
        Utility_Data_Request_Period__c testUDRP37 = new Utility_Data_Request_Period__c(
            Utility_Data_Request__c = testUDR5.Id, 
            Rate_Class__c = 'Test EDI Rate Class 1',
            Rate_Subclass__c = 'Test EDI Rate Class 1',
            Load_Profile_Description__c = 'testUDRP37',
            Service_Start_Date__c = Date.newInstance(2020, 9, 10),
            Measurement_Unit__c ='K1',
            Quantity__c = 1211,
            Used_In_Average_Demand_Calculation__c = false,
            Measurement_Significance_Code__c = '51'
        );
        
        Utility_Data_Request_Period__c testUDRP38 = new Utility_Data_Request_Period__c(
            Utility_Data_Request__c = testUDR5.Id, 
            Rate_Class__c = 'Test EDI Rate Class 1',
            Rate_Subclass__c = 'Test EDI Rate Class 1',
            Load_Profile_Description__c = 'testUDRP38',
            Service_Start_Date__c = Date.newInstance(2020, 8, 3),
            Measurement_Unit__c ='K1',
            Quantity__c = 4181,
            Used_In_Average_Demand_Calculation__c = false,
            Measurement_Significance_Code__c = '51'
        );
        
        Utility_Data_Request_Period__c testUDRP39 = new Utility_Data_Request_Period__c(
            Utility_Data_Request__c = testUDR5.Id, 
            Rate_Class__c = 'Test EDI Rate Class 1',
            Rate_Subclass__c = 'Test EDI Rate Class 1',
            Load_Profile_Description__c = 'testUDRP39',
            Service_Start_Date__c = Date.newInstance(2020, 7, 10),
            Measurement_Unit__c ='K1',
            Quantity__c = 2626,
            Used_In_Average_Demand_Calculation__c = false,
            Measurement_Significance_Code__c = '51'
        );
        
        Utility_Data_Request_Period__c testUDRP40 = new Utility_Data_Request_Period__c(
            Utility_Data_Request__c = testUDR5.Id, 
            Rate_Class__c = 'EDI Rate Class 1',
            Rate_Subclass__c = 'Test EDI Rate Class 1',
            Load_Profile_Description__c = 'testUDRP40',
            Service_Start_Date__c = Date.newInstance(2020, 6, 28),
            Measurement_Unit__c ='K1',
            Quantity__c = 6565,
            Used_In_Average_Demand_Calculation__c = false,
            Measurement_Significance_Code__c = '51'
        );
        
        Utility_Data_Request_Period__c testUDRP41 = new Utility_Data_Request_Period__c(
            Utility_Data_Request__c = testUDR5.Id, 
            Rate_Class__c = 'Test EDI Rate Class 1',
            Rate_Subclass__c = 'Test EDI Rate Class 1',
            Load_Profile_Description__c = 'testUDRP41',
            Service_Start_Date__c = Date.newInstance(2020, 5, 2),
            Measurement_Unit__c ='K1',
            Quantity__c = 66,
            Used_In_Average_Demand_Calculation__c = false,
            Measurement_Significance_Code__c = '51'
        );
        
        Utility_Data_Request_Period__c testUDRP42 = new Utility_Data_Request_Period__c(
            Utility_Data_Request__c = testUDR5.Id, 
            Rate_Class__c = 'Test EDI Rate Class 1',
            Rate_Subclass__c = 'Test EDI Rate Class 1',
            Load_Profile_Description__c = 'testUDRP42',
            Service_Start_Date__c = Date.newInstance(2020, 4, 17),
            Measurement_Unit__c ='K1',
            Quantity__c = 400,
            Used_In_Average_Demand_Calculation__c = false,
            Measurement_Significance_Code__c = '51'
        );
        
        Utility_Data_Request_Period__c testUDRP43 = new Utility_Data_Request_Period__c(
            Utility_Data_Request__c = testUDR5.Id, 
            Rate_Class__c = 'Test EDI Rate Class 1',
            Rate_Subclass__c = 'Test EDI Rate Class 1',
            Load_Profile_Description__c = 'testUDRP43',
            Service_Start_Date__c = Date.newInstance(2020, 3, 21),
            Measurement_Unit__c ='K1',
            Quantity__c = 582,
            Used_In_Average_Demand_Calculation__c = false,
            Measurement_Significance_Code__c = '51'
        );
        
        Utility_Data_Request_Period__c testUDRP44 = new Utility_Data_Request_Period__c(
            Utility_Data_Request__c = testUDR5.Id, 
            Rate_Class__c = 'Test EDI Rate Class 1',
            Rate_Subclass__c = 'Test EDI Rate Class 1',
            Load_Profile_Description__c = 'testUDRP44',
            Service_Start_Date__c = Date.newInstance(2020, 2, 20),
            Measurement_Unit__c ='K1',
            Quantity__c = 2020,
            Used_In_Average_Demand_Calculation__c = false,
            Measurement_Significance_Code__c = '51'
        );
        
        Utility_Data_Request_Period__c testUDRP45 = new Utility_Data_Request_Period__c(
            Utility_Data_Request__c = testUDR5.Id, 
            Rate_Class__c = 'EDI Rate Class 1',
            Rate_Subclass__c = 'Test EDI Rate Class 1',
            Load_Profile_Description__c = 'testUDRP45',
            Service_Start_Date__c = Date.newInstance(2020, 1, 2),
            Measurement_Unit__c ='K1',
            Quantity__c = 345,
            Used_In_Average_Demand_Calculation__c = false,
            Measurement_Significance_Code__c = '51'
        );
        
        Utility_Data_Request_Period__c testUDRP46 = new Utility_Data_Request_Period__c(
            Utility_Data_Request__c = testUDR5.Id, 
            Rate_Class__c = 'Test EDI Rate Class 1',
            Rate_Subclass__c = 'Test EDI Rate Class 1',
            Load_Profile_Description__c = 'testUDRP46',
            Service_Start_Date__c = Date.newInstance(2020, 1, 2),
            Measurement_Unit__c ='K1',
            Quantity__c = 777,
            Used_In_Average_Demand_Calculation__c = false,
            Measurement_Significance_Code__c = '51'
        );
        
        Utility_Data_Request_Period__c testUDRP47 = new Utility_Data_Request_Period__c(
            Utility_Data_Request__c = testUDR5.Id, 
            Rate_Class__c = 'Test EDI Rate Class 1',
            Rate_Subclass__c = 'Test EDI Rate Class 1',
            Load_Profile_Description__c = 'testUDRP47',
            Service_Start_Date__c = Date.newInstance(2015, 1, 2),
            Measurement_Unit__c ='K1',
            Quantity__c = 10,
            Used_In_Average_Demand_Calculation__c = false,
            Measurement_Significance_Code__c = '51'
        );
        
        List<Utility_Data_Request_Period__c> testUDRPList = new List<Utility_Data_Request_Period__c>{
            testUDRP1, testUDRP2, testUDRP3, testUDRP4, testUDRP5, testUDRP6, testUDRP7, testUDRP8, 
            testUDRP9, testUDRP10, testUDRP11, testUDRP12, testUDRP13, testUDRP14, testUDRP15, testUDRP16, 
            testUDRP17, testUDRP18, testUDRP19, testUDRP20, testUDRP21, testUDRP22, testUDRP23, testUDRP24, 
            testUDRP25, testUDRP26, testUDRP27, testUDRP28, testUDRP29, testUDRP30, testUDRP31, testUDRP32, 
            testUDRP33, testUDRP34, testUDRP35, testUDRP36, testUDRP37, testUDRP38, testUDRP39, testUDRP40, 
            testUDRP41, testUDRP42, testUDRP43, testUDRP44, testUDRP45, testUDRP46, testUDRP47};
        insert testUDRPList;
    }

    private static Utility_Data_Request__c getTestUDR(String customerName) {
        return [
            SELECT Id, Request_Status_new__c, Header_Status__c, Detail_Status__c, Customer_Name__c, State__c, Utility__c, Annual_kWh__c, Average_Demand__c, 
                Utility_Account_Log__c, Utility_Account_Log__r.Utility_Rate_Class__c, Old_Account_Number__c,
            	Num_months_Annual_kWh__c, Num_months_Average_Demand__c, Government_Credit_Code__c, LDC_Customer_Eligibility__c
            FROM Utility_Data_Request__c
            WHERE Old_Account_Number__c = :customerName
        ];
    }

    private static Utility_Account_Log__c getTestUAL(Id ualId) {
        return [
            SELECT Id, Name, Name_on_Account__c, Service_Address__c, Service_City__c, Service_State__c,
                Service_Zip_Code__c, Annual_kWh__c, Annual_Cost_of_Electricity__c, Account__c, Lead__c,
                Average_Demand__c, Utility_lookup__c, Utility_Rate_Class__c, Utility_Rate_Class__r.Name,
            	Num_months_Annual_kWh__c, Num_months_Average_Demand__c, NYPA__c, RNY__c, Address_Update__c,
            	Username__c, Previous_Name_on_Utility_Account__c, Previous_Service_Address__c, QC_Status__c,
            	Previous_Service_City__c, Previous_Service_State__c, Previous_Service_Zip_Code__c
            FROM Utility_Account_Log__c
            WHERE Id = :ualId
        ];
    }

    private static Utility_Data_Request_Period__c getTestUDRP(String udrp) {
        return [
            SELECT Id, Name, Utility_Data_Request__c, Rate_Class__c, Rate_Class_Lookup__c, Service_Start_Date__c, 
            Utility_Data_Request__r.Utility__c, Utility_Data_Request__r.Utility_Account_Log__r.Utility_Rate_Class__c,
            Rate_Subclass__c, Load_Profile_Description__c, Used_In_Annual_kWh_Calculation__c, Used_In_Average_Demand_Calculation__c
            FROM Utility_Data_Request_Period__c 
            WHERE Load_Profile_Description__c = :udrp
        ];
    }

    private static List<Utility_Data_Request_Period__c> getTestUDRPList(Id udrId) {
        return [
            SELECT Id, Name, Utility_Data_Request__c, Rate_Class__c, Rate_Class_Lookup__c, Service_Start_Date__c, 
            Utility_Data_Request__r.Utility__c, Utility_Data_Request__r.Utility_Account_Log__r.Utility_Rate_Class__c,
            Rate_Subclass__c, Load_Profile_Description__c, Used_In_Annual_kWh_Calculation__c, Used_In_Average_Demand_Calculation__c
            FROM Utility_Data_Request_Period__c 
            WHERE Utility_Data_Request__c = :udrId
        ];
    }

    private static Rate_Class__c getTestRateClass(String name) {
        return [
            SELECT Id, Name, EDI_Rate_Class__c, Utility__c
            FROM Rate_Class__c
            WHERE Name = :name
        ];
    }

    private static Lead getTestLead(String lastName) {
        return [
            SELECT Id,
                (SELECT Id, Name, Utility_lookup__c, Utility_lookup__r.Utility_DUNS_Number__c, Utility_lookup__r.Name
                FROM Utility_Account_Logs__r)
            FROM Lead
            WHERE LastName = 'testLead1'];
    }

    private static Integer udrCount(Id ualId) {
        return [
            SELECT COUNT()
            FROM Utility_Data_Request__c
            WHERE Utility_Account_Log__c =: ualId
        ];
    }

    @IsTest
    static void testRateClass() {
        List<Error_Log__c> errorLogs = [SELECT Id, Class__c, Method__c, Message__c, Severity__c FROM Error_Log__c];
        System.assertEquals(0, errorLogs.size());
        
        Utility_Data_Request__c testUDR1 = getTestUDR('testUDR1');
        testUDR1.Header_Status__c = 'Complete';
        testUDR1.Detail_Status__c = 'Complete';
        update testUDR1;
        
        Utility_Account_Log__c testUAL1 = getTestUAL(testUDR1.Utility_Account_Log__c);
        List<Utility_Data_Request_Period__c> testUDRPList = getTestUDRPList(testUDR1.Id);
        
        Rate_Class__c testRateClass1 = getTestRateClass('testRateClass1');
        Rate_Class__c testRateClass2 = getTestRateClass('testRateClass2');
        
        System.assertEquals(testRateClass1.Id, testUDRPList[0].Rate_Class_Lookup__c, 
                            'The Rate_Class_Lookup__c for testUDRP1 should now be testRateClass1.');
        System.assertEquals(testRateClass2.Id, testUDRPList[1].Rate_Class_Lookup__c, 
                            'The Rate_Class_Lookup__c for testUDRP2 should now be testRateClass2.');
        System.assertEquals(testRateClass2.Id, testUDRPList[2].Rate_Class_Lookup__c, 
                            'The Rate_Class_Lookup__c for testUDRP3 should now be testRateClass2.');
        System.assertEquals(Null, testUDRPList[3].Rate_Class_Lookup__c, 
                            'The Rate_Class_Lookup__c for testUDRP4 should be null because ' 
                            + 'the Rate_Class__c text was null, so no Rate Class object could be found for it.');
        System.assertEquals(Null, testUDRPList[4].Rate_Class_Lookup__c,  
                            'The Rate_Class_Lookup__c for testUDRP5 should be null because ' 
                            + 'the Rate_Class__c text did not match any Rate_Class__c.EDI_Rate_Class__c fields');
        System.assertEquals(testUAL1.Utility_Rate_Class__c, testUDRPList[2].Rate_Class_Lookup__c,  
                            'The "Rate Class" (Utility_Rate_Class__c) for the UAL on testUDR1 should be the same as the Rate Class for testUDRP3,' 
                            + 'becuase testUDRP3 has the most recent Service Start Date of the all UDRPs for testUDR1.');
        
        errorLogs = [SELECT Id, Class__c, Method__c, Message__c, Severity__c FROM Error_Log__c];
        
        System.assertEquals(2, errorLogs.size(),'There should be two error logs created when thsi test runs');
        
        for (error_log__c e : errorLogs){
            if (e.severity__c == 'Error'){
                System.assert(e.Message__c.contains('No matching Rate Class record with an EDI_Rate_Class__c that matches the Rate_Subclass__c on '),
                                                    'An error log should be created when a matching rate class is not found');
            } else {
                System.assert(e.Message__c.contains('Null Rate Subclass on'),'Null Rate Subclasses should log an INFO error log');        
            }
        }
        
        
    }
    
    @IsTest
    static void updateStatusToNotComplete() {
        Utility_Data_Request__c testUDR1 = getTestUDR('testUDR1');
        System.assertEquals(testUDR1.Detail_status__c,'Pending','Expect detail status to be pending');
        testUDR1.Header_Status__c = 'Complete';
        update testUDR1;
        testUDR1 = [select id, request_status_new__c from utility_data_request__c where id = :testUDR1.id];
        System.assertEquals(testUDR1.request_status_new__c,'Partial Data Received','Expect request status to be partial data received '
                                                          + 'because details have not been returned');

        
        List<Utility_Data_Request_Period__c> testUDRPList = getTestUDRPList(testUDR1.Id);
        
        System.assertEquals(testUDRPList[0].Rate_Class_Lookup__c, Null, 
                            'The Rate_Class_Lookup__c for testUDRP1 should still be null becuase ' 
                            + 'the status on the related UDR was not updated to Complete.');
        System.assertEquals(testUDRPList[1].Rate_Class_Lookup__c, Null,
                            'The Rate_Class_Lookup__c for testUDRP2 should still be null becuase ' 
                            + 'the status on the related UDR was not updated to Complete.');
        System.assertEquals(testUDRPList[2].Rate_Class_Lookup__c, Null,
                            'The Rate_Class_Lookup__c for testUDRP3 should still be null becuase ' 
                            + 'the status on the related UDR was not updated to Complete.');
        System.assertEquals(testUDRPList[3].Rate_Class_Lookup__c, Null,
                            'The Rate_Class_Lookup__c for testUDRP4 should still be null becuase ' 
                            + 'the status on the related UDR was not updated to Complete.');
        System.assertEquals(testUDRPList[4].Rate_Class_Lookup__c, Null,
                            'The Rate_Class_Lookup__c for testUDRP5 should still be null becuase ' 
                            + 'the status on the related UDR was not updated to Complete.');

    }
    
    @IsTest
    static void updateNotStatus() {
        Utility_Data_Request__c testUDR2 = getTestUDR('testUDR2');
        testUDR2.State__c = 'GA';
        update testUDR2;
        
        List<Utility_Data_Request_Period__c> testUDRPList = getTestUDRPList(testUDR2.Id);
        
        System.assertEquals(testUDRPList[0].Rate_Class_Lookup__c, Null, 
            'testUDRP6 is related to testUDR2, whose status was already Complete before the update,'
            + ' so the EDI_Rate_Class should still be null becuase the status did not update to complete,');
    }
    
    @IsTest
    static void testNullRecentUDRP() {
        List<Error_Log__c> errorLogs = [SELECT Id, Class__c, Method__c, Message__c, Severity__c FROM Error_Log__c];
        System.assertEquals(0, errorLogs.size());
        
        Utility_Data_Request_Period__c testUDRP4 = getTestUDRP('testUDRP4');
        testUDRP4.Service_Start_Date__c = Date.newInstance(2020, 10, 13);
        update testUDRP4;
        
        Utility_Data_Request__c testUDR1 = getTestUDR('testUDR1');
        testUDR1.Header_Status__c = 'Complete';
        testUDR1.Detail_Status__c = 'Complete';
        update testUDR1;
        
        System.assertEquals(null, testUDR1.Utility_Account_Log__r.Utility_Rate_Class__c,
            'The most recent UDRP has a null Rate Class, so the Utility_Rate_Class__c on  UAL should still be null'
        );
        
        errorLogs = [SELECT Id, Class__c, Method__c, Message__c, Severity__c FROM Error_Log__c];
        System.assertEquals(3, errorLogs.size(),'We expect 3 error logs - one for Null Rate subclass on a UDRP, another for not finding a matching EDI_Rate_Class on Rate Class'
                                                +' and a third for not being able to populate a rate class on UAL');
        
        for (error_log__c e : errorLogs){
            if (e.severity__c == 'Info'&& e.method__c =='populateRateClassOnUDRP'){
                System.assert(e.message__c.contains('Null Rate Subclass on'),'Null Rate Subclasses should log an INFO error log');   
            }
            else if (e.severity__c == 'Error'&& e.Method__c =='populateRateClassOnUDRP'){
                System.assert(e.message__c.contains('No matching Rate Class record with an EDI_Rate_Class__c that matches the Rate_Subclass__c on '),
                'An error log should be created when a matching rate class is not found');
            }
            else {
                System.assert(e.message__c.contains('Null Rate_Class_Lookup__c value for most recent UDRP related to'),'Null Rate on most recent UDRP should create an error log');       
            }
        }
    }
    
    @IsTest
    static void testUALFieldUpdates() {
        
        Utility_Data_Request__c testUDR1 = getTestUDR('testUDR1');
        Utility_Data_Request__c testUDR3 = getTestUDR('testUDR3');
        Utility_Data_Request__c testUDR4 = getTestUDR('testUDR4');
        Utility_Data_Request__c testUDR5 = getTestUDR('testUDR5');
        Utility_Data_Request__c testUDR6 = getTestUDR('testUDR6');	
        
        testUDR1.Header_Status__c = 'Complete';
        testUDR1.Detail_Status__c = 'Complete';
        testUDR3.Header_Status__c = 'Complete';
        testUDR3.Detail_Status__c = 'Complete';
        testUDR4.Header_Status__c = 'Complete';
        testUDR4.Detail_Status__c = 'Complete';
        testUDR5.Header_Status__c = 'Complete';
        testUDR5.Detail_Status__c = 'Complete';
        testUDR6.Header_Status__c = 'Complete';
        testUDR6.Detail_Status__c = 'Complete';
        
        List<Utility_Data_Request__c> testUDRList = new List<Utility_Data_Request__c>{testUDR1, testUDR3, testUDR4, testUDR5, testUDR6};	
        update testUDRList;
        
        Utility_Account_Log__c testUAL1 = getTestUAL(testUDR1.Utility_Account_Log__c);
        Utility_Account_Log__c testUAL3 = getTestUAL(testUDR3.Utility_Account_Log__c);
        Utility_Account_Log__c testUAL4 = getTestUAL(testUDR4.Utility_Account_Log__c);
        Utility_Account_Log__c testUAL5 = getTestUAL(testUDR5.Utility_Account_Log__c);
        Utility_Account_Log__c testUAL6 = getTestUAL(testUDR6.Utility_Account_Log__c);	
        
        Utility_Data_Request__c updatedTestUDR1 = getTestUDR('testUDR1');
        Utility_Data_Request__c updatedTestUDR3 = getTestUDR('testUDR3');
        Utility_Data_Request__c updatedTestUDR4 = getTestUDR('testUDR4');
        Utility_Data_Request__c updatedTestUDR5 = getTestUDR('testUDR5');
        Utility_Data_Request__c updatedTestUDR6 = getTestUDR('testUDR6');	
        
        System.assertEquals(33823.2, updatedTestUDR1.Annual_kWh__c, 'UDR1 has 5 KH UDRP so the Annual kWh should be ' 
                            + 'the sum of the UDRP.Quantity__c values multiplied by the number of months and divided by 12.'
                            + 'In this case the answer should be 33823.2.');
        System.assertEquals(2352.80, updatedTestUDR1.Average_Demand__c, 'UDR1 has 5 K1 UDRP so the Annual kWh should be ' 
                            + 'the sum of the UDRP.Quantity__c values multiplied by the number of months and divided by 12.'
                            + 'In this case the answer should be 2352.80.');
        System.assertEquals(5, updatedTestUDR1.Num_months_Annual_kWh__c);
        System.assertEquals(5, updatedTestUDR1.Num_months_Average_Demand__c);
        
        System.assertEquals(33823.2, testUAL1.Annual_kWh__c, 'UAL1 is related to UDR1,' 
                            + ' which has 5 KH UDRPs so the Annual kWh should be the sum of the UDRP.Quantity__c values divided by the number of months and multiplied by 12.'
                            + 'In this case the answer should be 33823.2.');
        System.assertEquals(2352.80, testUAL1.Average_Demand__c, 'UAL1 is related to UDR1,' 
                            + ' which has 5 K1 UDRPs so the Annual kWh should be the sum of the UDRP.Quantity__c values divided by the number of months and multiplied by 12.'
                            + 'In this case the answer should be 2352.80.');
        System.assertEquals(5, testUAL1.Num_months_Annual_kWh__c);
        System.assertEquals(5, testUAL1.Num_months_Average_Demand__c);
        
        System.assertEquals(165200, updatedTestUDR3.Annual_kWh__c, 'UDR3 has 1 KH UDRP, it is a non-Residential customer, and the Product.X4_month_sizing_method__c == State Average Annual Usage' 
                            + 'so the Annual kWh should be the related State Avg Annual Resi kWh.'
                            + 'In this case the answer should be 165200 since the test State Avg Annual Resi kWh is 165200.');
        System.assertEquals(549, updatedTestUDR3.Average_Demand__c, 'UDR3 has 2 K1 UDRP, so the Average Demand is the Annual kWh divided by 8260 '
                            + 'In this case the answer should be 549.');
        System.assertEquals(1, updatedTestUDR3.Num_months_Annual_kWh__c);
        System.assertEquals(2, updatedTestUDR3.Num_months_Average_Demand__c);
        
        System.assertEquals(165200, testUAL3.Annual_kWh__c, 'UAL3 is related to UDR3,' 
                            + ' which has 1 KH UDRP, it is a non-Residential customer, and the Product.X4_month_sizing_method__c == State Average Annual Usage, ' 
                            + 'so the Annual kWh should be the related State Avg Annual Resi kWh.'
                            + 'In this case the answer should be 165200 since the test State Avg Annual Resi kWh is 165200.');
        System.assertEquals(549, testUAL3.Average_Demand__c, 'UAL3 is related to UDR3, which has 2 K1 UDRP, so the Average Demand is the Annual kWh divided by 8260. '
                            + 'In this case the answer should be 549.');
        System.assertEquals(1, testUAL3.Num_months_Annual_kWh__c);
        System.assertEquals(2, testUAL3.Num_months_Average_Demand__c);
        
        System.assertEquals(60572, updatedTestUDR4.Annual_kWh__c, 'UDR4 has 3 KH UDRP and is a Residential customer, ' 
                            + 'so the Annual kWh should be the sum of the UDRP.Quantity__c values divided by the number of months and multiplied by 12.'
                            + 'In this case the answer should be 60572.');
        System.assertEquals(3461, updatedTestUDR4.Average_Demand__c, 'UDR4 has 3 K1 UDRP, so the Average Demand is the Annual kWh divided by 8260 '
                            + 'In this case the answer should be 3461.');
        System.assertEquals(3, updatedTestUDR4.Num_months_Annual_kWh__c);
        System.assertEquals(3, updatedTestUDR4.Num_months_Average_Demand__c);
        
        System.assertEquals(60572, testUAL4.Annual_kWh__c, 'UAL4 is related to UDR4,' 
                            + ' which has 3 KH UDRPs and is a Residential customer, ' 
                            + 'so the Annual kWh should be the sum of the UDRP.Quantity__c values divided by the number of months and multiplied by 12.'
                            + 'In this case the answer should be 60572.');
        System.assertEquals(3461, testUAL4.Average_Demand__c, 'UAL4 is related to UDR4,' 
                            + ' which has 3 K1 UDRPs, so the Average Demand is the Annual kWh divided by 8260 '
                            + 'In this case the answer should be 3461.');
        System.assertEquals(3, testUAL4.Num_months_Annual_kWh__c);
        System.assertEquals(3, testUAL4.Num_months_Average_Demand__c);
        
        System.assertEquals(487579, updatedTestUDR5.Annual_kWh__c, 'UDR5 has 14 KH UDRP and is a Residential customer, ' 
                            + 'so the Annual kWh should be the sum of the 12 most recent UDRP.Quantity__c values.'
                            + 'In this case the answer should be 487579.');
        System.assertEquals(1867.17, updatedTestUDR5.Average_Demand__c, 'UDR5 has 12 K1 UDRP and is a Residential customer, ' 
                            + 'so the Annual kWh should be the sum of the 12 most recent UDRP.Quantity__c values.'
                            + 'In this case the answer should be 1867.17.');
        System.assertEquals(14, updatedTestUDR5.Num_months_Annual_kWh__c);
        System.assertEquals(13, updatedTestUDR5.Num_months_Average_Demand__c);
        
        System.assertEquals(487579, testUAL5.Annual_kWh__c, 'UAL5 is related to UDR5,' 
                            + ' which has 14 KH UDRPs and is a Residential customer, ' 
                            + 'so the Annual kWh should be the sum of the 12 most recent UDRP.Quantity__c values.'
                            + 'In this case the answer should be 487579.');
        System.assertEquals(1867.17, testUAL5.Average_Demand__c, 'UAL5 is related to UDR5,' 
                            + ' which has 12 K1 UDRPs and is a Residential customer, ' 
                            + 'so the Annual kWh should be the sum of the 12 most recent UDRP.Quantity__c values.'
                            + 'In this case the answer should be 1867.17.');
        System.assertEquals(14, testUAL5.Num_months_Annual_kWh__c);
        System.assertEquals(13, testUAL5.Num_months_Average_Demand__c);
        
        List<Utility_Data_Request__c> updatedTestUDRList = new List<Utility_Data_Request__c>{testUDR1, testUDR3, testUDR4, testUDR5};
        List<Utility_Data_Request_Period__c> khUDRPList= udrpSelector.selectWithKHByUDR(updatedTestUDRList);
        List<Utility_Data_Request_Period__c> k1UDRPList= udrpSelector.selectWithK1ByUDR(updatedTestUDRList);
        
        for(Utility_Data_Request_Period__c udrp : khUDRPList) {
            if(udrp.Load_Profile_Description__c == 'testUDRP7' || udrp.Load_Profile_Description__c == 'testUDRP12' || udrp.Load_Profile_Description__c == 'testUDRP23') {
                System.assertEquals(false, udrp.Used_in_Annual_kWh_Calculation__c, 'UDRP not used in kWh calculation, should be false. UDRP: ' + udrp);
            } else {
                System.assertEquals(true, udrp.Used_in_Annual_kWh_Calculation__c, 'UDRP used in kWh Calculation, should be true. UDRP: ' + udrp);
            }
        }
        
        for(Utility_Data_Request_Period__c udrp : k1UDRPList) {
            if(udrp.Load_Profile_Description__c == 'testUDRP47') {
                System.assertEquals(false, udrp.Used_in_Average_Demand_Calculation__c, 'UDRP not used in avg demand calculation, should be false. UDRP: ' + udrp);
            } else {
                System.assertEquals(true, udrp.Used_in_Average_Demand_Calculation__c, 'UDRP used in avg demand Calculation, should be true. UDRP: ' + udrp);
            }
        }
        
        System.assertEquals('No', testUAL1.NYPA__c);
        System.assertEquals('No', testUAL1.RNY__c);
        System.assertEquals('No', testUAL3.NYPA__c);
        System.assertEquals('Yes', testUAL3.RNY__c);
        System.assertEquals('Yes', testUAL4.NYPA__c);
        System.assertEquals('No', testUAL4.RNY__c);
        System.assertEquals('Yes', testUAL5.NYPA__c);
        System.assertEquals('Yes', testUAL5.RNY__c);
        System.assertEquals('No', testUAL6.NYPA__c);
        System.assertEquals('No', testUAL6.RNY__c);
        
        System.assertEquals(false, testUAL1.Address_Update__c, 'The addresses should have matched, so the Address_Update__c should be false.');
        System.assertEquals(false, testUAL3.Address_Update__c, 'The addresses should have matched, so the Address_Update__c should be false.');
        System.assertEquals(true, testUAL4.Address_Update__c, 'The addresses should not have matched, so the Address_Update__c should be true.');
        System.assertEquals(true, testUAL5.Address_Update__c, 'The addresses should not have matched, so the Address_Update__c should be true.');
        System.assertEquals(true, testUAL6.Address_Update__c, 'The addresses should not have matched, so the Address_Update__c should be true.');	
        
        System.assertEquals('Bill', testUAL4.Previous_Name_on_Utility_Account__c);
        System.assertEquals('459  Broadway', testUAL4.Previous_Service_Address__c);
        System.assertEquals('Everett', testUAL4.Previous_Service_City__c);
        System.assertEquals('MA', testUAL4.Previous_Service_State__c);
        System.assertEquals('02149', testUAL4.Previous_Service_Zip_Code__c);
        
        System.assertEquals('Bill', testUAL4.Name_on_Account__c);
        System.assertEquals('458 Broadway', testUAL4.Service_Address__c);
        System.assertEquals('Everett', testUAL4.Service_City__c);
        System.assertEquals('MA', testUAL4.Service_State__c);
        System.assertEquals('02149', testUAL4.Service_Zip_Code__c);
        
        System.assertEquals('Bob', testUAL5.Previous_Name_on_Utility_Account__c);
        System.assertEquals('1 brighton ave, 20', testUAL5.Previous_Service_Address__c);
        System.assertEquals('Allston', testUAL5.Previous_Service_City__c);
        System.assertEquals('MA', testUAL5.Previous_Service_State__c);
        System.assertEquals('02134', testUAL5.Previous_Service_Zip_Code__c);
        
        System.assertEquals('Bob', testUAL5.Name_on_Account__c);
        System.assertEquals('1 Brighton Ave Unit 20', testUAL5.Service_Address__c);
        System.assertEquals('Allston', testUAL5.Service_City__c);
        System.assertEquals('Ma', testUAL5.Service_State__c);
        System.assertEquals('02134', testUAL5.Service_Zip_Code__c);
                
        System.assertEquals('Complete', testUAL1.QC_Status__c, 'The addresses should have matched, and the NYPA/RNY fields are No, so the status should be Complete.');        	
        System.assertEquals('Pending BW Review', testUAL3.QC_Status__c, 'The addresses should have matched, but the NYPA/RNY fields are No/Yes, so the status should be Pending BW Review.');
        System.assertEquals('Pending BW Review', testUAL4.QC_Status__c, 'The addresses should not have matched, and the NYPA/RNY fields are Yes/No, so the status should be Pending BW Review.');	
        System.assertEquals('Pending BW Review', testUAL5.QC_Status__c, 'The addresses should not have matched, and the NYPA/RNY fields are Yes/Yes, so the status should be Pending BW Review.');
        System.assertEquals('Pending BW Review', testUAL6.QC_Status__c, 'The NYPA/RNY fields are no, but the addresses should not have matched, so the status should be Pending BW Review.');	        
    }

    @IsTest
    static void testUDRGenerationNoMatch() {
        // Retrieve data
        Lead lead = getTestLead('testLead1');
        Utility_Account_Log__c ualForLead = lead.Utility_Account_Logs__r;
        Integer udrCount = udrCount(ualForLead.Id);

        Test.startTest();
            UtilityDataRequestService.create(new List<String>{lead.Id});
        Test.stopTest();

        // Check database to confirm no extra UDRs were generated for this UAL
        Integer udrCountNow = udrCount(ualForLead.Id);

        // Test lead already has one UDR already created (via @TestSetup method)
        // No new UDRs should have been created for this lead/UAL
        System.assertEquals(udrCount, udrCountNow, 'UDR generated when it should not have been. Duplicate UDR!');
    }

    @IsTest
    static void testUDRGeneration() {
        // Build data scenario
        Id utilityId = [SELECT Id FROM Utility__c WHERE Name = 'testUtility'].Id;
        Lead lead = new Lead (
            Product__c = [SELECT Id FROM Product2 WHERE Name = 'testProduct'].Id,
            Customer_type__c = 'Commercial',
            LastName = 'testLead1',
            Company = 'testBlueWave1',
            Utility_relationship__c = utilityId
        );
        insert lead;
        Utility_Account_Log__c ual = new Utility_Account_Log__c(
            Service_State__c = 'Georgia',
            Lead__c = lead.Id,
            Username__c = 'testUAL1',
            Utility_lookup__c = utilityId
        );
        insert ual;

        Test.startTest();
            System.assertEquals(0, udrCount(ual.Id), 'UDRs prior to create() method run should be 0');
            UtilityDataRequestService.create(new List<String>{lead.Id});
        Test.stopTest();

        // Check results... Should have generated a new UDR with appropriate field vals, and updated UAL
        List<Utility_Data_Request__c> udrs = [
            SELECT Id, Account_Number__c, Utility__c, Utility_DUNS__c, Utility_Name__c, Request_Status_new__c,
                Utility_Account_Log__r.Name, Utility_Account_Log__r.Utility_lookup__c,
                Utility_Account_Log__r.Utility_lookup__r.Name, Utility_Account_Log__r.Utility_lookup__r.Utility_DUNS_Number__c,
                Utility_Account_Log__r.QC_Status__c
            FROM Utility_Data_Request__c
            WHERE Utility_Account_Log__c =: ual.Id
        ];

        System.assert(!udrs.isEmpty(), 'No UDRs found after running create()');
        System.assertEquals(1, udrCount(ual.Id), '1 UDR should have been generated for UAL missing UDR');
        System.assertEquals(udrs[0].Utility_Account_Log__r.Name, udrs[0].Account_Number__c, 'Incorrect name for generated UDR');
        System.assertEquals(udrs[0].Utility_Account_Log__r.Utility_lookup__c, udrs[0].Utility__c, 'Incorrect utility for generated UDR');
        System.assertEquals(udrs[0].Utility_Account_Log__r.Utility_lookup__r.Utility_DUNS_Number__c, udrs[0].Utility_DUNS__c, 'Incorrect DUNS number for generated UDR');
        System.assertEquals(udrs[0].Utility_Account_Log__r.Utility_lookup__r.Name, udrs[0].Utility_Name__c, 'Incorrect utility name for generated UDR');
        System.assertEquals('Pending', udrs[0].Request_Status_new__c, 'Incorrect status for newly-generated UDR');
        System.assertEquals('Pending Utility Data', udrs[0].Utility_Account_Log__r.QC_Status__c, 'UAL status incorrect for pending UDR');
    }
    
}