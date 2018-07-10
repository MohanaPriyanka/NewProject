@isTest
public without sharing class CommunitySolarCustomerPortalTest {
    @testSetup static void setupTestData() {
        TestBillCreationandPayment.CSTestRecordWarehouse();
    }
    @isTest static void testMethodOne() {
        Test.startTest();
        Account parentAccount = [SELECT Id, Name
                                FROM Account
                                WHERE Name = 'Account Parent'];

        Profile communityProfile = [SELECT Id
                                    FROM Profile
                                    WHERE Name = 'Community Solar Community User'];

        List<Account_Bill__c> accountBillList = [SELECT Id, Name,
                                                Bill_Number__c, Property_Account_ID__c
                                                FROM Account_Bill__c];

        ChargentBase__Gateway__c chGateway  = [SELECT Id, Name, Entity__c
                                                FROM ChargentBase__Gateway__c
                                                LIMIT 1];

        Contact con = new Contact(
            FirstName = 'First',
            Email = 'communitiesUserContact@bluewave-capital.com',
            LastName = 'Last',
            AccountId = parentAccount.Id,
            Active_Communities_User__c = true
        );
        insert con;

        User communityUser = new User (
            ProfileId = communityProfile.Id,
            FirstName = 'Test',
            LastName = 'BFG_User',
            Username = 'communityuser@test.com',
            Email = 'communityuser@test.com',
            Alias = 'bfg_usr',
            ContactId = con.Id,
            CommunityNickname = 'bfg_usr',
            TimeZoneSidKey = 'America/New_York',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'ISO-8859-1',
            LanguageLocaleKey = 'en_US'
        );
        // To avoid UNABLE_TO_LOCK_ROW:
        Util.insertSobjs(new list<User>{communityUser});

        for (Account_Bill__c aBill : accountBillList){
            aBill.Published__c = true;
        }
        update accountBillList;

        ChargentOrders__ChargentOrder__c orderA = new ChargentOrders__ChargentOrder__c(
            ChargentOrders__Gateway__c = chGateway.Id,
            ChargentOrders__Payment_Frequency__c = 'Monthly',
            ChargentOrders__Payment_Status__c = 'Recurring',
            ChargentOrders__Payment_Stop__c = 'Unending',
            ChargentOrders__Charge_Date__c = '01',
            ChargentOrders__Payment_Start_Date__c = Date.today().addDays(1),
            ChargentOrders__Shipping_Name__c = chGateway.Entity__c,
            ChargentOrders__Billing_First_Name__c = 'Cole',
            ChargentOrders__Billing_Last_Name__c = 'Swain',
            ChargentOrders__Billing_Address__c = '108 Ridgeland Drive',
            ChargentOrders__Billing_Zip_Postal__c = '02467',
            ChargentOrders__Subtotal__c = 50,
            ChargentOrders__Payment_Method__c = 'Credit Card',
            Account_Bill__c = accountBillList[0].Id,
            ChargentOrders__Card_Type__c = 'Visa',
            ChargentOrders__Card_Number__c = '411111111111',
            ChargentOrders__Card_Security_Code__c = '999',
            ChargentOrders__Card_Expiration_Month__c = '02',
            ChargentOrders__Card_Expiration_Year__c = '2018',
            ChargentOrders__Card_Last_4__c = '1111'
        );
        insert orderA;

        ChargentOrders__Transaction__c transA = new ChargentOrders__Transaction__c(
            ChargentOrders__Order__c = orderA.id,
            ChargentOrders__Amount__c = 50,
            ChargentOrders__Response_Status__c ='Approved',
            ChargentOrders__Gateway_ID__c = chGateway.id,
            ChargentOrders__Gateway__c = chGateway.id,
            Distributed_Among_System_Bills__c = FALSE,
            ChargentOrders__Response_Message__c = 'OK',
            ChargentOrders__Type__c = 'Charge',
            ChargentOrders__Payment_Method__c = 'Credit Card',
            Activity_Type__c = 'Payment');
        insert transA;


        Map<String, Account> customerAccountMap = new Map<String, Account>();
        for (Account customerAccount : [SELECT Id, Name, Parent_Account_ID__c, Total_Outstanding_Balance__c
                                        FROM Account]){
            customerAccountMap.put(customerAccount.Name, customerAccount);
        }

        Entity__c entity1 = [   SELECT Id, Name
                                FROM Entity__c
                                WHERE Name = 'Oxford Barrett St. P1'];

          System.runAs(communityUser){

            //test the getContactInfo() method
            Contact ContactfromUser = MyAccountController.getContactInfo();
            System.assertEquals('First', ContactfromUser.FirstName);

            //test the updateContactInfo() method
            ContactfromUser.Email = 'jpentaleri@bluewavesolar.com';
            MyAccountController.updateContactInfo(ContactfromUser);

            //test the getUser() method
            User userInfo = MyAccountController.getUser();
            System.assertEquals('Test', userInfo.FirstName);

            // test the getMenuLabelList() method
            List<Account> menuLabelRespList = new List<Account>(MyAccountController.getMenuLabelList());
            System.assertEquals(1, menuLabelRespList.size());
            System.assertEquals(customerAccountMap.get('Account A').Id, menuLabelRespList.get(0).Id);

            //test the getSystemBills() method
            String propertyAccountId = String.valueOf(customerAccountMap.get('Account A').Id).subString(0,15);
            List<AggregateResult> systemBillPrAccRespList = new List<AggregateResult>(MyAccountController.getSystemBills(propertyAccountId));
            List<AggregateResult> systemBillallList = new List<AggregateResult>(MyAccountController.getSystemBills('all'));
            System.assertEquals(606.83, systemBillPrAccRespList[0].get('ChargentOrders__Subtotal__c'));
            System.assertEquals(entity1.Id, systemBillallList[0].get('ChargentOrders__Shipping_Name__c'));

            //test the getAccountBills() method
            propertyAccountId = String.valueOf(customerAccountMap.get('Account A').Id);
            List<Account_Bill__c> accountBillPrAccRespList = new List<Account_Bill__c>(MyAccountController.getAccountBills(propertyAccountId));
            List<Account_Bill__c> accountBillAllRespList = new List<Account_Bill__c>(MyAccountController.getAccountBills('All'));
            System.assertEquals(2, accountBillPrAccRespList.size());
            System.assertEquals(true, accountBillPrAccRespList[0].Published__c);

            //test the getTransactions() method
            List<ChargentOrders__Transaction__c> transactionPrAccRespList = new List<ChargentOrders__Transaction__c>(MyAccountController.getTransactions(propertyAccountId));
            List<ChargentOrders__Transaction__c> transactionAllRespList = new List<ChargentOrders__Transaction__c>(MyAccountController.getTransactions('All'));
            System.assertEquals(50, transactionPrAccRespList[0].ChargentOrders__Amount__c);
            System.assertEquals(1, transactionAllRespList.size());

            //test the getChargentOrder() method
            ChargentOrders__ChargentOrder__c coPrAcc = MyAccountController.getChargentOrder(propertyAccountId);
            ChargentOrders__ChargentOrder__c coAll = MyAccountController.getChargentOrder('All');
            System.assert(coPrAcc != null);
            System.assert(coAll != null);

            //test the getCode() method
            String referralCode = MyAccountController.getCode();
            System.assertEquals(referralCode, 'bluewaveFLast');

            //test the sendEmail() method
            MyAccountController.sendEmail('test@test.test');
          }
        Test.stopTest();
    }
}