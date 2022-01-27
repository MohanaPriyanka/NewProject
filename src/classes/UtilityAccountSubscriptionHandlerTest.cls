/**
 * Created by SarahRenfro on 12/2/2019.
 */

@IsTest
public class UtilityAccountSubscriptionHandlerTest {

    private static final String ERROR_MSG = 'Only a single subscription per Utility Account is allowed for UAL:';

    @TestSetup
    public static void setupData() {
        Utility__c ngrid = new Utility__c(
            Name = 'National Grid',
            Number_of_Decimal_Places__c = 2
        );
        insert ngrid;

        Account clientAccount = new Account(name = 'Test Client');
        insert clientAccount;

        Utility_NMC_Tariff__c eversizeNMC = new Utility_NMC_Tariff__c (Name = 'Eversource SEMA Class 2',
            Utility__c = 'Eversource',
            Class__c = 'Class 2',
            Value_of_Net_Metering_Credit__c = 0.1848,
            Sizing_Rate__c = TRUE);
        insert eversizeNMC;

        Product2 normalCSProduct = new Product2(Name = 'BlueWave Community Solar',
            Family = 'Community Solar',
            Product_Type__c = 'Community Solar',
            State__c = 'MA',
            ProductCode = 'CS - BlueWave - 10%',
            IsActive = True,
            NMC_Discount__c = 10,
            Annual_kWh_Maximum__c = 100000000,
            NM_Rate_Floor__c = 0,
            Days_In_Bill_Period__c = 20,
            Customer_Subscription_Type__c = 'kWh',
            Utility_Account_Subscription_Type__c = 'Multiple subscriptions per Utility Account');

        insert new List<Product2>{normalCSProduct};

        Shared_Solar_System__c sss1 = new Shared_Solar_System__c(Name = 'Project A',
            Service_Territory__c = 'SEMA',
            Service_Territories__c = 'SEMA',
            Open__c = true,
            Client_Account__c = clientAccount.Id,
            Utility_NMC_Tariff__c = eversizeNMC.Id,
            Billing_Method__c = 'NMC',
            Pending_Small_CS_Capacity__c = 10,
            Capacity_Committed_kW_DC__c = 0,
            Total_System_Size_kWh_DC__c = 1445.86,
            Total_System_Size_kW_AC__c = 1000,
            Utility__c = ngrid.Id,
            Credit_Score_Requirement__c = 300,
            Assignment_Order__c = '1',
            Expected_Yield_kWh_kW__c = 1300,
            Assemblage_Count__c = 1,
            Maximum_Subscription_Capacity_kWDC__c = 25,
            Product__c = normalCSProduct.Id);

        Shared_Solar_System__c sss2 = new Shared_Solar_System__c(Name = 'Project B',
            Service_Territory__c = 'SEMA',
            Service_Territories__c = 'SEMA',
            Open__c = true,
            Client_Account__c = clientAccount.Id,
            Utility_NMC_Tariff__c = eversizeNMC.Id,
            Billing_Method__c = 'NMC',
            Pending_Small_CS_Capacity__c = 10,
            Capacity_Committed_kW_DC__c = 0,
            Total_System_Size_kWh_DC__c = 1445.86,
            Total_System_Size_kW_AC__c = 1000,
            Utility__c = ngrid.Id,
            Credit_Score_Requirement__c = 300,
            Assignment_Order__c = '1',
            Expected_Yield_kWh_kW__c = 1300,
            Assemblage_Count__c = 1,
            Maximum_Subscription_Capacity_kWDC__c = 25,
            Product__c = normalCSProduct.Id);

        insert new List<Shared_Solar_System__c>{sss1, sss2};

        Partner__c partner = new Partner__c(
            Name = 'Some Partner'
        );
        insert partner;

        Id partnerAccountRT = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner Account').getRecordTypeId();

        Account partnerAccount = new Account(
            Name = 'Partner Account',
            RecordTypeId = partnerAccountRT
        );

        Id parentAccountRT = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Parent Account').getRecordTypeId();

        Account accountParent = new Account(name = 'Account Parent',
            RecordTypeId = parentAccountRT);

        Account propAccountA = new Account(name = 'Account A',
            Parent_Account__c = accountParent.Id);

        Account propAccountB = new Account(name = 'Account B',
            Parent_Account__c = accountParent.Id);

        insert new List<Account> {partnerAccount, accountParent, propAccountA, propAccountB};

        Opportunity opportunityone =
            new Opportunity(Name = 'AOpp',
                AccountId = propAccountA.Id,
                Shared_Solar_System__c = sss1.Id,
                StageName = 'Complete',
                NMC_Tariff__c = eversizeNMC.Id,
                Partner_tag_lookup__c = partner.Id,
                Partner_Account__c = partnerAccount.Id,
                Customer_Group__c = 'Residential',
                Product__c = normalCSProduct.Id,
                Product_Line__c = 'Community Solar',
                CloseDate = System.today());

        Opportunity opportunitytwo =
            new Opportunity(Name = 'BOpp',
                AccountId = propAccountB.Id,
                Shared_Solar_System__c = sss1.Id,
                StageName = 'Complete',
                NMC_Tariff__c = eversizeNMC.Id,
                Partner_tag_lookup__c = partner.Id,
                Partner_Account__c = partnerAccount.Id,
                Customer_Group__c = 'Residential',
                Product__c = normalCSProduct.Id,
                Product_Line__c = 'Community Solar',
                CloseDate = System.today()
            );

        insert new List<Opportunity>{opportunityone, opportunitytwo};

        Utility_Account_Log__c ualog =
            new Utility_Account_Log__c(Name = '0000234',
                Account__c = propAccountA.Id,
                Annual_Cost_of_Electricity__c = 10000,
                Name_on_Account__c = 'A Testcase');

        insert ualog;

        Utility_Account_Subscription__c uasone = new Utility_Account_Subscription__c(
            Name = '0000234',
            Utility_Account_Log__c = ualog.Id,
            Opportunity__c = opportunityone.Id,
            Next_Schedule_Z_Status__c = 'Active Subscription',
            Calculated_Annual_Cost_of_Electricity__c = 4000
        );
          
        insert uasone;
        TestSOCreator.registerByCapacity(uasone, 4000);


        Utility_Account_Log__c ualogOne =
            new Utility_Account_Log__c(Name = '0000234',
                Account__c = propAccountA.Id,
                Annual_Cost_of_Electricity__c = 10000,
                Name_on_Account__c = 'A Testcase'
            );


        Utility_Account_Log__c ualogTwo =
            new Utility_Account_Log__c(Name = '0000236',
                Account__c = propAccountB.Id,
                Annual_Cost_of_Electricity__c = 20000,
                Name_on_Account__c = 'B Testcase'
            );

        insert new List<Utility_Account_Log__c>{ualogOne, ualogTwo};

        Utility_Account_Subscription__c uasTwo =
            new Utility_Account_Subscription__c(Name = '0000236',
                Utility_Account_Log__c = ualogTwo.Id,
                Opportunity__c = opportunitytwo.Id,
                Next_Schedule_Z_Status__c = 'Active Subscription',
                Calculated_Annual_Cost_of_Electricity__c = 4000);
        insert uasTwo;
        TestSOCreator.registerByCapacity(uasTwo, 4000);
        TestSOCreator.commitWork();
    }

