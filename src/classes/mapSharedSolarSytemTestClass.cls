@isTest
private class mapSharedSolarSytemTestClass{

    static testMethod void mapSharedSolarSystemHandler(){

        Date myDate = Date.newInstance(2015, 2, 17);
        Date codDate = Date.newInstance(2015, 4, 17);
        Date codDateTwo = Date.newInstance(2015, 7, 17);

        Utility__c eversource = new Utility__c(
            Name = 'Eversource',
            Number_of_Decimal_Places__c = 2
        );

        Utility__c nationalGrid = new Utility__c(
            Name = 'National Grid',
            Number_of_Decimal_Places__c = 2
        );

        insert new List<Utility__c>{eversource, nationalGrid};

        Utility_NMC_Tariff__c nmcTariff = new Utility_NMC_Tariff__c(
            Name = 'Eversource SEMA Class 2',
            Class__c = 'Class 2',
            Value_of_Net_Metering_Credit__c = 0.1848,
            Utility__c = 'Eversource');
                insert nmcTariff;

        Shared_solar_system__c systemOne = new Shared_solar_system__c(
            Name = 'Fairhaven Mill Rd.',
            Total_System_Size_kWh_DC__c = 1000,
            Assignment_Order__c = '1',
            Open__c = TRUE,
            Total_System_Size_kW_AC__c = 750,
            Estimated_COD_Date_Manual__c = codDate,
            Service_Territories__c = 'SEMA',
            Utility__c = eversource.Id,
            credit_score_requirement__c = 600);
                insert systemOne;

        Shared_solar_system__c systemTwo = new Shared_solar_system__c(
            Name = 'Plympton Lake St.',
            Total_System_Size_kWh_DC__c = 1000,
            Open__c = TRUE,
            Assignment_Order__c = '2',
            Total_System_Size_kW_AC__c = 750,
            Estimated_COD_Date_Manual__c = codDateTwo,
            Service_Territories__c = 'SEMA',
            Utility__c = eversource.Id,
            credit_score_requirement__c = 700);
                insert systemTwo;

        LASERCA__Personal_Credit_Report__c creditReport = new LASERCA__Personal_Credit_Report__c(
            name = 'Tester',
            LASERCA__Credit_Score_TransUnion__c = '800');
                insert creditReport;

        Opportunity newOpportunity = new Opportunity(
            Name = 'Tester', 
            Type = 'New Business', 
            CloseDate = myDate, 
            StageName='New',
            Product_line__c = 'Community Solar',
            Project_assignment__c = 'Automatic - COD Date/Available Capacity',
            UtilityMapper__c = 'Eversource',
            Personal_Credit_Report2__c = creditReport.id); 
            
        Opportunity newOpportunity2 = new Opportunity(
            Name = 'Tester2', 
            Type = 'New Business', 
            CloseDate = myDate, 
            StageName='New',
            Product_line__c = 'Community Solar',
            Project_assignment__c = 'Automatic - Assignment Order',
            UtilityMapper__c = 'Eversource',
            Personal_Credit_Report2__c = creditReport.id); 

        Test.startTest();
        insert newOpportunity;
        insert newOpportunity2;
        Test.stopTest();

        //Opportunity verifyOpp = [SELECT Shared_solar_system__r.Name FROM Opportunity WHERE ID = : newOpportunity.ID];
        //System.debug(verifyOpp);
        //System.assertEquals('Fairhaven Mill Rd.', verifyOpp.Shared_solar_system__r.Name);

    }
}