@isTest
public class CongaTemplateAssignerTest {
    @testSetup static void setupTestData() {
        TestBillCreationForCancelledCustomers.testSetupBillRecords();

        APXTConga4__Conga_Template__c anchorTemplate = new APXTConga4__Conga_Template__c(
            APXTConga4__Name__c = 'anchorTemplate',
            Active__c = true,
            Autopay__c = false,
            Anchor__c = true,
            Max_Number_of_UASBs__c = null,
            Brand_Key__c = 'BluewaveLogo'
        );

        APXTConga4__Conga_Template__c bwShortBill = new APXTConga4__Conga_Template__c(
            APXTConga4__Name__c = 'bwShortBill',
            Active__c = true,
            Autopay__c = false,
            Anchor__c = false,
            Max_Number_of_UASBs__c = 2,
            Brand_Key__c = 'BluewaveLogo'
        );

        APXTConga4__Conga_Template__c bwLongBill = new APXTConga4__Conga_Template__c(
            APXTConga4__Name__c = 'bwLongBill',
            Active__c = true,
            Autopay__c = false,
            Anchor__c = false,
            Max_Number_of_UASBs__c = 5,
            Brand_Key__c = 'BluewaveLogo'
        );

        APXTConga4__Conga_Template__c ampShortBill = new APXTConga4__Conga_Template__c(
            APXTConga4__Name__c = 'ampShortBill',
            Active__c = true,
            Autopay__c = false,
            Anchor__c = false,
            Max_Number_of_UASBs__c = 2,
            Brand_Key__c = 'AmpRed'
        );

        APXTConga4__Conga_Template__c ampLongBill = new APXTConga4__Conga_Template__c(
            APXTConga4__Name__c = 'ampLongBill',
            Active__c = true,
            Autopay__c = false,
            Anchor__c = false,
            Max_Number_of_UASBs__c = 5,
            Brand_Key__c = 'AmpRed'
        );

        APXTConga4__Conga_Template__c bwLongAutopay = new APXTConga4__Conga_Template__c(
            APXTConga4__Name__c = 'bwLongAutopay',
            Active__c = true,
            Autopay__c = true,
            Anchor__c = false,
            Max_Number_of_UASBs__c = 5,
            Brand_Key__c = 'BluewaveLogo'
        );

        APXTConga4__Conga_Template__c ampLongAutopay = new APXTConga4__Conga_Template__c(
            APXTConga4__Name__c = 'ampLongAutopay',
            Active__c = true,
            Autopay__c = true,
            Anchor__c = false,
            Max_Number_of_UASBs__c = 5,
            Brand_Key__c = 'AmpRed'
        );

        // Missing: AMP Short Autopay, BW Short Autopay to test error handling
        insert new List<APXTConga4__Conga_Template__c>{
            anchorTemplate, bwShortBill, bwLongBill, ampShortBill, ampLongBill, bwLongAutopay, ampLongAutopay
        };

        List <Account_Bill__c> listAccountBills = [
            SELECT Id, Published__c
            FROM Account_Bill__c
            WHERE Published__c = FALSE
        ];

        for (Account_Bill__c acctBill : listAccountBills) {
            acctBill.Published__c = True;
        }
        update listAccountBills;
    }

    static List<Account_Bill__c> queryAccountBills(){
        List <Account_Bill__c> accountBillList = [
            SELECT Id, Name, Published__c, Month__c, Year__c, Conga_Template__c
            FROM Account_Bill__c
            WHERE Published__c = false
            ORDER BY Name
        ];
        return accountBillList;
    }

    static Map<String,APXTConga4__Conga_Template__c> getCongaTemplateMap(){
        Map<String,APXTConga4__Conga_Template__c> congaTemplateMap = new Map<String,APXTConga4__Conga_Template__c>();
        for (APXTConga4__Conga_Template__c template : [SELECT Id, APXTConga4__Name__c
                                                       FROM APXTConga4__Conga_Template__c]){
            congaTemplateMap.put(template.APXTConga4__Name__c, template);
        }
        return congaTemplateMap;
    }