    @IsTest
    public static void testUASInsert() {
        Opportunity opp = [
            SELECT Id, Shared_Solar_System__c
            FROM Opportunity
            ORDER BY Name
            LIMIT 1
        ];

        Utility_Account_Log__c ual = [
            SELECT Id
            FROM Utility_Account_Log__c
            ORDER BY Name
            LIMIT 1
        ];

        Utility_Account_Subscription__c uasone =
            new Utility_Account_Subscription__c(Name = '0000234',
                Utility_Account_Log__c = ual.Id,
                Opportunity__c = opp.Id,
                Next_Schedule_Z_Status__c = 'Active Subscription',
                Calculated_Annual_Cost_of_Electricity__c = 4000);
        insert uasone;

        Utility_Account_Subscription__c checkUAS = [
            SELECT Id, Shared_Solar_System__c
            FROM Utility_Account_Subscription__c
            WHERE Id = : uasone.Id
            LIMIT 1
        ];

        System.assertEquals(opp.Shared_Solar_System__c, checkUAS.Shared_Solar_System__c, 'SSS on UAS should match Opportunity');
    }

    @IsTest
    public static void testUASUpdate() {
        Opportunity opp = [
            SELECT Id, Shared_Solar_System__c
            FROM Opportunity
            ORDER BY Name
            LIMIT 1
        ];

        Utility_Account_Log__c ual = [
            SELECT Id
            FROM Utility_Account_Log__c
            ORDER BY Name
            LIMIT 1
        ];

        Utility_Account_Subscription__c uasone =
            new Utility_Account_Subscription__c(Name = '0000234',
                Utility_Account_Log__c = ual.Id,
                Next_Schedule_Z_Status__c = 'Active Subscription',
                Calculated_Annual_Cost_of_Electricity__c = 4000);
        insert uasone;

        Utility_Account_Subscription__c nullUAS = [
            SELECT Id, Shared_Solar_System__c
            FROM Utility_Account_Subscription__c
            WHERE Id = : uasone.Id
            LIMIT 1
        ];

        //Should be null because opp is null
        System.assertEquals(null, nullUAS.Shared_Solar_System__c,'UAS SSS should be null because it does not have an opportunity');

        nullUAS.Opportunity__c = opp.Id;
        update nullUAS;

        Utility_Account_Subscription__c checkUAS = [
            SELECT Id, Shared_Solar_System__c
            FROM Utility_Account_Subscription__c
            WHERE Id = : uasone.Id
            LIMIT 1
        ];

        //Will now be populated because UAS has opportunity now
        System.assertNotEquals(null, checkUAS.Shared_Solar_System__c, 'SSS should be populated on UAS after Opportunity is populated');
        System.assertEquals(opp.Shared_Solar_System__c, checkUAS.Shared_Solar_System__c,'SSS on UAS should match SSS on Opportunity');
    }

