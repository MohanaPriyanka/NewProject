/**
 * Created by SarahRenfro on 4/17/2020.
 *
 * Details: This testclass creates UASes that mimic the subscription sizing bugs we have experienced and since fixed.
 *
 */


@IsTest
public with sharing class SubscriptionSizingTestclass {

    @TestSetup
    public static void testSetup() {
        FeatureService.featureSelector = (FeatureSelector) Test.createStub(FeatureSelector.class, new FeatureServiceTest.MockCustomFeatureSelector(true));

        Partner__c partner1 = new Partner__c (
            Name = 'BlueWave Test Partner',
            Email__c = 'bwtest@email.com'
        );
        insert partner1;

        Utility__c eversource = new Utility__c(
            Name = 'Eversource',
            Number_of_Decimal_Places__c = 2
        );
        insert eversource;

        Utility_NMC_Tariff__c kwhSizingMethodR1 = new Utility_NMC_Tariff__c (Name = 'kwh Tariff? ',
            Utility__c = 'Eversource',
            Class__c = 'Class 1',
            Value_of_Net_Metering_Credit__c = 0.1137,
            Size_Ratio__c = 1.2,
            Current_Billing_Rate__c = TRUE
        );


        Utility_NMC_Tariff__c kwhSizingMethodR2 = new Utility_NMC_Tariff__c (Name = 'kwh Tariff? ',
            Utility__c = 'Eversource',
            Class__c = 'Class 2',
            Value_of_Net_Metering_Credit__c = 0.1137,
            Size_Ratio__c = 1.5,
            Current_Billing_Rate__c = TRUE,
            Customer_Type__c = 'Residential'
        );

        Utility_NMC_Tariff__c costSizingMethod = new Utility_NMC_Tariff__c (Name = 'Cost Tariff',
            Utility__c = 'Eversource',
            Class__c = 'Class 2',
            Value_of_Net_Metering_Credit__c = 0.1812,
            Current_Billing_Rate__c = TRUE);
        insert new List<Utility_NMC_Tariff__c>{kwhSizingMethodR1, kwhSizingMethodR2, costSizingMethod};

        Rate_Class__c rateClassR1 = new Rate_Class__c(
            Name = 'Eversource R1',
            Utility_NMC_Tariff__c = kwhSizingMethodR1.Id
        );

        Rate_Class__c rateClassR2 = new Rate_Class__c(
            Name = 'Eversource R2',
            Utility_NMC_Tariff__c = kwhSizingMethodR2.Id
        );

        insert new List<Rate_Class__c> {rateClassR1, rateClassR2};


        Product2 costProduct = new Product2( Name = 'BlueWave Community Solar',
            Family = 'Community Solar',
            Product_Type__c = 'Community Solar',
            State__c = 'MA',
            Customer_Subscription_Type__c = 'Electricity Cost ($)',
            Sizing_Method__c = 'Project Ratio',
            ProductCode = 'CS - BlueWave - 10%',
            IsActive = True,
            Lender_of_Record__c = 'BlueWave',
            NMC_Discount__c = 10,
            Annual_kWh_Maximum__c = 100000000,
            NM_Rate_Floor__c = 0,
            Days_In_Bill_Period__c = 30,
            Monthly_Late_Fee__c = 1);

        Product2 kwhProduct = new Product2( Name = 'BlueWave Community Solar',
            Family = 'Community Solar',
            Product_Type__c = 'Community Solar',
            State__c = 'MA',
            Customer_Subscription_Type__c = 'kWh',
            Sizing_Method__c = 'Rate Class Ratio',
            ProductCode = 'CS - BlueWave - 10%',
            IsActive = True,
            Lender_of_Record__c = 'BlueWave',
            NMC_Discount__c = 10,
            Annual_kWh_Maximum__c = 100000000,
            NM_Rate_Floor__c = 0,
            Days_In_Bill_Period__c = 30,
            Monthly_Late_Fee__c = 1);

        insert new List<Product2>{costProduct, kwhProduct};

        //product tariffs --> to be used when testing sizing method flag being off
        Product_Tariff__c kwhProductTariff = new Product_Tariff__c(
            Product__c = kwhProduct.Id,
            Size_Ratio__c = 1.5,
            Utility_NMC_Tariff__c = kwhSizingMethodR2.Id
        );
        insert kwhProductTariff;

        Shared_Solar_System__c costSSS = new Shared_Solar_System__c(
            Service_Territory__c = 'SEMA',
            Service_Territories__c = 'SEMA',
            Open__c = true,
            Billing_Method__c = 'NMC',
            Reserved_Capacity_kW_DC__c = '10',
            Capacity_Committed_kW_DC__c = 0,
            Total_System_Size_kWh_DC__c = 1082.88,
            Total_System_Size_kW_AC__c  = 996,
            Utility__c = eversource.Id,
            Utility_NMC_Tariff__c = costSizingMethod.Id,
            Product__c = costProduct.Id,
            Credit_Score_Requirement__c = 300,
            Assignment_Order__c = '1',
            Expected_Yield_kWh_kW__c = 1300,
            Assemblage_Count__c = 1,
            Sales_Partners__c = 'All',
            Maximum_Subscription_Capacity_kWDC__c = 25
        );

        Shared_Solar_System__c kwhSSS = new Shared_Solar_System__c(
            Name = 'kWh Shared Solar System',
            Service_Territory__c = 'SEMA',
            Service_Territories__c = 'SEMA',
            Open__c = true,
            Billing_Method__c = 'kWh',
            Reserved_Capacity_kW_DC__c = '10',
            Capacity_Committed_kW_DC__c = 0,
            Total_System_Size_kWh_DC__c = 5832,
            Total_System_Size_kW_AC__c  = 996,
            Utility__c = eversource.Id,
            Utility_NMC_Tariff__c = kwhSizingMethodR1.Id,
            Product__c = kwhProduct.Id,
            Credit_Score_Requirement__c = 300,
            Assignment_Order__c = '1',
            Expected_Yield_kWh_kW__c = 1316,
            Assemblage_Count__c = 1,
            Sales_Partners__c = 'All',
            Maximum_Subscription_Capacity_kWDC__c = 25
        );

        Shared_Solar_System__c kwhSSSTwo = new Shared_Solar_System__c(
            Name = 'kWh Shared Solar System Two',
            Service_Territory__c = 'SEMA',
            Service_Territories__c = 'SEMA',
            Open__c = true,
            Billing_Method__c = 'kWh',
            Reserved_Capacity_kW_DC__c = '10',
            Capacity_Committed_kW_DC__c = 0,
            Total_System_Size_kWh_DC__c = 5832,
            Total_System_Size_kW_AC__c  = 996,
            Utility__c = eversource.Id,
            Utility_NMC_Tariff__c = kwhSizingMethodR1.Id,
            Product__c = kwhProduct.Id,
            Credit_Score_Requirement__c = 300,
            Assignment_Order__c = '2',
            Expected_Yield_kWh_kW__c = 1316,
            Assemblage_Count__c = 1,
            Sales_Partners__c = 'All',
            Maximum_Subscription_Capacity_kWDC__c = 25
        );
        //max kwh subscription = 25*1316 = 32900
        insert new List<Shared_Solar_System__c>{costSSS, kwhSSS, kwhSSSTwo};

        Load_U__c eversourceLZU = new Load_U__c(
            Name = '12345',
            LZ__c = 'SEMA'
        );
        insert eversourceLZU;

        ZipCode_Utility_Junction__c junction = new ZipCode_Utility_Junction__c(
            Load_Zone_Utility__c = eversourceLZU.Id,
            Utility__c = eversource.Id
        );
        insert junction;

        Lead switchLead = (Lead)TestFactory.createSObject(new Lead(
            LastName = 'Testcase',
            FirstName = 'Switch',
            Email = 'switch@email.com',
            Utility_relationship__c = eversource.Id,
            LASERCA__Home_Address__c = '123 Street',
            LASERCA__Home_City__c = 'Albany',
            LASERCA__Home_Zip__c = '12345',
            LASERCA__Home_State__c = 'NY',
            LoadZone__c = 'SEMA',
            LeadSource = 'Switch',
            Company = 'Switch Comp',
            Status = 'Sales Qualified',
            Partner_Lookup__c = partner1.Id,
            Product_line__c = 'Community Solar',
            Product__c = kwhProduct.Id,
            Parcel_Zip__c = '12345',
            Customer_type__c = 'Residential',
            Application_Type__c = 'Residential',
            System_Assignment__c = 'Automatic - Assignment Order'));
        insert switchLead;


        Opportunity opportunityA = new Opportunity(
            Name = 'Ashley Smith',
            Shared_Solar_System__c = kwhSSS.Id,
            NMC_Tariff__c = kwhSizingMethodR1.Id,
            StageName = 'Complete',
            Customer_Group__c = 'Residential',
            Product__c = kwhProduct.Id,
            CloseDate = System.today()
        );

        Opportunity opportunityB = new Opportunity(
            Name = 'Stephen Ward',
            Shared_Solar_System__c = kwhSSS.Id,
            NMC_Tariff__c = kwhSizingMethodR1.Id,
            StageName = 'Complete',
            Customer_Group__c = 'Residential',
            Product__c = kwhProduct.Id,
            CloseDate = System.today()
        );

        Opportunity opportunityC = new Opportunity(
            Name = 'Nafisa Wong',
            Shared_Solar_System__c = costSSS.Id,
            NMC_Tariff__c = costSizingMethod.Id,
            StageName = 'Complete',
            Customer_Group__c = 'Residential',
            Product__c = costProduct.Id,
            CloseDate = System.today()
        );

        Opportunity opportunityD = new Opportunity(
            Name = 'Ritik Mann',
            Shared_Solar_System__c = costSSS.Id,
            NMC_Tariff__c = costSizingMethod.Id,
            StageName = 'Complete',
            Customer_Group__c = 'Residential',
            Product__c = costProduct.Id,
            CloseDate = System.today()
        );

        insert new List<Opportunity>{opportunityA, opportunityB, opportunityC, opportunityD};

        Utility_Account_Log__c ualA = new Utility_Account_Log__c(
            Name = '00088888'
        );

        Utility_Account_Log__c ualB = new Utility_Account_Log__c(
            Name = '00088888'
        );

        Utility_Account_Log__c ualC = new Utility_Account_Log__c(
            Name = '00088888'
        );

        Utility_Account_Log__c ualD = new Utility_Account_Log__c(
            Name = '00088888'
        );

        insert new List<Utility_Account_Log__c>{ualA, ualB, ualC, ualD};

        Utility_Account_Subscription__c uasA = new Utility_Account_Subscription__c(
            Name = '0000111',
            Utility_Account_Log__c = ualA.Id,
            Opportunity__c = opportunityA.Id,
            Next_Schedule_Z_Status__c = 'Active Subscription',
            Annual_kwh_subscription_future__c = 7587
        );

        Utility_Account_Subscription__c uasB = new Utility_Account_Subscription__c(
            Name = '0000222',
            Utility_Account_Log__c = ualB.Id,
            Opportunity__c =  opportunityB.Id,
            Next_Schedule_Z_Status__c = 'Active Subscription',
            Annual_kwh_subscription_future__c = 14345
        );

        Utility_Account_Subscription__c uasC = new Utility_Account_Subscription__c(
            Name = '0000333',
            Utility_Account_Log__c = ualC.Id,
            Opportunity__c = opportunityC.Id,
            Next_Schedule_Z_Status__c = 'Active Subscription',
            Subscribed_Annual_Cost_of_Electricity__c = 5889
        );

        Utility_Account_Subscription__c uasD = new Utility_Account_Subscription__c(
            Name = '0000444',
            Utility_Account_Log__c = ualD.Id,
            Opportunity__c = opportunityD.Id,
            Next_Schedule_Z_Status__c = 'Active Subscription',
            Subscribed_Annual_Cost_of_Electricity__c = 720.75
        );

        insert new List<Utility_Account_Subscription__c> {uasA, uasB, uasC, uasD};


    }

    @IsTest
    //Need to convert leads to actually test the sizing method apex
    public static void testSizingMethodConversion() {
        useMocks(true);
        Lead switchLead = [
            SELECT Id, Status, Company, Product_line__c, Utility_relationship__r.Id, LASERCA__Home_Address__c,
                LASERCA__Home_City__c, LASERCA__Home_State__c, LASERCA__Home_Zip__c, Product__c
            FROM Lead
            WHERE FirstName = 'Switch'
            LIMIT 1
        ];

        LeadService leadService = new LeadService();

        Account propertyAccount = leadService.buildPropertyAccountFromLegacyLead(switchLead);
        insert propertyAccount;

        Rate_Class__c rateClassR2 = [
            SELECT Id, Utility_NMC_Tariff__c, Utility_NMC_Tariff__r.Size_Ratio__c
            FROM Rate_Class__c
            WHERE Name = 'Eversource R2'
            LIMIT 1
        ];

        Utility_Account_Log__c ual = leadService.buildUtilityAccountLogFromLegacyLead(switchLead, propertyAccount);
        //size of ual should be split onto 2 separate projects
        //one should be maxed out (take the sss min), the other should take the ual min
        //should take on the 1.5 size ratio rather than the 1.2 on the sss
        ual.Annual_kWh__c = 40000;
        ual.Utility_Rate_Class__c = rateClassR2.Id;
        insert ual;
        LeadServiceTestclass.pullCreditForLead(switchLead.Id);


        switchLead.Status = 'Qualified';
        update switchLead;


        //convert the lead
        Database.LeadConvert lc = new Database.LeadConvert();
        lc.setLeadId(switchLead.Id);
        lc.setConvertedStatus('Qualified');
        lc.setDoNotCreateOpportunity(true);

        Database.LeadConvertResult lcr = Database.convertLead(lc, false);
        System.assert(lcr.isSuccess(), lcr.getErrors());

        // query for the opportunity and utility account subscriptions after the fact
        List<Opportunity> convertedOpps = [
            SELECT Id
            FROM Opportunity
            WHERE AccountId = :propertyAccount.Id
        ];
        System.assertEquals(2, convertedOpps.size());

        List<Utility_Account_Subscription__c> convertedUASes = [
            SELECT Id, Sizing_Method__c, Shared_Solar_System__r.Name, Annual_kWh_Subscription_Future_Rollup__c
            FROM Utility_Account_Subscription__c
            WHERE Utility_Account_Log__c = :ual.Id
        ];
        System.assertEquals(2, convertedUASes.size());
        for (Utility_Account_Subscription__c uas : convertedUASes) {
            if (uas.Shared_Solar_System__r.Name == 'kWh Shared Solar System Two') {
                System.assertEquals(rateClassR2.Utility_NMC_Tariff__c, uas.Sizing_Method__c );
                System.assertEquals(18066.67, uas.Annual_kWh_Subscription_Future_Rollup__c);
            } else {
                System.assertEquals(rateClassR2.Utility_NMC_Tariff__c, uas.Sizing_Method__c );
                System.assertEquals(21933.33, uas.Annual_kWh_Subscription_Future_Rollup__c);

            }
        }

    }

    @IsTest
    public static void testPartsOfAWholeBug() {
        /**
            Bug Explanation:
            Using subscription orders, the % share and kW DC on Utility Account Subscriptions are calculated by summing
            their related subscription orders. Each subscription order calculates the change in % share and change in
            kW DC for each incremental change in kWh or cost.

            However, because the formulas for % share and kW DC involve rounding and division, summing the “parts”
            (in this case, subscription orders) won’t always be equivalent to the calculation when it is done for the
            “whole” (in this case, the UAS). In this case, we should not sum numbers that have been rounded.

            SOLUTION:
            Always populate the total "New Annual kwh/Cost" as well as the "Previous Annual kWh/Cost" on the SO. Use the
            "New" values to calculate the "whole" subscription and store in System_Change_Percent_Share and
            System_Change_Subscription (labeled "New" in UI).

            The 4 "Approved Changes" can then be calculated by subtracting New - Previous values and rolled up to UAS.
       */

        Shared_Solar_System__c kwhSSS =[
            SELECT Id, Total_System_Size_kWh_DC__c, Expected_Yield_kWh_kW__c
            FROM Shared_Solar_System__c
            WHERE Name = 'kWh Shared Solar System'
            LIMIT 1
        ];
        kwhSSS.Total_System_Size_kWh_DC__c = 3467.75;
        kwhSSS.Expected_Yield_kWh_kW__c = 1300;
        update kwhSSS;

        //Delete subscription orders automatically inserted for testSetup
        List<Subscription_Order__c> deleteSOs = [
            SELECT Id
            FROM Subscription_Order__c
        ];
        delete deleteSOs;

        List<Utility_Account_Subscription__c> uases = [
            SELECT Id
            FROM Utility_Account_Subscription__c
            WHERE Name = '0000111' OR
            Name = '0000222'
            ORDER BY Name ASC
        ];

        Subscription_Order__c firstWrongSO = new Subscription_Order__c(
            Utility_Account_Subscription__c = uases[0].Id,
            Change_in_Annual_kWh__c = 4565

        );
        insert firstWrongSO;

        Subscription_Order__c secondWrongSO = new Subscription_Order__c(
            Utility_Account_Subscription__c = uases[0].Id,
            Change_in_Annual_kWh__c = 659.68
        );
        insert secondWrongSO;

        Subscription_Order__c firstCorrectedSO = new Subscription_Order__c(
            Utility_Account_Subscription__c = uases[1].Id,
            Approval_Status__c = 'Approved',
            New_Annual_kWh__c = 4565
        );
        insert firstCorrectedSO;

        Subscription_Order__c secondCorrectedSO = new Subscription_Order__c(
            Utility_Account_Subscription__c = uases[1].Id,
            Approval_Status__c = 'Approved',
            New_Annual_kWh__c = 5224.68
        );
        insert secondCorrectedSO;


        List<Subscription_Order__c> checkSOs = [
            SELECT Id, Calculated_Change_in_Subscription_KW_DC__c, Calculated_Change_in_Percent_Share_of_Sy__c,
                Calculated_Change_in_kW_DC_Rounded__c, Change_in_Annual_kWh__c
            FROM Subscription_Order__c
            WHERE Utility_Account_Subscription__c = :uases[0].Id
            ORDER BY CreatedDate ASC
        ];

        secondCorrectedSO = [
            SELECT Id, Approved_Change_in_Subscription__c, Approved_Change_in_Percent_Share__c, Change_in_Annual_kWh__c
            FROM Subscription_Order__c
            WHERE Id = :secondCorrectedSO.Id
            ORDER BY CreatedDate ASC
            LIMIT 1
        ];

        System.assertNotEquals(null, secondCorrectedSO.Approved_Change_in_Subscription__c );
        System.assertEquals(659.68, secondCorrectedSO.Change_in_Annual_kWh__c);

        Utility_Account_Subscription__c uasB = [
            SELECT Id, Future_Share_of_System_Rollup__c, Future_Customer_Subscription_KWDC_Rollup__c
            FROM Utility_Account_Subscription__c
            WHERE Id = :uases[1].Id
            LIMIT 1
        ];

        //Subscription Orders created using the old "Calculated" fields only used "Change in kWh"
        System.assertEquals(3.5115, checkSOs[0].Calculated_Change_in_Subscription_KW_DC__c);
        System.assertEquals(3.467750, checkSOs[0].Calculated_Change_in_kW_DC_Rounded__c);
        System.assertEquals(0.100, checkSOs[0].Calculated_Change_in_Percent_Share_of_Sy__c);

        System.assertEquals(0.5074, checkSOs[1].Calculated_Change_in_Subscription_KW_DC__c);
        System.assertEquals(0.346775, checkSOs[1].Calculated_Change_in_kW_DC_Rounded__c);
        System.assertEquals(0.0100, checkSOs[1].Calculated_Change_in_Percent_Share_of_Sy__c);

        //Calculate total subscription as "parts"
        Decimal totalUsage = checkSOs[0].Change_in_Annual_kWh__c + checkSOs[1].Change_in_Annual_kWh__c;
        Decimal wrongSubscriptionTotal = checkSOs[0].Calculated_Change_in_kW_DC_Rounded__c + checkSOs[1].Calculated_Change_in_kW_DC_Rounded__c;
        Decimal wrongShareTotal = checkSOs[0].Calculated_Change_in_Percent_Share_of_Sy__c + checkSOs[1].Calculated_Change_in_Percent_Share_of_Sy__c;
        System.assertEquals(5224.68, totalUsage);
        System.assertEquals(0.0011, wrongShareTotal/ 100);

        //Calculate total subscription as "whole"
        Decimal correctedSubscription = totalUsage/kwhSSS.Expected_Yield_kWh_kW__c;
        Decimal correctedShare = correctedSubscription/kwhSSS.Total_System_Size_kWh_DC__c;
        correctedShare = correctedShare.setScale(4);
        System.assertEquals(0.0012, correctedShare);
        correctedSubscription = correctedShare * kwhSSS.Total_System_Size_kWh_DC__c;
        System.assertEquals(4.1613, correctedSubscription);

        //Confirm the subscription orders that calculate via "parts" do not equal "whole" subscription
        System.assertNotEquals(correctedSubscription, wrongSubscriptionTotal);
        System.assertNotEquals(correctedShare, wrongShareTotal);

        //Confirm that the second set of Subscription Orders correctly rollup to the "Corrected" value (Fixed bug)
        System.assertEquals(correctedSubscription, uasB.Future_Customer_Subscription_KWDC_Rollup__c);
        System.assertEquals(correctedShare, uasB.Future_Share_of_System_Rollup__c/100);
    }

    @IsTest
    public static void testRoundingBug() {
    /**
        BUG: Subscription calculations were originally unrounded in the same way the uas.kW_Allocation__c was calculated.

        SOLUTION:
        To make the assertions pass, a new "rounded" field was added to the SO to round the subscription size appropriately
        and therefore match the kw Allocation.

        There are also assertions to ensure the Percent Share is correctly calculated despite the change.
     */
List<Utility_Account_Subscription__c> checkUASes = [
 SELECT Id, Name, kW_Allocation__c, Customer_Subscription_KW_DC__c,
     Future_Customer_Subscription_KWDC_Rollup__c, Future_Share_of_System_Rollup__c
 FROM Utility_Account_Subscription__c
 ORDER BY Name
];


for (Utility_Account_Subscription__c uas : checkUASes) {
 if (uas.Name == '0000111') {
     //Unrounded: 5.7652
     System.assertEquals(5.832, uas.kW_Allocation__c);
     System.assertEquals(5.832, uas.Future_Customer_Subscription_KWDC_Rollup__c);
     System.assertEquals(.1, uas.Future_Share_of_System_Rollup__c);
 } else if (uas.Name == '0000222') {
     //Unrounded: 10.9005
     System.assertEquals(11.0808, uas.kW_Allocation__c);
     System.assertEquals(11.0808, uas.Future_Customer_Subscription_KWDC_Rollup__c);
     System.assertEquals(.19, uas.Future_Share_of_System_Rollup__c);
 } else if (uas.Name == '0000333') {
     //Unrounded: 25
     System.assertEquals(25.014528, uas.kW_Allocation__c);
     System.assertEquals(25.014528, uas.Future_Customer_Subscription_KWDC_Rollup__c);
     System.assertEquals(2.31, uas.Future_Share_of_System_Rollup__c);
 } else {
     //Unrounded: 3.0597
     System.assertEquals(3.032064, uas.kW_Allocation__c);
     System.assertEquals(3.032064, uas.Future_Customer_Subscription_KWDC_Rollup__c);
     System.assertEquals(.28, uas.Future_Share_of_System_Rollup__c);
 }
}
}
    private static void useMocks(Boolean featureOn) {
        FeatureService.featureSelector = (FeatureSelector) Test.createStub(FeatureSelector.class, new FeatureServiceTest.MockCustomFeatureSelector(featureOn));
    }
}