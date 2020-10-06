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
    private static void testRateClassUpdate() {
        Product2 product0 = new Product2(Name = 'Test Product 0', Disclosure_Form_Conga_Template__c = null);
        insert product0;

        Lead lead = new Lead(FirstName = 'test', LastName = 'leadtest', Company = 'test leadtest', Product__c = product0.Id);
        insert lead;
        Account propertyAccount = new Account(Name = 'Property Account Test', Lead__c = lead.Id);
        insert propertyAccount;
        Contract contract = new Contract(Product__c = product0.Id, Lead__c = lead.Id, AccountId = propertyAccount.Id);
        insert contract;
        Rate_Class__c rateClass0 = new Rate_Class__c(Name = 'Rate Class 0', Suppress_Disclosure_Form__c = false);
        Rate_Class__c rateClass1 = new Rate_Class__c(Name = 'Rate Class 1', Suppress_Disclosure_Form__c = true);
        insert new List<Rate_Class__c>{rateClass0, rateClass1};
        Utility_Account_Log__c ual = new Utility_Account_Log__c(Lead__c = lead.Id, Account__c = propertyAccount.Id);
        insert ual;

        Test.startTest();
            // product.Disclosure_Form_Conga_Template__c = null
            //  ==> contract.Generate_Disclosure_Form__c = false
            ual.Utility_Rate_Class__c = rateClass0.Id;
            update ual;
            contract = [SELECT Id, Generate_Disclosure_Form__c FROM Contract WHERE Id = :contract.Id];
            System.assert(!contract.Generate_Disclosure_Form__c, 'No matter what the rate class is, Generate_Disclosure_Form__c should always be false when the product\'s Disclosure_Form_Conga_Template__c is null');



            ual.Utility_Rate_Class__c = rateClass1.Id;
            update ual;
            contract = [SELECT Id, Generate_Disclosure_Form__c FROM Contract WHERE Id = :contract.Id];
            System.assert(!contract.Generate_Disclosure_Form__c, 'No matter what the rate class is, Generate_Disclosure_Form__c should always be false when the product\'s Disclosure_Form_Conga_Template__c is null');

            // product.Disclosure_Form_Conga_Template__c != null
            product0.Disclosure_Form_Conga_Template__c = 'abc123';
            update product0;
            // rate class = null
            //  ==> contract.Generate_Disclosure_Form__c = true
            ual.Utility_Rate_Class__c = null;
            update ual;
            contract = [SELECT Id, Generate_Disclosure_Form__c FROM Contract WHERE Id = :contract.Id];
            System.assert(contract.Generate_Disclosure_Form__c, 'When the product\'s Disclosure_Form_Conga_Template__c is not null and the rate class is null, Generate_Disclosure_Form__c should be true');

            // rate class.Suppress_Disclosure_Form__c = true
            //  ==> contract.Generate_Disclosure_Form__c = false
            ual.Utility_Rate_Class__c = rateClass1.Id;
            update ual;
            contract = [SELECT Id, Generate_Disclosure_Form__c FROM Contract WHERE Id = :contract.Id];
            System.assert(!contract.Generate_Disclosure_Form__c, 'When the rate class\'s Suppress_Disclosure_Form__c is true, Generate_Disclosure_Form__c should be false');

            // rate class.Suppress_Disclosure_Form__c = false
            //  ==> contract.Generate_Disclosure_Form__c = true
            ual.Utility_Rate_Class__c = rateClass0.Id;
            update ual;
            contract = [SELECT Id, Generate_Disclosure_Form__c FROM Contract WHERE Id = :contract.Id];
            System.assert(contract.Generate_Disclosure_Form__c, 'When the rate class\'s Suppress_Disclosure_Form__c is false, Generate_Disclosure_Form__c should be true');
        Test.stopTest();

    }
}