    @IsTest
    public static void testChangeOpportunity() {
        List<Opportunity> opps = [
            SELECT Id, Shared_Solar_System__c
            FROM Opportunity
            ORDER BY Name
        ];

        Utility_Account_Log__c ual = [
            SELECT Id
            FROM Utility_Account_Log__c
            ORDER BY Name
            LIMIT 1
        ];

        Utility_Account_Subscription__c uas =
            new Utility_Account_Subscription__c(Name = '0000234',
                Utility_Account_Log__c = ual.Id,
                Opportunity__c = opps[0].Id,
                Next_Schedule_Z_Status__c = 'Active Subscription',
                Calculated_Annual_Cost_of_Electricity__c = 4000);
        insert uas;

        uas = [
            SELECT Id, Shared_Solar_System__c
            FROM Utility_Account_Subscription__c
            WHERE Id = : uas.Id
            LIMIT 1
        ];

        System.assertEquals(opps[0].Shared_Solar_System__c, uas.Shared_Solar_System__c,'Opp and UAS SSS should match before attempting to change them');

        // Change Opportunity - therefore SSS changes
        Shared_Solar_System__c sss2 = [
            SELECT Id FROM Shared_Solar_System__c
            WHERE Name = 'Project B'
            LIMIT 1
        ];
        opps[1].Shared_Solar_System__c = sss2.Id;
        update opps[1];

        uas.Opportunity__c = opps[1].Id;
        try {
            update uas;
            System.assert(false, 'The update should have thrown an exception from a validation rule before this assertion');
        }  catch (System.DmlException e) {
            System.assertEquals('FIELD_CUSTOM_VALIDATION_EXCEPTION' , e.getDmlStatusCode(0),'Updating the SSS on UAS should trigger a validation rule to prevent the txn' );
        }
    }

