/**
 * Created by PeterYao on 3/31/2021.
 */
@IsTest
public with sharing class SubscriptionTransferCalculatorTest {
    @IsTest
    private static void testBackingIntoAnnualkWh() {
        sfab_FabricatedSObject fabbedSSS = new sfab_FabricatedSObject(Shared_Solar_System__c.class);
        fabbedSSS.setField(Shared_Solar_System__c.Total_System_Size_kWh_DC__c, 10442.93);
        fabbedSSS.setField(Shared_Solar_System__c.Expected_Yield_kWh_kW__c, 1226);
        sfab_FabricatedSObject fabbedUtility = new sfab_FabricatedSObject(Utility__c.class);
        fabbedUtility.setField(Utility__c.Number_of_Decimal_Places__c, 2);
        fabbedSSS.setParent('Utility__r', fabbedUtility);
        Shared_Solar_System__c sss = (Shared_Solar_System__c) fabbedSSS.toSObject();

        sfab_FabricatedSObject fabbedSizingMethod = new sfab_FabricatedSObject(Utility_NMC_Tariff__c.class);
        fabbedSizingMethod.setField(Utility_NMC_Tariff__c.Size_Ratio__c, 1.489);
        Utility_NMC_Tariff__c sizingMethod = (Utility_NMC_Tariff__c) fabbedSizingMethod.toSObject();

        System.assertEquals(36113.32, new SubscriptionTransferCalculator().getAnnualkWh(sss, sizingMethod, 43.911414),
            '');
    }

    @IsTest
    private static void testBackingIntoAnnualCost() {
        sfab_FabricatedSObject fabbedSSS = new sfab_FabricatedSObject(Shared_Solar_System__c.class);
        fabbedSSS.setField(Shared_Solar_System__c.Total_System_Size_kWh_DC__c, 1371.50);
        fabbedSSS.setField(Shared_Solar_System__c.Expected_Yield_kWh_kW__c, 1248);
        sfab_FabricatedSObject fabbedUtility = new sfab_FabricatedSObject(Utility__c.class);
        fabbedUtility.setField(Utility__c.Number_of_Decimal_Places__c, 2);
        fabbedSSS.setParent('Utility__r', fabbedUtility);
        Shared_Solar_System__c sss = (Shared_Solar_System__c) fabbedSSS.toSObject();

        sfab_FabricatedSObject fabbedSizingMethod = new sfab_FabricatedSObject(Utility_NMC_Tariff__c.class);
        fabbedSizingMethod.setField(Utility_NMC_Tariff__c.Value_of_NMC__c, .1686);
        Utility_NMC_Tariff__c sizingMethod = (Utility_NMC_Tariff__c) fabbedSizingMethod.toSObject();

        System.assertEquals(5252.177025, new SubscriptionTransferCalculator().getAnnualCost(sss, sizingMethod, 25.005),
            'A New_Annual_Cost__c of 5252.177025 should result in an Approved_Change_in_Subscription__c of 24.9613 ' +
                'which is just .0437 kWh from the desired 25.005');
    }
}