@isTest
public with sharing class OpportunityTriggerTest {
    @testSetup static void setupData() {
        RecalculateUALCostControllerTest.setupTestData();
    }

    @isTest static void testRollup() {        
        Map<String, Opportunity> oppMap = new Map<String, Opportunity>();
       
        Utility_NMC_Tariff__c tariff = [
            SELECT Id FROM Utility_NMC_Tariff__c
            WHERE Name = 'National Grid WCMA Class 2' AND Value_of_Net_Metering_Credit__c = 1
        ];

        for(Opportunity opp : [SELECT Id, Name, 
                                Subscription_Size_for_Invoicing__c 
                                FROM Opportunity 
                                ORDER BY Name]){
            opp.NMC_Tariff__c = tariff.Id;
            opp.StageName = 'New';
            oppMap.put(opp.Name, opp);
        }
        update oppMap.values();
        List<Utility_Account_Subscription__c> uasList = [SELECT Id, Name, 
                                                        Customer_Subscription_KW_DC__c, Opportunity__r.Name, Opportunity__c 
                                                        FROM Utility_Account_Subscription__c
                                                        WHERE (Opportunity__r.Name = 'RecalcUALOpp1A'
                                                        OR Opportunity__r.Name = 'RecalcUALOpp8A')
                                                        ORDER BY Name];

        System.assertEquals(4,uasList.size());
       
        System.assertEquals(3.8462, uasList[0].Customer_Subscription_KW_DC__c);
        System.assertEquals('RecalcUALOpp1A', uasList[0].Opportunity__r.Name);

        System.assertEquals(2.3077, uasList[1].Customer_Subscription_KW_DC__c);
        System.assertEquals(6.9231, uasList[2].Customer_Subscription_KW_DC__c);
        System.assertEquals(7.6923, uasList[3].Customer_Subscription_KW_DC__c);
        System.assertEquals('RecalcUALOpp8A', uasList[1].Opportunity__r.Name);
        System.assertEquals('RecalcUALOpp8A', uasList[2].Opportunity__r.Name);
        System.assertEquals('RecalcUALOpp8A', uasList[3].Opportunity__r.Name);

        Opportunity one = oppMap.get('RecalcUALOpp1A');
        Opportunity eight = oppMap.get('RecalcUALOpp8A');
        System.assertEquals(null, one.Subscription_Size_for_Invoicing__c);
        System.assertEquals(null, eight.Subscription_Size_for_Invoicing__c);

        Test.StartTest();
        Util.enableTrigger('Disable_OpportunityTrigger__c');

        one.StageName = 'Complete';
        eight.StageName  = 'Complete';
        update new List<Opportunity> {one, eight};

        Test.StopTest();

        List<Opportunity> updatedOpp = [SELECT Id, Name, 
                                        Subscription_Size_for_Invoicing__c 
                                        FROM Opportunity 
                                        WHERE (Name = 'RecalcUALOpp1A' OR Name = 'RecalcUALOpp8A')
                                        ORDER BY Name];

        System.assertEquals(3.8462, updatedOpp[0].Subscription_Size_for_Invoicing__c);
        System.assertEquals(16.9231, updatedOpp[1].Subscription_Size_for_Invoicing__c);
    }


    @IsTest
    public static void testCSOpportunityStageUpdates() {
        Opportunity opportunityToTest = new Opportunity(
            Name = 'Test Opp',
            Product_Line__c = 'Community Solar',
            StageName = 'New',
            CloseDate = Date.today()
        );

        insert opportunityToTest;

        dsfs__DocuSign_Status__c docuSignStatus = new dsfs__DocuSign_Status__c(
            dsfs__Opportunity__c = opportunityToTest.Id
        );

        insert docuSignStatus;


        dsfs__DocuSign_Recipient_Status__c docuRecipientOne = new dsfs__DocuSign_Recipient_Status__c(
            dsfs__Parent_Status_Record__c = docuSignStatus.Id,
            dsfs__Recipient_Status__c = 'Completed',
            dsfs__DocuSign_Recipient_Id__c = 'recipient Id',
            dsfs__DocuSign_Routing_Order__c = 1,
            Opportunity__c = opportunityToTest.Id
        );
        dsfs__DocuSign_Recipient_Status__c docuRecipienttwo = new dsfs__DocuSign_Recipient_Status__c(
            dsfs__Parent_Status_Record__c = docuSignStatus.Id,
            dsfs__Recipient_Status__c = 'Sent',
            dsfs__DocuSign_Recipient_Id__c = 'recipient Id',
            dsfs__DocuSign_Routing_Order__c = 1
        );

        dsfs__DocuSign_Recipient_Status__c docuRecipientThree = new dsfs__DocuSign_Recipient_Status__c(
            dsfs__Parent_Status_Record__c = docuSignStatus.Id,
            dsfs__Recipient_Status__c = 'Sent',
            dsfs__DocuSign_Recipient_Id__c = 'recipient Id',
            dsfs__DocuSign_Routing_Order__c = 3,
            Opportunity__c = opportunityToTest.Id
        );

        insert new List<dsfs__DocuSign_Recipient_Status__c>{
            docuRecipientOne,
            docuRecipientTwo,
            docuRecipientThree
        };

        List<Opportunity> opps = [
            SELECT Id, StageName, Contract_Status__c
            FROM Opportunity
            WHERE Id = :opportunityToTest.Id
        ];

        System.assertNotEquals('Sent', opps[0].Contract_Status__c);
        System.assertNotEquals('Contract Pending', opps[0].StageName);

        docuRecipientTwo.Opportunity__c = opps[0].Id;

        Test.startTest();
        update new List<dsfs__DocuSign_Recipient_Status__c>{
            docuRecipientTwo
        };
        Test.stopTest();


        opps = [
            SELECT Id, StageName, Contract_Status__c
            FROM Opportunity
            WHERE Id = :opportunityToTest.Id
        ];

        System.assertEquals('Sent', opps[0].Contract_Status__c);
        System.assertEquals('Contract Pending', opps[0].StageName);

    }

    @IsTest
    public static void testRLOpportunityStageUpdates() {
        Opportunity opportunityToTest = new Opportunity(
            Name = 'Test Opp',
            Product_Line__c = 'Residential Loan',
            StageName = 'New',
            CloseDate = Date.today()
        );

        insert opportunityToTest;

        dsfs__DocuSign_Status__c docuSignStatus = new dsfs__DocuSign_Status__c(
            dsfs__Opportunity__c = opportunityToTest.Id
        );

        insert docuSignStatus;

        dsfs__DocuSign_Recipient_Status__c docuRecipientOne = new dsfs__DocuSign_Recipient_Status__c(
            dsfs__Parent_Status_Record__c = docuSignStatus.Id,
            dsfs__Recipient_Status__c = 'Sent',
            dsfs__DocuSign_Recipient_Id__c = 'recipient Id',
            dsfs__DocuSign_Routing_Order__c = 1
        );

        dsfs__DocuSign_Recipient_Status__c docuRecipientTwo = new dsfs__DocuSign_Recipient_Status__c(
            dsfs__Parent_Status_Record__c = docuSignStatus.Id,
            dsfs__Recipient_Status__c = 'Sent',
            dsfs__DocuSign_Recipient_Id__c = 'recipient Id',
            dsfs__DocuSign_Routing_Order__c = 2
        );

        dsfs__DocuSign_Recipient_Status__c docuRecipientThree = new dsfs__DocuSign_Recipient_Status__c(
            dsfs__Parent_Status_Record__c = docuSignStatus.Id,
            dsfs__Recipient_Status__c = 'Sent',
            dsfs__DocuSign_Recipient_Id__c = 'recipient Id',
            dsfs__DocuSign_Routing_Order__c = 3
        );

        insert new List<dsfs__DocuSign_Recipient_Status__c>{
            docuRecipientOne,
            docuRecipientTwo,
            docuRecipientThree
        };

        List<Opportunity> opps = [
            SELECT Id, StageName, Contract_Status__c
            FROM Opportunity
            WHERE Id = :opportunityToTest.Id
        ];

        System.assertNotEquals(null, opps[0].Contract_Status__c);
        System.assertNotEquals('New', opps[0].StageName);
    }
    @IsTest
    public static void testActivatePortalUser() {
        Opportunity testOpportunity = new Opportunity(
            Product_Line__c = 'Community Solar',
            BlueWave_Signature_Status__c = ''
        );
            System.assertEquals('', testOpportunity.BlueWave_Signature_Status__c);
            testOpportunity.BlueWave_Signature_Status__c = 'Completed';
            System.assertEquals('Completed', testOpportunity.BlueWave_Signature_Status__c);

        List<Contact> contactList = [
            SELECT Id, FirstName, LastName, Email, AccountId
            FROM Contact];


        if (testOpportunity.BlueWave_Signature_Status__c == 'Completed') {
            UserHandler userInsertJob = new UserHandler(contactList);
            System.enqueueJob(userInsertJob);
        }
        }
    }