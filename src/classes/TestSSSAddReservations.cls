@IsTest
private class TestSSSAddReservations {
    static testMethod void SSSAddReservations() {
        Utility__c eversource = new Utility__c(
            Name = 'Eversource',
            Number_of_Decimal_Places__c = 2
        );

        Utility__c nationalGrid = new Utility__c(
            Name = 'National Grid',
            Number_of_Decimal_Places__c = 2
        );

        insert new List<Utility__c>{
            eversource, nationalGrid
        };

        Utility_NMC_Tariff__c everbillNMC = new Utility_NMC_Tariff__c(
            Name = 'Eversource SEMA Class 2',
            Utility__c = 'Eversource',
            Class__c = 'Class 2',
            Value_of_Net_Metering_Credit__c = 0.1848,
            Current_Billing_Rate__c = true
        );

        insert everbillNMC;

        Account myAccount = new Account(Name = 'Test Account');
        insert myAccount;

        LASERCA__Personal_Credit_Report__c pcr1 = new LASERCA__Personal_Credit_Report__c(
            LASERCA__Credit_Score_TransUnion__c = '700'
        );

        insert pcr1;

        Date myDate = Date.newInstance(2015, 2, 17);

        Shared_Solar_System__c myProject = new Shared_Solar_System__c(
            Name = 'Oxford Barrett St. P1',
            Service_Territories__c = 'SEMA',
            Open__c = true,
            Reserved_Capacity_kW_DC__c = '0',
            Capacity_Committed_kW_DC__c = 0,
            Total_System_Size_kWh_DC__c = 1445.86,
            Total_System_Size_kW_AC__c = 996,
            Utility__c = eversource.Id,
            Credit_Score_Requirement__c = 200,
            Assignment_Order__c = '1',
            Expected_Yield_kWh_kW__c = 1300,
            Assemblage_Count__c = 1,
            Sales_Partners__c = 'All',
            Maximum_Subscription_Assemblage__c = 25
        );

        insert myProject;

        Opportunity newOpportunity = new Opportunity(
            Name = 'Cole',
            Account = myAccount,
            Project_Assignment__c = 'Manual',
            Type = 'New Business',
            StageName = 'Complete',
            Product_Line__c = 'Community Solar',
            Customer_Group__c = 'Residential',
            NMC_Tariff__c = everbillNMC.Id,
            Personal_Credit_Report2__c = pcr1.Id,
            Waitlist__c = false,
            CloseDate = myDate,
            Shared_Solar_System__c = myProject.Id
        );

        insert newOpportunity;

        Utility_Account_Log__c ual = new Utility_Account_Log__c(
            Account__c = myAccount.Id,
            Annual_Cost_of_Electricity__c = 10000,
            Name_on_Account__c = 'Joey Chan'
        );
        insert ual;

        Utility_Account_Subscription__c uas = new Utility_Account_Subscription__c(
            Utility_Account_Log__c = ual.Id,
            Name = '102342340',
            Opportunity__c = newOpportunity.Id,
            Customer_Subscription_KW_DC_STATIC__c = 24,
            Subscribed_Annual_Cost_of_Electricity__c = 5765.76,
            Annual_Cost_of_Electricity__c = 1300
        );
        insert uas;

        Opportunity newOpportunity3 = new Opportunity(
            Name = 'Cole2',
            Account = myAccount,
            Project_Assignment__c = 'Manual',
            Type = 'New Business',
            StageName = 'Complete',
            Product_Line__c = 'Community Solar',
            Customer_Group__c = 'Anchor',
            NMC_Tariff__c = everbillNMC.Id,
            Personal_Credit_Report2__c = pcr1.Id,
            Waitlist__c = false,
            CloseDate = myDate,
            Shared_Solar_System__c = myProject.Id
        );

        insert newOpportunity3;

        Utility_Account_Log__c ual2 = new Utility_Account_Log__c(
            Account__c = myAccount.Id,
            Annual_Cost_of_Electricity__c = 500000,
            Name_on_Account__c = 'Anchor'
        );
        insert ual2;

        Utility_Account_Subscription__c uas2 = new Utility_Account_Subscription__c(
            Utility_Account_Log__c = ual2.Id,
            Name = '102342340',
            Opportunity__c = newOpportunity3.Id,
            Customer_Subscription_KW_DC_STATIC__c = 22,
            Subscribed_Annual_Cost_of_Electricity__c = 5285.28,
            Annual_Cost_of_Electricity__c = 500000
        );
        insert uas2;

        update myProject;

        List <Shared_Solar_System__c> ssslist = [
            SELECT Id, Capacity_Committed_kW_DC__c, Anchor_Capacity_Reserved__c, Reserved_Capacity_kW_DC__c
            FROM Shared_Solar_System__c
        ];

        Test.startTest();
        for (Shared_Solar_System__c proj : ssslist) {
            System.assertEquals(24, proj.Capacity_Committed_kW_DC__c);
            System.assertEquals('0', proj.Reserved_Capacity_kW_DC__c);
            System.assertEquals(22, proj.Anchor_Capacity_Reserved__c);
        }
        Test.stopTest();
    }
}