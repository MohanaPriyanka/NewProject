/*************************************************************************************
 * Created By: peteryao on 6/9/18  
 * Description: Tests TaskHandler and taskreminderhandler
 *************************************************************************************/
@IsTest
public with sharing class TaskHandlerTest {
    @testSetup public static void setupTestData() {
        User newuser = new user (ProfileId = [SELECT Id FROM Profile WHERE Name = 'BFG Standard User'].Id,
            FirstName = 'first',
            LastName = 'last',
            Email = 'namethatsnotused@bluewave-capital.com',
            Username = 'namethatsnotused@bluewave-capital.com' + System.currentTimeMillis(),
            CompanyName = 'TEST',
            Title = 'title',
            Alias = 'alias',
            TimeZoneSidKey = 'America/Los_Angeles',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            IsActive = true);

        insert newuser;

        List<Lead> leads = new List<Lead>();
        Lead unconverted = new Lead(
            FirstName = 'First',
            LastName = 'Unconverted',
            Company = 'Test',
            Product_line__c = 'Residential Loan',
            DOER_Solar_Loan__c = true
        );
        leads.add(unconverted);
        Lead converted = new Lead(
            FirstName = 'First',
            LastName = 'Converted',
            Company = 'Test',
            Email = 'test@test.com',
            Product_line__c = 'Residential Loan',
            DOER_Solar_Loan__c = true
        );
        leads.add(converted);
        insert leads;
        CAPController.convertLead(converted.Id, converted.Email);
    }

    @IsTest
    static void testTaskInsert() {
        User user = [
            SELECT Id, Email, IsActive, FirstName
            FROM User
            WHERE LastName = 'last'
            LIMIT 1
        ];

        Task newtask = new Task(
            Subject = 'This is the subject',
            OwnerId = user.Id
        );

        insert newtask;
        update newtask;

        taskreminderhandler.taskreminder(newtask.Id);
    }

    @IsTest
    static void testTaskMove() {
        Lead converted = [SELECT Id, ConvertedContactId, (SELECT Id FROM Tasks) FROM Lead WHERE LastName = 'Converted'];
        System.assertEquals(0, converted.Tasks.size());
        Contact convertedContact = [SELECT Id, (SELECT Id, Subject FROM Tasks) FROM Contact WHERE Id =: converted.ConvertedContactId];
        // EMAIL LOG: RL - Installer - Notification Lead has been Created
        System.assertEquals(1, convertedContact.Tasks.size());

        Lead unconverted = [SELECT Id, (SELECT Id FROM Tasks) FROM Lead WHERE LastName = 'Unconverted'];
        System.assertEquals(1, unconverted.Tasks.size());

        converted.Manual_Credit_Decline__c = true;
        unconverted.Manual_Credit_Decline__c = true;
        update new List<Lead>{converted, unconverted};

        converted = [SELECT Id, ConvertedContactId, (SELECT Id FROM Tasks) FROM Lead WHERE LastName = 'Converted'];
        System.assertEquals(0, converted.Tasks.size());
        convertedContact = [SELECT Id, (SELECT Id, Subject FROM Tasks) FROM Contact WHERE Id =: converted.ConvertedContactId];
        // EMAIL LOG: RL - Installer - Notification Lead has been Created
        // EMAIL LOG: Lead - DOER - Credit Denial Email
        // EMAIL LOG: Lead - DOER - CoApplicant Form Linik
        // EMAIL LOG: RL - Installer - Notification - Lead Unqualified
        System.assertEquals(4, convertedContact.Tasks.size());

        unconverted = [SELECT Id, (SELECT Id FROM Tasks) FROM Lead WHERE LastName = 'Unconverted'];
        System.assertEquals(4, unconverted.Tasks.size());
    }
}