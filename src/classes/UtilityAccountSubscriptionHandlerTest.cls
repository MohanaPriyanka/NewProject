/**
 * Created by SarahRenfro on 12/2/2019.
 */

@IsTest
public class UtilityAccountSubscriptionHandlerTest {
    @TestSetup
    public static void setupData() {
        Utility__c ngrid = new Utility__c(
            Name = 'National Grid',
            Number_of_Decimal_Places__c = 2
        );
        insert ngrid;

        Account clientAccount = new Account(name = 'Test Client');
        insert clientAccount;

        Partner__c partner = new Partner__c(
            Name = 'Some Partner'
        );
        insert partner;

        Utility_NMC_Tariff__c eversizeNMC = new Utility_NMC_Tariff__c (Name = 'Eversource SEMA Class 2',
            Utility__c = 'Eversource',
            Class__c = 'Class 2',
            Value_of_Net_Metering_Credit__c = 0.1848,
            Sizing_Rate__c = TRUE);
        insert eversizeNMC;

        Shared_Solar_System__c sss1 = new Shared_Solar_System__c(Name = 'Project A',
            Service_Territory__c = 'SEMA',
            Service_Territories__c = 'SEMA',
            Open__c = true,
            Client_Account__c = clientAccount.Id,
            Utility_NMC_Tariff__c = eversizeNMC.Id,
            Billing_Method__c = 'NMC',
            Reserved_Capacity_kW_DC__c = '10',
            Capacity_Committed_kW_DC__c = 0,
            Total_System_Size_kWh_DC__c = 1445.86,
            Total_System_Size_kW_AC__c = 1000,
            Utility__c = ngrid.Id,
            Credit_Score_Requirement__c = 300,
            Assignment_Order__c = '1',
            Expected_Yield_kWh_kW__c = 1300,
            Assemblage_Count__c = 1,
            Sales_Partners__c = 'All',
            Maximum_Subscription_Capacity_kWDC__c = 25);

        insert sss1;

        Id parentAccountRT =
            Schema.SObjectType.Account.getRecordTypeInfosByName().get('Parent Account').getRecordTypeId();

        Account accountParent = new Account(name = 'Account Parent',
            RecordTypeId = parentAccountRT);

        Account accountA = new Account(name = 'Account A',
            Parent_Account__c = accountParent.Id);

        Account accountB = new Account(name = 'Account B',
            Parent_Account__c = accountParent.Id);

        insert new List<Account> {accountParent, accountA, accountB};

        Product2 normalCSProduct = new Product2(Name = 'BlueWave Community Solar',
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
            Customer_Subscription_Type__c = 'kWh',
            Monthly_Late_Fee__c = 1);
        insert normalCSProduct;

        Opportunity opportunityone =
            new Opportunity(Name = 'AOpp',
                AccountId = accountA.Id,
                Shared_Solar_System__c = sss1.Id,
                StageName = 'Complete',
                NMC_Tariff__c = eversizeNMC.Id,
                Partner_tag_lookup__c = partner.Id,
                Customer_Group__c = 'Residential',
                Product__c = normalCSProduct.Id,
                Product_Line__c = 'Community Solar',
                CloseDate = System.today());

        insert opportunityone;

        Utility_Account_Log__c ualog =
            new Utility_Account_Log__c(Name = '0000234',
                Account__c = accountA.Id,
                Annual_Cost_of_Electricity__c = 10000,
                Name_on_Account__c = 'A Testcase');

        insert ualog;

        Utility_Account_Subscription__c uasone =
            new Utility_Account_Subscription__c(Name = '0000234',
                Utility_Account_Log__c = ualog.Id,
                Opportunity__c = opportunityone.Id,
                Next_Schedule_Z_Status__c = 'Active Subscription',
                Annual_kwh_subscription_future__c = 4000,
                Calculated_Annual_Cost_of_Electricity__c = 4000,
                Subscribed_Annual_Cost_of_Electricity__c = 4000);
        insert uasone;

        Opportunity opportunitytwo =
            new Opportunity(Name = 'BOpp',
                AccountId = accountB.Id,
                Shared_Solar_System__c = sss1.Id,
                StageName = 'Complete',
                NMC_Tariff__c = eversizeNMC.Id,
                Partner_tag_lookup__c = partner.Id,
                Customer_Group__c = 'Residential',
                Product__c = normalCSProduct.Id,
                Product_Line__c = 'Community Solar',
                CloseDate = System.today());
        insert opportunitytwo;

        Utility_Account_Log__c ualogTwo =
            new Utility_Account_Log__c(Name = '0000236',
                Account__c = accountB.Id,
                Annual_Cost_of_Electricity__c = 20000,
                Name_on_Account__c = 'B Testcase');

        insert ualogTwo;

        Utility_Account_Subscription__c uasTwo =
            new Utility_Account_Subscription__c(Name = '0000236',
                Utility_Account_Log__c = ualogTwo.Id,
                Opportunity__c = opportunitytwo.Id,
                Next_Schedule_Z_Status__c = 'Active Subscription',
                Annual_kwh_subscription_future__c = 4000,
                Calculated_Annual_Cost_of_Electricity__c = 4000,
                Subscribed_Annual_Cost_of_Electricity__c = 4000);
        insert uasTwo;
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
                Annual_kwh_subscription_future__c = 4000,
                Calculated_Annual_Cost_of_Electricity__c = 4000,
                Subscribed_Annual_Cost_of_Electricity__c = 4000);
        insert uasone;

