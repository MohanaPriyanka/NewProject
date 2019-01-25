/**
 * Created by mstackhouse on 1/23/2019.
 * Description: 
 * Test: 
 */

@IsTest
public with sharing class CapacityServiceTest {
    @TestSetup
    public static void testSetup() {
        Utility__c eversource = new Utility__c(
            Name = 'Eversource',
            Number_of_Decimal_Places__c = 2
        );
        Utility__c nationalGrid = new Utility__c(
            Name = 'National Grid',
            Number_of_Decimal_Places__c = 2
        );
        insert new List<Utility__c>{eversource, nationalGrid};

        Load_U__c everLZU = new Load_U__c (
            Name = '12345',
            LZ__c = 'SEMA',
            Town__c= 'Medfield'
        );
        Load_U__c everLZU2 = new Load_U__c (
            Name = '23456',
            LZ__c = 'NEMA',
            Town__c= 'Medfield'
        );
        Load_U__c everLZU3 = new Load_U__c (
            Name = '54321',
            LZ__c = 'SEMA',
            Town__c= 'Medfield'
        );
        Load_U__c everLZU4 = new Load_U__c (
            Name = '65432',
            LZ__c = 'SEMA',
            Town__c= 'Medfield'
        );
        Load_U__c everLZU5 = new Load_U__c (
            Name = '65432',
            LZ__c = 'NEMA',
            Town__c= 'Medfield'
        );
        insert new List<Load_U__c>{everLZU, everLZU2, everLZU3, everLZU4, everLZU5};

        ZipCode_Utility_Junction__c junction = new ZipCode_Utility_Junction__c(
            Load_Zone_Utility__c = everLZU.Id,
            Utility__c = eversource.Id
        );
        ZipCode_Utility_Junction__c junction2 = new ZipCode_Utility_Junction__c(
            Load_Zone_Utility__c = everLZU2.Id,
            Utility__c = eversource.Id
        );
        ZipCode_Utility_Junction__c junction3 = new ZipCode_Utility_Junction__c(
            Load_Zone_Utility__c = everLZU3.Id,
            Utility__c = eversource.Id
        );
        ZipCode_Utility_Junction__c junction4 = new ZipCode_Utility_Junction__c(
            Load_Zone_Utility__c = everLZU4.Id,
            Utility__c = nationalGrid.Id
        );
        ZipCode_Utility_Junction__c junction5 = new ZipCode_Utility_Junction__c(
            Load_Zone_Utility__c = everLZU5.Id,
            Utility__c = eversource.Id
        );
        insert new List<ZipCode_Utility_Junction__c>{junction,junction2,junction3,junction4,junction5};

        Product2 srecProduct = new Product2( Name = 'SREC Community Solar',
            Family = 'Community Solar',
            Product_Type__c = 'Community Solar',
            Program__c = 'SREC - Community Solar',
            State__c = 'MA',
            ProductCode = 'CS - BlueWave - 10%',
            IsActive = true,
            Lender_of_Record__c = 'BlueWave',
            NMC_Discount__c = 10,
            Annual_kWh_Maximum__c = 100000000,
            NM_Rate_Floor__c = 0,
            Days_in_Bill_Period__c = 30,
            Monthly_Late_Fee__c = 1);

        Product2 smartProduct = new Product2( Name = 'SREC Community Solar',
            Family = 'Community Solar',
            Product_Type__c = 'Community Solar',
            Program__c = 'SMART - Community Solar',
            State__c = 'MA',
            ProductCode = 'CS - BlueWave - 10%',
            IsActive = true,
            Lender_of_Record__c = 'BlueWave',
            NMC_Discount__c = 10,
            Annual_kWh_Maximum__c = 100000000,
            NM_Rate_Floor__c = 0,
            Days_in_Bill_Period__c = 30,
            Monthly_Late_Fee__c = 1);

        insert new List<Product2>{srecProduct, smartProduct};

        Shared_Solar_System__c sss1 = new Shared_Solar_System__c(   Name = 'Oxford Barrett St. P1',
            Service_Territory__c = 'SEMA',
            Service_Territories__c = 'SEMA',
            Open__c = true,
            Reserved_Capacity_kW_DC__c = '10',
            Capacity_Committed_kW_DC__c = 0,
            Total_System_Size_kWh_DC__c = 1445.86,
            Total_System_Size_kW_AC__c  = 996,
            Utility__c = eversource.Id,
            Credit_Score_Requirement__c = 300,
            Assignment_Order__c = '1',
            Expected_Yield_kWh_kW__c = 1300,
            Assemblage_Count__c = 1,
            Sales_Partners__c = 'All',
            Product__c = srecProduct.Id,
            Maximum_Subscription_Assemblage__c = 25);

        Shared_Solar_System__c sss2 = new Shared_Solar_System__c(   Name = 'Oxford Barrett St. P1',
            Service_Territory__c = 'NEMA',
            Service_Territories__c = 'NEMA',
            Open__c = true,
            Reserved_Capacity_kW_DC__c = '10',
            Capacity_Committed_kW_DC__c = 0,
            Total_System_Size_kWh_DC__c = 1445.86,
            Total_System_Size_kW_AC__c  = 996,
            Utility__c = eversource.Id,
            Credit_Score_Requirement__c = 300,
            Assignment_Order__c = '1',
            Expected_Yield_kWh_kW__c = 1300,
            Assemblage_Count__c = 1,
            Sales_Partners__c = 'All',
            Product__c = srecProduct.Id,
            Maximum_Subscription_Assemblage__c = 25);

        Shared_Solar_System__c sss3 = new Shared_Solar_System__c(   Name = 'Oxford Barrett St. P1',
            Service_Territory__c = 'NEMA',
            Service_Territories__c = 'NEMA',
            Open__c = true,
            Reserved_Capacity_kW_DC__c = '10',
            Capacity_Committed_kW_DC__c = 0,
            Total_System_Size_kWh_DC__c = 1445.86,
            Total_System_Size_kW_AC__c  = 996,
            Utility__c = eversource.Id,
            Credit_Score_Requirement__c = 300,
            Assignment_Order__c = '1',
            Expected_Yield_kWh_kW__c = 1300,
            Assemblage_Count__c = 1,
            Sales_Partners__c = 'All',
            Product__c = smartProduct.Id,
            Maximum_Subscription_Assemblage__c = 25);

        Shared_Solar_System__c sss4 = new Shared_Solar_System__c(   Name = 'Oxford Barrett St. P1',
            Service_Territory__c = 'NEMA',
            Service_Territories__c = 'NEMA',
            Open__c = true,
            Reserved_Capacity_kW_DC__c = '10',
            Capacity_Committed_kW_DC__c = 0,
            Total_System_Size_kWh_DC__c = 1445.86,
            Total_System_Size_kW_AC__c  = 996,
            Utility__c = nationalGrid.Id,
            Credit_Score_Requirement__c = 300,
            Assignment_Order__c = '1',
            Expected_Yield_kWh_kW__c = 1300,
            Assemblage_Count__c = 1,
            Sales_Partners__c = 'All',
            Product__c = smartProduct.Id,
            Maximum_Subscription_Assemblage__c = 25);

        insert new List<Shared_Solar_System__c>{sss1, sss2, sss3, sss4};
    }

    @IsTest
    public static void testZipcodeServiceReturnsNoCSAssets() {
        CapacityService service = new CapacityService();
        CapacityService.ZipcodeResponse response = service.findCapacityByZipcode('11111');

        System.assertEquals('11111', response.zipcode);
        System.assertEquals(0, response.utilities.size());
        System.assertEquals(0, response.products.size());
        System.assertEquals(0, response.products.size());
        System.assertEquals(0, response.sharedSolarSystems.size());
    }

    @IsTest
    public static void testZipcodeServiceInvalidInputIncompleteZipcode() {
        CapacityService service = new CapacityService();
        CapacityService.ZipcodeResponse response = service.findCapacityByZipcode('12');

        System.assertEquals(null, response.zipcode);
        System.assertEquals(0, response.utilities.size());
        System.assertEquals(0, response.products.size());
        System.assertEquals(0, response.products.size());
        System.assertEquals(0, response.sharedSolarSystems.size());
    }

    @IsTest
    public static void testZipcodeServiceInvalidInputNotAZipcode() {
        CapacityService service = new CapacityService();
        CapacityService.ZipcodeResponse response = service.findCapacityByZipcode('hello');

        System.assertEquals(null, response.zipcode);
        System.assertEquals(0, response.utilities.size());
        System.assertEquals(0, response.products.size());
        System.assertEquals(0, response.products.size());
        System.assertEquals(0, response.sharedSolarSystems.size());
    }

    @IsTest
    public static void testZipcodeServiceReturnsCSAssets() {
        CapacityService service = new CapacityService();
        CapacityService.ZipcodeResponse response = service.findCapacityByZipcode('12345');

        System.assertEquals('12345', response.zipcode);
        System.assertEquals(1, response.utilities.size());
        System.assertEquals(1, response.loadZones.size());
        System.assertEquals(1, response.products.size());
        System.assertEquals(1, response.sharedSolarSystems.size());
    }

    @IsTest
    public static void testZipcodeServiceReturnsMultipleCSAssets() {
        CapacityService service = new CapacityService();
        CapacityService.ZipcodeResponse response = service.findCapacityByZipcode('23456');

        System.assertEquals('23456', response.zipcode);
        System.assertEquals(1, response.utilities.size());
        System.assertEquals(1, response.loadZones.size());
        System.assertEquals(2, response.products.size());
        System.assertEquals(2, response.sharedSolarSystems.size());
    }

    @IsTest
    public static void testZipcodeServiceReturnsMultipleUtilities() {
        CapacityService service = new CapacityService();
        CapacityService.ZipcodeResponse response = service.findCapacityByZipcode('65432');

        System.assertEquals('65432', response.zipcode);
        System.assertEquals(2, response.utilities.size());
        System.assertEquals(2, response.loadZones.size());
        System.assertEquals(2, response.products.size());
        System.assertEquals(4, response.sharedSolarSystems.size());
    }

    @IsTest
    public static void testZipcodeServiceMultipleRequestsReturnsOnlyRequestedZipcode() {
        CapacityService service = new CapacityService();
        CapacityService.ZipcodeResponse response = service.findCapacityByZipcode('65432');

        System.assertEquals('65432', response.zipcode);
        System.assertEquals(2, response.utilities.size());
        System.assertEquals(2, response.loadZones.size());
        System.assertEquals(2, response.products.size());
        System.assertEquals(4, response.sharedSolarSystems.size());

        response = service.findCapacityByZipcode('23456');

        System.assertEquals('23456', response.zipcode);
        System.assertEquals(1, response.utilities.size());
        System.assertEquals(1, response.loadZones.size());
        System.assertEquals(2, response.products.size());
        System.assertEquals(2, response.sharedSolarSystems.size());
    }

    @IsTest
    public static void testZipcodeServiceReturnsMultipleUtilitiesWithZip4() {
        CapacityService service = new CapacityService();
        CapacityService.ZipcodeResponse response = service.findCapacityByZipcode('65432-1234');

        System.assertEquals('65432', response.zipcode);
        System.assertEquals(2, response.utilities.size());
        System.assertEquals(2, response.loadZones.size());
        System.assertEquals(2, response.products.size());
        System.assertEquals(4, response.sharedSolarSystems.size());
        System.debug(response);
    }

    @IsTest
    public static void testZipcodeIsValid() {
        CapacityService service = new CapacityService();

        System.assert(
            service.isZipcodeValid('12345'),
            'Zipcode should be valid, is 5 digits and can be converted to a number'
        );

        System.assert(
            !service.isZipcodeValid('1235'),
            'Zipcode should not be valid, is not 5 digits'
        );

        System.assert(
            !service.isZipcodeValid('hello'),
            'Zipcode should not be valid, is cannot be converted to a number'
        );

        System.assert(
            service.isZipcodeValid('01234'),
            'Zipcode should be valid'
        );
        String zipcode = '01234-1234'.left(5);
        System.assert(
            service.isZipcodeValid(zipcode),
            'Zipcode should be valid'
        );
    }
}