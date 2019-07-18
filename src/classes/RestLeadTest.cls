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
        validNonResidentialLead.businessPhone = '555-555-5555';
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
    public static void testValidateCreateFieldsNoPropertyAccounts() {
        try {
            invalidResidentialLead.propertyAccounts = null;
            invalidResidentialLead.validateCreateFields();
            System.assert(false, 'Validation should not pass');
        } catch (Exception e) {
            System.assert(e.getMessage().containsIgnoreCase('propertyAccounts'), 'Should inform consumer that the propertyAccounts array is required');
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
    public static void testValidateCreateFieldsNoUALs() {
        try {
            invalidResidentialLead.propertyAccounts[0].utilityAccountLogs = null;
            invalidResidentialLead.validateCreateFields();
            System.assert(false, 'Validation should not pass');
        } catch (Exception e) {
            System.assert(e.getMessage().containsIgnoreCase('utilityAccountLogs'), 'Should inform consumer that the utilityAccountLogs array is required');
        }
    }


    @IsTest
    public static void testValidateCreateFieldsMissingServicePostalCode() {
        try {
            invalidResidentialLead.propertyAccounts[0].utilityAccountLogs[0].servicePostalCode = null;
            invalidResidentialLead.validateCreateFields();
            System.assert(false, 'Validation should not pass');
        } catch (Exception e) {
            System.assert(e.getMessage().containsIgnoreCase('servicePostalCode'), 'Should inform consumer that servicePostalCode is invalid');
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
    public static void testValidateCreateFieldsNonResiNoBusinessPhone() {
        try {
            invalidNonResidentialLead.businessPhone = null;
            invalidNonResidentialLead.validateCreateFields();
            System.assert(false, 'Validation should not pass');
        } catch (Exception e) {
            System.assert(e.getMessage().containsIgnoreCase('businessPhone'), 'Should inform consumer that businessPhone is invalid');
        }
    }

}