/**
 * Created by SarahRenfro on 11/15/2019.
 */

@IsTest
private class SubscriptionOrderServiceTest {
    @TestSetup
    public static void setupData() {
        Utility__c ngrid = new Utility__c(
            Name = 'National Grid',
            Number_of_Decimal_Places__c = 2
        );
        insert ngrid;

        Account clientAccount = new Account(name = 'Test Client');
        insert clientAccount;

        Shared_Solar_System__c sss1 = new Shared_Solar_System__c(Name = 'Project A',
            Service_Territory__c = 'SEMA',
            Service_Territories__c = 'SEMA',
            Open__c = true,
            Client_Account__c = clientAccount.Id,
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
            Maximum_Subscription_Assemblage__c = 25);

        insert sss1;

        Id parentAccountRT =
            Schema.SObjectType.Account.getRecordTypeInfosByName().get('Parent Account').getRecordTypeId();

        Account accountParent = new Account(name = 'Account Parent',
            RecordTypeId = parentAccountRT);

        Account accountA = new Account(name = 'Account A',
            Parent_Account__c = accountParent.Id);

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
            Monthly_Late_Fee__c = 1);
        insert normalCSProduct;

        Opportunity opportunityone =
            new Opportunity(Name = 'AOpp',
                AccountId = accountA.Id,
                Shared_Solar_System__c = sss1.Id,
                StageName = 'Complete',
                Customer_Group__c = 'Residential',
                Product__c = normalCSProduct.Id,
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
                Shared_Solar_System__c = sss1.Id,
                Next_Schedule_Z_Status__c = 'Active Subscription',
                Annual_kwh_subscription_future__c = 4000,
                Calculated_Annual_Cost_of_Electricity__c = 4000,
                Subscribed_Annual_Cost_of_Electricity__c = 4000);
        insert uasone;

    }

        @IsTest
        static void testSubscriptionOrderInsert() {

            Utility_Account_Subscription__c uas = [
                SELECT Id, Shared_Solar_System__c, Opportunity__c, Name, Shared_Solar_System__r.Client_Account__c
                FROM Utility_Account_Subscription__c
                LIMIT 1
            ];

            Shared_Solar_System__c sss = [
                SELECT Id, Client_Account__c, Expected_Yield_kWh_kW__c, Total_System_Size_kWh_DC__c,
                    Utility__r.Number_of_Decimal_Places__c
                FROM Shared_Solar_System__c
                LIMIT 1
            ];

            Opportunity opp = [
                SELECT Id, NMC_Tariff__c, NMC_Tariff__r.Value_of_NMC__c, Product__c
                FROM Opportunity
                WHERE Id = :uas.Opportunity__c
                LIMIT 1
            ];

            Subscription_Order__c so = new Subscription_Order__c(
                Utility_Account_Subscription__c = uas.Id
            );

            insert so;

            Subscription_Order__c checkSO = [
                SELECT Id, Client_Account__c, Expected_Yield_kWh_kW__c, Total_System_Size_kW_DC__c, Utility_NMC_Tariff__c,
                    Utility_Number_of_Decimal_Places__c, Value_of_NMC__c, Product__c
                FROM Subscription_Order__c
                LIMIT 1
            ];

            System.assertEquals(sss.Client_Account__c, checkSO.Client_Account__c);
            System.assertEquals(sss.Expected_Yield_kWh_kW__c, checkSO.Expected_Yield_kWh_kW__c);
            System.assertEquals(sss.Total_System_Size_kWh_DC__c, checkSO.Total_System_Size_kW_DC__c);
            System.assertEquals(sss.Utility__r.Number_of_Decimal_Places__c, checkSO.Utility_Number_of_Decimal_Places__c );
            System.assertEquals(opp.NMC_Tariff__c, checkSO.Utility_NMC_Tariff__c);
            System.assertEquals(opp.NMC_Tariff__r.Value_of_NMC__c, checkSO.Value_of_NMC__c);
            System.assertEquals(opp.Product__c, checkSO.Product__c);

    }
}