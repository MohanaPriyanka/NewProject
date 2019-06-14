@isTest
public without sharing class CommunitySolarCustomerPortalTest {
    @testSetup static void setupTestData() {
        TestBillCreationandPayment.CSTestRecordWarehouse();
    }
    @isTest static void testMethodOne() {
        Test.startTest();
        Account parentAccount = [
            SELECT Id, Name
            FROM Account
            WHERE Name = 'Account Parent'
            LIMIT 1
        ];

        Profile communityProfile = [SELECT Id
        FROM Profile
        WHERE Name = 'Community Solar Community User'];

        List<Account_Bill__c> accountBillList = [SELECT Id, Name,
            Bill_Number__c, Property_Account_ID__c
        FROM Account_Bill__c];

        Shared_Solar_System__c sss = [
            SELECT Id
            FROM Shared_Solar_System__c
            WHERE Name = 'Oxford Barrett St. P2'
        ];

        Product2 normalCSProduct = new Product2( Name = 'BlueWave Community Solar',
            Family = 'Community Solar',
            Product_Type__c = 'Community Solar',
            State__c = 'MA',
            ProductCode = 'CS - BlueWave - 10%',
            IsActive = True,
            Lender_of_Record__c = 'BlueWave',
            NMC_Discount__c = 10,
            Annual_kWh_Maximum__c = 100000000,
            NM_Rate_Floor__c = 0,
            Days_In_Bill_Period__c = 20,
            Monthly_Late_Fee__c = 1);
        insert normalCSProduct;

        Contact con = new Contact(
            FirstName = 'First',
            Email = 'communitiesUserContact@bluewave-capital.com',
            LastName = 'Last',
            AccountId = parentAccount.Id,
            Active_Communities_User__c = true,
            Product_Line__c = 'Community Solar'
        );
        insert con;

        User communityUser = new User (
            ProfileId = communityProfile.Id,
            FirstName = 'Test',
            LastName = 'BFG_User',
            Username = 'bob34873@test.com',
            Email = 'bob34873@test.com',
            Alias = 'bob348',
            ContactId = con.Id,
            CommunityNickname = 'bob348',
            TimeZoneSidKey = 'America/New_York',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'ISO-8859-1',
            LanguageLocaleKey = 'en_US'
        );
        // To avoid UNABLE_TO_LOCK_ROW:
        Util.insertSobjs(new list<User>{communityUser});

        Partner__c partner = new Partner__c (
            Name = 'Partner',
            Products__c = 'Community Solar'
        );
        insert partner;

        BSST__c salesRep = new BSST__c(
            Name = 'Sales Rep A',
            Partner__c = partner.Id
        );
        insert salesRep;

        BSST__c salesRep2 = new BSST__c (
            Name = 'Sales Rep B',
            Partner__c = partner.Id
        );
        insert salesRep2;

        partner.Default_Sales_Rep__c = salesRep2.Id;
        update partner;


        Partner__c csPartner = new Partner__c (
            Name = 'BlueWave Test Partner',
            Products__c = 'Community Solar',
            Default_Sales_Rep__c = salesRep2.Id
        );
        insert csPartner;

        TestFactory.setDefaultCSPartner(csPartner.Id);

        BSST__c csSalesRep = new BSST__c (
            Name = 'CS Sales Rep',
            Partner__c = csPartner.Id
        );
        insert csSalesRep;

        csPartner.Default_Sales_Rep__c = csSalesRep.Id;
        update csPartner;

        Partner__c oldPartner = new Partner__c(
            Name = 'Old Partner',
            Products__c = 'Community Solar',
            Default_Sales_Rep__c = salesRep.Id
        );
        insert oldPartner;

        //Most recent Property Account
        Account propAccountNew = new Account(
            Name = 'Property Account B New',
            ParentId = parentAccount.Id,
            Parent_Account__c = parentAccount.Id,
            Product_Line__c = 'Community Solar'
        );

        insert propAccountNew;

        Date yesterday = Date.Today().addDays(-1);

        //Old Opportunity with wrong partner
        Opportunity opportunityOLD = new Opportunity(
            Name = 'OLD Opp',
            AccountId = propAccountNew.Id,
            Shared_Solar_System__c = sss.Id,
            StageName = 'Complete',
            Product__c = normalCSProduct.Id,
            Partner_tag_lookup__c = oldPartner.Id,
            CloseDate = yesterday
        );
        insert opportunityOLD;

        Opportunity opportunityNEW = new Opportunity(
            Name = 'NEW Opp',
            AccountId = propAccountNew.Id,
            Shared_Solar_System__c = sss.Id,
            StageName = 'Complete',
            Product__c = normalCSProduct.Id,
            Partner_tag_lookup__c = partner.Id,
            BS_Sales_ID__c = salesRep.Id,
            CloseDate = System.today()
        );
        insert opportunityNEW;


        for (Account_Bill__c aBill : accountBillList){
            aBill.Published__c = true;
        }
        update accountBillList;

        Entity__c entity1 = [
            SELECT Id, Name, Gateway__c
            FROM Entity__c
            WHERE Name = 'Oxford Barrett St. P1'
        ];

        ChargentOrders__ChargentOrder__c orderA =
            new ChargentOrders__ChargentOrder__c(Entity__c = entity1.Id,
                ChargentOrders__Payment_Frequency__c = 'Monthly',
                ChargentOrders__Payment_Status__c = 'Recurring',
                ChargentOrders__Payment_Stop__c = 'Unending',
                ChargentOrders__Charge_Date__c = '01',
                ChargentOrders__Payment_Start_Date__c = Date.today().addDays(1),
                ChargentOrders__Billing_First_Name__c = 'Cole',
                ChargentOrders__Billing_Last_Name__c = 'Swain',
                ChargentOrders__Billing_Address__c = '108 Ridgeland Drive',
                ChargentOrders__Billing_Zip_Postal__c = '02467',
                ChargentOrders__Subtotal__c = 50,
                ChargentOrders__Payment_Method__c = 'Credit Card',
                Account_Bill__c = accountBillList[0].Id,
                ChargentOrders__Card_Type__c = 'Visa',
                ChargentOrders__Card_Number__c = '411111111111',
                ChargentOrders__Card_Expiration_Month__c = '02',
                ChargentOrders__Card_Expiration_Year__c = '2018',
                ChargentOrders__Card_Last_4__c = '1111');
        insert orderA;

        ChargentOrders__Transaction__c transA =
            new ChargentOrders__Transaction__c(ChargentOrders__Order__c = orderA.id,
                ChargentOrders__Amount__c = 50,
                ChargentOrders__Response_Status__c ='Approved',
                ChargentOrders__Gateway_ID__c = entity1.Gateway__c,
                ChargentOrders__Gateway__c = entity1.Gateway__c,
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
            System.assertEquals(2, menuLabelRespList.size());
            System.assertEquals(customerAccountMap.get('Account A').Id, menuLabelRespList.get(0).Id);

            //test the getSystemBills() method
            String propertyAccountId = String.valueOf(customerAccountMap.get('Account A').Id).subString(0,15);
            List<AggregateResult> systemBillPrAccRespList = new List<AggregateResult>(MyAccountController.getSystemBills(propertyAccountId));
            List<AggregateResult> systemBillallList = new List<AggregateResult>(MyAccountController.getSystemBills('all'));
            // If NOT waiving late fees:  System.assertEquals(631.07, systemBillPrAccRespList[0].get('ChargentOrders__Subtotal__c'));
            System.assertEquals(628.24, systemBillPrAccRespList[0].get('ChargentOrders__Subtotal__c'));
            System.assertEquals(entity1.Id, systemBillallList[0].get('Entity__c'));

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

            //Test getMostRecentOpportunityInfo() and sendEmail URL()
            Opportunity checkOpp = MyAccountController.getMostRecentOpportunityInfo();
            String checkPartnerId = checkOpp.Partner_tag_lookup__c;
            String checkSalesRepId = checkOpp.BS_Sales_ID__c;
            String checkContactId = ContactfromUser.Id;

            System.assertEquals(opportunityNEW.Partner_tag_lookup__c, checkPartnerId);
            System.assertEquals(opportunityNEW.BS_Sales_ID__c, checkSalesRepId);
            System.assertEquals(con.Id, checkContactId);

            //test the sendEmail() method
            MyAccountController.sendEmail('test@test.test');
        }

        Opportunity checkOpp = MyAccountController.getMostRecentOpportunityInfo();
        String checkPartnerId = checkOpp.Partner_tag_lookup__c;
        String checkSalesRepId = checkOpp.BS_Sales_ID__c;

        //Test getPartner()
        Partner__c checkPartner = PartnerSelector.selectPartnerByPartnerId(checkPartnerId);
        System.assertEquals('Partner', checkPartner.Name);
        System.assertNotEquals(checkPartner.Default_Sales_Rep__c, checkSalesRepId);
        System.assertEquals(salesRep.Id, checkOpp.BS_Sales_ID__c );

        //Default getPartner()
        Partner__c defaultPartner = PartnerSelector.selectDefaultCSPartner();
        System.assertEquals('BlueWave Test Partner', defaultPartner.Name);
        System.assertEquals(csSalesRep.Id, defaultPartner.Default_Sales_Rep__c);


        Test.stopTest();
    }

    @isTest static void testChargentLicenseAssignment(){
        Test.startTest();

        Account parentAccount = [
            SELECT Id, Name
            FROM Account
            WHERE Name = 'Account Parent'
            LIMIT 1
        ];

        Contact con = new Contact(
            FirstName = 'First',
            Email = 'communitiesUserContact@bluewave-capital.com',
            LastName = 'Last',
            AccountId = parentAccount.Id,
            Active_Communities_User__c = true
        );

        Contact conPartnerLogin = new Contact(
            FirstName = 'First',
            Email = 'communitiesUserContact@bluewave-capital.com',
            LastName = 'Last',
            AccountId = parentAccount.Id,
            Active_Communities_User__c = true
        );
        Contact conPartner = new Contact(
            FirstName = 'First',
            Email = 'communitiesUserContact@bluewave-capital.com',
            LastName = 'Last',
            AccountId = parentAccount.Id,
            Active_Communities_User__c = true
        );

        insert new List<Contact>{con, conPartnerLogin, conPartner};
        // To avoid DML operation on setup object error:
        // http://burnignorance.com/salesforce-tips/create-a-customer-portal-user-in-test-class-2/
        User thisUser = [ SELECT Id FROM User WHERE Id = :UserInfo.getUserId() ];

        System.runAs ( thisUser ) {

            Profile communityProfile = [SELECT Id
            FROM Profile
            WHERE Name = 'Community Solar Community User'];
            User communityUser = new User(
                ProfileId = communityProfile.Id,
                FirstName = 'Test',
                LastName = 'BFG_User',
                Username = 'moreUniqueemail3184@test.com',
                Email = 'moreUniqueemail3184@test.com',
                Alias = 'ema3184',
                ContactId = con.Id,
                CommunityNickname = 'ema3184',
                TimeZoneSidKey = 'America/New_York',
                LocaleSidKey = 'en_US',
                EmailEncodingKey = 'ISO-8859-1',
                LanguageLocaleKey = 'en_US'
            );

            Profile partnerLoginProfile = [SELECT Id
            FROM Profile
            WHERE Name = 'Partner Community Login User (Custom)'];
            User partnerLoginUser = new User(
                ProfileId = partnerLoginProfile.Id,
                FirstName = 'Test',
                LastName = 'PartnerLogin',
                Username = 'moreUniqueemail3184PartnerLogin@test.com',
                Email = 'moreUniqueemail3184PartnerLogin@test.com',
                Alias = 'ema318pl',
                ContactId = conPartnerLogin.Id,
                CommunityNickname = 'ema318pl',
                TimeZoneSidKey = 'America/New_York',
                LocaleSidKey = 'en_US',
                EmailEncodingKey = 'ISO-8859-1',
                LanguageLocaleKey = 'en_US'
            );

            Profile partnerProfile = [SELECT Id
            FROM Profile
            WHERE Name = 'Partner Community User (Custom)'];
            User partnerUser = new User(
                ProfileId = partnerProfile.Id,
                FirstName = 'Test',
                LastName = 'BFG_User',
                Username = 'moreUniqueemail3184partner@test.com',
                Email = 'moreUniqueemail3184partner@test.com',
                Alias = 'ema318p',
                ContactId = conPartner.Id,
                CommunityNickname = 'ema318p',
                TimeZoneSidKey = 'America/New_York',
                LocaleSidKey = 'en_US',
                EmailEncodingKey = 'ISO-8859-1',
                LanguageLocaleKey = 'en_US'
            );
            // To avoid UNABLE_TO_LOCK_ROW:
            Util.insertSobjs(new list<User>{communityUser, partnerLoginUser, partnerUser});

            PackageLicense pl = [   SELECT Id
            FROM PackageLicense
            WHERE NamespacePrefix = 'ChargentOrders'];

            List<UserPackageLicense> packageAssign = [  SELECT Id, UserId, PackageLicenseId
            FROM UserPackageLicense
            WHERE (UserId = : communityUser.Id
            OR UserId = : partnerLoginUser.Id
            OR UserId = : partnerUser.Id)
            AND PackageLicenseId = : pl.Id];

            System.assertEquals(3,packageAssign.size());
        }
        Test.stopTest();
    }

    @isTest static void testGetAllSystemBills() {
        Test.startTest();

        User user = [
            SELECT Id, Contact.Account.Id, Contact.AccountId
            FROM User
            WHERE Username = 'testBillCreationandPay@bluewavesolar.com'
        ];

        Account accountC = new Account(name = 'Account C', Parent_Account__c = user.Contact.AccountId);

        insert accountC;

        Utility_Account_Log__c ualog =
            new Utility_Account_Log__c(Name = '0000234',
                Account__c = accountC.Id,
                Annual_Cost_of_Electricity__c = 10000,
                Name_on_Account__c = 'jordan jordan');

        insert ualog;

        Product2 normalCSProduct = new Product2( Name = 'BlueWave Community Solar',
            Family = 'Community Solar',
            Product_Type__c = 'Community Solar',
            State__c = 'MA',
            ProductCode = 'CS - BlueWave - 10%',
            IsActive = True,
            Lender_of_Record__c = 'BlueWave',
            NMC_Discount__c = 10,
            Annual_kWh_Maximum__c = 100000000,
            NM_Rate_Floor__c = 0,
            Days_In_Bill_Period__c = 20,
            Monthly_Late_Fee__c = 1);
        insert normalCSProduct;

        Shared_Solar_System__c sss = [
            SELECT Id
            FROM Shared_Solar_System__c
            WHERE Name = 'Oxford Barrett St. P2'
        ];

        Opportunity opportunity = new Opportunity(
            Name = 'COpp One',
            AccountId = accountC.Id,
            Shared_Solar_System__c = sss.Id,
            StageName = 'Complete',
            Product__c = normalCSProduct.Id,
            CloseDate = System.today()
        );
        insert opportunity;

        Utility_Account_Subscription__c uas = new Utility_Account_Subscription__c(
            Name = '9203012',
            Utility_Account_Log__c = ualog.Id,
            Opportunity__c = opportunity.Id,
            Next_Schedule_Z_Status__c = 'Active Subscription',
            Annual_kwh_subscription_future__c = 4000,
            Calculated_Annual_Cost_of_Electricity__c = 4000,
            Subscribed_Annual_Cost_of_Electricity__c = 4000
        );

        insert uas;
        uas = [
            SELECT Id, Customer_Subscription_KW_DC__c
            FROM Utility_Account_Subscription__c
            WHERE Id = : uas.Id
        ];

        Schedule_Z__c scheduleZ = [
            SELECT Id, Shared_Solar_System__r.Utility__r.Number_of_Decimal_Places__c,
                Shared_Solar_System__r.Total_System_Size_kW_DC_QC__c
            FROM Schedule_Z__c
            WHERE Name = '18-0515 Oxford Barrett St. P2'
        ];

        Schedule_Z_Subscription__c newSub = new Schedule_Z_Subscription__c(
            Schedule_Z__c = scheduleZ.Id,
            Utility_Account_Subscription__c = uas.Id,
            Customer_Subscription_kW_DC__c = uas.Customer_Subscription_KW_DC__c,
            Number_of_Decimal_Places__c = scheduleZ.Shared_Solar_System__r.Utility__r.Number_of_Decimal_Places__c,
            System_Size_kW_DC__c = scheduleZ.Shared_Solar_System__r.Total_System_Size_kW_DC_QC__c
        );

        insert newSub;

        Energy_Usage_Update__c productionupdateB2 = [
            SELECT Id, Generate_Bills__c, Month_Number__c, Shared_Solar_System__c
            FROM Energy_Usage_Update__c
            WHERE Name = 'sssB - February 2016'
            LIMIT 1
        ];

        TestBillCreationandPayment.runProductionUpdate(new List<Id>{productionupdateB2.Id});

        List<Account_Bill__c> accountBills = [
            SELECT Id, Published__c, Parent_Account__c
            FROM Account_Bill__c
        ];

        for (Account_Bill__c accountBill : accountBills) {
            accountBill.Published__c = true;
        }
        update accountBills;

        List<System_Bill__c> systemBills = [
            SELECT Id, Bill_Number__c, Account_Bill_Number__c, Shared_Solar_System__c, Month__c
            FROM System_Bill__c
            WHERE Account_Bill__r.Parent_Account__r.Parent_Account__c = : user.Contact.Account.Id
        ];

        System.runAs(user) {
            String propertyAccount = 'All';
            List<AggregateResult> aggregateSystemBills = MyAccountController.getSystemBills(propertyAccount);

            // This user has 2 property accounts (Account A & Account C).
            // AccountA has 2 subscriptions, AccountC has 1 subscription
            // AccountA has 2 AccountBills (Jan & Feb), AccountC has 1 AccountBill (Feb)
            // Goal of this method is to return an aggregate of the most recent system bills
            System.assertEquals(3, aggregateSystemBills.size());
        }
        Test.stopTest();
    }
}