    @IsTest
    public static void testRollupAnchorUASes(){
        Opportunity anchorOpp = [
            SELECT Id, Customer_Group__c, AccountId
            FROM Opportunity
            WHERE Name = 'BOpp'
            LIMIT 1
        ];
        System.assertNotEquals(null, anchorOpp.AccountId,'Anchor opp used for testing should link to an account');
        anchorOpp.Customer_Group__c = 'Anchor';
        update anchorOpp;

        Utility_Account_Subscription__c anchorUAS = [
            SELECT Id, Customer_Group__c, Opportunity__c,
                Opportunity__r.AccountId, Annual_Subscription_Production_Summary__c
            FROM Utility_Account_Subscription__c
            WHERE Customer_Group__c = 'Anchor'
            LIMIT 1
        ];

        System.assertNotEquals(null, anchorUAS,'UASs with a Customer Group = Anchor should exist');
        System.assertEquals(null, anchorUAS.Annual_Subscription_Production_Summary__c,'Anchor UASs should not have any annual production before we rollup the data');
        System.assertEquals(anchorOpp.Id, anchorUAS.Opportunity__c,'The Anchor Opp and Anchor UAS should have the same Opportunity ID');

        Date billDate = System.today();

        UASB__c billOne = new UASB__c(
            Account__c = anchorUAS.Opportunity__r.AccountId,
            Zuora_Id__c = 'bbb1230005',
            Utility_Account_Subscription__c = anchorUAS.Id,
            Date__c = billDate.addMonths(-1),
            Subscription_Production_kWh_Static__c = 100
        );
        UASB__c billTwo = new UASB__c(
            Account__c = anchorUAS.Opportunity__r.AccountId,
            Zuora_Id__c = 'bbb1230001',
            Utility_Account_Subscription__c = anchorUAS.Id,
            Date__c = billDate.addMonths(-2),
            Subscription_Production_kWh_Static__c = 100
        );
        UASB__c billThree = new UASB__c(
            Account__c = anchorUAS.Opportunity__r.AccountId,
            Zuora_Id__c = 'bbb1230001',
            Utility_Account_Subscription__c = anchorUAS.Id,
            Date__c = billDate.addMonths(-3),
            Subscription_Production_kWh_Static__c = 100
        );
        UASB__c billLASTYEAR = new UASB__c(
            Account__c = anchorUAS.Opportunity__r.AccountId,
            Zuora_Id__c = 'bbb1230001',
            Utility_Account_Subscription__c = anchorUAS.Id,
            Date__c = billDate.addMonths(-13),
            Subscription_Production_kWh_Static__c = 100
        );
        insert new List<UASB__c>{billOne, billTwo, billThree, billLASTYEAR};
        Test.startTest();
        UtilityAccountSubscriptionHandler.rollupAnchorUASes();
        Test.stopTest();
        anchorUAS = [
            SELECT Id, Customer_Group__c, Opportunity__c,
                Opportunity__r.AccountId, Annual_Subscription_Production_Summary__c
            FROM Utility_Account_Subscription__c
            WHERE Customer_Group__c = 'Anchor'
            LIMIT 1
        ];

        System.assertEquals(300, anchorUAS.Annual_Subscription_Production_Summary__c,'The rollup of Anchor production should = 300');
    }

    /**
     * MOCKS
     * **/

    private static sfab_FabricatedSObject getMockSSS(Boolean hasSingleSubProduct) {

        String subType = hasSingleSubProduct ? 'Single subscription per Utility Account' : 'Multiple subscriptions per Utility Account';
        sfab_FabricatedSObject mockProduct = new sfab_FabricatedSObject(Product2.class);
        mockProduct.setField(Product2.Utility_Account_Subscription_Type__c, subType);

        sfab_FabricatedSObject mockSSS = new sfab_FabricatedSObject(Shared_Solar_System__c.class);
        mockSSS.setField(Shared_Solar_System__c.Product__c, Util.getFakeId(Product2.SObjectType));
        mockSSS.setParent('Product__r', mockProduct);

        return mockSSS;
    }

    private static sfab_FabricatedSObject getMockUAL() {
        sfab_FabricatedSObject mockUal = new sfab_FabricatedSObject(Utility_Account_Log__c.class);

        return mockUal;
    }

    private static sfab_FabricatedSObject getMockUAS(Boolean singleProduct) {
        String sssId = singleProduct ? 'singleSSS' : 'multiSSS';
        String ualId = 'a1b000000000000AAA';
        String uasId = '1uasTestId';

        sfab_FabricatedSObject mockUAL = getMockUAL();
        sfab_FabricatedSObject mockSSS = getMockSSS(singleProduct);

        sfab_FabricatedSObject mockUAS = new sfab_FabricatedSObject(Utility_Account_Subscription__c.class);
        mockUAS.setField(Utility_Account_Subscription__c.Id, uasId);
        mockUAS.setField(Utility_Account_Subscription__c.Name, uasId);
        mockUAS.setField(Utility_Account_Subscription__c.Utility_Account_Log__c, ualId);
        mockUAS.setParent('Utility_Account_Log__r', mockUAL);
        mockUAS.setField(Utility_Account_Subscription__c.Shared_Solar_System__c, sssId);
        mockUAS.setParent('Shared_Solar_System__r', mockSSS);

        return mockUAS;
    }