    static void runSecondMonthProductionUpdates() {
        List<Shared_Solar_System__c> sssList = [
            SELECT Id, Name, BWC_Project_Entity_Manual__r.Id, Product__r.Id
            FROM Shared_Solar_System__c
            ORDER BY Name DESC];

        Schedule_Z__c schZOne = new Schedule_Z__c(
            Name = '18-0515 Project A Oak Rd',
            Shared_Solar_System__c = sssList[0].Id,
            Status__c = 'Billing'
        );

        Schedule_Z__c schZTwo = new Schedule_Z__c(
            Name = '18-0515 Project B Main St',
            Shared_Solar_System__c = sssList[1].Id,
            Status__c = 'Billing'
        );

        insert new List<Schedule_Z__c>{schZOne, schZTwo};

        Date todaysDate = Date.today();
        Date oneMonthAgo = todaysDate.addMonths(-1);
        Date oneMonthInFuture = todaysDate.addMonths(1);

        Energy_Usage_Update__c secondProdUpdateSSS1 = new Energy_Usage_Update__c (
            Name = 'sssB - September 2016',
            Shared_Solar_System__c = sssList[0].Id,
            Production__c = 73072.00,
            Due_Date__c = oneMonthInFuture,
            Billing_Period_Start_Date__c = oneMonthAgo,
            Billing_Period_End_Date__c = todaysDate,
            Total_System_NMCs__c = 12033.73,
            Date__c = todaysDate,
            Schedule_Z__c =  schZOne.Id
        );
        insert secondProdUpdateSSS1;

        Energy_Usage_Update__c secondProdUpdateSSS2 = new Energy_Usage_Update__c (
            Name = 'sssA - September 2016',
            Shared_Solar_System__c = sssList[1].Id,
            Production__c = 73072.00,
            Due_Date__c = oneMonthInFuture,
            Billing_Period_Start_Date__c = oneMonthAgo,
            Billing_Period_End_Date__c = todaysDate,
            Total_System_NMCs__c = 12033.73,
            Date__c = todaysDate,
            Schedule_Z__c =  schZTwo.Id
        );

        insert secondProdUpdateSSS2;

        secondProdUpdateSSS1.Generate_Bills__c = true;
        secondProdUpdateSSS2.Generate_Bills__c = true;
        update secondProdUpdateSSS1;
        update secondProdUpdateSSS2;
    }

    @isTest public static void testTemplateAssignment(){
        Test.startTest();

        /* For reference:
          acA A = UASB Count : 1
          acB B = UASB Count : 3
          acC C = UASB Count : 4 */

        List<Account> acctList = new List<Account>();
        for (Account acct : [SELECT Id, Name FROM Account]){
            if (acct.Name == 'acA A'){
                acct.Recurring_Billing__c = false;
                acct.Client_Brand_Key__c = 'AmpRed';
            } else if (acct.Name == 'acB B'){
                acct.Recurring_Billing__c = true;
                acct.Client_Brand_Key__c = 'BluewaveLogo';
            } else {
                acct.Recurring_Billing__c = false;
                acct.Client_Brand_Key__c = 'BluewaveLogo';
            }
            acctList.add(acct);
        }
        update acctList;

        runSecondMonthProductionUpdates();

        Map<String,APXTConga4__Conga_Template__c> congaTemplateMap = getCongaTemplateMap();
        system.debug(congaTemplateMap);
        List <Account_Bill__c> prelimAccountBills = queryAccountBills();
        system.debug(prelimAccountBills);
        System.assertEquals(3, prelimAccountBills.size());
        System.assertEquals(null, prelimAccountBills[0].Conga_Template__c);
        System.assertEquals(null, prelimAccountBills[1].Conga_Template__c);
        System.assertEquals(null, prelimAccountBills[2].Conga_Template__c);

        APXT_BPM__Conductor__c congaConductor = new APXT_BPM__Conductor__c (
            APXT_BPM__Title__c = 'Conga Record'
        );
        insert congaConductor;
        congaConductor.Assign_Templates__c = true;
        update congaConductor;

        Test.stopTest();

        List<Account_Bill__c> updatedAccountBills = queryAccountBills();

        System.assertEquals(3, updatedAccountBills.size());
        System.assertEquals(congaTemplateMap.get('ampShortBill').Id, updatedAccountBills[0].Conga_Template__c);
        System.assertEquals(congaTemplateMap.get('bwLongAutopay').Id, updatedAccountBills[1].Conga_Template__c);
        System.assertEquals(congaTemplateMap.get('bwLongBill').Id, updatedAccountBills[2].Conga_Template__c);
    }
}