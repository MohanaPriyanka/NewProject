@isTest
public class TestBillCreationandPayment {
    @testSetup public static void CSTestRecordWarehouse(){
        Utility_NMC_Tariff__c eversizeNMC = new Utility_NMC_Tariff__c (Name = 'Eversource SEMA Class 2', 
                                                                       Utility__c = 'Eversource', 
                                                                       Class__c = 'Class 2',
                                                                       Value_of_Net_Metering_Credit__c = 0.1848,
                                                                       Sizing_Rate__c = TRUE);

        Utility_NMC_Tariff__c ngridsizeNMC = new Utility_NMC_Tariff__c (Name = 'National Grid WCMA Class 2', 
                                                                        Utility__c = 'National Grid', 
                                                                        Class__c = 'Class 2',
                                                                        Value_of_Net_Metering_Credit__c = 0.1848,
                                                                        Sizing_Rate__c = TRUE);

        insert new List<Utility_NMC_Tariff__c>{eversizeNMC, ngridsizeNMC};
        
        Load_U__c everLZU = new Load_U__c (Name = '02633', 
                                           Load_zone__c = 'SEMA Eversource', 
                                           LZ__c = 'SEMA', 
                                           Utility__C = 'Eversource', 
                                           Town__c= 'Medfield');

        Load_U__c ngridLZU = new Load_U__c (Name = '01570', 
                                            Load_zone__c= 'WCMA National Grid', 
                                            LZ__c = 'WCMA', 
                                            Utility__C = 'National Grid', 
                                            Town__c= 'Westtown');

        insert new List<Load_U__c>{everLZU, ngridLZU};
        insert new BW_Address__c(Name = 'BlueWave', Address_Line_One__c = '137 Newbury Street', Address_Line_Two__c = 'Boston, MA 02114');

        Entity__c entity1 = new Entity__c (Name = 'Oxford Barrett St. P1');
        insert entity1;
        
        Shared_Solar_System__c sss1 = 
            new Shared_Solar_System__c(Name = 'Oxford Barrett St. P1',
                                       Service_Territory__c = 'SEMA',
                                       Service_Territories__c = 'SEMA',
                                       Open__c = true,
                                       Reserved_Capacity_kW_DC__c = '0',
                                       Capacity_Committed_kW_DC__c = 0,
                                       Total_System_Size_kWh_DC__c = 1445.86,
                                       Total_System_Size_kW_AC__c  = 996,
                                       System_Utility__c = 'Eversource',
                                       Credit_Score_Requirement__c = 200,
                                       Assignment_order__c = '1',
                                       Utility_NMC_Tariff__c = eversizeNMC.Id,
                                       Expected_Yield_kWh_kW__c = 1300,
                                       Assemblage_Count__c = 1,
                                       Sales_Partners__c = 'All',
                                       BWC_Project_Entity_Manual__c = entity1.Id,
                                       Maximum_Subscription_Assemblage__c = 25);

        Shared_Solar_System__c sss2 = 
            new Shared_Solar_System__c(Name = 'Oxford Barrett St. P2',
                                       Service_Territory__c = 'SEMA',
                                       Service_Territories__c = 'SEMA',
                                       Open__c = true,
                                       Reserved_Capacity_kW_DC__c = '0',
                                       Capacity_Committed_kW_DC__c = 0,
                                       Total_System_Size_kWh_DC__c = 1445.86,
                                       Total_System_Size_kW_AC__c  = 996,
                                       System_Utility__c = 'Eversource',
                                       Credit_Score_Requirement__c = 200,
                                       Assignment_order__c = '2',
                                       Utility_NMC_Tariff__c = eversizeNMC.Id,
                                       Expected_Yield_kWh_kW__c = 1300,
                                       Assemblage_Count__c = 1,
                                       Sales_Partners__c = 'All',
                                       Maximum_Subscription_Assemblage__c = 25);
        insert new List<Shared_Solar_System__c>{sss1, sss2};

        ChargentBase__Gateway__c chGateway  = 
        new ChargentBase__Gateway__c(Name = 'Chargent Gateway',
                                         ChargentBase__Merchant_ID__c = '235986',
                                         Shared_Solar_System__c = sss1.id,
                                         Entity__c = entity1.Id,
                                         ChargentBase__Active__c = TRUE);
        insert chGateway;

        Id parentAccountRT = 
            Schema.SObjectType.Account.getRecordTypeInfosByName().get('Parent Account').getRecordTypeId();
        
        Account accountParent = new Account(name = 'Account Parent',
                                       RecordTypeId = parentAccountRT);
        insert accountParent;  

        Account accountA = new Account(name = 'Account A', 
                                      Parent_Account__c = accountParent.Id);
        insert accountA;     

        Utility_Account_Log__c ualog = 
            new Utility_Account_Log__c(Name = '0000234',
                                       Account__c = accountA.Id,
                                       Annual_Cost_of_Electricity__c = 10000,
                                       Name_on_Account__c = 'jordan jordan');
        insert ualog;

        Product2 normalCSProduct = new Product2( Name = 'BlueWave Community Solar',
                      Family = 'Community Solar',
                      Product_Type__c = 'Community Solar',
                      State__c = 'MA',
                      ProductCode = 'CS - BlueWave - 10%',
                      IsActive = True,
                      Lender_of_Record__c = 'BlueWave', 
                      NMC_Discount__c = 10,
                      Annual_kWh_Maximum__c = 100000000,
                      NM_Rate_Floor__c = 0,
                      Days_In_Bill_Period__c = 20,
                      Monthly_Late_Fee__c = 1);
        insert normalCSProduct;

        Opportunity opportunityone = 
            new Opportunity(Name = 'Jordan Jordan',
                            AccountId = accountA.Id,
                            Shared_Solar_System__c = sss1.Id,
                            StageName = 'Complete',
                            Product__c = normalCSProduct.Id,
                            CS_Capacity_Allocated__c = 25,
                            CloseDate = System.today());

        Opportunity opportunitytwo = 
            new Opportunity(Name = 'Jordan Jordan',
                            AccountId = accountA.Id,
                            Shared_Solar_System__c = sss2.Id,
                            StageName = 'Complete',
                            Product__c = normalCSProduct.Id,
                            CS_Capacity_Allocated__c = 20,
                            CloseDate = System.today()); 
        insert new List<Opportunity>{opportunityone, opportunitytwo};

        Utility_Account_Subscription__c uasone = 
            new Utility_Account_Subscription__c(Name = '0000234',
                                                Utility_Account_Log__c = ualog.Id,
                                                Opportunity__c = opportunityone.Id,
                                                Next_Schedule_Z_Status__c = 'Enacted: Removed',
                                                Calculated_Annual_Cost_of_Electricity__c = 4000,
                                                Subscribed_Annual_Cost_of_Electricity__c = 4000);

        Utility_Account_Subscription__c uastwo = 
            new Utility_Account_Subscription__c(Name = '000-0234',
                                                Utility_Account_Log__c = ualog.Id,
                                                Opportunity__c = opportunitytwo.Id,
                                                Next_Schedule_Z_Status__c = 'Enacted',
                                                Calculated_Annual_Cost_of_Electricity__c = 6000,
                                                Subscribed_Annual_Cost_of_Electricity__c = 6000);


        Utility_Account_Subscription__c uasthree = 
            new Utility_Account_Subscription__c(Name = '0000237',
                                                Utility_Account_Log__c = ualog.Id,
                                                Opportunity__c = opportunityone.Id,
                                                Next_Schedule_Z_Status__c = 'Not Enacted: Addition',
                                                Calculated_Annual_Cost_of_Electricity__c = 8000,
                                                Subscribed_Annual_Cost_of_Electricity__c = 8000);

        insert new List<Utility_Account_Subscription__c>{uasone, uastwo, uasthree};

        Bill_Adjustment__c adjustOne = new Bill_Adjustment__c(  Name = 'UASoneAdjustment',
                                                                Utility_Account_Subscription__c = uasOne.Id,
                                                                Adjustment_Amount__c = 24);
        insert adjustOne;

        uasone.Customer_Subscription_KW_DC_STATIC__c = 25;
        uastwo.Customer_Subscription_KW_DC_STATIC__c = 20;
        update new List<Utility_Account_Subscription__c>{uasone, uastwo};

        Date myDateJan = Date.newInstance(2016, 1, 1);
        Date myDateFeb = Date.newInstance(2016, 2, 2);
        Date myDateMar = Date.newInstance(2016, 3, 3);
        Date myDateApr = Date.newInstance(2016, 4, 4);

        Energy_Usage_Update__c productionupdateA1 = new Energy_Usage_Update__c (
                Name = 'sssA - January 2016',
                Shared_Solar_System__c = sss1.id,
                Production__c = 90000,
                Due_Date__c = myDateJan,
                Billing_Period_End_Date__c = myDateFeb,
                Total_System_NMCs__c = 16632,
                Date__c = myDateJan 
                );

        insert productionupdateA1;

        Energy_Usage_Update__c productionupdateB2 = new Energy_Usage_Update__c (
                Name = 'sssA - February 2016',
                Shared_Solar_System__c = sss1.id,
                Production__c = 120000,
                Due_Date__c = myDateFeb,
                Billing_Period_End_Date__c = myDateMar,
                Total_System_NMCs__c = 22176,
                Date__c = myDateFeb
                );
                
        insert productionupdateB2;

        Energy_Usage_Update__c productionupdateB3 = new Energy_Usage_Update__c (
                Name = 'sssA - March 2016',
                Shared_Solar_System__c = sss1.id,
                Production__c = 140000,
                Due_Date__c = myDateMar,
                Billing_Period_End_Date__c = myDateApr,
                Total_System_NMCs__c = 25872,
                Date__c = myDateMar
                );
                
        insert productionupdateB3;

        productionupdateA1.Generate_Bills__c = TRUE;
        productionupdateB2.Generate_Bills__c = TRUE;
        update productionupdateA1;
        update productionupdateB2; 

        APXT_BPM__Conductor__c newConga = new APXT_BPM__Conductor__c (APXT_BPM__Title__c = 'Conga Record');
        insert newConga;
        newConga.Apply_Overpay_Adjust__c = true;
        update newConga;
    }