        Utility_Account_Subscription__c checkUAS = [
            SELECT Id, Shared_Solar_System__c
            FROM Utility_Account_Subscription__c
            WHERE Id = : uasone.Id
            LIMIT 1
        ];

        System.assertEquals(opp.Shared_Solar_System__c, checkUAS.Shared_Solar_System__c);
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
                Annual_kwh_subscription_future__c = 4000,
                Calculated_Annual_Cost_of_Electricity__c = 4000,
                Subscribed_Annual_Cost_of_Electricity__c = 4000);
        insert uasone;

        Utility_Account_Subscription__c nullUAS = [
            SELECT Id, Shared_Solar_System__c
            FROM Utility_Account_Subscription__c
            WHERE Id = : uasone.id
            LIMIT 1
        ];

        //Should be null because opp is null
        System.assertEquals(null, nullUAS.Shared_Solar_System__c);

        nullUAS.Opportunity__c = opp.Id;
        update nullUAS;

        Utility_Account_Subscription__c checkUAS = [
            SELECT Id, Shared_Solar_System__c
            FROM Utility_Account_Subscription__c
            WHERE Id = : uasone.id
            LIMIT 1
        ];

        //Will now be populated because UAS has opportunity now
        System.assertNotEquals(null, checkUAS.Shared_Solar_System__c);
        System.assertEquals(opp.Shared_Solar_System__c, checkUAS.Shared_Solar_System__c);

    }

    @IsTest
    public static void testRollupAnchorUASes(){
        Opportunity anchorOpp = [
            SELECT Id, Customer_Group__c, AccountId
            FROM Opportunity
            WHERE Name = 'BOpp'
            LIMIT 1
        ];
        System.assertNotEquals(null, anchorOpp.AccountId);
        anchorOpp.Customer_Group__c = 'Anchor';
        update anchorOpp;

        Utility_Account_Subscription__c anchorUAS = [
            SELECT Id, Customer_Group__c, Opportunity__c,
                Opportunity__r.AccountId, Annual_Subscription_Production_Summary__c
            FROM Utility_Account_Subscription__c
            WHERE Customer_Group__c = 'Anchor'
            LIMIT 1
        ];

        System.assertNotEquals(null, anchorUAS);
        System.assertEquals(null, anchorUAS.Annual_Subscription_Production_Summary__c);
        System.assertEquals(anchorOpp.Id, anchorUAS.Opportunity__c);

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

        UtilityAccountSubscriptionHandler.rollupAnchorUASes();

        anchorUAS = [
            SELECT Id, Customer_Group__c, Opportunity__c,
                Opportunity__r.AccountId, Annual_Subscription_Production_Summary__c
            FROM Utility_Account_Subscription__c
            WHERE Customer_Group__c = 'Anchor'
            LIMIT 1
        ];

        System.assertEquals(300, anchorUAS.Annual_Subscription_Production_Summary__c);
    }
}