    @IsTest
    private static void testSingleSubUasNoSibling() {
        List<Utility_Account_Subscription__c> newList = new List<Utility_Account_Subscription__c>();

        sfab_FabricatedSObject mockUAS = getMockUAS(true);

        Utility_Account_Subscription__c uas = (Utility_Account_Subscription__c) mockUAS.toSObject();
        newList.add(uas);

        UtilityAccountSubscriptionHandler.ualSelector = (UALSelector) Test.createStub(UALSelector.class, new MockUALSelector(false, false));
        UtilityAccountSubscriptionHandler.sssSelector = (SharedSolarSystemsSelector) Test.createStub(SharedSolarSystemsSelector.class, new MockedSSSSelector());

        Test.startTest();
            UtilityAccountSubscriptionHandler handler = new UtilityAccountSubscriptionHandler(null, newList, TriggerOperation.BEFORE_INSERT);
            handler.verifyUALSubscriptionType();
        Test.stopTest();

        for (Utility_Account_Subscription__c sub : newList) {
            List<Database.Error> errors = sub.getErrors();
            System.assertEquals(0, errors.size(), 'There should only be no errors associated with the subscription order since there were no existing subscriptions for the related UAL');
        }


    }

    @IsTest
    private static void testSingleSubUasExistingSibling() {
        List<Utility_Account_Subscription__c> newList = new List<Utility_Account_Subscription__c>();

        sfab_FabricatedSObject mockUAS = getMockUAS(true);

        Utility_Account_Subscription__c uas = (Utility_Account_Subscription__c) mockUAS.toSObject();
        newList.add(uas);

        UtilityAccountSubscriptionHandler.ualSelector = (UALSelector) Test.createStub(UALSelector.class, new MockUALSelector(true, false));
        UtilityAccountSubscriptionHandler.sssSelector = (SharedSolarSystemsSelector) Test.createStub(SharedSolarSystemsSelector.class, new MockedSSSSelector());

        Test.startTest();
        UtilityAccountSubscriptionHandler handler = new UtilityAccountSubscriptionHandler(null, newList, TriggerOperation.BEFORE_INSERT);
        handler.verifyUALSubscriptionType();
        Test.stopTest();

        for (Utility_Account_Subscription__c sub : newList) {
            List<Database.Error> errors = sub.getErrors();
            System.assertEquals(1, errors.size(), 'There should only an error associated with the subscription order since the related UAL already had a child UAS and the new UAS only allowed single subs');
            Database.Error error = errors.get(0);
            System.assert(error.getMessage().contains(ERROR_MSG), 'Error message should match the subscription failure error msg');
        }


    }

    @IsTest
    private static void testSingleSubUasExistingMultiSibling() {
        List<Utility_Account_Subscription__c> newList = new List<Utility_Account_Subscription__c>();

        sfab_FabricatedSObject mockUAS = getMockUAS(true);

        Utility_Account_Subscription__c uas = (Utility_Account_Subscription__c) mockUAS.toSObject();
        newList.add(uas);

        UtilityAccountSubscriptionHandler.ualSelector = (UALSelector) Test.createStub(UALSelector.class, new MockUALSelector(true, true));
        UtilityAccountSubscriptionHandler.sssSelector = (SharedSolarSystemsSelector) Test.createStub(SharedSolarSystemsSelector.class, new MockedSSSSelector());

        Test.startTest();
        UtilityAccountSubscriptionHandler handler = new UtilityAccountSubscriptionHandler(null, newList, TriggerOperation.BEFORE_INSERT);
        handler.verifyUALSubscriptionType();
        Test.stopTest();

        for (Utility_Account_Subscription__c sub : newList) {
            List<Database.Error> errors = sub.getErrors();
            System.assertEquals(1, errors.size(), 'There should an error associated with the subscription order since the new UAS only allowed single subs and there were existing UAS records on the related UAL');
            Database.Error error = errors.get(0);
            System.assert(error.getMessage().contains(ERROR_MSG), 'Error message should match the subscription failure error msg');
        }


    }

