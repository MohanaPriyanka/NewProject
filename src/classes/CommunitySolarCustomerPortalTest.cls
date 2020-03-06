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

    @isTest static void testPaperlessBilling(){
        Account parentAccount = new Account(
            Name = 'Parent'
        );
        insert parentAccount;

        Account accountA = new Account(
            Name = 'Account A',
            Bill_Delivery_Preference__c = 'Email Only',
            Parent_Account__c = parentAccount.Id
        );
        Account accountB = new Account(
            Name = 'Account B',
            Bill_Delivery_Preference__c = 'Email only',
            Parent_Account__c = parentAccount.Id
        );
        Account accountC = new Account(
            Name = 'Account B',
            Bill_Delivery_Preference__c = 'Email only',
            Parent_Account__c = parentAccount.Id
        );
        insert new List<Account>{accountA, accountB, accountC};

        Boolean isPaperless = false;
        isPaperless = MyAccountController.isPaperless(parentAccount.Id);
        System.assert(isPaperless);

        accountB.Bill_Delivery_Preference__c = 'Email and Paper';
        accountC.Bill_Delivery_Preference__c = 'Paper Only';

        update accountB;
        update accountC;

        isPaperless = MyAccountController.isPaperless(parentAccount.Id);
        System.assert(!isPaperless);

        MyAccountController.setToPaperless(parentAccount.Id);

        AccountsSelector selector = new AccountsSelector();
        List<Account> properties = selector.getPropertiesFromParent(new Set<Id>{parentAccount.Id});
        System.assertEquals(3,properties.size());
        System.assertEquals('Email only',properties[0].Bill_Delivery_Preference__c);
        System.assertEquals('Email only',properties[1].Bill_Delivery_Preference__c);
        System.assertEquals('Email only',properties[2].Bill_Delivery_Preference__c);
    }
}