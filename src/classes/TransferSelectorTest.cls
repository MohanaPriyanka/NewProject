/**
 * Created by SarahRenfro on 10/10/2019.
 */

@IsTest
public class TransferSelectorTest {
    @TestSetup
    public static void setupTestData() {
        TestFactory.insertBWAddress();
        TestFactory.setCSBillSettings();

        Utility__c eversource = new Utility__c(
            Name = 'Eversource',
            Number_of_Decimal_Places__c = 2
        );
        insert new List<Utility__c>{
            eversource
        };

        Load_U__c everLZU = new Load_U__c(Name = '02633',
            LZ__c = 'SEMA',
            Town__c = 'Medfield');
        insert new List<Load_U__c>{
            everLZU
        };

        ZipCode_Utility_Junction__c junction = new ZipCode_Utility_Junction__c(
            Load_Zone_Utility__c = everLZU.Id,
            Utility__c = eversource.Id
        );
        insert new List<ZipCode_Utility_Junction__c>{
            junction
        };

        Utility_NMC_Tariff__c everbillNMC = new Utility_NMC_Tariff__c(Name = 'Eversource SEMA Class 2',
            Utility__c = 'Eversource',
            Class__c = 'Class 2',
            Value_of_Net_Metering_Credit__c = 0.1848,
            Current_Billing_Rate__c = TRUE);
        insert new List<Utility_NMC_Tariff__c>{
            everbillNMC
        };

        Product2 normalCSProduct = new Product2(Name = 'BlueWave Community Solar',
            Family = 'Community Solar',
            Product_Type__c = 'Community Solar',
            State__c = 'MA',
            ProductCode = 'CS - BlueWave - 10%',
            IsActive = True,
            Lender_of_Record__c = 'BlueWave',
            NMC_Discount__c = 10,
            Annual_kWh_Maximum__c = 100000000,
            NM_Rate_Floor__c = 0,
            Monthly_Late_Fee__c = 1);
        insert new List<Product2>{
            normalCSProduct
        };

        Account clientAccount = new Account(name = 'Test Client');
        insert clientAccount;

        Contact clientContact = new Contact(AccountId = clientAccount.Id, FirstName = 'Test', LastName = 'Client');
        insert clientContact;

        Entity__c entity1 = new Entity__c(
            Name = 'Project A Oak Road',
            Client_Account__c = clientAccount.Id
        );
        insert entity1;

        Shared_Solar_System__c sss1 =
            new Shared_Solar_System__c(Name = 'Project A Oak Road',
                Service_Territory__c = 'SEMA',
                Open__c = true,
                Client_Account__c = clientAccount.Id,
                Reserved_Capacity_kW_DC__c = '0',
                Capacity_Committed_kW_DC__c = 0,
                Total_System_Size_kWh_DC__c = 1445.86,
                Total_System_Size_kW_AC__c = 996,
                System_Utility__c = 'Eversource',
                Credit_Score_Requirement__c = 200,
                Assignment_order__c = '1',
                Billing_Method__c = 'NMC',
                Utility_NMC_Tariff__c = everbillNMC.Id,
                Expected_Yield_kWh_kW__c = 1300,
                Assemblage_Count__c = 1,
                Product__c = normalCSProduct.Id,
                Sales_Partners__c = 'All',
                BWC_Project_Entity_Manual__c = entity1.Id,
                Maximum_Subscription_Assemblage__c = 25,
                Utility__c = eversource.Id);

        Shared_Solar_System__c sss2 =
            new Shared_Solar_System__c(Name = 'Project B Main St',
                Service_Territory__c = 'SEMA',
                Open__c = true,
                Client_Account__c = clientAccount.Id,
                Reserved_Capacity_kW_DC__c = '0',
                Capacity_Committed_kW_DC__c = 0,
                Total_System_Size_kWh_DC__c = 1445.86,
                Total_System_Size_kW_AC__c = 996,
                System_Utility__c = 'Eversource',
                Credit_Score_Requirement__c = 200,
                Assignment_order__c = '2',
                Utility_NMC_Tariff__c = everbillNMC.Id,
                Billing_Method__c = 'NMC',
                Expected_Yield_kWh_kW__c = 1300,
                Assemblage_Count__c = 1,
                Product__c = normalCSProduct.Id,
                Sales_Partners__c = 'All',
                BWC_Project_Entity_Manual__c = entity1.Id,
                Maximum_Subscription_Assemblage__c = 25,
                Utility__c = eversource.Id);

        Shared_Solar_System__c sss3 =
            new Shared_Solar_System__c(Name = 'Project C Other St',
                Service_Territory__c = 'SEMA',
                Open__c = true,
                Client_Account__c = clientAccount.Id,
                Reserved_Capacity_kW_DC__c = '0',
                Capacity_Committed_kW_DC__c = 0,
                Total_System_Size_kWh_DC__c = 1245.86,
                Total_System_Size_kW_AC__c = 996,
                System_Utility__c = 'Eversource',
                Credit_Score_Requirement__c = 200,
                Assignment_order__c = '2',
                Utility_NMC_Tariff__c = everbillNMC.Id,
                Billing_Method__c = 'NMC',
                Expected_Yield_kWh_kW__c = 1300,
                Assemblage_Count__c = 1,
                Product__c = normalCSProduct.Id,
                Sales_Partners__c = 'All',
                BWC_Project_Entity_Manual__c = entity1.Id,
                Maximum_Subscription_Assemblage__c = 25,
                Utility__c = eversource.Id);
        insert new List<Shared_Solar_System__c>{
            sss1, sss2, sss3
        };



        Date thisMonth = Date.today();
        Date lastMonth = thisMonth.addMonths(-1);
        Date nextMonth = thisMonth.addMonths(1);

        Schedule_Z__c scheduleZ1 = new Schedule_Z__c(
            Name = '18-0515 Oxford Barrett St. P1',
            Shared_Solar_System__c = sss1.Id,
            Status__c = 'Billing'
        );

        Schedule_Z__c scheduleZ2 = new Schedule_Z__c(
            Name = '18-0515 Oxford Barrett St. P2',
            Shared_Solar_System__c = sss2.Id,
            Status__c = 'Billing'
        );

        Schedule_Z__c scheduleZ3 = new Schedule_Z__c(
            Name = '18-0515 Oxford Barrett St. P2',
            Shared_Solar_System__c = sss3.Id,
            Status__c = 'Billing'
        );

        insert new List<Schedule_Z__c>{
            scheduleZ1, scheduleZ2, scheduleZ3
        };


        Bill_Period__c bpA = new Bill_Period__c(
            Name = 'sssA - This Month',
            Shared_Solar_System__c = sss1.Id,
            Bill_Date__c = thisMonth
        );

        Bill_Period__c bpB = new Bill_Period__c(
            Name = 'sssB - This Month',
            Shared_Solar_System__c = sss2.Id,
            Bill_Date__c = thisMonth
        );

        Bill_Period__c bpC1 = new Bill_Period__c(
            Name = 'sssC - This Month',
            Shared_Solar_System__c = sss3.Id,
            Bill_Date__c = thisMonth
        );

        Bill_Period__c bpC2 = new Bill_Period__c(
            Name = 'sssC - Next Month',
            Shared_Solar_System__c = sss3.Id,
            Bill_Date__c = nextMonth
        );

        insert new List<Bill_Period__c>{bpA, bpB, bpC1, bpC2};

        // 5 productions
        Production__c prodA = new Production__c(
            Name = 'sssA This Month Production',
            Shared_Solar_System__c = sss1.Id,
            Start_Date__c = lastMonth - 1,
            End_Date__c = lastMonth,
            Production_kWh__c = 90000,
            Credits_Generated__c = 16632
        );

        Production__c prodB = new Production__c(
            Name = 'sssB This Month Production',
            Shared_Solar_System__c = sss2.Id,
            Start_Date__c = lastMonth - 1,
            End_Date__c = lastMonth,
            Production_kWh__c = 120000,
            Credits_Generated__c = 22176
        );

        Production__c prodC = new Production__c(
            Name = 'sssC This Month Production',
            Shared_Solar_System__c = sss3.Id,
            Start_Date__c = lastMonth - 1,
            End_Date__c = lastMonth ,
            Production_kWh__c = 140000,
            Credits_Generated__c = 25872
        );

        Production__c prodC2 = new Production__c(
            Name = 'sssC Next Month Production',
            Shared_Solar_System__c = sss3.Id,
            Start_Date__c = lastMonth,
            End_Date__c = thisMonth,
            Production_kWh__c = 142300,
            Credits_Generated__c = 25872
        );

        insert new List<Production__c>{prodA, prodB, prodC, prodC2};

        Transfer__c transferA = new Transfer__c(
            Name = 'Main Transfer - sssA This Month',
            Bill_Period__c = bpA.Id,
            Date_of_Transfer__c = lastMonth,
            Shared_Solar_System__c = sss1.Id,
            Transfer_Type__c = 'Main',
            Allocation_Schedule__c = scheduleZ1.Id,
            Attempted_kWh_Transfer__c = 90000,
            Attempted_Transfer__c = 16632,
            Transfer_Amount__c = 16632,
            Default_Credit_Value__c = 0.1848
        );

        Transfer__c transferB = new Transfer__c(
            Name = 'Main Transfer - sssB This Month',
            Bill_Period__c = bpB.Id,
            Date_of_Transfer__c = lastMonth,
            Shared_Solar_System__c = sss2.Id,
            Transfer_Type__c = 'Main',
            Allocation_Schedule__c = scheduleZ2.Id,
            Attempted_kWh_Transfer__c = 120000,
            Attempted_Transfer__c = 22176,
            Transfer_Amount__c = 22176,
            Default_Credit_Value__c = 0.1848
        );

        Transfer__c transferC = new Transfer__c(
            Name = 'Main Transfer - sssC This Month',
            Bill_Period__c = bpC1.Id,
            Date_of_Transfer__c = lastMonth,
            Shared_Solar_System__c = sss3.Id,
            Transfer_Type__c = 'Main',
            Allocation_Schedule__c = scheduleZ3.Id,
            Attempted_kWh_Transfer__c = 140000,
            Attempted_Transfer__c = 25872,
            Transfer_Amount__c = 25872,
            Default_Credit_Value__c = 0.1848
        );

        Transfer__c transferC2 = new Transfer__c(
            Name = 'Main Transfer - sssC Next Month',
            Date_of_Transfer__c = thisMonth,
            Shared_Solar_System__c = sss3.Id,
            Transfer_Type__c = 'One-Off',
            Bills_Generated__c = false,
            Allocation_Schedule__c = scheduleZ3.Id,
            Attempted_kWh_Transfer__c = 142300,
            Attempted_Transfer__c = 25872,
            Transfer_Amount__c = 25872,
            Default_Credit_Value__c = 0.1548
        );

        insert new List<Transfer__c>{transferA, transferB, transferC, transferC2};
    }