    @IsTest
    private static void testMultiSubUasNoSibling() {
        List<Utility_Account_Subscription__c> newList = new List<Utility_Account_Subscription__c>();

        sfab_FabricatedSObject mockUAS = getMockUAS(false);

        Utility_Account_Subscription__c uas = (Utility_Account_Subscription__c) mockUAS.toSObject();
        newList.add(uas);

        UtilityAccountSubscriptionHandler.ualSelector = (UALSelector) Test.createStub(UALSelector.class, new MockUALSelector(false, false));
        UtilityAccountSubscriptionHandler.sssSelector = (SharedSolarSystemsSelector) Test.createStub(SharedSolarSystemsSelector.class, new MockedSSSSelector());

        Test.startTest();
        UtilityAccountSubscriptionHandler handler = new UtilityAccountSubscriptionHandler(null, newList, TriggerOperation.BEFORE_INSERT);
        handler.verifyUALSubscriptionType();
        Test.stopTest();

        for (Utility_Account_Subscription__c sub : newList) {
            List<Database.Error> errors = sub.getErrors();
            System.assertEquals(0, errors.size(), 'There should only be no errors associated with the subscription order since there were no existing subscriptions for the related UAL');
        }


    }

    @IsTest
    private static void testMultiSubUasExistingSingleSibling() {
        List<Utility_Account_Subscription__c> newList = new List<Utility_Account_Subscription__c>();

        sfab_FabricatedSObject mockUAS = getMockUAS(false);


        Utility_Account_Subscription__c uas = (Utility_Account_Subscription__c) mockUAS.toSObject();
        newList.add(uas);

        UtilityAccountSubscriptionHandler.ualSelector = (UALSelector) Test.createStub(UALSelector.class, new MockUALSelector(true, false));
        UtilityAccountSubscriptionHandler.sssSelector = (SharedSolarSystemsSelector) Test.createStub(SharedSolarSystemsSelector.class, new MockedSSSSelector());


        Test.startTest();
        UtilityAccountSubscriptionHandler handler = new UtilityAccountSubscriptionHandler(null, newList, TriggerOperation.BEFORE_INSERT);
        handler.verifyUALSubscriptionType();
        Test.stopTest();

        for (Utility_Account_Subscription__c sub : newList) {
            List<Database.Error> errors = sub.getErrors();
            System.assertEquals(1, errors.size(), 'There should only an associated with the subscription order since the existing UAS on the related UAL only allowed single subs');
            Database.Error error = errors.get(0);
            System.assert(error.getMessage().contains(ERROR_MSG), 'Error message should match the subscription failure error msg');
        }


    }

    @IsTest
    private static void testMultiSubUasExistingMultiSibling() {
        List<Utility_Account_Subscription__c> newList = new List<Utility_Account_Subscription__c>();

        sfab_FabricatedSObject mockUAS = getMockUAS(false);

        Utility_Account_Subscription__c uas = (Utility_Account_Subscription__c) mockUAS.toSObject();
        newList.add(uas);

        UtilityAccountSubscriptionHandler.ualSelector = (UALSelector) Test.createStub(UALSelector.class, new MockUALSelector(true, true));
        UtilityAccountSubscriptionHandler.sssSelector = (SharedSolarSystemsSelector) Test.createStub(SharedSolarSystemsSelector.class, new MockedSSSSelector());


        Test.startTest();
        UtilityAccountSubscriptionHandler handler = new UtilityAccountSubscriptionHandler(null, newList, TriggerOperation.BEFORE_INSERT);
        handler.verifyUALSubscriptionType();
        Test.stopTest();

        for (Utility_Account_Subscription__c sub : newList) {
            List<Database.Error> errors = sub.getErrors();
            System.assertEquals(0, errors.size(), 'There should only be no errors associated with the subscription order since the new UAS allows multiple subs and the existing UAS also allows multiple');
        }


    }

    @IsTest
    private static void testBatchSingleSubNoExistingSibling() {
        List<Utility_Account_Subscription__c> newList = new List<Utility_Account_Subscription__c>();

        sfab_FabricatedSObject mockUAS1 = getMockUAS(true);
        sfab_FabricatedSObject mockUAS2 = getMockUAS(true);
        mockUAS2.setField(Utility_Account_Subscription__c.Id, 'secondUASId');

        Utility_Account_Subscription__c uas1 = (Utility_Account_Subscription__c) mockUAS1.toSObject();
        Utility_Account_Subscription__c uas2 = (Utility_Account_Subscription__c) mockUAS2.toSObject();
        newList.add(uas1);
        newList.add(uas2);

        UtilityAccountSubscriptionHandler.ualSelector = (UALSelector) Test.createStub(UALSelector.class, new MockUALSelector(false, false));
        UtilityAccountSubscriptionHandler.sssSelector = (SharedSolarSystemsSelector) Test.createStub(SharedSolarSystemsSelector.class, new MockedSSSSelector());


        Test.startTest();
        UtilityAccountSubscriptionHandler handler = new UtilityAccountSubscriptionHandler(null, newList, TriggerOperation.BEFORE_INSERT);
        handler.verifyUALSubscriptionType();
        Test.stopTest();

        for (Utility_Account_Subscription__c sub : newList) {
            List<Database.Error> errors = sub.getErrors();
            System.assertEquals(1, errors.size(), 'There should an error associated with the subscription order since two UAS records relating to the same UAL were being entered at the same time and they only allow a single sub');
            Database.Error error = errors.get(0);
            System.assert(error.getMessage().contains(ERROR_MSG), 'Error message should match the subscription failure error msg');
        }


    }

