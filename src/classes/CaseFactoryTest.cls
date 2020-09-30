/**
 * Created by mstackhouse on 12/28/2018.
 * Description: Tests for CaseFactory
 */

@IsTest
public with sharing class CaseFactoryTest {
    @TestSetup
    public static void setupTestData() {
        Test.startTest();
        Load_U__c loadZone = new Load_U__c (
            Name = '12345',
            LZ__c = 'Hudson Valley',
            Town__c = 'Albany'
        );

        Utility__c nyseg = new Utility__c(
            Name = 'NYS Electric and Gas',
            Number_of_Decimal_Places__c = 2,
            EIA_ID__c = '1234'
        );

        Product2 vderProduct = new Product2(Name = 'VDER',
            Family = 'Community Solar',
            Product_Type__c = 'Community Solar',
            Program__c = 'VDER - Community Solar',
            State__c = 'NY',
            IsActive = true,
            Lender_of_Record__c = 'BlueWave',
            NMC_Discount__c = 10,
            Annual_kWh_Maximum__c = 100000000,
            NM_Rate_Floor__c = 0,
            Days_in_Bill_Period__c = 20,
            Monthly_Late_Fee__c = 1);

        Lead resiLead = new Lead(
            FirstName = 'Switch',
            LastName = 'Testcase',
            Email = 'test@email.com',
            MobilePhone = '1231231234',
            Company = 'Post Testcase',
            Application_Type__c = 'Residential',
            LASERCA__Home_Address__c = '55 Boston St.',
            LASERCA__Home_City__c = 'Albany',
            LASERCA__Home_State__c = 'NY',
            LASERCA__Home_Zip__c = '12345',
            Street = '55 Boston St',
            City = 'Albany',
            State = BlueWaveParent.convertAbbreviationToState('NY'),
            PostalCode = '12345',
            Parcel_Zip__c = '12345',
            Application_Source_Phase_1__c = 'Switch without Partner',
            LeadSource = 'Switch',
            Product_line__c = 'Community Solar',
            Product__c = vderProduct.Id,
            LoadZone__c = loadZone.LZ__c,
            Utility_relationship__c = nyseg.Id,
            Phone = '1231231234',
            Customer_type__c = 'Residential',
            Status = 'Sales Qualified'
        );

        Database.DMLOptions dmo = new Database.DMLOptions();
        dmo.assignmentRuleHeader.useDefaultRule = true;
        resiLead.setOptions(dmo);

        insert resiLead;
        Test.stopTest();
    }
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
    public static void getDataOpsCase() {
        RecordType customerCare = [
            SELECT Id, Name
            FROM RecordType
            WHERE SobjectType = 'Case' AND DeveloperName = 'Customer_Care'
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
    @IsTest
    public static void testNoMatchCaseCreation() {

        Lead switchLead = [
            SELECT Id,Name,Parent_Account__c
            FROM Lead
            LIMIT 1
        ];

        System.assertEquals(0, new CaseSelector().selectOpenNoMatchCasesFromLead(switchLead).size(), 'There should be no open cases for ' +
            'this lead before enqueuing');
        Test.startTest();
        CaseFactory testFactory= new CaseFactory();
        CaseFactory testFactory2= new CaseFactory();
        testFactory.setLead(switchLead);
        testFactory2.setLead(switchLead);
        System.enqueueJob(testFactory);
        System.enqueueJob(testFactory2);
        Test.stopTest();
        System.assertEquals(1, new CaseSelector().selectOpenNoMatchCasesFromLead(switchLead).size(), 'If a case already ' +
            'exists another should not be created. There should only be 1 open case at a time.');
    }

}