    @isTest public static void testPreviewBills(){
        List<Energy_Usage_Update__c> productionUpdateList = [SELECT Id, Name FROM Energy_Usage_Update__c ORDER BY Date__c];
        Account accountA = [SELECT Id, Name, Parent_Account__r.Id
                            FROM Account
                            WHERE Name = 'Account A'];

        String parId = accountA.Parent_Account__r.Id;
        String acctId = accountA.Id;
        System.AssertEquals( 1, (PreviewProductionUpdateResults.getUASes(productionUpdateList[0].Id, TRUE)).size());
        System.AssertEquals( 1, (PreviewProductionUpdateResults.getUASes(productionUpdateList[1].Id, TRUE)).size());
        System.AssertEquals( 1, (PreviewProductionUpdateResults.getProperties(parId.substring(0,15), TRUE)).size());
        System.AssertEquals( 3, (PreviewProductionUpdateResults.getUASes(acctId.substring(0,15), FALSE)).size());

        List<UASB__c> uasbList = PreviewProductionUpdateResults.getUASes(productionUpdateList[1].Id, TRUE);
        System.AssertEquals(345.10, uasbList[0].PreGen_Discounted_Bill__c);
        System.AssertEquals(383.45, uasbList[0].PreGen_NMCs_Allocated__c);
    }