    @IsTest
    private static void testBatchMultiSubExistingSingleSibling() {
        List<Utility_Account_Subscription__c> newList = new List<Utility_Account_Subscription__c>();

        sfab_FabricatedSObject mockUAS1 = getMockUAS(false);
        sfab_FabricatedSObject mockUAS2 = getMockUAS(false);
        mockUAS2.setField(Utility_Account_Subscription__c.Id, 'secondUASId');

        Utility_Account_Subscription__c uas1 = (Utility_Account_Subscription__c) mockUAS1.toSObject();
        Utility_Account_Subscription__c uas2 = (Utility_Account_Subscription__c) mockUAS2.toSObject();
        newList.add(uas1);
        newList.add(uas2);

        UtilityAccountSubscriptionHandler.ualSelector = (UALSelector) Test.createStub(UALSelector.class, new MockUALSelector(true, false));
        UtilityAccountSubscriptionHandler.sssSelector = (SharedSolarSystemsSelector) Test.createStub(SharedSolarSystemsSelector.class, new MockedSSSSelector());


        Test.startTest();
        UtilityAccountSubscriptionHandler handler = new UtilityAccountSubscriptionHandler(null, newList, TriggerOperation.BEFORE_INSERT);
        handler.verifyUALSubscriptionType();
        Test.stopTest();

        for (Utility_Account_Subscription__c sub : newList) {
            List<Database.Error> errors = sub.getErrors();
            System.assertEquals(1, errors.size(), 'There should an error associated with the subscription order since the related UAL already had a UAS with a single sub allowed');
            Database.Error error = errors.get(0);
            System.assert(error.getMessage().contains(ERROR_MSG), 'Error message should match the subscription failure error msg');
        }


    }

    @IsTest
    private static void testBatchSingleSubExistingSibling() {
        List<Utility_Account_Subscription__c> newList = new List<Utility_Account_Subscription__c>();

        sfab_FabricatedSObject mockUAS1 = getMockUAS(true);
        sfab_FabricatedSObject mockUAS2 = getMockUAS(true);
        mockUAS2.setField(Utility_Account_Subscription__c.Id, 'secondUASId');

        Utility_Account_Subscription__c uas1 = (Utility_Account_Subscription__c) mockUAS1.toSObject();
        Utility_Account_Subscription__c uas2 = (Utility_Account_Subscription__c) mockUAS2.toSObject();
        newList.add(uas1);
        newList.add(uas2);

        UtilityAccountSubscriptionHandler.ualSelector = (UALSelector) Test.createStub(UALSelector.class, new MockUALSelector(true, true));
        UtilityAccountSubscriptionHandler.sssSelector = (SharedSolarSystemsSelector) Test.createStub(SharedSolarSystemsSelector.class, new MockedSSSSelector());


        Test.startTest();
        UtilityAccountSubscriptionHandler handler = new UtilityAccountSubscriptionHandler(null, newList, TriggerOperation.BEFORE_INSERT);
        handler.verifyUALSubscriptionType();
        Test.stopTest();

        for (Utility_Account_Subscription__c sub : newList) {
            List<Database.Error> errors = sub.getErrors();
            System.assertEquals(1, errors.size(), 'There should an error associated with the subscription order since the related UAL already had a UAS with a Single Sub allowed');
            Database.Error error = errors.get(0);
            System.assert(error.getMessage().contains(ERROR_MSG), 'Error message should match the subscription failure error msg');
        }


    }

