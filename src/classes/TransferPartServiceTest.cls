/**
 * Created by SarahRenfro on 9/5/2019.
 */

@IsTest
private class TransferPartServiceTest {

    @TestSetup
    public static void setupData() {

        Utility__c eversource = new Utility__c(
            Name = 'Eversource',
            Number_of_Decimal_Places__c = 2
        );

        insert eversource;

        Shared_Solar_System__c sss1 = new Shared_Solar_System__c(Name = 'Oxford Barrett St. P1',
            Service_Territory__c = 'SEMA',
            Service_Territories__c = 'SEMA',
            Open__c = true,
            Reserved_Capacity_kW_DC__c = '10',
            Capacity_Committed_kW_DC__c = 0,
            Total_System_Size_kWh_DC__c = 1445.86,
            Total_System_Size_kW_AC__c = 1000,
            Utility__c = eversource.Id,
            Credit_Score_Requirement__c = 300,
            Assignment_Order__c = '1',
            Expected_Yield_kWh_kW__c = 1300,
            Assemblage_Count__c = 1,
            Sales_Partners__c = 'All',
            Maximum_Subscription_Assemblage__c = 25);

        Shared_Solar_System__c sss2 = new Shared_Solar_System__c(Name = 'SSS 2',
            Service_Territory__c = 'NEMA',
            Service_Territories__c = 'NEMA',
            Open__c = true,
            Reserved_Capacity_kW_DC__c = '10',
            Capacity_Committed_kW_DC__c = 0,
            Total_System_Size_kWh_DC__c = 1445.86,
            Total_System_Size_kW_AC__c = 996,
            Utility__c = eversource.Id,
            Credit_Score_Requirement__c = 300,
            Assignment_Order__c = '2',
            Expected_Yield_kWh_kW__c = 1300,
            Assemblage_Count__c = 1,
            Sales_Partners__c = 'All',
            Maximum_Subscription_Assemblage__c = 25);

        insert new List<Shared_Solar_System__c> {sss1, sss2};

        Schedule_Z__c scheduleZ1 = new Schedule_Z__c(
            Name = '18-0515 Oxford Barrett St. P1',
            Shared_Solar_System__c = sss1.Id,
            Date_Enacted_by_Utility__c = Date.newInstance(2018,1,1),
            Status__c = 'Billing'
        );



        insert scheduleZ1;

        Production__c prod1 = new Production__c(
            Name = 'SSS 1 Production - May 2019',
            Shared_Solar_System__c = sss1.Id,
            Production_kWh__c = 20000,
            Credit_Value__c = 0.14,
            Credits_Generated__c = 10000,
            Start_Date__c = Date.newInstance(2019, 5, 1),
            End_Date__c = Date.newInstance(2019, 5, 29)
        );

        Production__c prod2 = new Production__c(
            Name = 'SSS 1 Production - June 2019',
            Shared_Solar_System__c = sss1.Id,
            Production_kWh__c = 15000,
            Credit_Value__c = 0.14,
            Credits_Generated__c = 8000,
            Start_Date__c = Date.newInstance(2019, 6, 1),
            End_Date__c = Date.newInstance(2019, 6, 29)
        );

        Production__c prod3 = new Production__c(
            Name = 'SSS 1 Production - July 2019',
            Shared_Solar_System__c = sss1.Id,
            Production_kWh__c = 10000,
            Credit_Value__c = 0.14,
            Credits_Generated__c = 5000,
            Start_Date__c = Date.newInstance(2019, 7, 1),
            End_Date__c = Date.newInstance(2019, 7, 29)
        );


        insert new List<Production__c> {prod1, prod2, prod3};

        Transfer_Part__c utilityFee = new Transfer_Part__c(
            Name = 'Eversource Utility Fee May 2019',
            Production__c = prod1.Id,
            Type__c = 'Fee',
            Fee_Paid_To__c = 'Utility',
            Amount__c = 10
        );

        insert utilityFee;

        //40 to be paid by excess
        Transfer__c onTime1 = new Transfer__c(
            Name = 'On-Time May Transfer',
            Allocation_Schedule__c = scheduleZ1.Id,
            Shared_Solar_System__c = sss1.Id,
            Attempted_Transfer__c = 9950,
            Transfer_Amount__c = 9950,
            Date_of_Transfer__c = Date.newInstance(2019, 6, 4)
        );

        //100 to be paid by excess
        Transfer__c onTime2 = new Transfer__c(
            Name = 'On-Time June Transfer',
            Allocation_Schedule__c = scheduleZ1.Id,
            Shared_Solar_System__c = sss1.Id,
            Attempted_Transfer__c = 7900,
            Transfer_Amount__c = 7900,
            Date_of_Transfer__c = Date.newInstance(2019, 7, 4)
        );

        //20 to be paid by excess
        Transfer__c onTimeToUpdate = new Transfer__c(
            Name = 'On-Time July Transfer',
            Allocation_Schedule__c = scheduleZ1.Id,
            Shared_Solar_System__c = sss1.Id,
            Attempted_Transfer__c = 4980,
            Transfer_Amount__c = 4980,
            Date_of_Transfer__c = Date.newInstance(2019, 8, 4)
        );

        insert new List<Transfer__c> {onTime1, onTime2, onTimeToUpdate};

        onTime1.Transfer_Type__c = 'On-Time';
        onTime2.Transfer_Type__c = 'On-Time';

        update new List<Transfer__c> {onTime1, onTime2};


    }


