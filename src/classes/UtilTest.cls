/**
 * Created by mstackhouse on 9/21/2018.
 * Description:
 */

@IsTest
public with sharing class UtilTest {
    @IsTest
    public static void testInsertSObj() {
        Profile profile = [
            SELECT Id
            FROM Profile
            WHERE Name='BFG Standard User'
        ];

        User u = new User(
            Alias = 'testUtil',
            Email='testUtil@test.test',
            EmailEncodingKey='UTF-8',
            LastName='testUtil',
            LanguageLocaleKey='en_US',
            LocaleSidKey='en_US',
            ProfileId = profile.Id,
            Country='United States',
            IsActive = true,
            TimeZoneSidKey='America/New_York',
            Username='testUtil@test.test');
        Util.insertSObj(u);

        User newUser = [
            SELECT Id, Alias, Email
            FROM User
            WHERE LastName = 'testUtil'
        ];

        System.assertNotEquals(null, newUser);
    }

    @IsTest
    public static void testDatabaseOperation() {
        List<Error_Log__c> errorLogs = [SELECT Id FROM Error_Log__c];
        // Shouldn't be any error logs yet
        System.assertEquals(0, errorLogs.size());
        Account foo = new Account(Name = 'foo');
        Account bar = new Account();
        // Datbase insert shouldn't be successful
        System.assertEquals(false, Util.insertAndLog(new List<Account>{foo, bar}, 'UtilTest', 'testDatabaseOperation'));
        // Shouldn't error, and should have a log
        errorLogs = [SELECT Id, Message__c FROM Error_Log__c];
        System.assertEquals(1, errorLogs.size());

        foo.Name = 'baz';
        System.assertEquals(true, Util.updateAndLog(new List<Account>{foo}, 'UtilTest', 'testDatabaseOperation'));
        // Should be successful
        errorLogs = [SELECT Id, Message__c FROM Error_Log__c];
        System.assertEquals(1, errorLogs.size());
    }

    @isTest
    public static void testDatabaseUpdate(){
        Account acct = new Account(Name = 'Account');
        insert acct;

        acct.Name = 'Updated Account';
        Util.updateSObjs(new List<Account>{acct});

        Account updatedAccount = [
            SELECT Id, Name
            FROM Account
            WHERE Id = : acct.Id
        ];

        System.assertEquals('Updated Account',updatedAccount.Name);
    }

    @IsTest
    public static void testNullToZero() {
        Decimal nullToZero;
        System.assertEquals(null, nullToZero);

        nullToZero = Util.nullToZero(nullToZero);
        System.assertEquals(0, nullToZero);
    }

    @IsTest
    public static void testMinTwoDates() {
        Date older = Date.newInstance(2014,02,03);
        Date newer = Date.newInstance(2017,04,23);

        System.assertEquals(older, Util.minTwoDates(older,newer));
        System.assertEquals(older, Util.minTwoDates(newer,older));
        System.assertEquals(older, Util.minTwoDates(null,older));
        System.assertEquals(null, Util.minTwoDates(null,null));
        System.assertEquals(newer, Util.minTwoDates(newer,null));
        System.assertEquals(newer, Util.minTwoDates(newer,newer));
    }

    @IsTest
    public static void testGetActiveProducts() {
        LoanTestRecordWarehouse.partnerSetup();
        insert LoanTestRecordWarehouse.getLoanProductsVariableInterestRatesandTerms();
        Partner__c partner = [SELECT Id FROM Partner__c WHERE Name = 'Bluewave Inside Sales' LIMIT 1];
        Product2 product = [
            SELECT Id, Name, Product_Type__c, Program__c, State__c,
                Credit_Minimum__c, Credit_Maximum__c, Loan_Interest_Rate__c, Loan_Term__c
            FROM Product2
            WHERE Name = 'BlueWave Solar Loan - MA - 10 Year Term - 6.49% (Low FICO)'
            AND Require_Junctions_to_Enable__c = TRUE
            LIMIT 1
        ];
        // Let the product be seen by getActiveProducts below...
        product.Hide_in_Requested_Product__c = false;
        update product;
        Partner_Product_Junction__c ppj = new Partner_Product_Junction__c(Enabled_Product__c = product.Id,
            Partner__c = partner.Id);
        Product2 bwsl = [
            SELECT Id
            FROM Product2
            WHERE Name = 'BlueWave Solar Loan - MA - 10 Year Term - 5.99%'
            LIMIT 1
        ];
        insert ppj;

        System.assertEquals(8, Util.getActiveProducts(new List<String>{
            'MA'
        }, partner.Id, 'Residential Loan').size());
    }

    @IsTest
    public static void testGetCommunitySiteURL() {
        String siteURL = Util.getCommunitySiteURL('Apply');
        System.assert(siteURL.contains('bluewavememberportal'), 'Should contain link to BlueWave Member Portal');
        System.assert(siteURL.contains('apply'), 'Should include apply in the URL');
    }

    @IsTest
    public static void testMinAndMax() {
        List<Decimal> listOfNumbers = new List<Decimal>{12,342,1,342,-12,10000};

        System.assertEquals(-12, Util.min(listOfNumbers));
        System.assertEquals(10000, Util.max(listOfNumbers));
    }

    @IsTest
    public static void testPrintLimits() {
        Boolean errorCaught = false;
        try {
            Util.printCPULimit('Print CPU Limit');
        } catch (Exception e) {
            errorCaught = true;
        }
        System.assert(!errorCaught);

        try {
            Util.printSOQLLimit('Print SOQL Limit');
        } catch (Exception e) {
            errorCaught = true;
        }
        System.assert(!errorCaught);
    }

    @IsTest
    public static void testPrepForCSV() {
        String unprepped = 'this is$_@an \n=+ un\n}pr{e[pp]ed, str)ing(.';
        String expected = 'this is_an  unprepped string.';
        System.assertEquals(expected, Util.prepForCSV(unprepped));
    }

    @IsTest
    public static void testTriggerDisable() {
        // By default, if there's no system property, triggers are not disabled
        System.assertEquals(false, Util.isDisabled('Disable_LoanTrigger__c'));
        System_Properties__c property = new System_Properties__c(Name = 'System', Disable_LoanTrigger__c = true);
        insert property;
        // We should be able to manually disable
        System.assertEquals(true, Util.isDisabled('Disable_LoanTrigger__c'));
        // If there's a system property, trigger shouldn't be disabled by default
        System.assertEquals(false, Util.isDisabled('Disable_LeadTrigger__c'));
        Util.disableTrigger('Disable_LeadTrigger__c');
        // We should be able to disable it
        System.assertEquals(true, Util.isDisabled('Disable_LeadTrigger__c'));
        Util.enableTrigger('Disable_LeadTrigger__c');
        // And enable it
        System.assertEquals(false, Util.isDisabled('Disable_LeadTrigger__c'));
        delete property;
        // Back to no System_Property, triggers should be enabled again
        System.assertEquals(false, Util.isDisabled('Disable_LeadTrigger__c'));
        System.assertEquals(false, Util.isDisabled('Disable_LoanTrigger__c'));
        Util.disableTrigger('Disable_LeadTrigger__c');
        // And we should be able to disable it without explicitly creating a System Property
        System.assertEquals(true, Util.isDisabled('Disable_LeadTrigger__c'));
        Util.disableTrigger('Disable_LoanTrigger__c');
        System.assertEquals(true, Util.isDisabled('Disable_LoanTrigger__c'));
        // There should only be one System Property
        System.assertEquals(1, System_Properties__c.getAll().values().size());
        // All This shouldn't use any SOQL queries
        System.assertEquals(0, Limits.getQueries());
    }
    @IsTest
    public static void testAllTriggerToggle() {
        // By default, if there's no system property, triggers are not disabled
        System.assertEquals(false, Util.isDisabled('Disable_LoanTrigger__c'));
        Util.disableAllTriggers();
        System.assertEquals(true, Util.isDisabled('Disable_LoanTrigger__c'));
        System.assertEquals(true, Util.isDisabled('Disable_LeadTrigger__c'));
        Util.enableAllTriggers();
        System.assertEquals(false, Util.isDisabled('Disable_LoanTrigger__c'));
        System.assertEquals(false, Util.isDisabled('Disable_LeadTrigger__c'));
        // And test that it still works with an existing system property
        Util.disableAllTriggers();
        System.assertEquals(true, Util.isDisabled('Disable_LoanTrigger__c'));
        System.assertEquals(true, Util.isDisabled('Disable_LeadTrigger__c'));
    }

    @IsTest
    public static void testObscureText() {
        String textToObscure = 'secret1234';
        String expectedAll = '**********';
        String expectedLast1 = '*********4';
        String expectedLast2 = '********34';
        String expectedLast3 = '*******234';
        String expectedLast4 = '******1234';
        String expectedSameAsLength = 'secret1234';

        System.assertEquals(expectedAll, Util.obscureText(textToObscure, 0));
        System.assertEquals(expectedLast1, Util.obscureText(textToObscure, 1));
        System.assertEquals(expectedLast2, Util.obscureText(textToObscure, 2));
        System.assertEquals(expectedLast3, Util.obscureText(textToObscure, 3));
        System.assertEquals(expectedLast4, Util.obscureText(textToObscure, 4));
        System.assertEquals(expectedSameAsLength, Util.obscureText(textToObscure, textToObscure.length()));
        System.assertEquals(expectedSameAsLength, Util.obscureText(textToObscure, 9999));
    }

    @IsTest
    public static void testReparentAttachment() {
        Lead residentialLead = new Lead(
            LastName = 'testcase',
            Company = 'Util'
        );
        insert residentialLead;

        Attachment bill = new Attachment(
            Name = 'file.pdf',
            Body = Blob.valueOf('body'),
            ParentId = residentialLead.Id,
            Description = 'Electric Bill'
        );
        Attachment notBill = new Attachment(
            Name = 'file.pdf',
            Body = Blob.valueOf('body'),
            ParentId = residentialLead.Id,
            Description = 'Other Document'
        );

        List<Attachment> newLeadAttachments = new List<Attachment>{bill, notBill};

        insert newLeadAttachments ;

        Utility_Account_Log__c utilityAccountLog = new Utility_Account_Log__c(
            Name = 'testLeadAttachmentsMovedToUAL',
            Lead__c = residentialLead.Id
        );

        insert utilityAccountLog;

        Util.reparentAttachments(newLeadAttachments , utilityAccountLog.Id);

        List<Attachment> leadAttachments = [
            SELECT Name, Description
            FROM Attachment
            WHERE ParentId = : utilityAccountLog.Lead__c
        ];

        List<Attachment> ualAttachments = [
            SELECT Name, Description
            FROM Attachment
            WHERE ParentId = : utilityAccountLog.Id
        ];

        System.assertEquals(0, leadAttachments.size());
        System.assertEquals(2, ualAttachments.size());
    }

    @IsTest
    public static void testGetSystemPropertyString() {
        System.assertEquals('', Util.getSystemPropertyString('Zuora_Contact_Substitution_Email__c'));
        System_Properties__c property = new System_Properties__c(
            Name = 'System',
            Zuora_Contact_Substitution_Email__c = 'sfdc-compliance@bluewavesolar.com'
        );
        insert property;
        System.assertEquals('sfdc-compliance@bluewavesolar.com', Util.getSystemPropertyString('Zuora_Contact_Substitution_Email__c'));
    }

    @IsTest
    public static void testGetSystemPropertyCheckbox() {
        System.assertEquals(false, Util.getSystemPropertyCheckbox('Disable_LoanTrigger__c'));
        System_Properties__c property = new System_Properties__c(Name = 'System', Disable_LoanTrigger__c = true);
        insert property;
        System.assertEquals(true, Util.getSystemPropertyCheckbox('Disable_LoanTrigger__c'));
    }

    @IsTest
    public static void testValidateStringsWithNullValue() {
        Map<String, String> requiredFields = new Map<String, String>{'nullField'=>null, 'validString'=>'hello world' };
        try {
            Util.validateStrings(requiredFields);
            System.assert(false, 'This assert should not be called, because an exception should be thrown');
        } catch (Exception e) {
            System.assertEquals(e.getMessage(), 'Required field not provided: nullField', 'Should detect null fields');
        }
    }

    @IsTest
    public static void testValidateStringsWithValidValues() {
        Map<String, String> requiredFields = new Map<String, String>{'validString'=>'hello world', 'anotherValidField'=>'foobar' };
        try {
            Util.validateStrings(requiredFields);
            System.assert(true, 'This assert should be called, because an exception should not be thrown');
        } catch (Exception e) {
            System.assert(false, 'This assert should not be called, because an exception should not be thrown');
        }
    }

    @IsTest
    public static void testGetFakeId() {
        String id = Util.getFakeId(Schema.Account.SObjectType);
        System.assertEquals('001000000000000', id, 'Fake ID should be 15 characters long, and have the proper 3-digit prefix for the entity');
    }
}