@isTest
public class CongaTemplateAssignerTest {
    public static final String NON_AUTOPAY_MESSAGE = 'Non-Autopay Message';
    public static final String AUTOPAY_MESSAGE = 'Autopay Message';

    @testSetup static void setupTestData() {
        TestBillCreationForCancelledCustomers.testSetupBillRecords();

        APXTConga4__Conga_Template__c anchorTemplate = new APXTConga4__Conga_Template__c(
            APXTConga4__Name__c = 'anchorTemplate',
            Active__c = true,
            Autopay__c = false,
            Anchor__c = true,
            Max_Number_of_UASBs__c = null,
            Payment_Plan__c = false,
            Welcome_Insert__c = false,
            Brand_Key__c = 'BluewaveLogo'
        );

        APXTConga4__Conga_Template__c bwShortBill = new APXTConga4__Conga_Template__c(
            APXTConga4__Name__c = 'bwShortBill',
            Active__c = true,
            Autopay__c = false,
            Anchor__c = false,
            Max_Number_of_UASBs__c = 2,
            Payment_Plan__c = false,
            Welcome_Insert__c = false,
            Brand_Key__c = 'BluewaveLogo'
        );

        APXTConga4__Conga_Template__c bwLongBill = new APXTConga4__Conga_Template__c(
            APXTConga4__Name__c = 'bwLongBill',
            Active__c = true,
            Autopay__c = false,
            Anchor__c = false,
            Max_Number_of_UASBs__c = 5,
            Payment_Plan__c = false,
            Welcome_Insert__c = false,
            Brand_Key__c = 'BluewaveLogo'
        );

        APXTConga4__Conga_Template__c ampShortBill = new APXTConga4__Conga_Template__c(
            APXTConga4__Name__c = 'ampShortBill',
            Active__c = true,
            Autopay__c = false,
            Anchor__c = false,
            Max_Number_of_UASBs__c = 2,
            Payment_Plan__c = false,
            Welcome_Insert__c = false,
            Brand_Key__c = 'AmpRed'
        );

        APXTConga4__Conga_Template__c ampLongBill = new APXTConga4__Conga_Template__c(
            APXTConga4__Name__c = 'ampLongBill',
            Active__c = true,
            Autopay__c = false,
            Anchor__c = false,
            Max_Number_of_UASBs__c = 5,
            Payment_Plan__c = false,
            Welcome_Insert__c = false,
            Brand_Key__c = 'AmpRed'
        );

        APXTConga4__Conga_Template__c bwShortAutopay = new APXTConga4__Conga_Template__c(
            APXTConga4__Name__c = 'bwShortAutopay',
            Active__c = true,
            Autopay__c = true,
            Anchor__c = false,
            Max_Number_of_UASBs__c = 2,
            Payment_Plan__c = false,
            Welcome_Insert__c = false,
            Brand_Key__c = 'BluewaveLogo'
        );

        APXTConga4__Conga_Template__c bwLongAutopay = new APXTConga4__Conga_Template__c(
            APXTConga4__Name__c = 'bwLongAutopay',
            Active__c = true,
            Autopay__c = true,
            Anchor__c = false,
            Max_Number_of_UASBs__c = 5,
            Payment_Plan__c = false,
            Welcome_Insert__c = false,
            Brand_Key__c = 'BluewaveLogo'
        );

        APXTConga4__Conga_Template__c ampLongAutopay = new APXTConga4__Conga_Template__c(
            APXTConga4__Name__c = 'ampLongAutopay',
            Active__c = true,
            Autopay__c = true,
            Anchor__c = false,
            Max_Number_of_UASBs__c = 5,
            Payment_Plan__c = false,
            Welcome_Insert__c = false,
            Brand_Key__c = 'AmpRed'
        );

        APXTConga4__Conga_Template__c ampWelcomeLetter = new APXTConga4__Conga_Template__c(
            APXTConga4__Name__c = 'ampWelcomeLetter',
            Active__c = true,
            Anchor__c = false,
            Payment_Plan__c = false,
            Welcome_Insert__c = true,
            Brand_Key__c = 'AmpRed'
        );

        APXTConga4__Conga_Template__c bwWelcomeLetter = new APXTConga4__Conga_Template__c(
            APXTConga4__Name__c = 'bwWelcomeLetter',
            Active__c = true,
            Anchor__c = false,
            Payment_Plan__c = false,
            Welcome_Insert__c = true,
            Brand_Key__c = 'BluewaveLogo'
        );

        APXTConga4__Conga_Template__c bwPaymentPlan = new APXTConga4__Conga_Template__c(
            APXTConga4__Name__c = 'bwPaymentPlan',
            Active__c = true,
            Autopay__c = true,
            Anchor__c = false,
            Max_Number_of_UASBs__c = 22,
            Payment_Plan__c = true,
            Welcome_Insert__c = false,
            Brand_Key__c = 'BluewaveLogo'
        );

        // Missing: AMP Short Autopay to test error handling
        insert new List<APXTConga4__Conga_Template__c>{
            anchorTemplate, bwShortBill, bwLongBill, ampShortBill,
            ampLongBill, bwLongAutopay, bwShortAutopay, ampLongAutopay,
            ampWelcomeLetter, bwWelcomeLetter, bwPaymentPlan
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

        CS_Bill_Setting__c csBillSetting = new CS_Bill_Setting__c(
            Default_Bill_Message_for_Autopay__c = AUTOPAY_MESSAGE,
            Default_Bill_Message_for_Non_Autopay__c = NON_AUTOPAY_MESSAGE
        );
        insert csBillSetting;
    }

    static List<Account_Bill__c> queryAccountBills(){
        List <Account_Bill__c> accountBillList = [
            SELECT Id, Name, Published__c, Bill_Number__c, Month__c, Year__c, Bill_Template__c, Bill_Template__r.APXTConga4__Name__c,
                Parent_Account__r.Recurring_Billing__c, Parent_Account__r.Client_Brand_Key__c, Additional_Bill_Insert__c,
                Additional_Bill_Insert__r.APXTConga4__Name__c, Bill_Message__c
            FROM Account_Bill__c
            WHERE Published__c = FALSE
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

        Bill_Period__c bpB2 = new Bill_Period__c(
            Name = 'sssB - September 2016',
            Shared_Solar_System__c = sssList[0].Id,
            Bill_Date__c = todaysDate
        );

        Bill_Period__c bpA2 = new Bill_Period__c(
            Name = 'sssA - September 2016',
            Shared_Solar_System__c = sssList[1].Id,
            Bill_Date__c = todaysDate
        );

        insert new List<Bill_Period__c>{bpA2, bpB2};

        Production__c prodB3 = new Production__c(
            Name = 'sssB September Production',
            Shared_Solar_System__c = sssList[0].Id,
            Start_Date__c = oneMonthAgo,
            End_Date__c = todaysDate,
            Production_kWh__c = 73072.00,
            Credits_Generated__c = 12033.73
        );

        Production__c prodA2 = new Production__c(
            Name = 'sssA September Production',
            Shared_Solar_System__c = sssList[1].Id,
            Start_Date__c = oneMonthAgo,
            End_Date__c = todaysDate,
            Production_kWh__c = 73072.00,
            Credits_Generated__c = 12033.73
        );

        insert new List<Production__c>{prodB3, prodA2};

        Transfer__c transferB3 = new Transfer__c(
            Name = 'Main Transfer - sssB September',
            Bill_Period__c = bpB2.Id,
            Date_of_Transfer__c = todaysDate,
            Shared_Solar_System__c = sssList[0].Id,
            Transfer_Type__c = 'Main',
            Allocation_Schedule__c = schZOne.Id,
            Attempted_Transfer__c =  12033.73,
            Attempted_kWh_Transfer__c = 73072,
            Transfer_Amount__c =  12033.73,
            Default_Credit_Value__c = 0.13
        );

        Transfer__c transferA2 = new Transfer__c(
            Name = 'Main Transfer - sssA September',
            Bill_Period__c = bpA2.Id,
            Date_of_Transfer__c = todaysDate,
            Shared_Solar_System__c = sssList[1].Id,
            Transfer_Type__c = 'Main',
            Allocation_Schedule__c = schZTwo.Id,
            Attempted_Transfer__c =  12033.73,
            Attempted_kWh_Transfer__c = 73072,
            Transfer_Amount__c =  12033.73,
            Default_Credit_Value__c = 0.13
        );

        insert new List<Transfer__c>{transferA2, transferB3};

        TransferPartService transferPartService = new TransferPartService();
        transferPartService.createPartsFromTransfer(new List<Transfer__c>{transferA2, transferB3});

        TestBillCreationandPayment.runBillPeriod(new List<Id>{bpA2.Id, bpB2.Id});
    }

    @isTest public static void testBasicTemplates(){
        Test.startTest();

        /* For reference:
          acA A = UASB Count : 1
          acB B = UASB Count : 2
          acC C = UASB Count : 3
        */

        runSecondMonthProductionUpdates();

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

        Map<String,APXTConga4__Conga_Template__c> congaTemplateMap = getCongaTemplateMap();

        List<Account_Bill__c> prelimAccountBills = queryAccountBills();
        System.assertEquals(3, prelimAccountBills.size());
        System.assertEquals(null, prelimAccountBills[0].Bill_Template__c);
        System.assertEquals(null, prelimAccountBills[1].Bill_Template__c);
        System.assertEquals(null, prelimAccountBills[2].Bill_Template__c);

        InvocableCSBillTemplateAssigner.assignTemplates();

        Test.stopTest();

        List<Account_Bill__c> updatedAccountBills = queryAccountBills();

        System.assertEquals(3, updatedAccountBills.size());

        System.assertEquals(congaTemplateMap.get('ampShortBill').APXTConga4__Name__c, updatedAccountBills[0].Bill_Template__r.APXTConga4__Name__c);
        System.assertEquals(congaTemplateMap.get('bwShortAutopay').APXTConga4__Name__c, updatedAccountBills[1].Bill_Template__r.APXTConga4__Name__c);
        System.assertEquals(congaTemplateMap.get('bwLongBill').APXTConga4__Name__c, updatedAccountBills[2].Bill_Template__r.APXTConga4__Name__c);
        System.assertEquals(NON_AUTOPAY_MESSAGE, updatedAccountBills[0].Bill_Message__c);
        System.assertEquals(AUTOPAY_MESSAGE, updatedAccountBills[1].Bill_Message__c);
        System.assertEquals(NON_AUTOPAY_MESSAGE, updatedAccountBills[2].Bill_Message__c);
        System.assertEquals(null, updatedAccountBills[0].Additional_Bill_Insert__c);
        System.assertEquals(null, updatedAccountBills[1].Additional_Bill_Insert__c);
        System.assertEquals(null, updatedAccountBills[2].Additional_Bill_Insert__c);
    }

    @isTest public static void testPaymentPlan(){
        Test.startTest();

        /* For reference:
          acA A = UASB Count : 1
          acB B = UASB Count : 2
          acC C = UASB Count : 3
        */

        List<System_Bill__c> sbsToUpdate = new List<System_Bill__c>();
        for (System_Bill__c sysBill : [ SELECT Id, Name, Account_Bill__r.Parent_Account__r.Name,
                                        Distribute_This_Balance_as_Payment_Plan__c
                                        FROM System_Bill__c
                                        WHERE Account_Bill__r.Parent_Account__r.Name = 'acB B']){
            sysBill.Distribute_This_Balance_as_Payment_Plan__c = true;
            sbsToUpdate.add(sysBill);
        }
        update sbsToUpdate;

        runSecondMonthProductionUpdates();

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

        Map<String,APXTConga4__Conga_Template__c> congaTemplateMap = getCongaTemplateMap();

        List<Account_Bill__c> prelimAccountBills = queryAccountBills();
        System.assertEquals(3, prelimAccountBills.size());
        System.assertEquals(null, prelimAccountBills[0].Bill_Template__c);
        System.assertEquals(null, prelimAccountBills[1].Bill_Template__c);
        System.assertEquals(null, prelimAccountBills[2].Bill_Template__c);

        InvocableCSBillTemplateAssigner.assignTemplates();

        Test.stopTest();

        List<Account_Bill__c> updatedAccountBills = queryAccountBills();

        System.assertEquals(3, updatedAccountBills.size());

        System.assertEquals(congaTemplateMap.get('ampShortBill').APXTConga4__Name__c, updatedAccountBills[0].Bill_Template__r.APXTConga4__Name__c);
        System.assertEquals(congaTemplateMap.get('bwPaymentPlan').APXTConga4__Name__c, updatedAccountBills[1].Bill_Template__r.APXTConga4__Name__c);
        System.assertEquals(congaTemplateMap.get('bwLongBill').APXTConga4__Name__c, updatedAccountBills[2].Bill_Template__r.APXTConga4__Name__c);
    }

    @isTest public static void testWelcomeLetter(){
        Test.startTest();

        /* For reference (first production update is for >1 month):
          acA A = UASB Count : 1
          acB B = UASB Count : 3
          acC C = UASB Count : 4
        */

        List <Account_Bill__c> listAccountBills = [
            SELECT Id, Published__c
            FROM Account_Bill__c
            WHERE Published__c = true
            ORDER BY Name
        ];

        for (Account_Bill__c acctBill : listAccountBills) {
            acctBill.Published__c = false;
            acctBill.Date__c = System.Today();
            acctBill.Reason_For_Unpublish__c = 'Test Reason for Unpublishing bill';
        }
        update listAccountBills;

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

        Map<String,APXTConga4__Conga_Template__c> congaTemplateMap = getCongaTemplateMap();

        System.assertEquals(null, listAccountBills[0].Bill_Template__c);
        System.assertEquals(null, listAccountBills[1].Bill_Template__c);
        System.assertEquals(null, listAccountBills[2].Bill_Template__c);

        InvocableCSBillTemplateAssigner.assignTemplates();

        Test.stopTest();

        List<Account_Bill__c> updatedAccountBills = queryAccountBills();

        System.assertEquals(congaTemplateMap.get('ampShortBill').APXTConga4__Name__c, updatedAccountBills[0].Bill_Template__r.APXTConga4__Name__c);
        System.assertEquals(congaTemplateMap.get('bwLongAutopay').APXTConga4__Name__c, updatedAccountBills[1].Bill_Template__r.APXTConga4__Name__c);
        System.assertEquals(congaTemplateMap.get('bwLongBill').APXTConga4__Name__c, updatedAccountBills[2].Bill_Template__r.APXTConga4__Name__c);
        System.assertEquals(congaTemplateMap.get('ampWelcomeLetter').APXTConga4__Name__c, updatedAccountBills[0].Additional_Bill_Insert__r.APXTConga4__Name__c);
        System.assertEquals(congaTemplateMap.get('bwWelcomeLetter').APXTConga4__Name__c, updatedAccountBills[1].Additional_Bill_Insert__r.APXTConga4__Name__c);
        System.assertEquals(congaTemplateMap.get('bwWelcomeLetter').APXTConga4__Name__c, updatedAccountBills[2].Additional_Bill_Insert__r.APXTConga4__Name__c);
    }

    @isTest public static void testErrorLogging() {
        APXTConga4__Conga_Template__c templateToDelete = [
            SELECT Id, Name
            FROM APXTConga4__Conga_Template__c
            WHERE APXTConga4__Name__c = 'ampLongAutopay'
            LIMIT 1];

        delete templateToDelete;

        Test.startTest();

        /* For reference:
          acA A = UASB Count : 1
          acB B = UASB Count : 2
          acC C = UASB Count : 3
        */

        runSecondMonthProductionUpdates();

        List<Account> acctList = new List<Account>();
        for (Account acct : [SELECT Id, Name FROM Account]){
            if (acct.Name == 'acA A'){
                acct.Recurring_Billing__c = true;
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

        Map<String,APXTConga4__Conga_Template__c> congaTemplateMap = getCongaTemplateMap();

        List<Account_Bill__c> prelimAccountBills = queryAccountBills();
        System.assertEquals(3, prelimAccountBills.size());
        System.assertEquals(null, prelimAccountBills[0].Bill_Template__c);
        System.assertEquals(null, prelimAccountBills[1].Bill_Template__c);
        System.assertEquals(null, prelimAccountBills[2].Bill_Template__c);

        InvocableCSBillTemplateAssigner.assignTemplates();

        Test.stopTest();

        List<Error_Log__c> errorLogs = [SELECT Id, Name FROM Error_Log__c];
        List<Account_Bill__c> updatedAccountBills = queryAccountBills();

        System.assertEquals(3, updatedAccountBills.size());

        // AMP Short Autopay template does not exist. Should log an error:
        System.assertEquals(null, updatedAccountBills[0].Bill_Template__c);
        System.assertEquals(1, errorLogs.size());

        // Other templates should still be assigned:
        System.assertEquals(congaTemplateMap.get('bwShortAutopay').APXTConga4__Name__c, updatedAccountBills[1].Bill_Template__r.APXTConga4__Name__c);
        System.assertEquals(congaTemplateMap.get('bwLongBill').APXTConga4__Name__c, updatedAccountBills[2].Bill_Template__r.APXTConga4__Name__c);

    }
}