    @IsTest
    static void testOnTimeTransfer() {

        Transfer__c onTime = [
            SELECT Id, Transfer_Amount__c, Shared_Solar_System__r.Name, Total_Transferred__c, Transfer_Type__c
            FROM Transfer__c
            WHERE Name = 'On-Time July Transfer'
            LIMIT 1
        ];

        onTime.Transfer_Type__c = 'On-Time';
        update onTime;

        List<Transfer_Part__c> onTimeParts = [
          SELECT Id, Type__c, Amount__c, Transfer__c, Production__c
          FROM Transfer_Part__c
            WHERE Transfer__c = :onTime.Id
        ];

        Production__c production = [
            SELECT Id, Name, Credits_Transferred__c, Untransferred_Credits__c
            FROM Production__c
            WHERE Id = :onTimeParts[0].Production__c
            LIMIT 1
        ];

        Transfer__c checkTransfer = [SELECT Id, Total_Transferred__c FROM Transfer__c WHERE Id = :onTime.Id LIMIT 1];

        System.assertEquals(1, onTimeParts.size());
        System.assertEquals('Transfer', onTimeParts[0].Type__c);
        System.assertEquals(4980, onTimeParts[0].Amount__c);
        System.assertEquals(checkTransfer.Id, onTimeParts[0].Transfer__c);
        System.assertEquals(4980, checkTransfer.Total_Transferred__c);
        System.assertEquals('SSS 1 Production - July 2019', production.Name);
        System.assertEquals(4980, production.Credits_Transferred__c);
        System.assertEquals(20, production.Untransferred_Credits__c);


    }

    @IsTest
    public static void testExcessCreditTransfer() {

        Shared_Solar_System__c sss1 = [
            SELECT Id
            FROM Shared_Solar_System__c
            WHERE Name = 'Oxford Barrett St. P1'
            LIMIT 1
        ];

        Schedule_Z__c scheduleZ = [SELECT Id FROM Schedule_Z__c LIMIT 1];

        Transfer__c excessTransfer = new Transfer__c(
            Name = 'Excess May Transfer',
            Allocation_Schedule__c = scheduleZ.Id,
            Shared_Solar_System__c = sss1.Id,
            Attempted_Transfer__c = 40,
            Transfer_Amount__c = 40,
            Date_of_Transfer__c = Date.newInstance(2019, 8, 2)
        );

        insert excessTransfer;

        excessTransfer.Transfer_Type__c = 'Excess Credit';
        update excessTransfer;

        List<Transfer_Part__c> excessParts = [
            SELECT Id, Type__c, Amount__c, Transfer__c, Production__c
            FROM Transfer_Part__c
            WHERE Transfer__c = :excessTransfer.Id
        ];

        List<Production__c> productions = [
            SELECT Id, Name, Credits_Transferred__c, Untransferred_Credits__c
            FROM Production__c
            WHERE Id = :excessParts[0].Production__c
            ORDER BY Start_Date__c DESC
        ];

        Transfer__c checkTransfer = [
            SELECT Id, Total_Transferred__c
            FROM Transfer__c
            WHERE Id = :excessTransfer.Id
            LIMIT 1
        ];


        System.assertEquals(1, excessParts.size());
        System.assertEquals(40, excessParts[0].Amount__c);
        System.assertEquals(excessTransfer.Id, excessParts[0].Transfer__c);
        System.assertEquals(40, checkTransfer.Total_Transferred__c);
        System.assertEquals('Transfer', excessParts[0].Type__c);
        System.assertEquals('SSS 1 Production - May 2019', productions[0].Name);
        System.assertEquals(9990, productions[0].Credits_Transferred__c);
        System.assertEquals(0, productions[0].Untransferred_Credits__c);


    }

