/**
 * Created by mstackhouse on 12/28/2018.
 * Description: Tests for CaseFactory
 */

@IsTest
public with sharing class CaseFactoryTest {
    @IsTest
    public static void testGetProductSupportCase() {
        RecordType productSupport = [
            SELECT Id, Name
            FROM RecordType
            WHERE SobjectType = 'Case' AND DeveloperName = 'Product_Support'
            LIMIT 1
        ];

        Group productQueueID = [
            SELECT Id, DeveloperName
            FROM Group
            WHERE Type = 'Queue'
            AND DeveloperName = 'Product_Support'
            LIMIT 1
        ];

        CaseFactory caseFactory = new CaseFactory();
        Case testCase = caseFactory.getCase('Product_Support');

        System.assertEquals(productSupport.Id, testCase.RecordTypeId);
        System.assertEquals(productQueueID.Id, testCase.OwnerId);
    }

    @IsTest
    public static void testGetCustomerCareCase() {
        RecordType customerCare = [
            SELECT Id, Name
            FROM RecordType
            Where SobjectType = 'Case' and DeveloperName = 'Customer_Care'
            LIMIT 1
        ];

        Group customerCareQueueID = [
            SELECT Id, DeveloperName
            FROM Group
            WHERE Type = 'Queue'
            AND DeveloperName = 'Customer_Care'
            LIMIT 1
        ];


        CaseFactory caseFactory = new CaseFactory();
        Case testCase = caseFactory.getCase('Customer_Care');

        System.assertEquals(customerCare.Id, testCase.RecordTypeId);
        System.assertEquals(customerCareQueueID.Id, testCase.OwnerId);
    }

    @IsTest
    public static void getCollectionsCase() {
        RecordType customerCare = [
            SELECT Id, Name
            FROM RecordType
            Where SobjectType = 'Case' and DeveloperName = 'Customer_Care'
            LIMIT 1
        ];

        Group collectionsQueue = [
            SELECT Id, DeveloperName
            FROM Group
            WHERE Type = 'Queue'
            AND DeveloperName = 'Collections'
            LIMIT 1
        ];

        CaseFactory caseFactory = new CaseFactory();
        Case testCase = caseFactory.getCase('Collections');

        System.assertEquals(customerCare.Id, testCase.RecordTypeId);
        System.assertEquals(collectionsQueue.Id, testCase.OwnerId);
    }

    @IsTest
    public static void getDataOpsCase(){
        RecordType customerCare = [
            SELECT Id, Name
            FROM RecordType
            Where SobjectType = 'Case' and DeveloperName = 'Customer_Care'
            LIMIT 1
        ];

        Group dataOpsQueue = [
            SELECT Id, DeveloperName
            FROM Group
            WHERE Type = 'Queue'
            AND DeveloperName = 'Data_Ops'
            LIMIT 1
        ];

        CaseFactory caseFactory = new CaseFactory();
        Case testCase = caseFactory.getCase('Data_Ops');

        System.assertEquals(customerCare.Id, testCase.RecordTypeId);
        System.assertEquals(dataOpsQueue.Id, testCase.OwnerId);
    }

    @IsTest
    public static void testGetCaseWithoutType() {
        CaseFactory caseFactory = new CaseFactory();
        Case testCase = caseFactory.getCase('Emotional_Support');

        System.assertEquals(null, testCase.RecordTypeId);
        System.assertEquals(null, testCase.OwnerId);
    }
}