    @isTest public static void testPaymentPlan() {    
        List<System_Bill__c> systemBillList = 
            [SELECT Id, Late_Fees__c, Late_Payments__c, YTD_Billed__c, YTD_Payments__c, 
             Shared_Solar_System_ID__c, Payment_Plan_Balance_to_Distribute__c, Bill_Number__c, 
             Payment_Plan_Balance__c, Name, Due_This_Month__c, Previous_Month_Overdue_Balance__c, 
             Total_Due__c, Balance_Net_Late_Payments__c, Total_Payments_This_Month__c, 
             Property_Account__r.Directions_To_Write_Paper_Check__c,
             Property_Account__r.Parent_Account__r.Id, Opportunity__r.Id,
             Property_Account__r.Id, Shared_Solar_System__c, Property_Account_ID__c, 
             Adjustments__c, Bill_Date__c, Due_Date__c, Refund_this_Balance__c,
             Waive_Late_Fees__c, Previous_Overpayments__c, Balance_Adjustment__c,
             Adjustments_UASB__c, 
             Billing_Period_End_Date__c, Billing_Period_Start_Date__c
             FROM System_Bill__c
             ORDER BY Bill_Number__c];

        List <UASB__c> uablist = 
            [SELECT Id, Name, Bill_Date__c, System_Bill__r.Bill_Number__c, 
            Due_Date__c, Billing_Period_End_Date__c, Utility_Account_Subscription__c
            FROM UASB__c
            ORDER BY Bill_Date__c ];
        
        Date myDateJan = Date.newInstance(2016, 1, 1);
        Date myDateFeb = Date.newInstance(2016, 2, 2);
        Date myDateMar = Date.newInstance(2016, 3, 3);

        for (UASB__c uabill : uablist) {
          if (uabill.System_Bill__r.Bill_Number__c == 1){
              System.assertEquals(myDateJan, uabill.Due_Date__c);
              System.assertEquals(myDateFeb, uabill.Billing_Period_End_Date__c);
          }
          if (uabill.System_Bill__r.Bill_Number__c == 2){
              System.assertEquals(myDateFeb, uabill.Due_Date__c);
              System.assertEquals(myDateMar, uabill.Billing_Period_End_Date__c);
          }
        }
 
        String acctId = systemBillList[1].Property_Account_Id__c; 
        system.AssertEquals( 3, (PreviewProductionUpdateResults.getUASes(acctId, FALSE)).size());

        systemBillList[1].Waive_Late_Fees__c = TRUE;
        systemBillList[1].Distribute_This_Balance_As_Payment_Plan__c = TRUE;
        update systemBillList[1];

        List <System_Bill__c> sbstoupdate = new list <System_Bill__c>();                     

        for (Integer j = 3; j < 10 ; j++) {
            Boolean latefee = FALSE;
            Boolean published = TRUE;

            if (j==5) {
                latefee = TRUE;
            } else if (j==9) {
                published = FALSE;
            }
            
            Account_Bill__c accBillThree = 
                        new Account_Bill__c (Bill_Number__c = j,
                                             Parent_Account__c = systemBillList[1].Property_Account_Id__c,
                                             Name = 'First Last Month 2016' + j,
                                             Published__c = published,
                                             Unique_ID__c = '000111000111000111FAS' + j );
            insert accBillThree;

            System_Bill__c billThree = 
                        new System_Bill__c (Shared_Solar_System__c = systemBillList[1].Shared_Solar_System_Id__c,
                                            Shared_Solar_System_ID2__c = systemBillList[1].Shared_Solar_System_Id__c,
                                            Bill_Number__c = j,
                                            Opportunity__c = systemBillList[1].Opportunity__r.Id,
                                            Account_Bill__c = accBillThree.id,
                                            Property_Account__c = systemBillList[1].Property_Account_Id__c,
                                            Waive_Late_Fees__c = latefee,
                                            Name = 'First Last March 2016' + j,
                                            Unique_ID__c = '000111000111000111FAS' + j);
            sbstoupdate.add(billThree);
        }

        insert sbstoupdate;

        List<System_Bill__c> updatedsystemBillList = 
            [SELECT Id, Late_Fees__c, Late_Payments__c, YTD_Billed__c, YTD_Payments__c, 
             Shared_Solar_System_ID__c, Payment_Plan_Balance_to_Distribute__c, Bill_Number__c, 
             Payment_Plan_Balance__c, Name, Due_This_Month__c, Previous_Month_Overdue_Balance__c, 
             Total_Due__c, Balance_Net_Late_Payments__c, Total_Payments_This_Month__c, 
             Property_Account__r.Directions_To_Write_Paper_Check__c,
             Property_Account__r.Parent_Account__r.Id, Opportunity__r.Id,
             Property_Account__r.Id, Shared_Solar_System__c, Property_Account_ID__c, 
             Adjustments__c, Bill_Date__c, Due_Date__c, Refund_this_Balance__c,
             Waive_Late_Fees__c, Previous_Overpayments__c, Balance_Adjustment__c,
             Adjustments_UASB__c, 
             Billing_Period_End_Date__c, Billing_Period_Start_Date__c
             FROM System_Bill__c
             ORDER BY Bill_Number__c];

        System.assertEquals(9, updatedsystemBillList.size());
        for (System_Bill__c sbs : updatedsystemBillList) {
            if (sbs.Bill_Number__c == 2) {
                System.assertEquals(627.92, sbs.Payment_Plan_Balance_to_Distribute__c);
            } else if (sbs.Bill_Number__c == 3 || sbs.Bill_Number__c == 4  || sbs.Bill_Number__c == 8) {
                System.assertEquals(104.65, sbs.Payment_Plan_Balance__c);
            } else if (sbs.Bill_Number__c == 9) {
                System.assertEquals(0, sbs.Payment_Plan_Balance__c);
            }
        } 
    }