    @IsTest
    public static void testMultipleExcessCreditParts(){
        Shared_Solar_System__c sss1 = [
            SELECT Id
            FROM Shared_Solar_System__c
            WHERE Name = 'Oxford Barrett St. P1'
            LIMIT 1
        ];

        Schedule_Z__c scheduleZ = [SELECT Id FROM Schedule_Z__c LIMIT 1];

        Transfer__c excessTransfer = new Transfer__c(
            Name = 'Excess May Transfer',
            Allocation_Schedule__c = scheduleZ.Id,
            Shared_Solar_System__c = sss1.Id,
            Attempted_Transfer__c = 130,
            Transfer_Amount__c = 130,
            Date_of_Transfer__c = Date.newInstance(2019, 8, 2)
        );

        insert excessTransfer;

        excessTransfer.Transfer_Type__c = 'Excess Credit';
        update excessTransfer;

        List<Transfer_Part__c> excessParts = [
            SELECT Id, Type__c, Amount__c, Transfer__c, Production__c, Production__r.Name, Production__r.Id
            FROM Transfer_Part__c
            WHERE Transfer__c = :excessTransfer.Id
            ORDER BY Production__r.Start_Date__c ASC
        ];

        List<Production__c> productions = [
            SELECT Id, Name, Credits_Transferred__c, Untransferred_Credits__c
            FROM Production__c
            ORDER BY Start_Date__c ASC
        ];
        Transfer__c checkTransfer = [
            SELECT Id, Total_Transferred__c, Transfer_Amount__c
            FROM Transfer__c
            WHERE Id = :excessTransfer.Id
            LIMIT 1
        ];

        System.assertEquals(2, excessParts.size());
        System.assertEquals(checkTransfer.Total_Transferred__c, excessTransfer.Transfer_Amount__c);

        //First Transfer Part
        System.assertEquals(40, excessParts[0].Amount__c);
        System.assertEquals(excessTransfer.Id, excessParts[0].Transfer__c);
        System.assertEquals('Transfer', excessParts[0].Type__c);
        System.assertEquals('SSS 1 Production - May 2019', excessParts[0].Production__r.Name);
        System.assertEquals(productions[0].Id, excessParts[0].Production__r.Id);
        System.assertEquals(9990, productions[0].Credits_Transferred__c);
        System.assertEquals(0, productions[0].Untransferred_Credits__c);

        //Second Transfer Part
        System.assertEquals(90, excessParts[1].Amount__c);
        System.assertEquals(excessTransfer.Id, excessParts[1].Transfer__c);
        System.assertEquals('Transfer', excessParts[1].Type__c);
        System.assertEquals('SSS 1 Production - June 2019', excessParts[1].Production__r.Name);
        System.assertEquals(productions[1].Id, excessParts[1].Production__r.Id);
        System.assertEquals(7990, productions[1].Credits_Transferred__c);
        System.assertEquals(10, productions[1].Untransferred_Credits__c);

    }

    //TODO: WRITE RETURNED TRANSFER TEST


    @IsTest
    public static void testCreateCaseForTooMuchTransferCredit(){
        Shared_Solar_System__c sss1 = [
            SELECT Id
            FROM Shared_Solar_System__c
            WHERE Name = 'Oxford Barrett St. P1'
            LIMIT 1
        ];

        Schedule_Z__c scheduleZ = [SELECT Id FROM Schedule_Z__c LIMIT 1];

        Transfer__c excessTransfer = new Transfer__c(
            Name = 'Excess May Transfer',
            Allocation_Schedule__c = scheduleZ.Id,
            Shared_Solar_System__c = sss1.Id,
            Attempted_Transfer__c = 150,
            Transfer_Amount__c = 150,
            Date_of_Transfer__c = Date.newInstance(2019, 8, 2)
        );

        insert excessTransfer;

        excessTransfer.Transfer_Type__c = 'Excess Credit';
        update excessTransfer;

        List<Transfer_Part__c> excessParts = [
            SELECT Id, Type__c, Amount__c, Transfer__c, Production__c, Production__r.Name, Production__r.Id
            FROM Transfer_Part__c
            WHERE Transfer__c = :excessTransfer.Id
            ORDER BY Production__r.Start_Date__c ASC
        ];

        Transfer__c checkTransfer = [
            SELECT Id, Total_Transferred__c, Transfer_Amount__c
            FROM Transfer__c
            WHERE Id = :excessTransfer.Id
            LIMIT 1
        ];

        List<Case> checkCase = [SELECT Id, Subject FROM Case WHERE Shared_Solar_System__c = :excessTransfer.Shared_Solar_System__c];

        System.assertEquals(1, checkCase.size());
        System.assertEquals(2, excessParts.size());

        System.assertEquals(140, checkTransfer.Total_Transferred__c);
        System.assertEquals(150, checkTransfer.Transfer_Amount__c);

    }

    @IsTest
    public static void testUtilityFees() {

        Production__c production = [
            SELECT Id, Name, Credits_Transferred__c, Untransferred_Credits__c, Credits_Available_for_Allocation__c
            FROM Production__c
            WHERE Name = 'SSS 1 Production - June 2019'
            LIMIT 1
        ];

        System.assertEquals(8000, production.Credits_Available_for_Allocation__c);

        Transfer_Part__c utilityFee = new Transfer_Part__c(
            Name = 'Eversource Utility Fee May 2019',
            Production__c = production.Id,
            Type__c = 'Fee',
            Fee_Paid_To__c = 'Utility',
            Amount__c = 10
        );

        insert utilityFee;

        Production__c checkProd = [
            SELECT Id, Utility_Fees__c, Credits_Available_for_Allocation__c
            FROM Production__c
            WHERE Id =:production.Id
            LIMIT 1
        ];

        System.assertEquals(10, checkProd.Utility_Fees__c);
        System.assertEquals(7990, checkProd.Credits_Available_for_Allocation__c);

    }






}