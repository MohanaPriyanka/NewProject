/**
 * Created by jlugo on 2019-07-09.
 */

@IsTest
public with sharing class RestLeadTest {


    private static RestLead validResidentialLead = new RestLead();
    private static RestLead validNonResidentialLead;
    private static RestLead invalidNonResidentialLead;
    private static RestLead invalidResidentialLead;
    private static RestLead.RestPropertyAccount validPropertyAccount = new RestLead.RestPropertyAccount();
    private static RestLead.RestUtilityAccountLog validUtilityAccountLog = new RestLead.RestUtilityAccountLog();

    static {
        validResidentialLead.id = Util.getFakeId(Schema.Lead.SObjectType);
        validResidentialLead.applicationType = 'Residential';
        validResidentialLead.firstName = 'ValidFirstName';
        validResidentialLead.lastName = 'ValidLastName';
        validResidentialLead.email = 'email@bluewavesoalr.com.invalid';
        validResidentialLead.mobilePhone = '555-555-5555';
        validResidentialLead.streetAddress = '1 Home Street';
        validResidentialLead.city = 'Anytown';
        validResidentialLead.state = 'NY';
        validResidentialLead.zipCode = '00000';
        validResidentialLead.productName = 'VDER';

        validPropertyAccount.billingStreet = '1 Billing Street';
        validPropertyAccount.billingCity = 'Billing City';
        validPropertyAccount.billingState = 'MA';
        validPropertyAccount.billingPostalCode = '55555';

        validUtilityAccountLog.nameOnAccount = 'My Company';
        validUtilityAccountLog.serviceStreet = '1 Service Address';
        validUtilityAccountLog.serviceCity = 'Service City';
        validUtilityAccountLog.serviceState = 'NY';
        validUtilityAccountLog.servicePostalCode = '11111';

        validPropertyAccount.utilityAccountLogs = new List<RestLead.RestUtilityAccountLog>();
        validPropertyAccount.utilityAccountLogs.add(validUtilityAccountLog);

        validResidentialLead.propertyAccounts = new List<RestLead.RestPropertyAccount>();
        validResidentialLead.propertyAccounts.add(validPropertyAccount);


        validNonResidentialLead = validResidentialLead.clone();
        validNonResidentialLead.applicationType = 'Non-Residential';
        validNonResidentialLead.businessName = 'My cool company';
        validNonResidentialLead.businessTitle = 'Janitor';

        invalidResidentialLead = validResidentialLead.clone();
        invalidNonResidentialLead = validNonResidentialLead.clone();

    }


    /******************
    *** RestLead ***
    *******************/

    @IsTest
    public static void testValidateCreateFieldsSuccess() {
        try {
            validResidentialLead.validateCreateFields();
            System.assert(true, 'Validation should pass');
        } catch (Exception e) {
            System.assert(false, 'Validation should not fail');
        }
    }

    @IsTest
    public static void testValidateCreateFieldsMissingFirstName() {
        try {
            invalidResidentialLead.firstName = null;
            invalidResidentialLead.validateCreateFields();
            System.assert(false, 'Validation should not pass');
        } catch (Exception e) {
            System.assert(e.getMessage().containsIgnoreCase('firstName'), 'Should inform consumer that firstName is invalid');
        }
    }

    @IsTest
    public static void testValidateCreateFieldsInvalidApplicationType() {
        try {
            invalidResidentialLead.applicationType = 'Space Station';
            invalidResidentialLead.validateCreateFields();
            System.assert(false, 'Validation should not pass');
        } catch (Exception e) {
            System.assert(e.getMessage().containsIgnoreCase('Space Station'), 'Should inform consumer that the application type is invalid');
        }
    }

    @IsTest
    public static void testValidateCreateFieldsMissingBillingStreet() {
        try {
            invalidResidentialLead.propertyAccounts[0].billingStreet = null;
            invalidResidentialLead.validateCreateFields();
            System.assert(false, 'Validation should not pass');
        } catch (Exception e) {
            System.assert(e.getMessage().containsIgnoreCase('billingStreet'), 'Should inform consumer that billingStreet is invalid');
        }
    }

    @IsTest
    public static void testValidateCreateFieldsNonResiSuccess() {
        try {
            validNonResidentialLead.validateCreateFields();
            System.assert(true, 'Validation should pass');
        } catch (Exception e) {
            System.assert(false, 'Validation should not fail');
        }
    }

    @IsTest
    public static void testValidateCreateFieldsNonResiNoBusinessName() {
        try {
            invalidNonResidentialLead.businessName = null;
            invalidNonResidentialLead.validateCreateFields();
            System.assert(false, 'Validation should not pass');
        } catch (Exception e) {
            System.assert(e.getMessage().containsIgnoreCase('businessName'), 'Should inform consumer that businessName is invalid');
        }
    }

    @IsTest
    static void testUalRateClass(){
        Utility__c utility1 = new Utility__c(Name = 'utility1');
        Utility__c utility2 = new Utility__c(Name = 'utility2');
        insert new List<Utility__c>{utility1, utility2};

        Rate_Class__c rateClass1 = new Rate_Class__c(Name = 'rateClass', Utility__c = utility1.Id);
        Rate_Class__c rateClass2 = new Rate_Class__c(Name = 'rateClass', Utility__c = utility2.Id);
        insert new List<Rate_Class__c>{rateClass1, rateClass2};

        Lead lead = validResidentialLead.asLead();
        lead.Id = null;
        insert lead;

        Account propertyAccount = validPropertyAccount.asAccount(lead);
        propertyAccount.Lead__c = lead.Id;
        propertyAccount.Id = null;
        insert propertyAccount;

        validUtilityAccountLog.rateClass = 'rateClass';
        Utility_Account_Log__c ual = validUtilityAccountLog.asUAL(propertyAccount);
        System.assertNotEquals(null, ual.Utility_Rate_Class__c, 'asUAL() method should have returned either of the Rate Classes, as both match the name in the RestUtilityAccountLog');
        
        lead.Utility_relationship__c = utility2.Id;
        update lead;
        ual = validUtilityAccountLog.asUAL(propertyAccount);
        System.assertEquals(rateClass2.Id, ual.Utility_Rate_Class__c, 'asUAL() method should have returned the Rate Class matching the Utility record on the lead');

        ual.Utility_Rate_Class__c = rateClass1.Id;
        insert ual;
        rateClass1.Name = 'New Rate Class Name';
        rateClass1.Utility__c = utility2.Id;
        update rateClass1;
        ual = new UALSelector().selectOne(ual.Id);
        RestLead.RestUtilityAccountLog newRestUAL = new RestLead.RestUtilityAccountLog(ual);
        System.assertEquals('New Rate Class Name', newRestUAL.rateClass, 'RestUAL should reflect new rate class name from input Utility Account Log');

        newRestUAL.rateClass = null;
        newRestUAL.mergeFields(new Set<String>{'rateClass'}, ual);
        System.assertEquals(null, ual.Utility_Rate_Class__c, 'mergeFields() method should have cleared the value of the Utility_Rate_Class__c field on the Utility Account Log');

        newRestUAL.rateClass = 'rateClass';
        newRestUAL.mergeFields(new Set<String>{'rateClass'}, ual);
        System.assertEquals(rateClass2.Id, ual.Utility_Rate_Class__c, 'mergeFields() method should have returned the Rate Class matching the name in the RestUtilityAccountLog');

        lead.Utility_relationship__c = utility1.Id;
        update lead;
        ual.Utility_lookup__c = utility1.Id;
        update ual;
        newRestUAL.rateClass = 'New Rate Class Name';
        newRestUAL.mergeFields(new Set<String>{'rateClass'}, ual);
        List<Error_Log__c> errorLogs = [SELECT Id, Message__c FROM Error_Log__c WHERE Class__c = 'RestLead.RestUtilityAccountLog' AND Method__c = 'updateRateClass'];
        System.assert(!errorLogs.isEmpty(), 'An error log should have been created by the mergeFields() method, as there is no Rate Class matching both the name in the RestUtilityAccountLog and the Utility in the parent lead');
    }
}