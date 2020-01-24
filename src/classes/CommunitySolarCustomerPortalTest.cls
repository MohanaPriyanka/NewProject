@isTest
public without sharing class CommunitySolarCustomerPortalTest {
    @isTest static void testUserQuery(){
        Test.startTest();
        Account parentAccount = new Account(Name = 'Account Parent');
        insert parentAccount;

        Contact contactA = new Contact(
            FirstName = 'Contact',
            LastName = 'A',
            AccountId = parentAccount.Id
        );
        insert contactA;

        Profile profileRecord = [
            SELECT Id
            FROM Profile
            WHERE Name='Community Solar Community User'
        ];

        User userRecord = new User(
            FirstName = 'Jordan',
            Lastname ='Testcase',
            Alias = 'xxx234',
            Email = 'jpentaleri@bluewavesolar.com',
            Emailencodingkey ='UTF-8',
            Languagelocalekey ='en_US',
            Localesidkey ='en_US',
            Profileid = profileRecord.Id,
            Country ='United States',
            IsActive = true,
            ContactId = contactA.Id,
            Timezonesidkey='America/Los_Angeles',
            Username='testBillCreationandPay@bluewavesolar.com'
        );

        Util.insertSobjs(new list<User>{userRecord});

        System.runAs(userRecord){
            Contact userContact = MyAccountController.getContactInfo();
            System.assertEquals(contactA.Id,userContact.Id);

            userContact.Email = 'someotherEmail2@bluewavesolar.com';
            MyAccountController.updateContactInfo(userContact);
        }
    }
}