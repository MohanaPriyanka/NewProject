@IsTest
private class TransferServiceTest {
    @IsTest
    public static void testSSSBilledProductionCount(){
        useMocks();
        List<Transfer__c> newTransfers = getTransferMocks();
        Map<Id, Transfer__c> oldTransferMap = new Map<Id, Transfer__c>();
        for (Transfer__c transfer : newTransfers){
            Transfer__c oldTransfer = new Transfer__c(
                Bills_Generated__c = false
            );
            oldTransferMap.put(transfer.Id, oldTransfer);
        }

        TransferService service = new TransferService();
        service.changeInBillsGenerated(newTransfers,oldTransferMap);

        // 6 Transfers, but only for 4 SSSes. Of the 4, only 3 require an update:
        System.assertEquals(3,service.sssToUpdate.size());

        for (Shared_Solar_System__c sssToUp : service.sssToUpdate){
            if (sssToUp.Id == 'a1J3K0000005hM0UAI'){
                System.assertEquals(7,sssToUp.Number_of_Billed_Production_Periods__c);
            } else if (sssToUp.Id == 'a1J3K0000006hM0UAI'){
                System.assertEquals(0,sssToUp.Number_of_Billed_Production_Periods__c);
            } else if (sssToUp.Id == 'a1J3K0000007hM0UAI'){
                System.assertEquals(4,sssToUp.Number_of_Billed_Production_Periods__c);
            } else {
                System.assert(false);
            }
        }
    }

    @IsTest
    public static void testTriggers(){
        Shared_Solar_System__c sss1 = new Shared_Solar_System__c(
            Name = 'Project 1A',
            Billing_Method__c = 'NMC',
            Reserved_Capacity_kW_DC__c = '10',
            Capacity_Committed_kW_DC__c = 0,
            Total_System_Size_kWh_DC__c = 1445.86,
            Total_System_Size_kW_AC__c = 1000,
            Maximum_Subscription_Assemblage__c = 25);
        insert sss1;

        Transfer__c transferP1 = new Transfer__c(
            Shared_Solar_System__c = sss1.Id,
            Attempted_Transfer__c = 100,
            Attempted_kWh_Transfer__c = 100,
            Transfer_Amount__c = 100,
            Date_of_Transfer__c = Date.newInstance(2019, 6, 4),
            Name = 'TRF',
            Bills_Generated__c = false
        );
        insert transferP1;
        transferP1.Default_Credit_Value__c = 0.12;
        update transferP1;
        delete transferP1;

        List<Transfer__c> transfers = [
            SELECT Id
            FROM Transfer__c
        ];
        System.assertEquals(0,transfers.size());
    }

    @IsTest
    private static void testCreditValueChange(){
        useMocks();
        Map<Id, Transfer__c> oldTransferMap = new Map<Id, Transfer__c>();
        List<Transfer__c> newTransfers = new List<Transfer__c>();

        List<Transfer__c> oldTransfers = getTransferMocks();

        for (Transfer__c oldTransfer : oldTransfers){
            oldTransfer.Default_Credit_Value__c = 0.17;
            if (oldTransfer.Id == 'a903K000000028ZQAQ'){
                oldTransfer.Default_Credit_Value__c = null;
            }
            oldTransferMap.put(oldTransfer.Id, oldTransfer);
        }

        newTransfers = getTransferMocks();
        for (Transfer__c transfer : newTransfers){
            transfer.Default_Credit_Value__c = 0.12;
            if (transfer.Id == 'a903K000000026ZQAQ'){
                transfer.Default_Credit_Value__c = null;
            } else if (transfer.Id == 'a903K000000011ZQAQ'){
                transfer.Default_Credit_Value__c = 0.17;
            }
        }

        TransferService service = new TransferService();
        List<Transfer_Part__c> partsToUpdate = service.findPartsOnCreditValueUpdate(newTransfers, oldTransferMap);
        System.assertEquals(5,partsToUpdate.size());
        Map<Id, Transfer_Part__c> partMap = new Map<Id, Transfer_Part__c>();

        for (Transfer_Part__c part : partsToUpdate){
            partMap.put(part.Transfer__c, part);
        }

        System.assertEquals(0.12,partMap.get('a903K000000028ZQAQ').Main_Transfer_Default_Credit_Value__c,
            'main transfer credit value was updated from null to a value, but the transfer part did not update'
        );
        System.assertEquals(null,partMap.get('a903K000000026ZQAQ').Main_Transfer_Default_Credit_Value__c,
            'main transfer credit value was updated from a value to null, but the transfer part did not update'
        );
        System.assertEquals(null,partMap.get('a903K000000011ZQAQ'),
            'main transfer credit value was updated to the same value as before, transfer part should not have updated'
        );
        System.assertEquals(0.12,partMap.get('a903K000000027ZQAQ').Main_Transfer_Default_Credit_Value__c,
            'main transfer credit value was updated, but the transfer part did not update'
        );
        System.assertEquals(0.12,partMap.get('a903K000000029ZQAQ').Main_Transfer_Default_Credit_Value__c,
            'main transfer credit value was updated, but the transfer part did not update'
        );
    }