    @isTest public static void testAdjustments() {    
        List<System_Bill__c> systemBillList = 
            [SELECT Id, Late_Fees__c, Late_Payments__c, YTD_Billed__c, YTD_Payments__c, 
             Shared_Solar_System_ID__c, Payment_Plan_Balance_to_Distribute__c, Bill_Number__c, 
             Payment_Plan_Balance__c, Name, Due_This_Month__c, Previous_Month_Overdue_Balance__c, 
             Total_Due__c, Balance_Net_Late_Payments__c, Total_Payments_This_Month__c, 
             Property_Account__r.Directions_To_Write_Paper_Check__c,
             Property_Account__r.Parent_Account__r.Id, Opportunity__r.Id,
             Property_Account__r.Id, Shared_Solar_System__c, Property_Account_ID__c, 
             Adjustments__c, Bill_Date__c, Due_Date__c, Refund_this_Balance__c,
             Waive_Late_Fees__c, Previous_Overpayments__c, Balance_Adjustment__c,
             Adjustments_UASB__c, 
             Billing_Period_End_Date__c, Billing_Period_Start_Date__c
             FROM System_Bill__c
             ORDER BY Bill_Number__c];

        System.AssertEquals(282.82,systemBillList[0].Total_Due__c);
        System.AssertEquals(606.51,systembillList[1].Total_Due__c);
        System.AssertEquals(258.82,systembillList[0].Due_This_Month__c);
        System.AssertEquals(345.10,systembillList[1].Due_This_Month__c);
        System.AssertEquals(24,systembillList[0].Adjustments_UASB__c);
        System.AssertEquals(0,systembillList[1].Adjustments_UASB__c);
        System.AssertEquals(24,systembillList[0].Balance_Adjustment__c);
        System.AssertEquals(0,systembillList[1].Balance_Adjustment__c);
        System.AssertEquals(0,systembillList[1].Previous_Overpayments__c);

        List<Account_Bill__c> accountbilllist = [SELECT Id, Name, 
                                                Bill_Number__c, Property_Account_ID__c
                                                FROM Account_Bill__c];

        Account accountA = [SELECT Id, Name
                            FROM Account
                            WHERE Name = 'Account A'];

        ChargentBase__Gateway__c chGateway  = [SELECT Id, Name, Entity__c 
                                                FROM ChargentBase__Gateway__c
                                                LIMIT 1];
        Test.startTest();

        for (Account_Bill__c abill : accountbilllist) {
            abill.Published__c = True;
        }
        update accountbilllist;

        for (Account_Bill__c accountbill : accountbilllist) {
            if(accountbill.Bill_Number__c == 2) {
                ChargentOrders__ChargentOrder__c orderA = 
                    new ChargentOrders__ChargentOrder__c(ChargentOrders__Gateway__c = chGateway.Id,
                                                         ChargentOrders__Shipping_Name__c = chGateway.Entity__c,
                                                         ChargentOrders__Billing_First_Name__c = 'Cole',
                                                         ChargentOrders__Billing_Last_Name__c = 'Swain',
                                                         ChargentOrders__Billing_Address__c = '108 Ridgeland Drive',
                                                         ChargentOrders__Billing_Zip_Postal__c = '02467',
                                                         ChargentOrders__Subtotal__c = 50,
                                                         ChargentOrders__Payment_Method__c = 'Credit Card',
                                                         Account_Bill__c = accountbill.Id,
                                                         ChargentOrders__Card_Type__c = 'Visa',
                                                         ChargentOrders__Card_Number__c = '411111111111',
                                                         ChargentOrders__Card_Security_Code__c = '999',
                                                         ChargentOrders__Card_Expiration_Month__c = '02',
                                                         ChargentOrders__Card_Expiration_Year__c = '2018',
                                                         ChargentOrders__Card_Last_4__c = '1111'); 
                insert orderA;

                ChargentOrders__Transaction__c transA = 
                    new ChargentOrders__Transaction__c(ChargentOrders__Order__c = orderA.id,
                                                       ChargentOrders__Amount__c = 50,
                                                       ChargentOrders__Response_Status__c ='Approved',
                                                       ChargentOrders__Gateway_ID__c = chGateway.id,
                                                       ChargentOrders__Gateway__c = chGateway.id,
                                                       Distributed_Among_System_Bills__c = FALSE,
                                                       ChargentOrders__Response_Message__c = 'OK',
                                                       ChargentOrders__Type__c = 'Charge',
                                                       ChargentOrders__Payment_Method__c = 'Credit Card',                                    
                                                       Activity_Type__c = 'Payment');

                insert transA;
                transA.Distributed_Among_System_Bills__c = TRUE;
                update transA;
                                
                ChargentOrders__Transaction__c transB = 
                    new ChargentOrders__Transaction__c(ChargentOrders__Order__c = orderA.id,
                                                       ChargentOrders__Amount__c = 700,
                                                       ChargentOrders__Response_Status__c ='Approved',
                                                       ChargentOrders__Recurring__c = True,
                                                       ChargentOrders__Gateway_ID__c = chGateway.id,
                                                       ChargentOrders__Gateway__c = chGateway.id,
                                                       Distributed_Among_System_Bills__c = FALSE,
                                                       ChargentOrders__Response_Message__c = 'OK',
                                                       ChargentOrders__Type__c = 'Charge',
                                                       ChargentOrders__Payment_Method__c = 'Credit Card',                                    
                                                       Activity_Type__c = 'Payment');
                insert transB;
            }   
        } 

        List<Account> acctList = new List<Account>();
        acctList.add(accountA); 
        system.AssertEquals( 2, (PreviewProductionUpdateResults.getTransactions(acctList)).size());

        List<Bill_Adjustment__c> adjustList = [  SELECT Id, Name, 
                                                    Adjustment_Amount__c
                                                    FROM Bill_Adjustment__c
                                                    WHERE Overpayment__c = TRUE];
        System.AssertEquals(1, adjustList.size());
        System.AssertEquals(-119.25, adjustList[0].Adjustment_Amount__c);
        
        List<Adjustment_Application__c> adjustApp = [SELECT Id, Name, Bill_Adjustment__c, System_Bill__c,
                                                     Overpayment_Amount__c, Adjustment_Amount__c,
                                                     Bill_Adjustment__r.Outstanding__c,
                                                     Bill_Adjustment__r.Overpayment__c
                                                     FROM Adjustment_Application__c];
        System.AssertEquals(1, adjustApp.size());
        System.AssertEquals(0, adjustApp[0].Bill_Adjustment__r.Outstanding__c);

        List<System_Bill__c> updatedsystemBillListOne = 
            [SELECT Id, Late_Fees__c, Late_Payments__c, YTD_Billed__c, YTD_Payments__c, 
             Shared_Solar_System_ID__c, Payment_Plan_Balance_to_Distribute__c, Bill_Number__c, 
             Payment_Plan_Balance__c, Name, Due_This_Month__c, Previous_Month_Overdue_Balance__c, 
             Total_Due__c, Balance_Net_Late_Payments__c, Late_Fee_Payments__c, Total_Payments_This_Month__c, 
             Property_Account__r.Directions_To_Write_Paper_Check__c, Payments_Net_Previous_Balances__c,
             Property_Account__r.Parent_Account__r.Id, Opportunity__r.Id,
             Property_Account__r.Id, Shared_Solar_System__c, Property_Account_ID__c, 
             Adjustments__c, Bill_Date__c, Due_Date__c, Refund_this_Balance__c,
             Waive_Late_Fees__c, Previous_Overpayments__c, Balance_Adjustment__c,
             Adjustments_UASB__c, 
             Billing_Period_End_Date__c, Billing_Period_Start_Date__c
             FROM System_Bill__c
             ORDER BY Bill_Number__c];

        System.AssertEquals(282.82, updatedsystemBillListOne[0].Total_Due__c);
        System.AssertEquals(282.82, updatedsystemBillListOne[0].Late_Payments__c);
        System.AssertEquals(0, updatedsystemBillListOne[0].Balance_Net_Late_Payments__c);
        System.AssertEquals(0, updatedsystemBillListOne[0].Total_Payments_This_Month__c);

        System.Assert(updatedsystemBillListOne[1].Total_Due__c > 0);
        System.AssertNotEquals(0, updatedsystemBillListOne[1].Late_Fees__c );
        System.AssertEquals(0, updatedsystemBillListOne[1].Late_Payments__c );
        System.AssertEquals(630.75, updatedsystemBillListOne[1].Total_Payments_This_Month__c );

        String oldCheckAddressField; 
        String propertyAccountId;

        for (System_Bill__c editBill : updatedsystemBillListOne) {
          if (editBill.Bill_Number__c == 2) {
              oldCheckAddressField = editBill.Property_Account__r.Directions_To_Write_Paper_Check__c;
              propertyAccountId = editBill.Property_Account__r.Id;
              editBill.Waive_Late_Fees__c = True;
              update editBill;
          } 
        }

        Account propertyAccount = [ SELECT Id, Name, Directions_To_Write_Paper_Check__c
                                    FROM Account
                                    WHERE Id = : propertyAccountId];                                            

        System.assertNotEquals(oldCheckAddressField, propertyAccount.Directions_To_Write_Paper_Check__c);
        System.assert(propertyAccount.Directions_To_Write_Paper_Check__c.contains('Oxford Barrett St. P1'));

        Energy_Usage_Update__c prodUpdate = [SELECT Id, Name, Generate_Bills__c FROM Energy_Usage_Update__c WHERE Generate_Bills__c = false];
        prodUpdate.Generate_Bills__c = True;
        update prodUpdate;
        Test.stopTest();

        APXT_BPM__Conductor__c congaRecord = new APXT_BPM__Conductor__c (APXT_BPM__Title__c = 'Conga Record');
        insert congaRecord;
        congaRecord.Apply_Overpay_Adjust__c = true;
        update congaRecord;

        List<Adjustment_Application__c> secondAdjustApp =   [SELECT Id, Name, Bill_Adjustment__c, System_Bill__c,
                                                            Overpayment_Amount__c, Adjustment_Amount__c,
                                                            Bill_Adjustment__r.Overpayment__c
                                                            FROM Adjustment_Application__c
                                                            WHERE Bill_Adjustment__r.Overpayment__c = true];
        System.AssertEquals(1, secondAdjustApp.size());
        System.AssertEquals(-119.25, secondAdjustApp[0].Overpayment_Amount__c);

        List<System_Bill__c> updatedsystemBillList = 
            [SELECT Id, Late_Fees__c, Late_Payments__c, YTD_Billed__c, YTD_Payments__c, 
             Shared_Solar_System_ID__c, Payment_Plan_Balance_to_Distribute__c, Bill_Number__c, 
             Payment_Plan_Balance__c, Name, Due_This_Month__c, Previous_Month_Overdue_Balance__c, 
             Total_Due__c, Balance_Net_Late_Payments__c, Total_Payments_This_Month__c, 
             Property_Account__r.Directions_To_Write_Paper_Check__c,
             Property_Account__r.Parent_Account__r.Id, Opportunity__r.Id,
             Property_Account__r.Id, Shared_Solar_System__c, Property_Account_ID__c, 
             Adjustments__c, Bill_Date__c, Due_Date__c, Refund_this_Balance__c,
             Waive_Late_Fees__c, Previous_Overpayments__c, Balance_Adjustment__c,
             Adjustments_UASB__c, 
             Billing_Period_End_Date__c, Billing_Period_Start_Date__c
             FROM System_Bill__c
             ORDER BY Bill_Number__c];

        System.assertEquals(280.54, updatedsystemBillList[2].Total_Due__c );
        System.assertEquals(283.37, updatedsystemBillList[2].Balance_Net_late_Payments__c );
        System.assertEquals(-119.25, updatedsystemBillList[2].Previous_Overpayments__c );
        System.assertEquals(0, updatedsystemBillList[2].Adjustments_UASB__c );
    }
}