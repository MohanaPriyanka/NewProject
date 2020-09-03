/**
 * Created by mstackhouse on 12/17/2018.
 * Description: 
 * Test: 
 */

@IsTest
public with sharing class UtilityAccountLogTriggerHandlerTest {
    @IsTest
    public static void testUpdateProposedkWhWithTariff() {
        Utility_NMC_Tariff__c eversourceG1 =  new Utility_NMC_Tariff__c(
            Value_of_Net_Metering_Credit__c = .70578,
            Name = 'Eversource G1',
            Utility__c = 'Eversource',
            Customer_Type__c = 'Non-Residential',
            Maximum_kWh__c = 10000,
            Date__c = Date.today()
        );
        insert eversourceG1;

        Product_Tariff__c productTariff = new Product_Tariff__c(
            Utility_NMC_Tariff__c = eversourceG1.Id,
            Size_Ratio__c = 1.1
        );

        insert productTariff;

        Utility_Account_Log__c ual = new Utility_Account_Log__c(
            Annual_kWh__c = 1000,
            Proposed_kWh__c = 1000,
            Name_on_Account__c = 'Primary 1',
            Utility_NMC_Tariff__c = eversourceG1.Id,
            Product_Tariff__c = productTariff.Id
        );
        insert ual;

        System.assertEquals(1000, ual.Proposed_kWh__c);

        ual.Annual_kWh__c = 2000;
        update ual;

        Utility_Account_Log__c ualAfterUpdate = [
            SELECT Id, Annual_kWh__c, Proposed_kWh__c, Utility_NMC_Tariff__c, Product_Tariff__c
            FROM Utility_Account_Log__c
            WHERE Id = :ual.Id
            LIMIT 1
        ];

        System.assertEquals(ualAfterUpdate.Annual_kWh__c * productTariff.Size_Ratio__c, ualAfterUpdate.Proposed_kWh__c);
        System.assertEquals(eversourceG1.Id, ualAfterUpdate.Utility_NMC_Tariff__c);
        System.assertEquals(productTariff.Id, ualAfterUpdate.Product_Tariff__c);
        System.assertNotEquals(ual.Proposed_kWh__c, ualAfterUpdate.Proposed_kWh__c);
    }

    @IsTest
    public static void testUpdateProposedkWhWithoutTariff() {
        Utility_Account_Log__c ual = new Utility_Account_Log__c(
            Annual_kWh__c = 1000,
            Proposed_kWh__c = 1000,
            Name_on_Account__c = 'Primary 1'
        );
        insert ual;

        System.assertEquals(1000, ual.Proposed_kWh__c);

        ual.Annual_kWh__c = 2000;
        update ual;

        Utility_Account_Log__c ualAfterUpdate = [
            SELECT Id, Annual_kWh__c, Proposed_kWh__c, Utility_NMC_Tariff__c, Product_Tariff__c
            FROM Utility_Account_Log__c
            WHERE Id = :ual.Id
            LIMIT 1
        ];

        System.assertEquals(2000, ualAfterUpdate.Proposed_kWh__c);
        System.assertEquals(null, ualAfterUpdate.Utility_NMC_Tariff__c);
        System.assertEquals(null, ualAfterUpdate.Product_Tariff__c);
        System.assertNotEquals(ual.Proposed_kWh__c, ualAfterUpdate.Proposed_kWh__c);
    }

    @IsTest
    public static void testDontUpdateProposedkWh() {
        Utility_Account_Log__c ual = new Utility_Account_Log__c(
            Annual_kWh__c = 1000,
            Proposed_kWh__c = 1234,
            Name_on_Account__c = 'Primary 1'
        );
        insert ual;

        System.assertEquals(1234, ual.Proposed_kWh__c);

        ual.Name_on_Account__c = 'Primary Two';
        update ual;

        Utility_Account_Log__c ualAfterUpdate = [
            SELECT Id, Annual_kWh__c, Proposed_kWh__c, Utility_NMC_Tariff__c, Product_Tariff__c
            FROM Utility_Account_Log__c
            WHERE Id = :ual.Id
            LIMIT 1
        ];

        System.assertEquals(1234, ualAfterUpdate.Proposed_kWh__c);
        System.assertEquals(null, ualAfterUpdate.Utility_NMC_Tariff__c);
        System.assertEquals(null, ualAfterUpdate.Product_Tariff__c);
        System.assertEquals(ual.Annual_kWh__c, ualAfterUpdate.Annual_kWh__c);
        System.assertEquals(ual.Proposed_kWh__c, ualAfterUpdate.Proposed_kWh__c);
    }

    @IsTest
    private static void testCreateUALSharesForGuestUser() {
        Utility_Account_Log__c ualA = new Utility_Account_Log__c(
            Annual_kWh__c = 1000,
            Proposed_kWh__c = 1234,
            Name_on_Account__c = 'Primary A'
        );
        Utility_Account_Log__c ualB = new Utility_Account_Log__c(
            Annual_kWh__c = 1000,
            Proposed_kWh__c = 1234,
            Name_on_Account__c = 'Primary B'
        );
        Utility_Account_Log__c ualC = new Utility_Account_Log__c(
            Annual_kWh__c = 1000,
            Proposed_kWh__c = 1234,
            Name_on_Account__c = 'Primary C'
        );
        insert new List<Utility_Account_Log__c>{ualA, ualB, ualC};

        UtilityAccountLogs ualList = new UtilityAccountLogs(new List<Utility_Account_Log__c> {ualA, ualB, ualC});
        ualList.createUALSharesForGuestUser();
        List<Utility_Account_Log__Share> shareRecords = [
            SELECT Id, RowCause, AccessLevel
            FROM Utility_Account_Log__Share
            WHERE RowCause = 'Guest_User_Access__c'
        ];
        
        System.assertEquals(3, shareRecords.size());
    }
}