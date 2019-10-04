/**
 * Created by PeterYao on 4/30/2019.
 */
@IsTest
public with sharing class ZuoraAccountServiceTest {
    @TestSetup
    public static void setupTestData() {
        CSAPControllerTest.setupTestData();
    }

    @IsTest
    static void testZuoraAccountCreationOnConvert() {
        User apiUser = [
            SELECT Id, Name, Username
            FROM User
            WHERE Name = 'API'
            AND IsActive = TRUE
            LIMIT 1
        ];

        Product2 smartProduct = [
            SELECT Id
            FROM Product2
            WHERE IsActive = TRUE
            AND Program__c = 'SMART - Community Solar'
            LIMIT 1
        ];

        Lead residentialLead = CSAPControllerTest.getLeadForTest();

        residentialLead.Status = 'Qualified';
        residentialLead.OwnerId = apiUser.Id;
        residentialLead.Product__c = smartProduct.Id;
        residentialLead.Zuora_Payment_Ref_Id__c = '12345678901234567890123456789012';
        insert residentialLead;

        CSAPControllerTest.pullCreditForLead(residentialLead.Id);

        residentialLead = [
            SELECT Id, CSAP_Stage__c, FirstName, LastName, Email, Phone, LASERCA__Birthdate__c, Street, City, State, PostalCode,
                Application_Type__c, LASERCA__Home_Address__c, LASERCA__Home_City__c, LASERCA__Home_State__c, LASERCA__Home_Zip__c, LASERCA__SSN__c,
                Company, Type_of_Business__c, Business_Title__c, Number_of_Years_in_Business__c, Number_of_Years_at_Location__c,
                Credit_Check_Acknowledged__c, Privacy_Policy_Acknowledged__c, Utility_Bill_Access_Acknowledged__c,
                Previous_BW_Applicant__c, Estimated_Install_Date__c, System_Size_kW_DC__c, Product_line__c,
                LASERCA__Pull_Credit_Report__c, Parent_Account__c, Parcel_Zip__c, Electricity_Provider__c,
                Parent_Account__r.Owner.Name, Parent_Account__r.Owner.Id, Utility_relationship__c, Personal_Credit_Report__c,
                Status, Product__c, Product__r.Program__c, Partner_Lookup__c, bs_Sales_ID__c, Date_of_Application__c
            FROM Lead
            WHERE Email = 'testymctesterson@tester.com'
            LIMIT 1
        ];
        Utility_Account_Log__c ual = new Utility_Account_Log__c(
            Lead__c = residentialLead.Id,
            Annual_Cost_of_Electricity__c = 10000,
            Name_on_Account__c = 'Tester Testcase'
        );
        insert ual;

        List<Opportunity> opps = [SELECT Id, Name FROM Opportunity];
        // There shouldn't be any opportunities yet, because nothing has been converted
        System.assertEquals(0, opps.size());

        Test.startTest();
        CSAPController.convertCSLead(residentialLead.Id, residentialLead.Email);
        Test.stopTest();

        residentialLead = [
            SELECT Id, Email, IsConverted, ConvertedAccountId
            FROM Lead
            WHERE Email = 'testymctesterson@tester.com'
            AND Application_Type__c = 'Residential'
        ];
        List<Account> propertyAccounts = AccountsSelector.selectWithSendBillsContact(new Set<Id>{residentialLead.ConvertedAccountId});
        // The lead in the testSetup is residential, and should be converted
        System.assertEquals(true, residentialLead.IsConverted);
        opps = [SELECT Id, OwnerId, Name FROM Opportunity];
        System.assertEquals(1, opps.size());
        // The account and contact should now have a zuora Id
        System.assertEquals(1, propertyAccounts.size());
        System.assertEquals(ZuoraAPIMock.genericId, propertyAccounts[0].Zuora_Id__c);
        // There should be a Zuora Contact record under the Salesforce Contact
        List<Zuora_Contact__c> zuoraContacts = [
            SELECT Id, Zuora_Id__c
            FROM Zuora_Contact__c
            WHERE Contact__c = :propertyAccounts[0].Send_Bills_Contact__c
        ];
        System.assertEquals(1, zuoraContacts.size());
        System.assertEquals(ZuoraAPIMock.genericId, zuoraContacts[0].Zuora_Id__c);
    }

    @IsTest
    static void testZuoraAccountCreationIssue() {
        User apiUser = [
            SELECT Id, Name, Username
            FROM User
            WHERE Name = 'API'
            AND IsActive = TRUE
            LIMIT 1
        ];

        Product2 smartProduct = [
            SELECT Id
            FROM Product2
            WHERE IsActive = TRUE
            AND Program__c = 'SMART - Community Solar'
            LIMIT 1
        ];

        Lead residentialLead = CSAPControllerTest.getLeadForTest();

        residentialLead.Status = 'Qualified';
        residentialLead.OwnerId = apiUser.Id;
        residentialLead.Product__c = smartProduct.Id;
        residentialLead.Zuora_Payment_Ref_Id__c = '12345678901234567890123456789012';
        insert residentialLead;

        CSAPControllerTest.pullCreditForLead(residentialLead.Id);

        residentialLead = [
            SELECT Id, CSAP_Stage__c, FirstName, LastName, Email, Phone, LASERCA__Birthdate__c, Street, City, State, PostalCode,
                Application_Type__c, LASERCA__Home_Address__c, LASERCA__Home_City__c, LASERCA__Home_State__c, LASERCA__Home_Zip__c, LASERCA__SSN__c,
                Company, Type_of_Business__c, Business_Title__c, Number_of_Years_in_Business__c, Number_of_Years_at_Location__c,
                Credit_Check_Acknowledged__c, Privacy_Policy_Acknowledged__c, Utility_Bill_Access_Acknowledged__c,
                Previous_BW_Applicant__c, Estimated_Install_Date__c, System_Size_kW_DC__c, Product_line__c,
                LASERCA__Pull_Credit_Report__c, Parent_Account__c, Parcel_Zip__c, Electricity_Provider__c,
                Parent_Account__r.Owner.Name, Parent_Account__r.Owner.Id, Utility_relationship__c, Personal_Credit_Report__c,
                Status, Product__c, Product__r.Program__c, Partner_Lookup__c, bs_Sales_ID__c, Date_of_Application__c
            FROM Lead
            WHERE Email = 'testymctesterson@tester.com'
            LIMIT 1
        ];
        Utility_Account_Log__c ual = new Utility_Account_Log__c(
            Lead__c = residentialLead.Id,
            Annual_Cost_of_Electricity__c = 10000,
            Name_on_Account__c = 'Tester Testcase'
        );
        insert ual;

        List<Opportunity> opps = [SELECT Id, Name FROM Opportunity];
        // There shouldn't be any opportunities yet, because nothing has been converted
        System.assertEquals(0, opps.size());

        Test.startTest();
        CSAPController.convertCSLead(residentialLead.Id, residentialLead.Email);
        residentialLead = [
            SELECT Id, Email, IsConverted, ConvertedAccountId
            FROM Lead
            WHERE Email = 'testymctesterson@tester.com'
            AND Application_Type__c = 'Residential'
        ];
        // This should cause the queueable job to fail with a SOQL issue when it's run
        delete residentialLead;
        Test.stopTest();

        opps = [SELECT Id, OwnerId, Name, Account.Zuora_Id__c FROM Opportunity];
        System.assertEquals(1, opps.size());
        // The account and contact should now have a zuora Id
        System.assertEquals(null, opps[0].Account.Zuora_Id__c);
        List<Error_Log__c> errorLogs = [
            SELECT Id, Class__c, Message__c
            FROM Error_Log__c
        ];
        System.assertEquals(1, errorLogs.size());
        // Because we deleted the lead:
        System.assert(errorLogs[0].Message__c.contains('Found no property accounts to create for these lead Ids:'));
    }

    @IsTest
    static void testZuoraAccountCreationWithoutRefId() {
        User apiUser = [
            SELECT Id, Name, Username
            FROM User
            WHERE Name = 'API'
            AND IsActive = TRUE
            LIMIT 1
        ];

        Product2 smartProduct = [
            SELECT Id
            FROM Product2
            WHERE IsActive = TRUE
            AND Program__c = 'SMART - Community Solar'
            LIMIT 1
        ];

        Lead residentialLead = CSAPControllerTest.getLeadForTest();

        residentialLead.Status = 'Qualified';
        residentialLead.OwnerId = apiUser.Id;
        residentialLead.Product__c = smartProduct.Id;
        residentialLead.Zuora_Payment_Ref_Id__c = '12345678901234567890123456789012';
        residentialLead.Zuora_Payment_Ref_Id_Expiration_Date__c = Datetime.now()-1; // Ref Id expired yesterday
        insert residentialLead;

        CSAPControllerTest.pullCreditForLead(residentialLead.Id);

        residentialLead = [
            SELECT Id, CSAP_Stage__c, FirstName, LastName, Email, Phone, LASERCA__Birthdate__c, Street, City, State, PostalCode,
                Application_Type__c, LASERCA__Home_Address__c, LASERCA__Home_City__c, LASERCA__Home_State__c, LASERCA__Home_Zip__c, LASERCA__SSN__c,
                Company, Type_of_Business__c, Business_Title__c, Number_of_Years_in_Business__c, Number_of_Years_at_Location__c,
                Credit_Check_Acknowledged__c, Privacy_Policy_Acknowledged__c, Utility_Bill_Access_Acknowledged__c,
                Previous_BW_Applicant__c, Estimated_Install_Date__c, System_Size_kW_DC__c, Product_line__c,
                LASERCA__Pull_Credit_Report__c, Parent_Account__c, Parcel_Zip__c, Electricity_Provider__c,
                Parent_Account__r.Owner.Name, Parent_Account__r.Owner.Id, Utility_relationship__c, Personal_Credit_Report__c,
                Status, Product__c, Product__r.Program__c, Partner_Lookup__c, bs_Sales_ID__c, Date_of_Application__c
            FROM Lead
            WHERE Email = 'testymctesterson@tester.com'
            LIMIT 1
        ];
        Utility_Account_Log__c ual = new Utility_Account_Log__c(
            Lead__c = residentialLead.Id,
            Annual_Cost_of_Electricity__c = 10000,
            Name_on_Account__c = 'Tester Testcase'
        );
        insert ual;

        List<Opportunity> opps = [SELECT Id, Name FROM Opportunity];
        // There shouldn't be any opportunities yet, because nothing has been converted
        System.assertEquals(0, opps.size());

        Test.startTest();
        CSAPController.convertCSLead(residentialLead.Id, residentialLead.Email);
        Test.stopTest();

        residentialLead = [
            SELECT Id, Email, IsConverted, ConvertedAccountId
            FROM Lead
            WHERE Email = 'testymctesterson@tester.com'
            AND Application_Type__c = 'Residential'
        ];
        List<Account> propertyAccounts = AccountsSelector.selectWithSendBillsContact(new Set<Id>{residentialLead.ConvertedAccountId});
        // The lead in the testSetup is residential, and should be converted
        System.assertEquals(true, residentialLead.IsConverted);
        opps = [SELECT Id, OwnerId, Name FROM Opportunity];
        System.assertEquals(1, opps.size());
        // The account and contact should now have a zuora Id
        System.assertEquals(1, propertyAccounts.size());
        System.assertEquals(ZuoraAPIMock.genericId, propertyAccounts[0].Zuora_Id__c);
        // There should be a Zuora Contact record under the Salesforce Contact
        List<Zuora_Contact__c> zuoraContacts = [
            SELECT Id, Zuora_Id__c
            FROM Zuora_Contact__c
            WHERE Contact__c = :propertyAccounts[0].Send_Bills_Contact__c
        ];
        System.assertEquals(1, zuoraContacts.size());
        System.assertEquals(ZuoraAPIMock.genericId, zuoraContacts[0].Zuora_Id__c);
        List<Error_Log__c> errorLogs = [
            SELECT Id, Class__c, Message__c
            FROM Error_Log__c
        ];
        System.assert(errorLogs.size() > 1, 'Should be at least one error log');
        String message = '';
        for (Error_Log__c errorLog : errorLogs) {
            message += errorLog.Message__c;
        }
        // Because we didn't include the refId, one of the error logs should report the error
        System.assert(message.contains('Found an expired payment method '));
    }

    @IsTest
    static void testZuoraAccountCreationWithException() {
        User apiUser = [
            SELECT Id, Name, Username
            FROM User
            WHERE Name = 'API'
            AND IsActive = TRUE
            LIMIT 1
        ];

        Product2 smartProduct = [
            SELECT Id
            FROM Product2
            WHERE IsActive = TRUE
            AND Program__c = 'SMART - Community Solar'
            LIMIT 1
        ];

        Lead residentialLead = CSAPControllerTest.getLeadForTest();
        residentialLead.Company = 'ThrowException';
        residentialLead.Status = 'Qualified';
        residentialLead.OwnerId = apiUser.Id;
        residentialLead.Product__c = smartProduct.Id;
        residentialLead.Zuora_Payment_Ref_Id__c = '12345678901234567890123456789012';
        residentialLead.Zuora_Payment_Ref_Id_Expiration_Date__c = Datetime.now()+1; // Ref Id good until tomorrow
        insert residentialLead;

        CSAPControllerTest.pullCreditForLead(residentialLead.Id);

        residentialLead = [
            SELECT Id, CSAP_Stage__c, FirstName, LastName, Email, Phone, LASERCA__Birthdate__c, Street, City, State, PostalCode,
                Application_Type__c, LASERCA__Home_Address__c, LASERCA__Home_City__c, LASERCA__Home_State__c, LASERCA__Home_Zip__c, LASERCA__SSN__c,
                Company, Type_of_Business__c, Business_Title__c, Number_of_Years_in_Business__c, Number_of_Years_at_Location__c,
                Credit_Check_Acknowledged__c, Privacy_Policy_Acknowledged__c, Utility_Bill_Access_Acknowledged__c,
                Previous_BW_Applicant__c, Estimated_Install_Date__c, System_Size_kW_DC__c, Product_line__c,
                LASERCA__Pull_Credit_Report__c, Parent_Account__c, Parcel_Zip__c, Electricity_Provider__c,
                Parent_Account__r.Owner.Name, Parent_Account__r.Owner.Id, Utility_relationship__c, Personal_Credit_Report__c,
                Status, Product__c, Product__r.Program__c, Partner_Lookup__c, bs_Sales_ID__c, Date_of_Application__c
            FROM Lead
            WHERE Email = 'testymctesterson@tester.com'
            LIMIT 1
        ];
        Utility_Account_Log__c ual = new Utility_Account_Log__c(
            Lead__c = residentialLead.Id,
            Annual_Cost_of_Electricity__c = 10000,
            Name_on_Account__c = 'Tester Testcase'
        );
        insert ual;

        List<Opportunity> opps = [SELECT Id, Name FROM Opportunity];
        // There shouldn't be any opportunities yet, because nothing has been converted
        System.assertEquals(0, opps.size());

        Test.startTest();
        CSAPController.convertCSLead(residentialLead.Id, residentialLead.Email);
        Test.stopTest();

        residentialLead = [
            SELECT Id, Email, IsConverted, ConvertedAccountId
            FROM Lead
            WHERE Email = 'testymctesterson@tester.com'
            AND Application_Type__c = 'Residential'
        ];
        List<Account> propertyAccounts = AccountsSelector.selectWithSendBillsContact(new Set<Id>{residentialLead.ConvertedAccountId});
        // The lead in the testSetup is residential, and should be converted
        System.assertEquals(true, residentialLead.IsConverted);
        opps = [SELECT Id, OwnerId, Name FROM Opportunity];
        System.assertEquals(1, opps.size());
        // But since the callout failed, the property account shouldn't have a zuora id:
        System.assertEquals(1, propertyAccounts.size());
        System.assertEquals(null, propertyAccounts[0].Zuora_Id__c);
        // And we should have logged an error
        List<Error_Log__c> errorLogs = [
            SELECT Message__c
            FROM Error_Log__c
            WHERE Severity__c = :Logger.ERROR
        ];
        System.assertEquals(1, errorLogs.size());
        System.assert(errorLogs[0].Message__c.contains('Zuora account async CREATE operation failed for lead'));
    }

    @IsTest
    public static void testContactEmailNotObfuscated() {
        String actualEmail = 'pyao@bluewavesolar.com';
        Contact contact = new Contact(
            FirstName = 'Test',
            LastName = 'Test',
            Email = actualEmail
        );
        insert contact;

        Account propertyAccount = new Account(
            Name = 'Property',
            Send_Bills_Contact__c = contact.Id,
            Zuora_Id__c = '12345'
        );
        insert propertyAccount;

        Map<Id, String> accountIdToZuoraIdMap = new Map<Id, String>();
        accountIdToZuoraIdMap.put(propertyAccount.Id, propertyAccount.Zuora_Id__c);

        List<System_Properties__c> systemProperties = System_Properties__c.getAll().values();
        systemProperties[0].Use_Actual_Email_For_Zuora_Upload__c = true;
        update systemProperties[0];
        System.assertEquals(true, Util.getSystemPropertyCheckbox('Use_Actual_Email_For_Zuora_Upload__c'));

        List<Account> propertyAccounts = AccountsSelector.selectWithSendBillsContact(new Set<Id>{
            propertyAccount.Id
        });
        ZuoraAccountService.createContact(propertyAccounts, accountIdToZuoraIdMap);
        // There should be one list of logs for ZuoraAPIHelper, Fine
        System.assertEquals(1, Logger.logs.values().size());
        // There should be one log in that list of logs
        System.assertEquals(1, Logger.logs.values()[0].size());
        // It should have pyao@bluewavesolar.com in it
        System.assert(Logger.logs.values()[0][0].message.contains(actualEmail));
    }

    @IsTest
    public static void testContactEmailObfuscation() {
        String actualEmail = 'pyao@bluewavesolar.com';
        Contact contact = new Contact(
            FirstName = 'Test',
            LastName = 'Test',
            Email = actualEmail
        );
        insert contact;

        Account propertyAccount = new Account(
            Name = 'Property',
            Send_Bills_Contact__c = contact.Id,
            Zuora_Id__c = '12345'
        );
        insert propertyAccount;

        Map<Id, String> accountIdToZuoraIdMap = new Map<Id, String>();
        accountIdToZuoraIdMap.put(propertyAccount.Id, propertyAccount.Zuora_Id__c);

        System.assertEquals(false, Util.getSystemPropertyCheckbox('Use_Actual_Email_For_Zuora_Upload__c'));

        List<Account> propertyAccounts = AccountsSelector.selectWithSendBillsContact(new Set<Id>{
            propertyAccount.Id
        });
        ZuoraAccountService.createContact(propertyAccounts, accountIdToZuoraIdMap);
        // There should be one list of logs for ZuoraAPIHelper, Fine
        System.assertEquals(1, Logger.logs.values().size());
        // There should be one log in that list of logs
        System.assertEquals(1, Logger.logs.values()[0].size());
        // It should have pyao@bluewavesolar.com.disabled in it
        System.assert(Logger.logs.values()[0][0].message.contains(actualEmail + '.disabled'));
        Logger.logs = null;

        List<System_Properties__c> systemProperties = System_Properties__c.getAll().values();
        systemProperties[0].Zuora_Contact_Substitution_Email__c = 'sfdc-compliance@bluewavesolar.com';
        update systemProperties[0];

        ZuoraAccountService.createContact(propertyAccounts, accountIdToZuoraIdMap);
        // There should be one list of logs for ZuoraAPIHelper, Fine
        System.assertEquals(1, Logger.logs.values().size());
        // There should be one log in that list of logs
        System.assertEquals(1, Logger.logs.values()[0].size());
        // It should have pyao@bluewavesolar.com.disabled in it
        System.assert(Logger.logs.values()[0][0].message.contains(systemProperties[0].Zuora_Contact_Substitution_Email__c));
    }

    @IsTest
    public static void testNoSendBillsContact() {
        Account propertyAccount = new Account(
            Name = 'Property',
            Zuora_Id__c = '12345'
        );
        insert propertyAccount;

        Map<Id, String> accountIdToZuoraIdMap = new Map<Id, String>();
        accountIdToZuoraIdMap.put(propertyAccount.Id, propertyAccount.Zuora_Id__c);

        List<Account> propertyAccounts = AccountsSelector.selectWithSendBillsContact(new Set<Id>{
            propertyAccount.Id
        });
        ZuoraAccountService.createContact(propertyAccounts, accountIdToZuoraIdMap);
        System.assertEquals(1, Logger.logs.values().size(),
            'There should be one list of logs for ZuoraAPIHelper, Fine');
        System.assertEquals(1, Logger.logs.values()[0].size(),
            'There should be one log in the list of logs for ZuoraAPIHelper, Fine');
        System.assert(Logger.logs.values()[0][0].message.contains('"Success":true'),
            'Expected contact creation to be successful, even if there is no send bills contact');
        System.assert(Logger.logs.values()[0][0].message.contains('"LastName":"Billing Contact","FirstName":"Default"'),
            'Expected to create a Default Billing Contact if no send bills contact');
    }
}