/**
 * Created by PeterYao on 4/30/2019.
 */
@IsTest
public with sharing class ZuoraAccountServiceTest {
    public static void useMocks() {
        ZuoraAccountService.accountSelector = (AccountsSelector) Test.createStub(AccountsSelector.class, new MockAccountsSelector());
    }
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
    static void testZuoraAccountCreationSwitchLead() {

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
        residentialLead.LeadSource = 'Switch';
        residentialLead.OwnerId = apiUser.Id;
        residentialLead.Product__c = smartProduct.Id;
        insert residentialLead;

        CSAPControllerTest.pullCreditForLead(residentialLead.Id);

        residentialLead = [
            SELECT Id, CSAP_Stage__c, FirstName, LastName, Email, Phone, LASERCA__Birthdate__c, Street, City, State, PostalCode,
                Application_Type__c, LASERCA__Home_Address__c, LASERCA__Home_City__c, LASERCA__Home_State__c, LASERCA__Home_Zip__c, LASERCA__SSN__c,
                Company, Type_of_Business__c, Business_Title__c, Number_of_Years_in_Business__c, Number_of_Years_at_Location__c,
                Credit_Check_Acknowledged__c, Privacy_Policy_Acknowledged__c, Utility_Bill_Access_Acknowledged__c,
                Previous_BW_Applicant__c, Estimated_Install_Date__c, System_Size_kW_DC__c, Product_line__c,
                LASERCA__Pull_Credit_Report__c, Parent_Account__c, Parcel_Zip__c, Electricity_Provider__c,
                Parent_Account__r.Owner.Name, Parent_Account__r.Owner.Id, Utility_relationship__c, Utility_relationship__r.Id, Personal_Credit_Report__c,
                Status, Product__c, Product__r.Program__c, Partner_Lookup__c, bs_Sales_ID__c, Date_of_Application__c
            FROM Lead
            WHERE Email = 'testymctesterson@tester.com'
            LIMIT 1
        ];

        LeadService leadService = new LeadService();
        Account propertyAccount = leadService.buildPropertyAccountFromLegacyLead(residentialLead);
        propertyAccount.Zuora_Payment_Ref_Id__c = '12345678901234567890123456789012';
        insert propertyAccount;

        Utility_Account_Log__c ual = leadService.buildUtilityAccountLogFromLegacyLead(residentialLead, propertyAccount);
        insert ual;

        Test.startTest();
        //TODO: Why doesnt it work with the Async Service?
        ZuoraAccountService.createAccounts(new List<Account> {propertyAccount});
//        System.enqueueJob(new ZuoraAccountAsyncService(new List<Account>{propertyAccount}));

        Test.stopTest();

        residentialLead = [
            SELECT Id, Email, IsConverted, ConvertedAccountId
            FROM Lead
            WHERE Email = 'testymctesterson@tester.com'
            AND Application_Type__c = 'Residential'
        ];

        propertyAccount = [
            SELECT Id, Zuora_Payment_Ref_Id__c, Zuora_Id__c
            FROM Account
            WHERE Lead__c = :residentialLead.Id
        ];

        List<Account> propertyAccounts = AccountsSelector.selectWithSendBillsContact(new Set<Id>{propertyAccount.Id});

        // The account and contact should now have a zuora Id
        System.assertEquals(1, propertyAccounts.size());
        System.assertEquals(ZuoraAPIMock.genericId, propertyAccounts[0].Zuora_Id__c);
        // There should be a Zuora Contact record under the Salesforce Contact
        List<Zuora_Contact__c> zuoraContacts = [
            SELECT Id, Zuora_Id__c, Contact__c
            FROM Zuora_Contact__c
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
            Zuora_Id__c = '12345',
            BillingCity = 'Boston',
            BillingState = 'Massachusetts',
            BillingCountry = 'United States'
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
        System.assert(Logger.logs.values()[0][0].message.contains('"City":"Boston"') &&
            Logger.logs.values()[0][0].message.contains('"State":"Massachusetts"') &&
            Logger.logs.values()[0][0].message.contains('"Country":"United States"'),
            'Expected to set the address for the default contact');
    }

    @IsTest
    private static void testHandleAccountUpdates() {
        Account account = [SELECT Id, Name, Address_Attn__c FROM Account LIMIT 1];
        account.Zuora_Id__c = '123455';
        account.Name = account.Name + ' Changed';
        account.Address_Attn__c = account.Address_Attn__c + ' Changed';
        Test.startTest();
        update account;
        Test.stopTest();

        Boolean foundContactCreate = false;
        Boolean foundBillToUpdate = false;
        Boolean foundNameUpdate = false;
        for (ZuoraAPIHelper.EndpointCall endpointCall : ZuoraAPIHelper.endpointsCalled) {
            if (endpointCall.endpoint == '/v1/action/create' && endpointCall.jsonBody.contains('\"type\":\"Contact\"')) {
                foundContactCreate = true;
            } else if (endpointCall.endpoint == '/v1/action/update' && endpointCall.jsonBody.contains('\"type\":\"Account\"')) {
                if (endpointCall.jsonBody.contains('BillTo')) {
                    foundBillToUpdate = true;
                } else if (endpointCall.jsonBody.contains('Name')) {
                    foundNameUpdate = true;
                }
            }
        }
        System.assert(foundBillToUpdate, 'Did not find the account updated with the Bill To');
        System.assert(foundNameUpdate, 'Did not find the account update for the Name');
        System.assert(foundContactCreate, 'Did not find a contact create');
    }

    @IsTest
    private static void testHandleAccountNameUpdatesFuture() {
        useMocks();
        Test.startTest();
        ZuoraAccountService.handleAccountNameUpdates(new Set<Id>{'001S000000yKIYqIAO'});
        Test.stopTest();
        System.assertEquals(1, ZuoraAPIHelper.endpointsCalled.size());
        System.assert(ZuoraAPIHelper.endpointsCalled[0].jsonBody.contains('\"type\":\"Account\"'));
        System.assertEquals('/v1/action/update', ZuoraAPIHelper.endpointsCalled[0].endpoint);
    }

    @IsTest
    private static void testHandleAccountAddressUpdatesFuture() {
        useMocks();
        Test.startTest();
        ZuoraAccountService.handleAccountAddressUpdatesFuture(new Set<Id>{'001S000000yKIYqIAO'});
        Test.stopTest();
        System.assertEquals(2, ZuoraAPIHelper.endpointsCalled.size());
        System.assertEquals('/v1/action/create', ZuoraAPIHelper.endpointsCalled[0].endpoint);
        System.assert(ZuoraAPIHelper.endpointsCalled[0].jsonBody.contains('\"type\":\"Contact\"'),
            'First endpoint should create a contact');
        System.assertEquals('/v1/action/update', ZuoraAPIHelper.endpointsCalled[1].endpoint);
        System.assert(ZuoraAPIHelper.endpointsCalled[1].jsonBody.contains('\"type\":\"Account\"'),
            'Second endpoint should update the account with the contact as Bill To');
    }

    @IsTest
    private static void testAccountsWithZuoraUpdates() {
        String json = '{"attributes":{"type":"Account","url":"/services/data/v47.0/sobjects/Account/001S000000yKIYqIAO"},' +
            '"Id":"001S000000yKIYqIAO",' +
            '"Name":"Keith Morgan",' +
            '"BillingStreet":"8888 Main Street",' +
            '"BillingCity":"Boston",' +
            '"BillingState":"Massachusetts",' +
            '"BillingStateCode":"MA",' +
            '"BillingPostalCode":"12312",' +
            '"BillingCountry":"United States",' +
            '"Send_Bills_Contact__c":"003S0000016Y23tIAC"}';
        Account oldAccount = (Account) System.JSON.deserialize(json, Account.class);
        Account newAccount = oldAccount.clone(true);
        newAccount.Name = oldAccount.Name + ' Changed';
        Map<Id, Account> oldAccounts = new Map<Id, Account>();
        Map<Id, Account> newAccounts = new Map<Id, Account>();
        oldAccounts.put(oldAccount.Id, oldAccount);
        newAccounts.put(newAccount.Id, newAccount);
        System.assertEquals(false, new ZuoraAccountService().accountsWithZuoraUpdates(oldAccounts, newAccounts).hasChanges(),
            'No changes expected because accounts have no zuora id'
        );
        oldAccount.Zuora_Id__c = '123455';
        newAccount.Zuora_Id__c = '123455';
        System.assertEquals(true, new ZuoraAccountService().accountsWithZuoraUpdates(oldAccounts, newAccounts).hasChanges());


    }

    @IsTest
    private static void testAccountNeedsAddressUpdate() {
        String json = '{"attributes":{"type":"Account","url":"/services/data/v47.0/sobjects/Account/001S000000yKIYqIAO"},' +
            '"Id":"001S000000yKIYqIAO",' +
            '"Name":"Keith Morgan",' +
            '"BillingStreet":"8888 Main Street",' +
            '"BillingCity":"Boston",' +
            '"BillingState":"Massachusetts",' +
            '"BillingStateCode":"MA",' +
            '"BillingPostalCode":"12312",' +
            '"BillingCountry":"United States",' +
            '"Send_Bills_Contact__c":"003S0000016Y23tIAC"}';
        Account oldAccount = (Account) System.JSON.deserialize(json, Account.class);
        Account newAccount = oldAccount.clone(true);
        newAccount.BillingCity = 'Somerville';
        System.assertEquals(false, new ZuoraAccountService().accountNeedsAddressUpdate(oldAccount, newAccount),
            'Expected no change necessary because there is no Zuora Id'
        );
        newAccount.Zuora_Id__c = '123456';
        System.assertEquals(true, new ZuoraAccountService().accountNeedsAddressUpdate(oldAccount, newAccount),
            'Expected to need to update Zuora'
        );
        newAccount.BillingCity = oldAccount.BillingCity;
        System.assertNotEquals(null, newAccount.Zuora_Id__c, 'Zuora Id is still set');
        System.assertEquals(false, new ZuoraAccountService().accountNeedsAddressUpdate(oldAccount, newAccount),
            'Expected no change necessary because addresses are the same'
        );
        newAccount.Name = oldAccount.Name + ' Changed';
        System.assertEquals(false, new ZuoraAccountService().accountNeedsAddressUpdate(oldAccount, newAccount),
            'Expected no change necessary because there is no address change'
        );
    }


    /*************
      *** MOCKS ***
      *************/
    public class MockAccountsSelector extends MockProvider {
        public MockAccountsSelector() {
        }

        public override Object handleMethodCall(MethodCall methodCall) {
            switch on methodCall.stubbedMethodName {
                when 'selectAll' {
                    String json = '[{"attributes":{"type":"Account","url":"/services/data/v47.0/sobjects/Account/001S000000yKIYqIAO"},' +
                        '"Id":"001S000000yKIYqIAO",' +
                        '"Name":"Keith Morgan",' +
                        '"BillingStreet":"8888 Main Street",' +
                        '"BillingCity":"Boston",' +
                        '"BillingState":"Massachusetts",' +
                        '"BillingStateCode":"MA",' +
                        '"BillingPostalCode":"12312",' +
                        '"BillingCountry":"United States",' +
                        '"Send_Bills_Contact__c":"003S0000016Y23tIAC",' +
                        '"Zuora_Id__c":"2c92c0f86e5e38b0016e5fc9f13d15fb",' +
                        '"Send_Bills_Contact__r":{"attributes":{"type":"Contact","url":"/services/data/v47.0/sobjects/Contact/003S0000016Y23tIAC"},' +
                        '"Id":"003S0000016Y23tIAC",' +
                        '"Email":"bulk@bluewavesolar.com.disabledagain",' +
                        '"FirstName":"Keith",' +
                        '"LastName":"Morgan"}}]';
                    List<Account> accounts = (List<Account>) System.JSON.deserialize(json, List<Account>.class);
                    return accounts;
                }
            }
            return null;
        }
    }
}