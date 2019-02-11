@isTest
private class UASTestClass
{
 
Static testMethod void UASTestClass()
{

        Date myDate = Date.newInstance(2015, 2, 17);
        Utility__c eversource = new Utility__c(
            Name = 'Eversource',
            Number_of_Decimal_Places__c = 2
        );

        Utility__c nationalGrid = new Utility__c(
            Name = 'National Grid',
            Number_of_Decimal_Places__c = 2
        );

        insert new List<Utility__c>{eversource, nationalGrid};

        Load_U__c newLZU = new Load_U__c ( name = '02052', LZ__c= 'NEMA', town__c = 'Medfield');
        insert newLZU;

        ZipCode_Utility_Junction__c junction = new ZipCode_Utility_Junction__c(
            Load_Zone_Utility__c = newLZU.Id,
            Utility__c = nationalGrid.Id
        );
        insert junction;

        lead newLead = new lead (Lastname = 'BlueWave', company = 'BlueWave', status = 'new', product_line__c = 'Community Solar', parcel_zip__c = '02052');
        insert newLead;
        
        account newAcc = new account (name = 'Cole Swain');
        insert newAcc;         
        
        utility_account_log__c newUtilityLogAccount = new utility_account_log__c ( 
        name = 'Cole Swain', 
        annual_cost_of_electricity__c = 10000, 
        name_on_account__c = '234234',
        account__c = newAcc.id,
        lead__c = newLead.id );
        
        insert newUtilityLogAccount;     
        
        utility_nmc_tariff__c newNMC = new utility_nmc_tariff__c (
        
        name = 'Eversource NEMA Class 2', 
        Value_of_Net_Metering_Credit__c = 0.18);
        
        insert newNMC;
        
        shared_solar_system__c newSSS = new shared_solar_system__c( 

        name = 'test', 
        Service_Territories__c = 'NEMA',
        total_system_size_kWh_DC__c = 950,
        Expected_Yield_kWh_kW__c = 1450,
        Utility__c = eversource.Id,
        assemblage_count__c = 5,
        Maximum_Subscription_Assemblage__c = 25);

        insert newSSS;

        opportunity newOpp = new opportunity( 
        
        name = 'Cole Matthew Swain', 
        stageName = 'New', 
        custom_id__c = 'Cole 1',
        nmc_tariff_method__c = 'Manual',
        nmc_tariff__c = newNMC.id,
        closeDate= myDate, 
        Utilitymapper__c = 'Eversource', 
        parcel_zip__c = '02052',
        Project_Assignment__c = 'Manual',
        shared_solar_system__c = newSSS.id,  
        product_line__c = 'Community Solar', 
        account = newAcc,
        accountid = newAcc.id,
        lead_id__c = newLead.id);
        
        insert newOpp;
        
        utility_account_subscription__c newUAS = new utility_account_subscription__c(
        
        name = '2309432',
        opportunity__c = newOpp.id,
        utility_account_log__c = newUtilityLogAccount.id,
        Annual_Cost_of_Electricity__c = 10000,
        calculated_annual_cost_of_electricity__c = 5000);
        
        insert newUAS;  
 
        test.startTest();

        update newOpp;
 
        test.stopTest();

}
}