    public class MockedSSSSelector extends MockProvider {
        public override Object handleMethodCall(MethodCall methodCall) {
            switch on methodCall.stubbedMethodName {
                when 'getSSSMap' {

                    sfab_FabricatedSObject mockProduct1 = new sfab_FabricatedSObject(Product2.class);
                    mockProduct1.setField(Product2.Utility_Account_Subscription_Type__c, 'Single subscription per Utility Account');

                    sfab_FabricatedSObject mockProduct2 = new sfab_FabricatedSObject(Product2.class);
                    mockProduct2.setField(Product2.Utility_Account_Subscription_Type__c, 'Multiple subscriptions per Utility Account');

                    sfab_FabricatedSObject mockSSS1 = new sfab_FabricatedSObject(Shared_Solar_System__c.class);
                    mockSSS1.setField(Shared_Solar_System__c.Id, 'singleSSS');
                    mockSSS1.setParent('Product__r', mockProduct1);
                    Shared_Solar_System__c sss1 = (Shared_Solar_System__c) mockSSS1.toSObject();

                    sfab_FabricatedSObject mockSSS2 = new sfab_FabricatedSObject(Shared_Solar_System__c.class);
                    mockSSS2.setField(Shared_Solar_System__c.Id, 'multiSSS');
                    mockSSS2.setParent('Product__r', mockProduct2);
                    Shared_Solar_System__c sss2 = (Shared_Solar_System__c) mockSSS2.toSObject();

                    return new Map<Id, Shared_Solar_System__c>{
                        sss1.Id => sss1,
                        sss2.Id => sss2
                    };
                }
            }
            return null;
        }
    }

    public class MockUALSelector extends MockProvider {
        private Boolean ualHasChildSubs;
        private Boolean multiSubAllowed;
        public MockUALSelector(Boolean ualHasChildSubs, Boolean multiSubAllowed) {
            this.ualHasChildSubs = ualHasChildSubs;
            this.multiSubAllowed = multiSubAllowed;
        }
        public override Object handleMethodCall(MethodCall methodCall) {
            switch on methodCall.stubbedMethodName {
                when 'selectUALSWithActiveUASMap' {
                    List<sfab_FabricatedSObject> mockUasList = new List<sfab_FabricatedSObject>();
                    sfab_FabricatedSObject uas;
                    if (ualHasChildSubs) {
                        uas = getUASWithProduct();
                        mockUasList.add(uas);
                    }

                    String ualId = 'a1b000000000000AAA';
                    sfab_FabricatedSObject mockUal = new sfab_FabricatedSObject(Utility_Account_Log__c.class);
                    mockUal.setField(Utility_Account_Log__c.Id, ualId);
                    mockUal.setChildren('Utility_Account_Subscriptions__r', mockUasList);
                    Utility_Account_Log__c ual = (Utility_Account_Log__c) mockUal.toSObject();

                    Map<Id,Utility_Account_Log__c> ualMap = new Map<Id,Utility_Account_Log__c>();
                    ualMap.put(ualId, ual);

                    return ualMap;
                }
            }
            return null;
        }

        private sfab_FabricatedSObject getUASWithProduct() {
            String productSubType = multiSubAllowed ? 'Multiple subscriptions per Utility Account' : 'Single subscription per Utility Account';
            String sssId = multiSubAllowed ? 'multiSSS' : 'singleSSS';

            String productId = Util.getFakeId(Product2.SObjectType);
            sfab_FabricatedSObject mockProduct = new sfab_FabricatedSObject(Product2.class);
            mockProduct.setField(Product2.Utility_Account_Subscription_Type__c, productSubType);
            mockProduct.setField(Product2.Id, productId);

            sfab_FabricatedSObject mockSSS = new sfab_FabricatedSObject(Shared_Solar_System__c.class);
            mockSSS.setField(Shared_Solar_System__c.Id, sssId);
            mockSSS.setParent('Product__r', mockProduct);
            mockSSS.setField(Shared_Solar_System__c.Product__c, productId);

            String uasId = '1mockSelectorId';
            sfab_FabricatedSObject mockUAS = new sfab_FabricatedSObject(Utility_Account_Subscription__c.class);
            mockUAS.setField(Utility_Account_Subscription__c.Id, uasId);
            mockUAS.setField(Utility_Account_Subscription__c.Name, uasId);
            mockUAS.setField(Utility_Account_Subscription__c.Next_Schedule_Z_Status__c, 'Active Subscription');
            mockUAS.setField(Utility_Account_Subscription__c.Shared_Solar_System__c, sssId);
            mockUAS.setParent('Shared_Solar_System__r', mockSSS);

            return mockUAS;

        }
    }

}