    public static List<Transfer__c> getTransferMocks(){
        Transfer__c transferOne = new Transfer__c(Id = 'a903K000000026ZQAQ', Transfer_Type__c = 'Main', Bills_Generated__c = true, Shared_Solar_System__c = 'a1J3K0000006hM0UAI');
        Transfer__c transferTwo = new Transfer__c(Id = 'a903K000000027ZQAQ', Transfer_Type__c = 'Main', Bills_Generated__c = true, Shared_Solar_System__c = 'a1J3K0000008hM0UAI');
        Transfer__c transferThree = new Transfer__c(Id = 'a903K000000028ZQAQ', Transfer_Type__c = 'Main', Bills_Generated__c = true, Shared_Solar_System__c = 'a1J3K0000008hM0UAI');
        Transfer__c transferFour = new Transfer__c(Id = 'a903K000000029ZQAQ', Transfer_Type__c = 'Main', Bills_Generated__c = true, Shared_Solar_System__c = 'a1J3K0000007hM0UAI');
        Transfer__c transferFive = new Transfer__c(Id = 'a903K000000010ZQAQ', Transfer_Type__c = 'Main', Bills_Generated__c = true, Shared_Solar_System__c = 'a1J3K0000007hM0UAI');
        Transfer__c transferSix = new Transfer__c(Id = 'a903K000000011ZQAQ', Transfer_Type__c = 'Main', Bills_Generated__c = true, Shared_Solar_System__c = 'a1J3K0000005hM0UAI');
        return new List<Transfer__c>{
            transferOne, transferTwo, transferThree, transferFour, transferFive, transferSix
        };
    }

    private static void useMocks() {
        TransferService.prodSelector = (ProductionSelector) Test.createStub(ProductionSelector.class, new MockProductionSelector());
        TransferService.prodDetailSelector = (ProductionDetailSelector) Test.createStub(ProductionDetailSelector.class, new MockProductionDetailSelector());
        TransferService.sssSelector = (SharedSolarSystemsSelector) Test.createStub(SharedSolarSystemsSelector.class, new MockSSSSelctor());
    }

    public class MockProductionSelector extends MockProvider {
        public MockProductionSelector() {
        }

        public override Object handleMethodCall(MethodCall methodCall) {
            Map<Id,Integer> sssIdToCountMap = new Map<Id,Integer>();
            sssIdToCountMap.put('a1J3K0000005hM0UAI',7);
            sssIdToCountMap.put('a1J3K0000008hM0UAI',3);
            sssIdToCountMap.put('a1J3K0000007hM0UAI',4);
            sssIdToCountMap.put('a1J3K0000006hM0UAI',0);

            switch on methodCall.stubbedMethodName {
                when 'getBilledProductionBySSS' {
                    return sssIdToCountMap;
                }
            }
            return null;
        }
    }

    public class MockSSSSelctor extends MockProvider {
        public MockSSSSelctor() {
        }

        public override Object handleMethodCall(MethodCall methodCall) {
            Map<Id, Shared_Solar_System__c> sssMap = new Map<Id, Shared_Solar_System__c>();
            Shared_Solar_System__c sssOne = new Shared_Solar_System__c(
                Id = 'a1J3K0000005hM0UAI',
                Number_of_Billed_Production_Periods__c = 3
            );
            Shared_Solar_System__c sssTwo = new Shared_Solar_System__c(
                Id = 'a1J3K0000006hM0UAI',
                Number_of_Billed_Production_Periods__c = 3
            );
            Shared_Solar_System__c sssThree = new Shared_Solar_System__c(
                Id = 'a1J3K0000007hM0UAI',
                Number_of_Billed_Production_Periods__c = 3
            );
            Shared_Solar_System__c sssFour = new Shared_Solar_System__c(
                Id = 'a1J3K0000008hM0UAI',
                Number_of_Billed_Production_Periods__c = 3
            );
            sssMap.put(sssOne.Id, sssOne);
            sssMap.put(sssTwo.Id, sssTwo);
            sssMap.put(sssThree.Id, sssThree);
            sssMap.put(sssFour.Id, sssFour);
            switch on methodCall.stubbedMethodName {
                when 'getSSSMap' {
                    return sssMap;
                }
            }
            return null;
        }
    }

    public class MockProductionDetailSelector extends MockProvider {
        public MockProductionDetailSelector() {
        }

        public override Object handleMethodCall(MethodCall methodCall) {
            String partsAsString = '' +
                '[{"Transfer__c":"a903K000000026ZQAQ","Transfer__r":{"Id":"a903K000000026ZQAQ","Default_Credit_Value__c":null}},' +
                '{"Transfer__c":"a903K000000027ZQAQ","Transfer__r":{"Id":"a903K000000027ZQAQ","Default_Credit_Value__c":0.12}},' +
                '{"Transfer__c":"a903K000000028ZQAQ","Transfer__r":{"Id":"a903K000000028ZQAQ","Default_Credit_Value__c":0.12}},' +
                '{"Transfer__c":"a903K000000029ZQAQ","Transfer__r":{"Id":"a903K000000029ZQAQ","Default_Credit_Value__c":0.12}},' +
                '{"Transfer__c":"a903K000000010ZQAQ","Transfer__r":{"Id":"a903K000000010ZQAQ","Default_Credit_Value__c":0.12}}]';

            switch on methodCall.stubbedMethodName {
                when 'getPartsFromTransfer' {
                    return (List<Transfer_Part__c>)JSON.deserialize(partsAsString,List<Transfer_Part__c>.class);
                }
            }
            return null;
        }
    }
}