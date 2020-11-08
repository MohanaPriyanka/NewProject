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
        
        State__c stateGA = new State__c(
            Name = 'Georgia',
            Avg_Annual_Resi_kWh__c = 1234
        );
        insert stateGA;
        
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
            Service_State__c = 'Georgia',
            Lead__c = resiLead.Id,
            Name_on_Account__c = 'testUAL1',
            Utility_lookup__c = testUtility.Id
        );
        
        Utility_Account_Log__c testUAL2 = new Utility_Account_Log__c(
            Service_State__c = 'Georgia',
            Lead__c = resiLead.Id,
            Name_on_Account__c = 'testUAL2'
        );
        
        Utility_Account_Log__c testUAL3 = new Utility_Account_Log__c(
            Service_State__c = 'Georgia',
            Lead__c = nonResiLead.Id,
            Name_on_Account__c = 'testUAL3'
        );
        
        Utility_Account_Log__c testUAL4 = new Utility_Account_Log__c(
            Service_State__c = 'Georgia',
            Lead__c = resiLead.Id,
            Name_on_Account__c = 'testUAL4'
        );
        
        Utility_Account_Log__c testUAL5 = new Utility_Account_Log__c(
            Service_State__c = 'Georgia',
            Lead__c = resiLead.Id,
            Name_on_Account__c = 'testUAL5'
        );
        
        List<Utility_Account_Log__c> testUALList = new List<Utility_Account_Log__c>{testUAL1, testUAL2, testUAL3, testUAL4, testUAL5};
        insert testUALList;
        
        Utility_Data_Request__c testUDR1 = new Utility_Data_Request__c(
            Request_Status__c = 'Pending',
            Customer_Name__c = 'testUDR1',
            Utility_Account_Log__c = testUAL1.Id,
            State__c = 'MA',
            Utility__c = testUtility.Id
        );
        
        Utility_Data_Request__c testUDR2 = new Utility_Data_Request__c(
            Request_Status__c = 'Complete',
            Customer_Name__c = 'testUDR2',
            Utility_Account_Log__c = testUAL2.Id,
            State__c = 'MA',
            Utility__c = testUtility.Id
        );
        
        Utility_Data_Request__c testUDR3 = new Utility_Data_Request__c(
            Request_Status__c = 'Pending',
            Customer_Name__c = 'testUDR3',
            Utility_Account_Log__c = testUAL3.Id,
            State__c = 'MA',
            Utility__c = testUtility.Id
        );
        
        Utility_Data_Request__c testUDR4 = new Utility_Data_Request__c(
            Request_Status__c = 'Pending',
            Customer_Name__c = 'testUDR4',
            Utility_Account_Log__c = testUAL4.Id,
            State__c = 'MA',
            Utility__c = testUtility.Id
        );
        
        Utility_Data_Request__c testUDR5 = new Utility_Data_Request__c(
            Request_Status__c = 'Pending',
            Customer_Name__c = 'testUDR5',
            Utility_Account_Log__c = testUAL5.Id,
            State__c = 'MA',
            Utility__c = testUtility.Id
        );
        
        List<Utility_Data_Request__c> testUDRList = new List<Utility_Data_Request__c>{testUDR1, testUDR2, testUDR3, testUDR4, testUDR5};
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
            Rate_Subclass__c = 'testUDRP1',
            Service_Start_Date__c = Date.newInstance(2020, 5, 10),
            Measurement_Unit__c ='KH',
            Quantity__c = 25,
            Used_In_Annual_kWh_Calculation__c = false,
            Measurement_Significance_Code__c = '51'
        );
        
        Utility_Data_Request_Period__c testUDRP2 = new Utility_Data_Request_Period__c(
            Utility_Data_Request__c = testUDR1.Id, 
            Rate_Class__c = 'Test EDI Rate Class 2',
            Rate_Subclass__c = 'testUDRP2',
            Service_Start_Date__c = Date.newInstance(2020, 7, 7),
            Measurement_Unit__c ='KH',
            Quantity__c = 101,
            Used_In_Annual_kWh_Calculation__c = false,
            Measurement_Significance_Code__c = '51'
        );
        
        Utility_Data_Request_Period__c testUDRP3 = new Utility_Data_Request_Period__c(
            Utility_Data_Request__c = testUDR1.Id, 
            Rate_Class__c = 'Test EDI Rate Class 2',
            Rate_Subclass__c = 'testUDRP3',
            Service_Start_Date__c = Date.newInstance(2020, 10, 12),
            Measurement_Unit__c ='KH',
            Quantity__c = 6914,
            Used_In_Annual_kWh_Calculation__c = false,
            Measurement_Significance_Code__c = '51'
        );
        
        Utility_Data_Request_Period__c testUDRP4 = new Utility_Data_Request_Period__c(
            Utility_Data_Request__c = testUDR1.Id, 
            Rate_Class__c = Null,
            Rate_Subclass__c = 'testUDRP4',
            Service_Start_Date__c = Date.newInstance(2020, 9, 15),
            Measurement_Unit__c ='KH',
            Quantity__c = 50,
            Used_In_Annual_kWh_Calculation__c = false,
            Measurement_Significance_Code__c = '51'
        );
        
        Utility_Data_Request_Period__c testUDRP5 = new Utility_Data_Request_Period__c(
            Utility_Data_Request__c = testUDR1.Id, 
            Rate_Class__c = 'Nonexistent/Misspelled EDI',
            Rate_Subclass__c = 'testUDRP5',
            Service_Start_Date__c = Date.newInstance(2020, 2, 1),
            Measurement_Unit__c ='KH',
            Quantity__c = 7003,
            Used_In_Annual_kWh_Calculation__c = false,
            Measurement_Significance_Code__c = '51'
        );
        
        Utility_Data_Request_Period__c testUDRP6 = new Utility_Data_Request_Period__c(
            Utility_Data_Request__c = testUDR2.Id, 
            Rate_Class__c = 'Test EDI Rate Class 2',
            Rate_Subclass__c = 'testUDRP6',
            Service_Start_Date__c = Date.newInstance(2020, 9, 14),
            Measurement_Unit__c ='KH',
            Quantity__c = 1234,
            Used_In_Annual_kWh_Calculation__c = false,
            Measurement_Significance_Code__c = '51'
        );
        
        Utility_Data_Request_Period__c testUDRP7 = new Utility_Data_Request_Period__c(
            Utility_Data_Request__c = testUDR3.Id, 
            Rate_Class__c = 'Test EDI Rate Class 1',
            Rate_Subclass__c = 'testUDRP7',
            Service_Start_Date__c = Date.newInstance(2020, 9, 1),
            Measurement_Unit__c ='KH',
            Quantity__c = 12099,
            Used_In_Annual_kWh_Calculation__c = false,
            Measurement_Significance_Code__c = '51'
        );
        
        Utility_Data_Request_Period__c testUDRP8 = new Utility_Data_Request_Period__c(
            Utility_Data_Request__c = testUDR4.Id, 
            Rate_Class__c = 'Test EDI Rate Class 1',
            Rate_Subclass__c = 'testUDRP8',
            Service_Start_Date__c = Date.newInstance(2019, 5, 20),
            Measurement_Unit__c ='KH',
            Quantity__c = 4387,
            Used_In_Annual_kWh_Calculation__c = false,
            Measurement_Significance_Code__c = '51'
        );
        
        Utility_Data_Request_Period__c testUDRP9 = new Utility_Data_Request_Period__c(
            Utility_Data_Request__c = testUDR4.Id, 
            Rate_Class__c = 'Test EDI Rate Class 1',
            Rate_Subclass__c = 'testUDRP9',
            Service_Start_Date__c = Date.newInstance(2020, 5, 20),
            Measurement_Unit__c ='KH',
            Quantity__c = 999,
            Used_In_Annual_kWh_Calculation__c = false,
            Measurement_Significance_Code__c = '51'
        );
        
        Utility_Data_Request_Period__c testUDRP10 = new Utility_Data_Request_Period__c(
            Utility_Data_Request__c = testUDR4.Id, 
            Rate_Class__c = 'Test EDI Rate Class 1',
            Rate_Subclass__c = 'testUDRP10',
            Service_Start_Date__c = Date.newInstance(2020, 8, 28),
            Measurement_Unit__c ='KH',
            Quantity__c = 9757,
            Used_In_Annual_kWh_Calculation__c = false,
            Measurement_Significance_Code__c = '51'
        );
        
        Utility_Data_Request_Period__c testUDRP11 = new Utility_Data_Request_Period__c(
            Utility_Data_Request__c = testUDR5.Id, 
            Rate_Class__c = 'Test EDI Rate Class 1',
            Rate_Subclass__c = 'testUDRP11',
            Service_Start_Date__c = Date.newInstance(2020, 10, 3),
            Measurement_Unit__c ='KH',
            Quantity__c = 6789,
            Used_In_Annual_kWh_Calculation__c = false,
            Measurement_Significance_Code__c = '51'
        );
        
        Utility_Data_Request_Period__c testUDRP12 = new Utility_Data_Request_Period__c(
            Utility_Data_Request__c = testUDR5.Id, 
            Rate_Class__c = 'Test EDI Rate Class 1',
            Rate_Subclass__c = 'testUDRP12',
            Service_Start_Date__c = Date.newInstance(2019, 2, 22),
            Measurement_Unit__c ='KH',
            Quantity__c = 8311,
            Used_In_Annual_kWh_Calculation__c = false,
            Measurement_Significance_Code__c = '51'
        );
        
        Utility_Data_Request_Period__c testUDRP13 = new Utility_Data_Request_Period__c(
            Utility_Data_Request__c = testUDR5.Id, 
            Rate_Class__c = 'Test EDI Rate Class 1',
            Rate_Subclass__c = 'testUDRP13',
            Service_Start_Date__c = Date.newInstance(2020, 9, 10),
            Measurement_Unit__c ='KH',
            Quantity__c = 11111,
            Used_In_Annual_kWh_Calculation__c = false,
            Measurement_Significance_Code__c = '51'
        );
        
        Utility_Data_Request_Period__c testUDRP14 = new Utility_Data_Request_Period__c(
            Utility_Data_Request__c = testUDR5.Id, 
            Rate_Class__c = 'Test EDI Rate Class 1',
            Rate_Subclass__c = 'testUDRP14',
            Service_Start_Date__c = Date.newInstance(2020, 8, 3),
            Measurement_Unit__c ='KH',
            Quantity__c = 53977,
            Used_In_Annual_kWh_Calculation__c = false,
            Measurement_Significance_Code__c = '51'
        );
        
        Utility_Data_Request_Period__c testUDRP15 = new Utility_Data_Request_Period__c(
            Utility_Data_Request__c = testUDR5.Id, 
            Rate_Class__c = 'Test EDI Rate Class 1',
            Rate_Subclass__c = 'testUDRP15',
            Service_Start_Date__c = Date.newInstance(2020, 7, 10),
            Measurement_Unit__c ='KH',
            Quantity__c = 2525,
            Used_In_Annual_kWh_Calculation__c = false,
            Measurement_Significance_Code__c = '51'
        );
        
        Utility_Data_Request_Period__c testUDRP16 = new Utility_Data_Request_Period__c(
            Utility_Data_Request__c = testUDR5.Id, 
            Rate_Class__c = 'Test EDI Rate Class 1',
            Rate_Subclass__c = 'testUDRP16',
            Service_Start_Date__c = Date.newInstance(2020, 6, 28),
            Measurement_Unit__c ='KH',
            Quantity__c = 9222,
            Used_In_Annual_kWh_Calculation__c = false,
            Measurement_Significance_Code__c = '51'
        );
        
        Utility_Data_Request_Period__c testUDRP17 = new Utility_Data_Request_Period__c(
            Utility_Data_Request__c = testUDR5.Id, 
            Rate_Class__c = 'Test EDI Rate Class 1',
            Rate_Subclass__c = 'testUDRP17',
            Service_Start_Date__c = Date.newInstance(2020, 5, 2),
            Measurement_Unit__c ='KH',
            Quantity__c = 88,
            Used_In_Annual_kWh_Calculation__c = false,
            Measurement_Significance_Code__c = '51'
        );
        
        Utility_Data_Request_Period__c testUDRP18 = new Utility_Data_Request_Period__c(
            Utility_Data_Request__c = testUDR5.Id, 
            Rate_Class__c = 'Test EDI Rate Class 1',
            Rate_Subclass__c = 'testUDRP18',
            Service_Start_Date__c = Date.newInstance(2020, 4, 17),
            Measurement_Unit__c ='KH',
            Quantity__c = 417,
            Used_In_Annual_kWh_Calculation__c = false,
            Measurement_Significance_Code__c = '51'
        );
        
        Utility_Data_Request_Period__c testUDRP19 = new Utility_Data_Request_Period__c(
            Utility_Data_Request__c = testUDR5.Id, 
            Rate_Class__c = 'Test EDI Rate Class 1',
            Rate_Subclass__c = 'testUDRP19',
            Service_Start_Date__c = Date.newInstance(2020, 3, 20),
            Measurement_Unit__c ='KH',
            Quantity__c = 4399,
            Used_In_Annual_kWh_Calculation__c = false,
            Measurement_Significance_Code__c = '51'
        );
        
        Utility_Data_Request_Period__c testUDRP20 = new Utility_Data_Request_Period__c(
            Utility_Data_Request__c = testUDR5.Id, 
            Rate_Class__c = 'Test EDI Rate Class 1',
            Rate_Subclass__c = 'testUDRP20',
            Service_Start_Date__c = Date.newInstance(2020, 2, 19),
            Measurement_Unit__c ='KH',
            Quantity__c = 2019,
            Used_In_Annual_kWh_Calculation__c = false,
            Measurement_Significance_Code__c = '51'
        );
        
        Utility_Data_Request_Period__c testUDRP21 = new Utility_Data_Request_Period__c(
            Utility_Data_Request__c = testUDR5.Id, 
            Rate_Class__c = 'Test EDI Rate Class 1',
            Rate_Subclass__c = 'testUDRP21',
            Service_Start_Date__c = Date.newInstance(2020, 1, 1),
            Measurement_Unit__c ='KH',
            Quantity__c = 334455,
            Used_In_Annual_kWh_Calculation__c = false,
            Measurement_Significance_Code__c = '51'
        );
        
        Utility_Data_Request_Period__c testUDRP22 = new Utility_Data_Request_Period__c(
            Utility_Data_Request__c = testUDR5.Id, 
            Rate_Class__c = 'Test EDI Rate Class 1',
            Rate_Subclass__c = 'testUDRP22',
            Service_Start_Date__c = Date.newInstance(2020, 1, 2),
            Measurement_Unit__c ='KH',
            Quantity__c = 19788,
            Used_In_Annual_kWh_Calculation__c = false,
            Measurement_Significance_Code__c = '51'
        );
        
        Utility_Data_Request_Period__c testUDRP23 = new Utility_Data_Request_Period__c(
            Utility_Data_Request__c = testUDR5.Id, 
            Rate_Class__c = 'Test EDI Rate Class 1',
            Rate_Subclass__c = 'testUDRP23',
            Service_Start_Date__c = Date.newInstance(2019, 2, 19),
            Measurement_Unit__c ='KH',
            Quantity__c = 764655,
            Used_In_Annual_kWh_Calculation__c = false,
            Measurement_Significance_Code__c = '51'
        );
        
        Utility_Data_Request_Period__c testUDRP24 = new Utility_Data_Request_Period__c(
            Utility_Data_Request__c = testUDR5.Id, 
            Rate_Class__c = 'Test EDI Rate Class 1',
            Rate_Subclass__c = 'testUDRP24',
            Service_Start_Date__c = Date.newInstance(2020, 4, 27),
            Measurement_Unit__c ='KH',
            Quantity__c = 42789,
            Used_In_Annual_kWh_Calculation__c = false,
            Measurement_Significance_Code__c = '51'
        );
        
        List<Utility_Data_Request_Period__c> testUDRPList = new List<Utility_Data_Request_Period__c>{
            testUDRP1, testUDRP2, testUDRP3, testUDRP4, testUDRP5, testUDRP6, testUDRP7, testUDRP8, 
            testUDRP9, testUDRP10, testUDRP11, testUDRP12, testUDRP13, testUDRP14, testUDRP15, testUDRP16, 
            testUDRP17, testUDRP18, testUDRP19, testUDRP20, testUDRP21, testUDRP22, testUDRP23, testUDRP24};
        insert testUDRPList;
    }

    private static Utility_Data_Request__c getTestUDR(String customerName) {
        return [
            SELECT Id, Request_Status__c, Customer_Name__c, State__c, Utility__c, Annual_kWh__c,
                Utility_Account_Log__c, Utility_Account_Log__r.Utility_Rate_Class__c
            FROM Utility_Data_Request__c
            WHERE Customer_Name__c = :customerName
        ];
    }

    private static Utility_Account_Log__c getTestUAL(Id ualId) {
        return [
            SELECT Id, Name, Name_on_Account__c, Utility_Rate_Class__c, Annual_kWh__c
            FROM Utility_Account_Log__c
            WHERE Id = :ualId
        ];
    }

    private static Utility_Data_Request_Period__c getTestUDRP(String rateSubclass) {
        return [
            SELECT Id, Name, Utility_Data_Request__c, Rate_Class__c, Rate_Class_Lookup__c, Service_Start_Date__c,
                Utility_Data_Request__r.Utility__c, Utility_Data_Request__r.Utility_Account_Log__r.Utility_Rate_Class__c,
                Used_In_Annual_kWh_Calculation__c
            FROM Utility_Data_Request_Period__c
            WHERE Rate_Subclass__c = :rateSubclass
        ];
    }

    private static List<Utility_Data_Request_Period__c> getTestUDRPList(Id udrId) {
        return [
            SELECT Id, Name, Utility_Data_Request__c, Rate_Class__c, Rate_Class_Lookup__c, Service_Start_Date__c,
                Utility_Data_Request__r.Utility__c, Utility_Data_Request__r.Utility_Account_Log__r.Utility_Rate_Class__c,
                Used_In_Annual_kWh_Calculation__c
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
    static void updateStatusToComplete() {
        List<Error_Log__c> errorLogs = [SELECT Id, Class__c, Method__c, Message__c, Severity__c FROM Error_Log__c];
        System.assertEquals(0, errorLogs.size());
        
        Utility_Data_Request__c testUDR1 = getTestUDR('testUDR1');
        testUDR1.Request_Status__c = 'Complete';
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
        System.assertEquals(1, errorLogs.size());
        
        System.assert(errorLogs[0].Message__c.contains('Null Rate Class on'));
        System.assert(errorLogs[0].Message__c.contains('No matching Rate Class record with an EDI Rate Class for the Rate Class text on'));
        
    }
    
    @IsTest
    static void updateStatusToNotComplete() {
        Utility_Data_Request__c testUDR1 = getTestUDR('testUDR1');
        testUDR1.Request_Status__c = 'Sent';
        update testUDR1;
        
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
        testUDR1.Request_Status__c = 'Complete';
        update testUDR1;
        
        System.assertEquals(null, testUDR1.Utility_Account_Log__r.Utility_Rate_Class__c,
            'The most recent UDRP has a null Rate Class, so the Utility_Rate_Class__c on  UAL should still be null'
        );
        
        errorLogs = [SELECT Id, Class__c, Method__c, Message__c, Severity__c FROM Error_Log__c];
        System.assert(!errorLogs.isEmpty(), 'Error logs should have generated for this transaction');
    }
    
    @IsTest
    static void testAnnualkWhPopulation() {
        Utility_Data_Request__c testUDR1 = getTestUDR('testUDR1');
        Utility_Data_Request__c testUDR3 = getTestUDR('testUDR3');
        Utility_Data_Request__c testUDR4 = getTestUDR('testUDR4');
        Utility_Data_Request__c testUDR5 = getTestUDR('testUDR5');
        
        testUDR1.Request_Status__c = 'Complete';
        testUDR3.Request_Status__c = 'Complete';
        testUDR4.Request_Status__c = 'Complete';
        testUDR5.Request_Status__c = 'Complete';
        
        List<Utility_Data_Request__c> testUDRList = new List<Utility_Data_Request__c>{testUDR1, testUDR3, testUDR4, testUDR5};
        update testUDRList;
        
        Utility_Account_Log__c testUAL1 = getTestUAL(testUDR1.Utility_Account_Log__c);
        Utility_Account_Log__c testUAL3 = getTestUAL(testUDR3.Utility_Account_Log__c);
        Utility_Account_Log__c testUAL4 = getTestUAL(testUDR4.Utility_Account_Log__c);
        Utility_Account_Log__c testUAL5 = getTestUAL(testUDR5.Utility_Account_Log__c);
        
        Utility_Data_Request__c updatedTestUDR1 = getTestUDR('testUDR1');
        Utility_Data_Request__c updatedTestUDR3 = getTestUDR('testUDR3');
        Utility_Data_Request__c updatedTestUDR4 = getTestUDR('testUDR4');
        Utility_Data_Request__c updatedTestUDR5 = getTestUDR('testUDR5');
        
        System.assertEquals(33823.2, testUAL1.Annual_kWh__c, 'UAL1 is related to UDR1,' 
                            + ' which has 5 UDRPs so the Annual kWh should be the sum of the UDRP.Quantity__c values divided by the number of months and multiplied by 12.'
                            + 'In this case the answer should be 33823.2.');
        System.assertEquals(1234, testUAL3.Annual_kWh__c, 'UAL3 is related to UDR3,' 
                            + ' which has 1 UDRP, it is a non-Residential customer, and the Product.X4_month_sizing_method__c == State Average Annual Usage, ' 
                            + 'so the Annual kWh should be the related State Avg Annual Resi kWh.'
                            + 'In this case the answer should be 1234 since the test State Avg Annual Resi kWh is 1234.');
        System.assertEquals(60572, testUAL4.Annual_kWh__c, 'UAL4 is related to UDR4,' 
                            + ' which has 3 UDRPs and is a Residential customer, ' 
                            + 'so the Annual kWh should be the sum of the UDRP.Quantity__c values divided by the number of months and multiplied by 12.'
                            + 'In this case the answer should be 60572.');
        System.assertEquals(487579, testUAL5.Annual_kWh__c, 'UAL5 is related to UDR5,' 
                            + ' which has 14 UDRPs and is a Residential customer, ' 
                            + 'so the Annual kWh should be the sum of the 12 most recent UDRP.Quantity__c values.'
                            + 'In this case the answer should be 487579.');
        
        System.assertEquals(33823.2, updatedTestUDR1.Annual_kWh__c, 'UDR1 has 5 UDRPs so the Annual kWh should be ' 
                            + 'the sum of the UDRP.Quantity__c values multiplied by the number of months and divided by 12.'
                            + 'In this case the answer should be 33823.2.');
        System.assertEquals(1234, updatedTestUDR3.Annual_kWh__c, 'UDR3 has 1 UDRPs, it is a non-Residential customer, and the Product.X4_month_sizing_method__c == State Average Annual Usage' 
                            + 'so the Annual kWh should be the related State Avg Annual Resi kWh.'
                            + 'In this case the answer should be 1234 since the test State Avg Annual Resi kWh is 1234.');
        System.assertEquals(60572, updatedTestUDR4.Annual_kWh__c, 'UDR4 has 3 UDRPs and is a Residential customer, ' 
                            + 'so the Annual kWh should be the sum of the UDRP.Quantity__c values divided by the number of months and multiplied by 12.'
                            + 'In this case the answer should be 60572.');
        System.assertEquals(487579, updatedTestUDR5.Annual_kWh__c, 'UDR5 has 14 UDRPs and is a Residential customer, ' 
                            + 'so the Annual kWh should be the sum of the 12 most recent UDRP.Quantity__c values.'
                            + 'In this case the answer should be 487579.');
        
        List<Utility_Data_Request__c> updatedTestUDRList = new List<Utility_Data_Request__c>{testUDR1, testUDR3, testUDR4, testUDR5};
        List<Utility_Data_Request_Period__c> testUDRPList= udrpSelector.selectWithKHByUDR(updatedTestUDRList);
        
        for(Utility_Data_Request_Period__c udrp : testUDRPList) {
            if(udrp.Rate_Subclass__c == 'testUDRP7' || udrp.Rate_Subclass__c == 'testUDRP12' || udrp.Rate_Subclass__c == 'testUDRP23') {
                System.assertEquals(false, udrp.Used_in_Annual_kWh_Calculation__c, 'Not used in kWh calculation, should be false.');
            } else {
                System.assertEquals(true, udrp.Used_in_Annual_kWh_Calculation__c, 'Used in kWh Calculation, should be true.');
            }
        }
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
            Name_on_Account__c = 'testUAL1',
            Utility_lookup__c = utilityId
        );
        insert ual;

        Test.startTest();
            System.assertEquals(0, udrCount(ual.Id), 'UDRs prior to create() method run should be 0');
            UtilityDataRequestService.create(new List<String>{lead.Id});
        Test.stopTest();

        // Check results... Should have generated a new UDR with appropriate field vals, and updated UAL
        List<Utility_Data_Request__c> udrs = [
            SELECT Id, Account_Number__c, Utility__c, Utility_DUNS__c, Utility_Name__c, Request_Status__c,
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
        System.assertEquals('Pending', udrs[0].Request_Status__c, 'Incorrect status for newly-generated UDR');
        System.assertEquals('Pending Utility Data', udrs[0].Utility_Account_Log__r.QC_Status__c, 'UAL status incorrect for pending UDR');
    }
    
}