/**
 * Created by SarahRenfro on 6/4/2019.
 */

@IsTest
private class UtilityLoadZoneServiceTestclass {
    @isTest
    public static void testUpdateLZUL() {

        Utility__c nyseg = new Utility__c(
            Name = 'NYS Electric & Gas'
        );

        insert nyseg;

        Utility__c central = new Utility__c(
            Name = 'Central Hudson Gas & Electric',
            Number_of_Decimal_Places__c = 2
        );
        insert central;

        Load_U__c lzu = new Load_U__c(
            Name = '12345',
            LZ__c = 'Hudson Valley'
        );

        Load_U__c splitLZU = new Load_U__c(
            Name = '98765',
            LZ__c = 'Hudson Valley'
        );

        insert new List<Load_U__c> {lzu, splitLZU};

        ZipCode_Utility_Junction__c junction1 = new ZipCode_Utility_Junction__c(
            Load_Zone_Utility__c = lzu.Id,
            Utility__c = nyseg.Id
        );

        ZipCode_Utility_Junction__c junction2 = new ZipCode_Utility_Junction__c(
            Load_Zone_Utility__c = splitLZU.Id,
            Utility__c = nyseg.Id
        );

        ZipCode_Utility_Junction__c junction3 = new ZipCode_Utility_Junction__c(
            Load_Zone_Utility__c = splitLZU.Id,
            Utility__c = central.Id
        );

        insert new List<ZipCode_Utility_Junction__c>{junction1, junction2, junction3};


        Lead lead = (Lead)TestFactory.createSObject(new Lead(
            LastName = 'Testcase',
            FirstName = 'Single',
            Email = 'switch@email.com',
            LASERCA__Home_Address__c = '123 Street',
            LASERCA__Home_City__c = 'Albany',
            LASERCA__Home_Zip__c = '12345',
            LASERCA__Home_State__c = 'NY',
            LeadSource = 'Switch',
            Company = 'Switch Comp',
            Status = 'Sales Qualified',
            Product_Line__c = 'Community Solar',
            Parcel_Zip__c = '12345',
            Customer_type__c = 'Residential',
            Application_Type__c = 'Residential',
            System_Assignment__c = 'Automatic - Assignment Order'));
        insert lead;

        Lead splitLead = (Lead)TestFactory.createSObject(new Lead(
            LastName = 'Testcase',
            FirstName = 'Split',
            Email = 'switch@email.com',
            LASERCA__Home_Address__c = '123 Street',
            LASERCA__Home_City__c = 'Albany',
            LASERCA__Home_Zip__c = '12345',
            LASERCA__Home_State__c = 'NY',
            LeadSource = 'Switch',
            Company = 'Switch Comp',
            Status = 'Sales Qualified',
            Product_Line__c = 'Community Solar',
            Parcel_Zip__c = '98765',
            Customer_type__c = 'Residential',
            Application_Type__c = 'Residential',
            System_Assignment__c = 'Automatic - Assignment Order'));
        insert splitLead;

        Lead checkLead = [
            SELECT Id, LoadZone__c, Utility_relationship__c, Confirm_Utility__c, ZipCode__c
            FROM Lead
            WHERE FirstName = 'Single'
            LIMIT 1
        ];

        Lead checkSplitLead = [
            SELECT Id, LoadZone__c, Utility_relationship__c, Confirm_Utility__c, ZipCode__c
            FROM Lead
            WHERE FirstName = 'Split'
            LIMIT 1
        ];

        System.assertEquals(lzu.Id, checkLead.ZipCode__c);
        System.assertEquals(lzu.LZ__c, checkLead.LoadZone__c);
        System.assertEquals(nyseg.Id, checkLead.Utility_relationship__c);


        System.assertEquals(splitLZU.Id, checkSplitLead.ZipCode__c);
        System.assertEquals(splitLZU.LZ__c, checkSplitLead.LoadZone__c);
        System.assertEquals(null, checkSplitLead.Utility_relationship__c);
        System.assertNotEquals(null, checkSplitLead.Confirm_Utility__c);

    }
}