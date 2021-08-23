/**
 * Created by aingram on 8/23/21.
 */

@IsTest
private class PartnerSSFLinkController_Test {

    public static final Id PARTNER_PORTAL_ID = [SELECT Id FROM Profile WHERE Name = 'Partner Portal Community User' LIMIT 1].Id;

    @TestSetup
    public static void testSetup() {
        Account partnerAccount = new Account(Name = 'Test Partner Account');

        insert partnerAccount;

        Partner__c partner = new Partner__c(
            Name = 'Test Partner',
            Email__c = 'test@email.com'
        );

        insert partner;

        Contact contactOne = new Contact(
            FirstName = 'Foo',
            LastName = 'Test',
            Partner_Lookup__c = partner.Id,
            AccountId = partnerAccount.Id
        );

        insert contactOne;

        User partnerPortalUser = new User(
            Username = 'test123@test.com',
            ContactId = contactOne.Id,
            ProfileId = PARTNER_PORTAL_ID,
            Alias = 'test123',
            Email = 'test123@test.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'TestCase',
            CommunityNickname = 'test123',
            TimeZoneSidKey = 'America/New_York',
            LocaleSidKey = 'en_US',
            LanguageLocaleKey = 'en_US'
        );

        insert partnerPortalUser;
    }

    @IsTest
    public static void getNewApplicationLinkTest() {
        User partnerUser = [SELECT Id, ContactId FROM User WHERE Username = 'test123@test.com' LIMIT 1];
        Contact contactUser = [SELECT Id, Partner_Lookup__c FROM Contact WHERE Id = :partnerUser.ContactId LIMIT 1];

        System.runAs(partnerUser) {
            String ssfUrl = PartnerSSFLinkController.getNewApplicationLink();
            System.assert(ssfUrl.contains(contactUser.Partner_Lookup__c), 'URL should contain partnerId in parameters');

        }

    }
}