/**
 * Created by SarahRenfro on 6/3/2020.
 */

@IsTest
private class ProductionServiceTest {
    @IsTest
    public static void testDeleteProduction() {

        Utility__c ngrid = new Utility__c(
            Name = 'National Grid',
            Number_of_Decimal_Places__c = 2
        );

        insert ngrid;

        Shared_Solar_System__c sss1 = new Shared_Solar_System__c(Name = 'Oxford Barrett St. P1',
            Service_Territory__c = 'SEMA',
            Service_Territories__c = 'SEMA',
            Open__c = true,
            Billing_Method__c = 'NMC',
            Reserved_Capacity_kW_DC__c = '10',
            Capacity_Committed_kW_DC__c = 0,
            Total_System_Size_kWh_DC__c = 1445.86,
            Total_System_Size_kW_AC__c = 1000,
            Utility__c = ngrid.Id,
            Credit_Score_Requirement__c = 300,
            Assignment_Order__c = '1',
            Expected_Yield_kWh_kW__c = 1300,
            Assemblage_Count__c = 1,
            Maximum_Subscription_Capacity_kWDC__c = 25);

        insert sss1;

        Production__c production = new Production__c(
            Name = 'SSS 1 Production - May 2019',
            Verification_Status__c = 'Verified',
            Shared_Solar_System__c = sss1.Id,
            Production_kWh__c = 20000,
            Credits_Generated__c = 10000,
            Start_Date__c = Date.newInstance(2019, 5, 1),
            End_Date__c = Date.newInstance(2019, 5, 29)
        );

        insert production;

        try {
            delete production;
            System.assert(false, 'Expected delete to throw an exception - Production cannot be deleted when Verified');
        } catch (Exception e) {
        }

    }

    @IsTest
    public static void testVerifyProductions() {
        useMocks();
        ProductionService service = new ProductionService();
        List<Production__c> checkVerified = service.verifyProductions(null);
        System.assertEquals(1, checkVerified.size());
        System.assertEquals('Verified', checkVerified[0].Verification_Status__c);

    }


    private static void useMocks() {
        ProductionService.productionSelector = (ProductionSelector) Test.createStub(ProductionSelector.class, new MockProductionSelector());
    }
    public class MockProductionSelector extends MockProvider {
        public MockProductionSelector() {
        }
        public override Object handleMethodCall(MethodCall methodCall) {

            String pendingProduction =
                '[{"attributes" : {"type" : "Production__c","url" : "/services/data/v47.0/sobjects/Production__c/a8u2C0000008dX2QAI"},' +
                    '"Id" : "a8u2C0000008dX2QAI",' +
                    '"Name" : "SSS 1 Production - May 2019",' +
                    '"Verification_Status__c" : "Pending Verification"' +
                    '}]';
            String billPeriod =
                '[{"attributes" : {"type" : "Bill_Period__c","url" : "/services/data/v47.0/sobjects/Bill_Period__c/a8x2C000000KzzCQAS"},' +
                    '"Id" : "a8x2C000000KzzCQAS",' +
                    '"Name" : "Bill Period - May 2019",' +
                    '"Bill_Date__c" : "' + System.today() + '"' +
                    '}]';

            switch on methodCall.stubbedMethodName {
                when 'selectPendingVerificationProductions' {
                    return (List<Production__c>) JSON.deserialize(pendingProduction, List<Production__c>.class );
                } when 'selectProductionByBillPeriod' {
                    Map<Production__c, Bill_Period__c> productionMap = new Map<Production__c, Bill_Period__c>();
                    Production__c production = (Production__c) JSON.deserialize(pendingProduction, Production__c.class);
                    Bill_Period__c bp  = (Bill_Period__c) JSON.deserialize(billPeriod, Bill_Period__c.class);
                    productionMap.put(production, bp);
                    return productionMap;
                }
            }
            return null;
        }
    }


}