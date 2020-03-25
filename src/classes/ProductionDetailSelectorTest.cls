@isTest
public class ProductionDetailSelectorTest {
    @testSetup
    public static void setupTestData() {
        // Don't need to test Allocation Schedule Population or transfer part creation:
        Util.DisableTrigger('Disable_TransferTrigger__c');

        Journal_Entry__c entryOne = new Journal_Entry__c(
            Object_Type__c = 'InvoiceItem',
            Query_Type__c = 'InvoiceItem',
            Project__c = 'SSS-000001',
            Client__c = 'BW-0009470',
            Amount__c = 252.73,
            External_Id__c = '2c92c0fa6e3a9391016e3df87b1f687a',
            Customer_Account__c = 'bw-00524',
            Date__c = Date.newInstance(2019,05,20)
        );
        Journal_Entry__c entryTwo = new Journal_Entry__c(
            Object_Type__c = 'InvoiceItem',
            Query_Type__c = 'InvoiceItem',
            Project__c = 'SSS-000001',
            Client__c = 'BW-0009470',
            Amount__c = 135.06,
            External_Id__c = '2c92c0fa6e3a9391016e3e30d48066d2',
            Customer_Account__c = 'bw-00524',
            Date__c = Date.newInstance(2019,06,20)
        );
        insert new List<Journal_Entry__c>{entryOne, entryTwo};

        Shared_Solar_System__c sss1 = new Shared_Solar_System__c(
            Name = 'Test Project',
            Billing_Method__c = 'NMC'
        );
        Shared_Solar_System__c sss2 = new Shared_Solar_System__c(
            Name = 'Test Project',
            Billing_Method__c = 'NMC'
        );
        insert sss1;
        insert sss2;

        Production__c productionOne = new Production__c(
            Name = 'Production A',
            Shared_Solar_System__c = sss1.Id,
            Production_kWh__c = 15000,
            Credits_Generated__c = 8000,
            Start_Date__c = Date.newInstance(2019, 6, 1),
            End_Date__c = Date.newInstance(2019, 6, 29)
        );
        Production__c productionTwo = new Production__c(
            Name = 'Production B',
            Shared_Solar_System__c = sss1.Id,
            Production_kWh__c = 15000,
            Credits_Generated__c = 8000,
            Start_Date__c = Date.newInstance(2019, 6, 1),
            End_Date__c = Date.newInstance(2019, 6, 29)
        );
        Production__c productionThree = new Production__c(
            Name = 'Production C',
            Shared_Solar_System__c = sss2.Id,
            Production_kWh__c = 15000,
            Credits_Generated__c = 8000,
            Start_Date__c = Date.newInstance(2019, 6, 1),
            End_Date__c = Date.newInstance(2019, 6, 29)
        );
        insert new List<Production__c>{productionOne, productionTwo, productionThree};

        Transfer__c transferOne = new Transfer__c(
            Name = 'TransferA',
            Transfer_Type__c = 'Main',
            Shared_Solar_System__c = sss1.Id,
            Attempted_Transfer__c = 1000,
            Attempted_kWh_Transfer__c = 19000,
            Transfer_Amount__c = 1000,
            Date_of_Transfer__c = Date.newInstance(2019, 6, 4)
        );
        Transfer__c transferTwo = new Transfer__c(
            Name = 'TransferB',
            Transfer_Type__c = 'Main',
            Shared_Solar_System__c = sss1.Id,
            Attempted_Transfer__c = 1000,
            Attempted_kWh_Transfer__c = 19000,
            Transfer_Amount__c = 1000,
            Date_of_Transfer__c = Date.newInstance(2019, 6, 4)
        );
        Transfer__c transferThree = new Transfer__c(
            Name = 'TransferC',
            Transfer_Type__c = 'Main',
            Shared_Solar_System__c = sss2.Id,
            Attempted_Transfer__c = 1000,
            Attempted_kWh_Transfer__c = 19000,
            Transfer_Amount__c = 2000,
            Date_of_Transfer__c = Date.newInstance(2019, 6, 4)
        );
        insert new List<Transfer__c>{transferOne, transferTwo, transferThree};

        Transfer_Part__c utilityFeeOne = new Transfer_Part__c(
            Name = 'Eversource Utility Fee',
            Production__c = productionOne.Id,
            Type__c = 'Fee',
            Amount__c = 10
        );
        Transfer_Part__c utilityFeeTwo = new Transfer_Part__c(
            Name = 'Eversource Utility Fee',
            Production__c = productionTwo.Id,
            Type__c = 'Fee',
            Amount__c = 10
        );
        Transfer_Part__c transferPartOne = new Transfer_Part__c(
            Transfer__c = transferOne.Id,
            Production__c = productionOne.Id,
            Type__c = 'Transfer',
            Amount__c = 1000
        );
        Transfer_Part__c transferPartTwo = new Transfer_Part__c(
            Transfer__c = transferTwo.Id,
            Production__c = productionTwo.Id,
            Type__c = 'Transfer',
            Amount__c = 333.33
        );
        Transfer_Part__c transferPartThree = new Transfer_Part__c(
            Transfer__c = transferTwo.Id,
            Production__c = productionTwo.Id,
            Type__c = 'Transfer',
            Amount__c = 333.33
        );
        Transfer_Part__c transferPartFour = new Transfer_Part__c(
            Transfer__c = transferTwo.Id,
            Production__c = productionTwo.Id,
            Type__c = 'Transfer',
            Amount__c = 333.34
        );
        Transfer_Part__c transferPartFive = new Transfer_Part__c(
            Transfer__c = transferThree.Id,
            Production__c = productionThree.Id,
            Type__c = 'Transfer',
            Amount__c = 1999.93
        );
        Transfer_Part__c transferPartSix = new Transfer_Part__c(
            Transfer__c = transferThree.Id,
            Production__c = productionThree.Id,
            Type__c = 'Transfer',
            Amount__c = 0.07
        );
        Transfer_Part__c billPartOne = new Transfer_Part__c(
            Transfer__c = transferOne.Id,
            Production__c = productionOne.Id,
            Journal_Entry__c = entryOne.Id,
            Type__c = 'Bill',
            Amount__c = 100
        );
        Transfer_Part__c billPartTwo = new Transfer_Part__c(
            Transfer__c = transferTwo.Id,
            Production__c = productionTwo.Id,
            Journal_Entry__c = entryOne.Id,
            Type__c = 'Bill',
            Amount__c = 33.33
        );
        Transfer_Part__c billPartThree = new Transfer_Part__c(
            Transfer__c = transferTwo.Id,
            Production__c = productionTwo.Id,
            Journal_Entry__c = entryOne.Id,
            Type__c = 'Bill',
            Amount__c = 33.33
        );
        Transfer_Part__c billPartFour = new Transfer_Part__c(
            Transfer__c = transferTwo.Id,
            Production__c = productionTwo.Id,
            Journal_Entry__c = entryOne.Id,
            Type__c = 'Bill',
            Amount__c = 33.34
        );
        Transfer_Part__c billPartFive = new Transfer_Part__c(
            Transfer__c = transferThree.Id,
            Production__c = productionThree.Id,
            Journal_Entry__c = entryTwo.Id,
            Type__c = 'Bill',
            Amount__c = 199.93
        );
        Transfer_Part__c billPartSix = new Transfer_Part__c(
            Transfer__c = transferThree.Id,
            Production__c = productionThree.Id,
            Journal_Entry__c = entryTwo.Id,
            Type__c = 'Bill',
            Amount__c = 0.07
        );
        insert new List<Transfer_Part__c>{
            transferPartOne, transferPartTwo, transferPartThree,
            transferPartFour, transferPartFive, transferPartSix,
            utilityFeeOne, utilityFeeTwo,
            billPartOne, billPartTwo, billPartThree,
            billPartFour, billPartFive, billPartSix
        };

        Transfer_Part__c paymentPartOne = new Transfer_Part__c(
            Transfer__c = transferThree.Id,
            Production__c = productionThree.Id,
            Journal_Entry__c = entryTwo.Id,
            Type__c = 'Payment',
            Bill_Part__c = billPartOne.Id,
            Amount__c = 50.12
        );
        Transfer_Part__c paymentPartTwo = new Transfer_Part__c(
            Transfer__c = transferThree.Id,
            Production__c = productionThree.Id,
            Journal_Entry__c = entryTwo.Id,
            Type__c = 'Payment',
            Bill_Part__c = billPartFive.Id,
            Amount__c = 60.12
        );
        Transfer_Part__c paymentPartThree = new Transfer_Part__c(
            Transfer__c = transferThree.Id,
            Production__c = productionThree.Id,
            Journal_Entry__c = entryTwo.Id,
            Type__c = 'Payment',
            Bill_Part__c = billPartFive.Id,
            Amount__c = 40.12
        );
        insert new List<Transfer_Part__c>{
            paymentPartOne, paymentPartTwo, paymentPartThree
        };
    }

