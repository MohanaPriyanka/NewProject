/**
 * Created by: Kristin White on 10/13/2020
 * 
 */

@IsTest
public class UtilityDataRequestPeriodSelectorTest {
    
    private static UtilityDataRequestPeriodSelector controller = new UtilityDataRequestPeriodSelector();
    
    @TestSetup
    public static void setupData() {
        
        Utility_Data_Request__c testUDR1 = new Utility_Data_Request__c(
            Request_Status__c = 'Pending',
            Customer_Name__c = 'testUDR1',
            State__c = 'MA'
        );
        
        insert testUDR1;
        
        Utility_Data_Request_Period__c testUDRP1 = new Utility_Data_Request_Period__c(
            Utility_Data_Request__c = testUDR1.Id, 
            Rate_Class__c = 'Test EDI Rate Class 2',
            Rate_Subclass__c = 'testUDRP1',
            Service_Start_Date__c = Date.newInstance(2019, 11, 3)
        );
        
        Utility_Data_Request_Period__c testUDRP2 = new Utility_Data_Request_Period__c(
            Utility_Data_Request__c = testUDR1.Id, 
            Rate_Class__c = 'Test EDI Rate Class 2',
            Rate_Subclass__c = 'testUDRP2',
            Service_Start_Date__c = Date.newInstance(2020, 7, 1)
        );
        
        Utility_Data_Request_Period__c testUDRP3 = new Utility_Data_Request_Period__c(
            Utility_Data_Request__c = testUDR1.Id, 
            Rate_Class__c = 'Test EDI Rate Class 1',
            Rate_Subclass__c = 'testUDRP3',
            Service_Start_Date__c = Date.newInstance(2020, 9, 14)
        );
        
        List<Utility_Data_Request_Period__c> testUDRPList = new List<Utility_Data_Request_Period__c>{testUDRP1, testUDRP2, testUDRP3};
        insert testUDRPList;
    }
    
    @IsTest
    static void testSelectByUDR() {
        Set<Id> udrIdSet = new Set<Id>();
        
        Utility_Data_Request__c testUDR1 = [
            SELECT Id, Request_Status__c, Customer_Name__c, State__c, Utility__c 
            FROM Utility_Data_Request__c 
            WHERE Customer_Name__c = 'testUDR1'
        ];
        
        udrIdSet.add(testUDR1.Id);
        
        List<Utility_Data_Request_Period__c> udrpList = controller.selectByUDR(udrIdSet);
        
        System.assertEquals(udrpList[0].Rate_Class__c, 'Test EDI Rate Class 1');
    }

}