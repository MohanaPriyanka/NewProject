/**
 * Created by: Kristin White on 9/29/2020
 * 
 */

@IsTest
private class UtilityDataRequestServiceTest {
    
    @TestSetup
    public static void setupData() {
        
        Utility__c testUtility = new Utility__c(
            Name = 'testUtility'
        );
        
        Utility_Data_Request__c testUDR1 = new Utility_Data_Request__c(
            Request_Status__c = 'Pending',
            Customer_Name__c = 'testUDR1',
            State__c = 'MA',
            Utility__c = testUtility.Id
        );
        
        Utility_Data_Request__c testUDR2 = new Utility_Data_Request__c(
            Request_Status__c = 'Complete',
            Customer_Name__c = 'testUDR2',
            State__c = 'MA',
            Utility__c = testUtility.Id
        );
        
        List<Utility_Data_Request__c> testUDRList = new List<Utility_Data_Request__c>{testUDR1, testUDR2};
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
            Rate_Subclass__c = 'testUDRP1'
        );
        
        Utility_Data_Request_Period__c testUDRP2 = new Utility_Data_Request_Period__c(
            Utility_Data_Request__c = testUDR1.Id, 
            Rate_Class__c = 'Test EDI Rate Class 2',
            Rate_Subclass__c = 'testUDRP2'
        );
        
        Utility_Data_Request_Period__c testUDRP3 = new Utility_Data_Request_Period__c(
            Utility_Data_Request__c = testUDR1.Id, 
            Rate_Class__c = 'Test EDI Rate Class 2',
            Rate_Subclass__c = 'testUDRP3'
        );
        
        Utility_Data_Request_Period__c testUDRP4 = new Utility_Data_Request_Period__c(
            Utility_Data_Request__c = testUDR1.Id, 
            Rate_Class__c = Null,
            Rate_Subclass__c = 'testUDRP4'
        );
        
        Utility_Data_Request_Period__c testUDRP5 = new Utility_Data_Request_Period__c(
            Utility_Data_Request__c = testUDR1.Id, 
            Rate_Class__c = 'Nonexistent/Misspelled EDI',
            Rate_Subclass__c = 'testUDRP5'
        );
        
        Utility_Data_Request_Period__c testUDRP6 = new Utility_Data_Request_Period__c(
            Utility_Data_Request__c = testUDR2.Id, 
            Rate_Class__c = 'Test EDI Rate Class 2',
            Rate_Subclass__c = 'testUDRP6'
        );
        
        List<Utility_Data_Request_Period__c> testUDRPList = new List<Utility_Data_Request_Period__c>{testUDRP1, testUDRP2, testUDRP3, testUDRP4, testUDRP5, testUDRP6};
        insert testUDRPList;
    }
    
    @IsTest
    static void updateStatusToComplete() {
        List<Error_Log__c> errorLogs = [SELECT Id, Class__c, Method__c, Message__c, Severity__c FROM Error_Log__c];
        System.assertEquals(0, errorLogs.size());
        
        Utility_Data_Request__c testUDR1 = [
            SELECT Id, Request_Status__c, Customer_Name__c, State__c, Utility__c 
            FROM Utility_Data_Request__c 
            WHERE Customer_Name__c = 'testUDR1'
        ];
        
        testUDR1.Request_Status__c = 'Complete';
        update testUDR1;
        
        List<Utility_Data_Request_Period__c> testUDRPList = [
            SELECT Id, Utility_Data_Request__c, Rate_Class__c, Rate_Class_Lookup__c 
            FROM Utility_Data_Request_Period__c 
            WHERE Utility_Data_Request__c = :testUDR1.Id
        ];
        
        List<Rate_Class__c> testRateClassList = [
            SELECT Id, Name, EDI_Rate_Class__c, Utility__c
            FROM Rate_Class__c 
            WHERE Name IN ('testRateClass1', 'testRateClass2')
        ];
        
        System.assertEquals(testUDRPList[0].Rate_Class_Lookup__c, testRateClassList[0].Id, 
                            'The Rate_Class_Lookup__c for testUDRP1 should now be testRateClass1.');
        System.assertEquals(testUDRPList[1].Rate_Class_Lookup__c, testRateClassList[1].Id, 
                            'The Rate_Class_Lookup__c for testUDRP2 should now be testRateClass2.');
        System.assertEquals(testUDRPList[2].Rate_Class_Lookup__c, testRateClassList[1].Id, 
                            'The Rate_Class_Lookup__c for testUDRP3 should now be testRateClass2.');
        System.assertEquals(testUDRPList[3].Rate_Class_Lookup__c, Null, 
                            'The Rate_Class_Lookup__c for testUDRP4 should be null because ' 
                            + 'the Rate_Class__c text was null, so no Rate Class object could be found for it.');
        System.assertEquals(testUDRPList[4].Rate_Class_Lookup__c, Null, 
                            'The Rate_Class_Lookup__c for testUDRP5 should be null because ' 
                            + 'the Rate_Class__c text did not match any Rate_Class__c.EDI_Rate_Class__c fields');
        
        errorLogs = [SELECT Id, Class__c, Method__c, Message__c, Severity__c FROM Error_Log__c];
        System.assertEquals(1, errorLogs.size());
        
        System.assert(errorLogs[0].Message__c.contains('Null Rate Class on UDRP'));
        System.assert(errorLogs[0].Message__c.contains('No matching Rate Class record with an EDI Rate Class for the Rate Class text on UDRP '));
        
    }
    
    @IsTest
    static void updateStatusToNotComplete() {
        Utility_Data_Request__c testUDR1 = [
            SELECT Id, Request_Status__c, Customer_Name__c, State__c, Utility__c 
            FROM Utility_Data_Request__c 
            WHERE Customer_Name__c = 'testUDR1'
        ];
        testUDR1.Request_Status__c = 'Sent';
        update testUDR1;
        
        List<Utility_Data_Request_Period__c> testUDRPList = [
            SELECT Id, Utility_Data_Request__c, Rate_Class__c, Rate_Class_Lookup__c 
            FROM Utility_Data_Request_Period__c 
            WHERE Utility_Data_Request__c = :testUDR1.Id
        ];
        
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
        Utility_Data_Request__c testUDR2 = [
            SELECT Id, Request_Status__c, Customer_Name__c, State__c, Utility__c 
            FROM Utility_Data_Request__c 
            WHERE Customer_Name__c = 'testUDR2'
        ];
        testUDR2.State__c = 'GA';
        update testUDR2;

        List<Utility_Data_Request_Period__c> testUDRPList = [
            SELECT Id, Utility_Data_Request__c, Rate_Class__c, Rate_Class_Lookup__c 
            FROM Utility_Data_Request_Period__c 
            WHERE Utility_Data_Request__c = :testUDR2.Id
        ];
        
        System.assertEquals(testUDRPList[0].Rate_Class_Lookup__c, Null, 
                            'testUDRP6 is related to testUDR2, whose status was already Complete before the update,' 
                            + ' so the EDI_Rate_Class should still be null becuase the status did not update to complete,');
    }
    
}