    @isTest
    public static void testGetTransferPartMap() {
        Set<Id> idSet = new Set<Id>();
        List<Transfer__c> allTransfers = [
            SELECT Id
            FROM Transfer__c
            ORDER BY Name
        ];
        for (Transfer__c transfer : allTransfers){
            idSet.add(transfer.Id);
        }
        System.assertEquals(3, allTransfers.size());

        ProductionDetailSelector selector = new ProductionDetailSelector();
        Map<Id, List<Transfer_Part__c>> partsMap = selector.getTransferPartMap(idSet);

        System.assertEquals(3, partsMap.keySet().size());
        System.assertEquals(1, partsMap.get(allTransfers[0].Id).size());
        System.assertEquals(3, partsMap.get(allTransfers[1].Id).size());
        System.assertEquals(2, partsMap.get(allTransfers[2].Id).size());
    }

    @isTest
    public static void testGetInvoicePartMap(){
        Set<String> entryExternalIds = new Set<String>{
            '2c92c0fa6e3a9391016e3e30d48066d2','2c92c0fa6e3a9391016e3df87b1f687a'
        };

        ProductionDetailSelector selector = new ProductionDetailSelector();
        Map<String, List<Transfer_Part__c>> partsMap = selector.getInvoicePartMap(entryExternalIds);

        System.assertEquals(2,partsMap.keySet().size());
        System.assertEquals(4,partsMap.get('2c92c0fa6e3a9391016e3e30d48066d2').size());
        System.assertEquals(2,partsMap.get('2c92c0fa6e3a9391016e3df87b1f687a').size());
    }

    @isTest
    public static void testGetPaymentSum(){
        Set<String> entryExternalIds = new Set<String>{
            '2c92c0fa6e3a9391016e3e30d48066d2','2c92c0fa6e3a9391016e3df87b1f687a'
        };

        ProductionDetailSelector selector = new ProductionDetailSelector();
        Map<Id,Decimal> paymentMap = selector.getPaymentSum(entryExternalIds);

        List<Transfer_Part__c> entries = [
            SELECT Id, Journal_Entry__r.External_Id__c
            FROM Transfer_Part__c
            WHERE Type__c = 'Bill'
            AND (Amount__c = 100 OR Amount__c = 199.93)
            ORDER BY Amount__c
            LIMIT 2
        ];

        System.assertEquals(50.12,paymentMap.get(entries[0].Id));
        System.assertEquals(100.24,paymentMap.get(entries[1].Id));
    }
}