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

        Rate_Class__c everRateClass = new Rate_Class__c(
            LDC_Rate_Class__c = 'abc',
            LDC_Rate_Subclass__c = '123',
            Name = 'Eversource Rate Class',
            Utility__c = eversource.Id
        );
        Rate_Class__c natRateClass = new Rate_Class__c(
            LDC_Rate_Class__c = 'abc',
            LDC_Rate_Subclass__c = '123',
            Name = 'National Grid Rate Class',
            Utility__c = nationalGrid.Id
        );
        insert new List<Rate_Class__c>{everRateClass, natRateClass};

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
            LZ__c = 'SEMA/NEMA',
            Town__c= 'Medfield'
        );
        insert new List<Load_U__c>{everLZU, everLZU2, everLZU3, everLZU4};

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
            Load_Zone_Utility__c = everLZU4.Id,
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
            Sales_Partners__c = 'ACE Solar',
            Product__c = srecProduct.Id,
            Maximum_Subscription_Capacity_kWDC__c = 25,
            Available_SMB_Underwriting_Method_FICO__c = true,
            Available_SMB_Underwriting_Method_Docs__c = true);

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
            Sales_Partners__c = 'BlueWave Inside Sales',
            Product__c = srecProduct.Id,
            Maximum_Subscription_Capacity_kWDC__c = 25,
            Available_SMB_Underwriting_Method_FICO__c = true,
            Available_SMB_Underwriting_Method_Docs__c = false);

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
            Sales_Partners__c = 'BlueWave Inside Sales',
            Product__c = smartProduct.Id,
            Maximum_Subscription_Capacity_kWDC__c = 25,
            Available_SMB_Underwriting_Method_FICO__c = false,
            Available_SMB_Underwriting_Method_Docs__c = true);

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
            Maximum_Subscription_Capacity_kWDC__c = 25,
            Available_SMB_Underwriting_Method_FICO__c = false,
            Available_SMB_Underwriting_Method_Docs__c = false);

        insert new List<Shared_Solar_System__c>{sss1, sss2, sss3, sss4};

        Partner__c partner = new Partner__c(
            Name = 'ACE Solar'
        );
        Partner__c defaultPartner = new Partner__c(
            Name = 'BlueWave Inside Sales'
        );
        insert new List<Partner__c>{partner, defaultPartner};

        System_Properties__c property = new System_Properties__c(Name = 'System', Default_CS_Partner__c = defaultPartner.Id);
        insert property;
    }

    @IsTest
    public static void testZipcodeServiceReturnsNoCSAssets() {
        CapacityService service = new CapacityService();
        CapacityService.ZipcodeResponse response = service.findCapacityByZipcode('11111');

        System.assertEquals('11111', response.zipcode);
        System.assertEquals(0, response.utilities.size());
        System.assertEquals(0, response.products.size());
        System.assertEquals(0, response.loadZones.size());
        System.assertEquals(0, response.sharedSolarSystems.size());
        System.assertEquals(false, response.hasCapacity());
    }

    @IsTest
    public static void testZipcodeServiceInvalidInputIncompleteZipcode() {
        CapacityService service = new CapacityService();
        CapacityService.ZipcodeResponse response = service.findCapacityByZipcode('12');

        System.assertEquals(null, response.zipcode);
        System.assertEquals(0, response.utilities.size());
        System.assertEquals(0, response.loadZones.size());
        System.assertEquals(0, response.products.size());
        System.assertEquals(0, response.sharedSolarSystems.size());
        System.assertEquals(0, response.rateClasses.size());
        System.assertEquals(false, response.hasCapacity());
    }

    @IsTest
    public static void testZipcodeServiceInvalidInputNotAZipcode() {
        CapacityService service = new CapacityService();
        CapacityService.ZipcodeResponse response = service.findCapacityByZipcode('hello');

        System.assertEquals(null, response.zipcode);
        System.assertEquals(0, response.utilities.size());
        System.assertEquals(0, response.products.size());
        System.assertEquals(0, response.loadZones.size());
        System.assertEquals(0, response.sharedSolarSystems.size());
        System.assertEquals(0, response.rateClasses.size());
        System.assertEquals(false, response.hasCapacity());
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
        System.assertEquals(1, response.rateClasses.size());
        System.assertEquals(true, response.hasCapacity());
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
        System.assertEquals(1, response.rateClasses.size());
        System.assertEquals(true, response.hasCapacity());
    }

    @IsTest
    public static void testZipcodeServiceReturnsMultipleUtilities() {
        CapacityService service = new CapacityService();
        CapacityService.ZipcodeResponse response = service.findCapacityByZipcode('65432');

        System.assertEquals('65432', response.zipcode);
        System.assertEquals(2, response.utilities.size());
        System.assertEquals(1, response.loadZones.size());
        System.assertEquals(2, response.loadZoneNames.size());
        System.assertEquals(2, response.products.size());
        System.assertEquals(4, response.sharedSolarSystems.size());
        System.assertEquals(2, response.rateClasses.size());
    }

    @IsTest
    public static void testZipcodeServiceMultipleRequestsReturnsOnlyRequestedZipcode() {
        CapacityService service = new CapacityService();
        CapacityService.ZipcodeResponse response = service.findCapacityByZipcode('65432');

        System.assertEquals('65432', response.zipcode);
        System.assertEquals(2, response.utilities.size());
        System.assertEquals(1, response.loadZones.size());
        System.assertEquals(2, response.loadZoneNames.size());
        System.assertEquals(2, response.products.size());
        System.assertEquals(4, response.sharedSolarSystems.size());
        System.assertEquals(2, response.rateClasses.size());
        System.assertEquals(true, response.hasCapacity());

        response = service.findCapacityByZipcode('23456');

        System.assertEquals('23456', response.zipcode);
        System.assertEquals(1, response.utilities.size());
        System.assertEquals(1, response.loadZones.size());
        System.assertEquals(2, response.products.size());
        System.assertEquals(2, response.sharedSolarSystems.size());
        System.assertEquals(1, response.rateClasses.size());
        System.assertEquals(true, response.hasCapacity());
    }

    @IsTest
    public static void testZipcodeServiceReturnsMultipleUtilitiesWithZip4() {
        CapacityService service = new CapacityService();
        CapacityService.ZipcodeResponse response = service.findCapacityByZipcode('65432-1234');

        System.assertEquals('65432', response.zipcode);
        System.assertEquals(2, response.utilities.size());
        System.assertEquals(1, response.loadZones.size());
        System.assertEquals(2, response.loadZoneNames.size());
        System.assertEquals(2, response.products.size());
        System.assertEquals(4, response.sharedSolarSystems.size());
        System.assertEquals(2, response.rateClasses.size());
        System.assertEquals(true, response.hasCapacity());
    }

    @IsTest
    private static void testFindCapacityByZipCodeNoPartners() {
        Partner__c partner =[SELECT Id FROM Partner__c WHERE Name = 'ACE Solar'];
        Shared_Solar_System__c sss = [SELECT Id, Sales_Partners__c FROM Shared_Solar_System__c WHERE Sales_Partners__c = 'ACE Solar'];
        sss.Sales_Partners__c = null;
        update sss;

        CapacityService service = new CapacityService();
        CapacityService.ZipcodeResponse response = service.findCapacityByZipcode('12345', partner.Id);
        System.assertEquals('12345', response.zipcode, 'Response zip code (' + response.zipcode + ') should match submitted zip code (12345)');
        System.assertNotEquals(0, response.utilities.size(), 'At least one utility should match the zip code and be returned');
        System.assertNotEquals(0, response.utilityIds.size(), 'At least one utility ID should match the zip code and be returned');
        System.assertNotEquals(0, response.loadZones.size(), 'At least one load zone should match the zip code and be returned');
        System.assertNotEquals(0, response.loadZoneNames.size(), 'At least one load zone name should match the zip code and be returned');
        System.assertEquals(0, response.products.size(), 'Because the match Shared Solar System does not have any Sales Partners, no products should be returned');
        System.assertEquals(0, response.sharedSolarSystems.size(), 'Because the match Shared Solar System does not have any Sales Partners, no Shared Solar Systems should be returned');
        System.assertNotEquals(0, response.rateClasses.size(), 'At least one rate class should be returned because at least one utility was returned');
        System.assertEquals(false, response.hasCapacity(), 'Because the match Shared Solar System does not have any Sales Partners, the response should indicate no available capacity');
    }

    @IsTest
    public static void testFindCapacityByZipCodeWithPartner() {
        CapacityService service = new CapacityService();
        CapacityService.ZipcodeResponse response = service.findCapacityByZipcode('12345');
        System.assertEquals(1, response.sharedSolarSystems.size());
        System.assertEquals(4, response.utilityZipCodesServed.size());
        List<Shared_Solar_System__c> sharedSolarSystems = new List<Shared_Solar_System__c>(response.sharedSolarSystems);
        System.assertEquals('ACE Solar', sharedSolarSystems[0].Sales_Partners__c,
            'Expected the system for 12345 to only be available for ACE Solar');
        System.assertEquals(true, response.hasCapacity(), 'Expected to find capacity if not looking by partner (for CSAP)');

        List<Error_Log__c> errorLogs = [SELECT Message__c FROM Error_Log__c WHERE Class__c = 'CapacityService'];
        System.assertEquals(0, errorLogs.size(), 'Expected to start with no error logs');
        response = service.findCapacityByZipcode('12345', Util.getFakeId(Partner__c.SObjectType));
        System.assertEquals(0, response.sharedSolarSystems.size());
        System.assertEquals(false, response.hasCapacity(), 'Expected no capacity for an unknown partner');
        errorLogs = [SELECT Message__c FROM Error_Log__c WHERE Class__c = 'CapacityService'];
        System.assertEquals(1, errorLogs.size(), 'Expected to find an error log for an unknown partner');
        System.assert(errorLogs[0].Message__c.contains('but proceeding with the default partner'), 'Expected to proceed with the default partner');
        delete errorLogs;

        Partner__c ace = [SELECT Id FROM Partner__c WHERE Name = 'ACE Solar' LIMIT 1];
        response = service.findCapacityByZipcode('12345', ace.Id);
        System.assertEquals(1, response.sharedSolarSystems.size());
        System.assertEquals(true, response.hasCapacity(), 'Expected capacity for ACE Solar');

        response = service.findCapacityByZipcode('23456');
        System.assertEquals(2, response.sharedSolarSystems.size());
        sharedSolarSystems = new List<Shared_Solar_System__c>(response.sharedSolarSystems);
        System.assertEquals('BlueWave Inside Sales', sharedSolarSystems[0].Sales_Partners__c,
            'Expected the systems for 23456 to only be available for BlueWave Inside Sales, the default partner');
        System.assertEquals('BlueWave Inside Sales', sharedSolarSystems[1].Sales_Partners__c,
            'Expected the systems for 23456 to only be available for BlueWave Inside Sales, the default partner');
        System.assertEquals(true, response.hasCapacity(), 'Expected to find capacity if not looking by partner (for CSAP)');

        errorLogs = [SELECT Message__c FROM Error_Log__c WHERE Class__c = 'CapacityService'];
        System.assertEquals(0, errorLogs.size(), 'Expected to start with no error logs');
        response = service.findCapacityByZipcode('23456', Util.getFakeId(Partner__c.SObjectType));
        System.assertEquals(2, response.sharedSolarSystems.size());
        System.assertEquals(true, response.hasCapacity(), 'Expected capacity for an unknown partner since there is a system for the default partner');
        errorLogs = [SELECT Message__c FROM Error_Log__c WHERE Class__c = 'CapacityService'];
        System.assertEquals(1, errorLogs.size(), 'Expected to find an error log for an unknown partner');
        System.assert(errorLogs[0].Message__c.contains('but proceeding with the default partner'), 'Expected to proceed with the default partner');
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