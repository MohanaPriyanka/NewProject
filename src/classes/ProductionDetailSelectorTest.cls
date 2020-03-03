@isTest
public class ProductionDetailSelectorTest {
    @testSetup public static void setupTestData() {
        // Don't need to test Allocation Schedule Population or transfer part creation:
        Util.DisableTrigger('Disable_TransferTrigger__c');
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
        insert new List<Transfer_Part__c>{
            transferPartOne, transferPartTwo, transferPartThree,
            transferPartFour, transferPartFive, transferPartSix,
            utilityFeeOne, utilityFeeTwo
        };
    }

    @isTest public static void testGetTransferPartMap() {
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
}