    @IsTest
    static void testQueryTransfer() {
        Date todaysDate = Date.today();

        List<Transfer__c> transferList;
        transferList = TransferSelector.getTransfersByMonth(todaysDate.month(), todaysDate.year());

        System.assertEquals(3, transferList.size());

        List<Transfer__c> transfersById;
        transfersById = TransferSelector.getAllTransfersById(new List<Id>{transferList[0].Id, transferList[1].Id });

        System.assertEquals(2, transfersById.size());

    }


    @IsTest
    static void testGetTransferById() {
        Shared_Solar_System__c sssC = [SELECT Id FROM Shared_Solar_System__c WHERE Name = 'Project C Other St' LIMIT 1];
        List<Transfer__c> transfers = TransferSelector.getAllTransfersBySSS(new List<Id>{sssC.Id});

        System.assertEquals(1, transfers.size());

        Transfer__c checkTransfer = TransferSelector.getTransferById(transfers[0].Id);

        System.assertNotEquals(null, checkTransfer);
    }


    @IsTest
    static void testGetAllTransfersBySSS() {
        Shared_Solar_System__c sssC = [SELECT Id FROM Shared_Solar_System__c WHERE Name = 'Project C Other St' LIMIT 1];
        List<Transfer__c> transfers = TransferSelector.getAllTransfersBySSS(new List<Id>{sssC.Id});

        System.assertEquals(1, transfers.size());
    }

    @IsTest
    static void testGetTransfersForBillPeriods() {
        Shared_Solar_System__c sssC = [SELECT Id FROM Shared_Solar_System__c WHERE Name = 'Project C Other St' LIMIT 1];
        List<Transfer__c> transfers = TransferSelector.getTransfersForBillPeriods(new Set<Id>{sssC.Id});

        System.assertEquals(1, transfers.size());
    }

    @IsTest
    static void testGetAllTransferByBillPeriod() {
        Bill_Period__c bp = [SELECT Id FROM Bill_Period__c WHERE Name = 'sssA - This Month' LIMIT 1];
        List<Transfer__c> transfers = TransferSelector.getAllTransfersByBillPeriod(new Set<Id>{bp.Id});

        System.assertEquals(1, transfers.size());
    }

    @IsTest
    static void testSSSWithoutTransfers() {
        List<Shared_Solar_System__c> sssList;
        sssList = SharedSolarSystemsSelector.getAllSSSWithTransfersNotInList(null);

        System.assertEquals(3, sssList.size());
    }
}