/**
 * Created by: Kristin White on 9/29/2020
 * 
 */

@IsTest
private class UtilityDataRequestServiceTest {
    
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
            SELECT Id, Name_on_Account__c, Utility_Rate_Class__c, Annual_kWh__c
            FROM Utility_Account_Log__c
            WHERE Id = :ualId
        ];
    }
    
    private static Utility_Data_Request_Period__c getTestUDRP(String rateSubclass) {
        return [
            SELECT Id, Name, Utility_Data_Request__c, Rate_Class__c, Rate_Class_Lookup__c, Service_Start_Date__c, 
            Utility_Data_Request__r.Utility__c, Utility_Data_Request__r.Utility_Account_Log__r.Utility_Rate_Class__c
            FROM Utility_Data_Request_Period__c 
            WHERE Rate_Subclass__c = :rateSubclass
        ];
    }
    
    private static List<Utility_Data_Request_Period__c> getTestUDRPList(Id udrId) {
        return [
            SELECT Id, Name, Utility_Data_Request__c, Rate_Class__c, Rate_Class_Lookup__c, Service_Start_Date__c, 
            Utility_Data_Request__r.Utility__c, Utility_Data_Request__r.Utility_Account_Log__r.Utility_Rate_Class__c
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
    
    @TestSetup
    public static void setupData() {
        
        Partner__c testPartner = new Partner__c(
    		Name = 'Default CS Partner',
    		Email__c = 'default@email.com'
		);
		insert testPartner;
		TestFactory.setDefaultCSPartner(testPartner.Id);
        
        Utility__c testUtility = new Utility__c(
            Name = 'testUtility'
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
            Partner_Lookup__c = testPartner.Id
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
            Name_on_Account__c = 'testUAL1'
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
            Quantity__c = 25
        );
        
        Utility_Data_Request_Period__c testUDRP2 = new Utility_Data_Request_Period__c(
            Utility_Data_Request__c = testUDR1.Id, 
            Rate_Class__c = 'Test EDI Rate Class 2',
            Rate_Subclass__c = 'testUDRP2',
            Service_Start_Date__c = Date.newInstance(2020, 7, 7),
            Measurement_Unit__c ='KH',
            Quantity__c = 101
        );
        
        Utility_Data_Request_Period__c testUDRP3 = new Utility_Data_Request_Period__c(
            Utility_Data_Request__c = testUDR1.Id, 
            Rate_Class__c = 'Test EDI Rate Class 2',
            Rate_Subclass__c = 'testUDRP3',
            Service_Start_Date__c = Date.newInstance(2020, 10, 12),
            Measurement_Unit__c ='KH',
            Quantity__c = 6914
        );
        
        Utility_Data_Request_Period__c testUDRP4 = new Utility_Data_Request_Period__c(
            Utility_Data_Request__c = testUDR1.Id, 
            Rate_Class__c = Null,
            Rate_Subclass__c = 'testUDRP4',
            Service_Start_Date__c = Date.newInstance(2020, 9, 15),
            Measurement_Unit__c ='KH',
            Quantity__c = 50
        );
        
        Utility_Data_Request_Period__c testUDRP5 = new Utility_Data_Request_Period__c(
            Utility_Data_Request__c = testUDR1.Id, 
            Rate_Class__c = 'Nonexistent/Misspelled EDI',
            Rate_Subclass__c = 'testUDRP5',
            Service_Start_Date__c = Date.newInstance(2020, 2, 1),
            Measurement_Unit__c ='KH',
            Quantity__c = 7003
        );
        
        Utility_Data_Request_Period__c testUDRP6 = new Utility_Data_Request_Period__c(
            Utility_Data_Request__c = testUDR2.Id, 
            Rate_Class__c = 'Test EDI Rate Class 2',
            Rate_Subclass__c = 'testUDRP6',
            Service_Start_Date__c = Date.newInstance(2020, 9, 14),
            Measurement_Unit__c ='KH',
            Quantity__c = 1234
        );
        
        Utility_Data_Request_Period__c testUDRP7 = new Utility_Data_Request_Period__c(
            Utility_Data_Request__c = testUDR3.Id, 
            Rate_Class__c = 'Test EDI Rate Class 1',
            Rate_Subclass__c = 'testUDRP7',
            Service_Start_Date__c = Date.newInstance(2020, 9, 1),
            Measurement_Unit__c ='KH',
            Quantity__c = 12099
        );
        
        Utility_Data_Request_Period__c testUDRP8 = new Utility_Data_Request_Period__c(
            Utility_Data_Request__c = testUDR4.Id, 
            Rate_Class__c = 'Test EDI Rate Class 1',
            Rate_Subclass__c = 'testUDRP8',
            Service_Start_Date__c = Date.newInstance(2019, 5, 20),
            Measurement_Unit__c ='KH',
            Quantity__c = 4387
        );
        
        Utility_Data_Request_Period__c testUDRP9 = new Utility_Data_Request_Period__c(
            Utility_Data_Request__c = testUDR4.Id, 
            Rate_Class__c = 'Test EDI Rate Class 1',
            Rate_Subclass__c = 'testUDRP9',
            Service_Start_Date__c = Date.newInstance(2020, 5, 20),
            Measurement_Unit__c ='KH',
            Quantity__c = 999
        );
        
        Utility_Data_Request_Period__c testUDRP10 = new Utility_Data_Request_Period__c(
            Utility_Data_Request__c = testUDR4.Id, 
            Rate_Class__c = 'Test EDI Rate Class 1',
            Rate_Subclass__c = 'testUDRP10',
            Service_Start_Date__c = Date.newInstance(2020, 8, 28),
            Measurement_Unit__c ='KH',
            Quantity__c = 9757
        );
        
        Utility_Data_Request_Period__c testUDRP11 = new Utility_Data_Request_Period__c(
            Utility_Data_Request__c = testUDR5.Id, 
            Rate_Class__c = 'Test EDI Rate Class 1',
            Rate_Subclass__c = 'testUDRP11',
            Service_Start_Date__c = Date.newInstance(2020, 10, 3),
            Measurement_Unit__c ='KH',
            Quantity__c = 6789
        );
        
        Utility_Data_Request_Period__c testUDRP12 = new Utility_Data_Request_Period__c(
            Utility_Data_Request__c = testUDR5.Id, 
            Rate_Class__c = 'Test EDI Rate Class 1',
            Rate_Subclass__c = 'testUDRP12',
            Service_Start_Date__c = Date.newInstance(2019, 2, 22),
            Measurement_Unit__c ='KH',
            Quantity__c = 8311
        );
        
        Utility_Data_Request_Period__c testUDRP13 = new Utility_Data_Request_Period__c(
            Utility_Data_Request__c = testUDR5.Id, 
            Rate_Class__c = 'Test EDI Rate Class 1',
            Rate_Subclass__c = 'testUDRP13',
            Service_Start_Date__c = Date.newInstance(2020, 9, 10),
            Measurement_Unit__c ='KH',
            Quantity__c = 11111
        );
        
        Utility_Data_Request_Period__c testUDRP14 = new Utility_Data_Request_Period__c(
            Utility_Data_Request__c = testUDR5.Id, 
            Rate_Class__c = 'Test EDI Rate Class 1',
            Rate_Subclass__c = 'testUDRP14',
            Service_Start_Date__c = Date.newInstance(2020, 8, 3),
            Measurement_Unit__c ='KH',
            Quantity__c = 53977
        );
        
        Utility_Data_Request_Period__c testUDRP15 = new Utility_Data_Request_Period__c(
            Utility_Data_Request__c = testUDR5.Id, 
            Rate_Class__c = 'Test EDI Rate Class 1',
            Rate_Subclass__c = 'testUDRP15',
            Service_Start_Date__c = Date.newInstance(2020, 7, 10),
            Measurement_Unit__c ='KH',
            Quantity__c = 2525
        );
        
        Utility_Data_Request_Period__c testUDRP16 = new Utility_Data_Request_Period__c(
            Utility_Data_Request__c = testUDR5.Id, 
            Rate_Class__c = 'Test EDI Rate Class 1',
            Rate_Subclass__c = 'testUDRP16',
            Service_Start_Date__c = Date.newInstance(2020, 6, 28),
            Measurement_Unit__c ='KH',
            Quantity__c = 9222
        );
        
        Utility_Data_Request_Period__c testUDRP17 = new Utility_Data_Request_Period__c(
            Utility_Data_Request__c = testUDR5.Id, 
            Rate_Class__c = 'Test EDI Rate Class 1',
            Rate_Subclass__c = 'testUDRP17',
            Service_Start_Date__c = Date.newInstance(2020, 5, 2),
            Measurement_Unit__c ='KH',
            Quantity__c = 88
        );
        
        Utility_Data_Request_Period__c testUDRP18 = new Utility_Data_Request_Period__c(
            Utility_Data_Request__c = testUDR5.Id, 
            Rate_Class__c = 'Test EDI Rate Class 1',
            Rate_Subclass__c = 'testUDRP18',
            Service_Start_Date__c = Date.newInstance(2020, 4, 17),
            Measurement_Unit__c ='KH',
            Quantity__c = 417
        );
        
        Utility_Data_Request_Period__c testUDRP19 = new Utility_Data_Request_Period__c(
            Utility_Data_Request__c = testUDR5.Id, 
            Rate_Class__c = 'Test EDI Rate Class 1',
            Rate_Subclass__c = 'testUDRP19',
            Service_Start_Date__c = Date.newInstance(2020, 3, 20),
            Measurement_Unit__c ='KH',
            Quantity__c = 4399
        );
        
        Utility_Data_Request_Period__c testUDRP20 = new Utility_Data_Request_Period__c(
            Utility_Data_Request__c = testUDR5.Id, 
            Rate_Class__c = 'Test EDI Rate Class 1',
            Rate_Subclass__c = 'testUDRP20',
            Service_Start_Date__c = Date.newInstance(2020, 2, 19),
            Measurement_Unit__c ='KH',
            Quantity__c = 2019
        );
        
        Utility_Data_Request_Period__c testUDRP21 = new Utility_Data_Request_Period__c(
            Utility_Data_Request__c = testUDR5.Id, 
            Rate_Class__c = 'Test EDI Rate Class 1',
            Rate_Subclass__c = 'testUDRP21',
            Service_Start_Date__c = Date.newInstance(2020, 1, 1),
            Measurement_Unit__c ='KH',
            Quantity__c = 334455
        );
        
        Utility_Data_Request_Period__c testUDRP22 = new Utility_Data_Request_Period__c(
            Utility_Data_Request__c = testUDR5.Id, 
            Rate_Class__c = 'Test EDI Rate Class 1',
            Rate_Subclass__c = 'testUDRP22',
            Service_Start_Date__c = Date.newInstance(2020, 1, 2),
            Measurement_Unit__c ='KH',
            Quantity__c = 19788
        );
        
        Utility_Data_Request_Period__c testUDRP23 = new Utility_Data_Request_Period__c(
            Utility_Data_Request__c = testUDR5.Id, 
            Rate_Class__c = 'Test EDI Rate Class 1',
            Rate_Subclass__c = 'testUDRP23',
            Service_Start_Date__c = Date.newInstance(2019, 2, 19),
            Measurement_Unit__c ='KH',
            Quantity__c = 764655
        );
        
        Utility_Data_Request_Period__c testUDRP24 = new Utility_Data_Request_Period__c(
            Utility_Data_Request__c = testUDR5.Id, 
            Rate_Class__c = 'Test EDI Rate Class 1',
            Rate_Subclass__c = 'testUDRP24',
            Service_Start_Date__c = Date.newInstance(2020, 4, 27),
            Measurement_Unit__c ='KH',
            Quantity__c = 42789
        );
        
        List<Utility_Data_Request_Period__c> testUDRPList = new List<Utility_Data_Request_Period__c>{
            testUDRP1, testUDRP2, testUDRP3, testUDRP4, testUDRP5, testUDRP6, testUDRP7, testUDRP8, 
            testUDRP9, testUDRP10, testUDRP11, testUDRP12, testUDRP13, testUDRP14, testUDRP15, testUDRP16, 
            testUDRP17, testUDRP18, testUDRP19, testUDRP20, testUDRP21, testUDRP22, testUDRP23, testUDRP24};
        insert testUDRPList;
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
        
        System.assert(errorLogs[0].Message__c.contains('Null Rate Class on UDRP'));
        System.assert(errorLogs[0].Message__c.contains('No matching Rate Class record with an EDI Rate Class for the Rate Class text on UDRP '));
        
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
        
        System.assertEquals(Null, testUDR1.Utility_Account_Log__r.Utility_Rate_Class__c, 
                            'The most recent UDRP has a null Rate Class Lookup, so the "Rate Class" (Utility_Rate_Class__c) on the UAL should still be null');
        
        errorLogs = [SELECT Id, Class__c, Method__c, Message__c, Severity__c FROM Error_Log__c];
        System.assertEquals(2, errorLogs.size());
        
        System.assert(errorLogs[1].Message__c.contains('Null Rate_Class_Lookup__c value for most recent UDRP related to UDR'));
        
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
        
        System.assertEquals(42279, testUAL1.Annual_kWh__c, 'UAL1 is related to UDR1,' 
                            + ' which has 5 UDRPs so the Annual kWh should be the sum of the UDRP.Quantity__c values divided by 4 and multiplied by 12.'
                            + 'In this case the answer should be 42279.');
        System.assertEquals(1234, testUAL3.Annual_kWh__c, 'UAL3 is related to UDR3,' 
                            + ' which has 1 UDRP, it is a non-Residential customer, and the Product.X4_month_sizing_method__c == State Average Annual Usage, ' 
                            + 'so the Annual kWh should be the related State Avg Annual Resi kWh.'
                            + 'In this case the answer should be 1234 since the test State Avg Annual Resi kWh is 1234.');
        System.assertEquals(45429, testUAL4.Annual_kWh__c, 'UAL4 is related to UDR4,' 
                            + ' which has 3 UDRPs and is a Residential customer, ' 
                            + 'so the Annual kWh should be the sum of the UDRP.Quantity__c values divided by 4 and multiplied by 12.'
                            + 'In this case the answer should be 45429.');
        System.assertEquals(487579, testUAL5.Annual_kWh__c, 'UAL5 is related to UDR5,' 
                            + ' which has 14 UDRPs and is a Residential customer, ' 
                            + 'so the Annual kWh should be the sum of the 12 most recent UDRP.Quantity__c values.'
                            + 'In this case the answer should be 487579.');
        
        System.assertEquals(42279, updatedTestUDR1.Annual_kWh__c, 'UDR1 has 5 UDRPs so the Annual kWh should be ' 
                            + 'the sum of the UDRP.Quantity__c values multiplied by 4 and divided by 12.'
                            + 'In this case the answer should be 42279.');
        System.assertEquals(1234, updatedTestUDR3.Annual_kWh__c, 'UDR3 has 1 UDRPs, it is a non-Residential customer, and the Product.X4_month_sizing_method__c == State Average Annual Usage' 
                            + 'so the Annual kWh should be the related State Avg Annual Resi kWh.'
                            + 'In this case the answer should be 1234 since the test State Avg Annual Resi kWh is 1234.');
        System.assertEquals(45429, updatedTestUDR4.Annual_kWh__c, 'UDR4 has 3 UDRPs and is a Residential customer, ' 
                            + 'so the Annual kWh should be the sum of the UDRP.Quantity__c values divided by 4 and multiplied by 12.'
                            + 'In this case the answer should be 45429.');
        System.assertEquals(487579, updatedTestUDR5.Annual_kWh__c, 'UDR5 has 14 UDRPs and is a Residential customer, ' 
                            + 'so the Annual kWh should be the sum of the 12 most recent UDRP.Quantity__c values.'
                            + 'In this case the answer should be 487579.');
    }
    
}