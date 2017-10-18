@isTest
Public without sharing class CommunitySolarCustomerPortalTest {
    @testSetup static void setupTestData() {
        Account parentAccount = new Account(Name = 'Parent Account', 
                          Product_Line__c = 'Community Solar');
        Account parentAccount2 = new Account(Name = 'Parent Account 2', 
                          Product_Line__c = 'Community Solar');        
        insert new List<Account>{parentAccount, parentAccount2};        

        Contact con = new Contact(FirstName = 'First',
                                  Email = 'communitiesUserContact@bluewave-capital.com',
                                  LastName = 'Last',
                                  AccountId = parentAccount.Id, 
                                  Active_Communities_User__c = true);
        Contact con2 = new Contact(FirstName = 'First',
                                  LastName = 'Last',
                                  Email = 'communitiesUserContact2@bluewave-capital.com',                                  
                                  AccountId = parentAccount2.Id, 
                                  Active_Communities_User__c = true);        
        insert new List<Contact>{con, con2};

        //the user has to be insert after the contact because it is a community user and can't be inserted without a contact.
        Profile communityProfile = 
            [SELECT Id from Profile WHERE Name = 'Community Solar Community User'];
        User communityUser = new User (ProfileId = communityProfile.Id,
                                 FirstName = 'Test',
                                 LastName = 'BFG_User',
                                 Username = 'communityuser@test.com',
                                 Email = 'communityuser@test.com',
                                 Alias = 'bfg_usr',
                                 ContactId = con.Id,
                                 CommunityNickname = 'bfg_usr',
                                 TimeZoneSidKey = 'America/New_York',
                                 LocaleSidKey = 'en_US',
                                 EmailEncodingKey = 'ISO-8859-1',
                                 LanguageLocaleKey = 'en_US');
        User communityUser2 = new User (ProfileId = communityProfile.Id,
                                 FirstName = 'Test2',
                                 LastName = 'BFG_User2',
                                 Username = 'communityuser2@test.com',
                                 Email = 'communityuser2@test.com',
                                 Alias = 'bfg_usr2',
                                 ContactId = con2.Id,
                                 CommunityNickname = 'bfg_usr2',
                                 TimeZoneSidKey = 'America/New_York',
                                 LocaleSidKey = 'en_US',
                                 EmailEncodingKey = 'ISO-8859-1',
                                 LanguageLocaleKey = 'en_US');
        Util.insertSObjs(new List<User>{communityUser, communityUser2});

        Account propertyAcc = new Account(Name = 'Property Account',
                                          Parent_Account__c = parentAccount.Id,
                                          Product_Line__c = 'Community Solar');
        Account propertyAcc2 = new Account(Name = 'Property Account 2',
                                          Parent_Account__c = parentAccount2.Id,
                                          Product_Line__c = 'Community Solar');        
        insert new List<Account>{propertyAcc, propertyAcc2};

        Utility_NMC_Tariff__c nmcRate = 
            new Utility_NMC_Tariff__c(Value_of_Net_Metering_Credit__c = 0.15,
                                      Name = 'Nation Grid WCMA Class 2 - S/F 2016',
                                      Sizing_Rate__c = true,
                                      Date__c = Date.today());
        insert nmcRate;    

        Entity__c entityone = new Entity__c (Name = 'Barrett ProjectCo');  
        Entity__c entitytwo = new Entity__c (Name = 'Two ProjectCo');

        insert new List <Entity__c>{entityone, entitytwo};
        
        Shared_Solar_System__c sss1 = 
            new Shared_Solar_System__c(Name = 'Oxford Barrett St. P1',
                                       Service_Territory__c = 'WCMA',
                                       Open__c = true,
                                       BWC_Project_Entity_Manual__c = entityone.Id,
                                       Auto_Payment_Form__c = false,
                                       Reserved_Capacity_kW_DC__c = '100',
                                       Capacity_Committed_kW_DC__c = 100,
                                       Total_System_Size_kWh_DC__c = 1000,
                                       Total_System_Size_kW_AC__c = 996,
                                       System_Utility__c = 'National Grid',
                                       Credit_Score_Requirement__c = 200,
                                       Assignment_order__c = '1',
                                       Utility_NMC_Tariff__c = nmcRate.Id,
                                       Expected_Yield_kWh_kW__c = 1300,
                                       Assemblage_Count__c = 1,
                                       Maximum_Subscription_Assemblage__c = 25);
        Shared_Solar_System__c sss2 = 
            new Shared_Solar_System__c(Name = 'Oxford Barrett St. P2',
                                       Service_Territory__c = 'WCMA',
                                       Open__c = true,
                                       BWC_Project_Entity_Manual__c = entitytwo.Id,
                                       Auto_Payment_Form__c = true,
                                       Reserved_Capacity_kW_DC__c = '100',
                                       Capacity_Committed_kW_DC__c = 100,
                                       Total_System_Size_kWh_DC__c = 1000,
                                       System_Utility__c = 'National Grid',
                                       Credit_Score_Requirement__c = 200,
                                       Assignment_order__c = '2'); 
        insert new List<Shared_Solar_System__c>{sss1, sss2};
           
        Opportunity oppP1A = new Opportunity(Name = 'oppP1A',
                                           StageName = 'Complete',
                                           CloseDate = System.today(),
                                           AccountId = propertyAcc.Id,
                                           Shared_Solar_System__c = sss1.Id,
                                           NMC_Tariff__c = nmcRate.id,
                                           Customer_Group__c = 'Residential',
                                           CS_Capacity_Allocated__c = 25);

        Opportunity oppP2A = new Opportunity(Name = 'oppP2A',
                                           StageName = 'Complete',
                                           CloseDate = System.today(),
                                           AccountId = propertyAcc.Id,
                                           Shared_Solar_System__c = sss2.Id,
                                           NMC_Tariff__c = nmcRate.id,
                                           Customer_Group__c = 'Residential',
                                           CS_Capacity_Allocated__c = 25);

        Opportunity oppP2B = new Opportunity(Name = 'oppP2B',
                                           StageName = 'Complete',
                                           CloseDate = System.today(),
                                           AccountId = propertyAcc2.Id,
                                           Shared_Solar_System__c = sss2.Id,
                                           NMC_Tariff__c = nmcRate.id,
                                           Customer_Group__c = 'Residential',
                                           CS_Capacity_Allocated__c = 25); 
    insert new List<Opportunity>{oppP1A, oppP2A, oppP2B};                                          
        
        Utility_Account_Log__c ualA = 
            new Utility_Account_Log__c(Name = 'Cole Swain testUal',
                                       Account__c = propertyAcc.Id,
                                       Annual_Cost_of_Electricity__c = 0,
                                       Name_on_Account__c = 'Cole Swain');
        Utility_Account_Log__c ualB = 
            new Utility_Account_Log__c(Name = 'Cole Swain testUal 2',
                                       Account__c = propertyAcc2.Id,
                                       Annual_Cost_of_Electricity__c = 0,
                                       Name_on_Account__c = 'Cole Swain 2');            
        insert new List<Utility_Account_Log__c>{ualA, ualB};             
        
        Utility_Account_Subscription__c uasP1A = new Utility_Account_Subscription__c(Name = 'Cole Swain testUas',
                                                                  Utility_Account_Log__c = ualA.Id,
                                                                  Opportunity__c = oppP1A.Id,
                                                                  Calculated_Annual_Cost_of_Electricity__c = 4225,
                                                                  Subscribed_Annual_Cost_of_Electricity__c = 4225,
                                                                  Customer_Subscription_KW_DC_STATIC__c = 25,
                                                                  Uas_number__c = 1);    

        Utility_Account_Subscription__c uasP2A = new Utility_Account_Subscription__c(Name = 'Cole Swain testUas',
                                                                  Utility_Account_Log__c = ualA.Id,
                                                                  Opportunity__c = oppP2A.Id,
                                                                  Calculated_Annual_Cost_of_Electricity__c = 1335,
                                                                  Subscribed_Annual_Cost_of_Electricity__c = 1335,
                                                                  Customer_Subscription_KW_DC_STATIC__c = 25,
                                                                  Uas_number__c = 2);  

        Utility_Account_Subscription__c uasP2B = new Utility_Account_Subscription__c(Name = 'Cole Swain testUas 2',
                                                                  Utility_Account_Log__c = ualB.Id,
                                                                  Opportunity__c = oppP2B.Id,
                                                                  Calculated_Annual_Cost_of_Electricity__c = 4225,
                                                                  Subscribed_Annual_Cost_of_Electricity__c = 4225,
                                                                  Customer_Subscription_KW_DC_STATIC__c = 25,
                                                                  Uas_number__c = 1);                                                 
        insert new List<Utility_Account_Subscription__c>{uasP1A, uasP2A, uasP2B};

        Date billingDate1 = Date.newInstance(2016, 1, 1);
        Date billingDate2 = Date.newInstance(2016, 2, 2);

        Account_Bill__c abJanA = new Account_Bill__c(Name = propertyAcc.Name,
                                                 Date__c = billingDate1,
                                                 Parent_Account__c = propertyAcc.Id,
                                                 Bill_Number__c = 1,
                                                 Published__c = true,
                                                 Unique_ID__c = propertyAcc.Id + ' ' + DateTime.newInstance(billingDate1.year(), billingDate1.month(), billingDate1.day()).format('yyyy-MM'));
        Account_Bill__c abFebA = new Account_Bill__c(Name = propertyAcc.Name,
                                                 Date__c = billingDate2,
                                                 Parent_Account__c = propertyAcc.Id,
                                                 Bill_Number__c = 2,
                                                 Published__c = true,
                                                 Unique_ID__c = propertyAcc.Id + ' ' + DateTime.newInstance(billingDate2.year(), billingDate2.month(), billingDate2.day()).format('yyyy-MM'));        
        Account_Bill__c abFebB = new Account_Bill__c(Name = propertyAcc2.Name,
                                                 Date__c = billingDate2,
                                                 Parent_Account__c = propertyAcc2.Id,
                                                 Bill_Number__c = 1,
                                                 Published__c = true,
                                                 Unique_ID__c = propertyAcc2.Id + ' ' + DateTime.newInstance(billingDate2.year(), billingDate2.month(), billingDate2.day()).format('yyyy-MM'));        
        insert new List<Account_Bill__c>{abJanA, abFebA, abFebB};                                                     

        //below used to the getStatement() method; however that is no longer in use due to problems with the code in communities - URL mapping of the parentID doesn't work.
        //Blob bodyBlob = Blob.valueOf('testStatement');
        //Attachment attach = new Attachment(Name = 'testStatement',
        //                                   Body = bodyBlob,
        //                                   ParentId = ab.Id);
        //insert attach;
        System_Bill__c sbJanP1A = new System_Bill__c(Name = oppP1A.Name + ' ' + sss1.Name + ' ' + billingDate1.Month() + ' ' + billingDate1.Year(),
                                               Shared_Solar_System__c = sss1.Id,
                                               Account_Bill__c = abJanA.Id,
                                               Date__c = billingDate1,
                                               Bill_Number__c = 1,
                                               Opportunity__c = oppP1A.Id,
                                               Due_this_month__c = 375,
                                               Refund_This_Balance__c = TRUE,
                                               Amount_To_Add__c = 100,
                                               Previous_month_overdue_balance__c = 0,
                                               Total_Due__c = 375,
                                               Balance_net_late_payments__c = 375,
                                               Carry_over_balance__c = 375,
                                               Property_Account__c = propertyAcc.Id,
                                               Unique_ID__c = oppP1A.Name + ' ' + sss1.Id + ' ' + DateTime.newInstance(billingDate1.year(), billingDate1.month(), billingDate1.day()).format('yyyy-MM'));

        System_Bill__c sbFebP1A = new System_Bill__c(Name = oppP1A.Name + ' ' + sss1.Name + ' ' + billingDate2.Month() + ' ' + billingDate2.Year(),
                                               Shared_Solar_System__c = sss1.Id,
                                               Account_Bill__c = abFebA.Id,
                                               Date__c = billingDate2,
                                               Bill_Number__c = 2,
                                               Opportunity__c = oppP1A.Id,
                                               Due_this_month__c = 375,
                                               Refund_This_Balance__c = TRUE,
                                               Amount_To_Add__c = 100,
                                               Previous_month_overdue_balance__c = 0,
                                               Total_Due__c = 375,
                                               Balance_net_late_payments__c = 375,
                                               Carry_over_balance__c = 375,
                                               Property_Account__c = propertyAcc.Id,
                                               Unique_ID__c = oppP1A.Name + ' ' + sss1.Id + ' ' + DateTime.newInstance(billingDate2.year(), billingDate2.month(), billingDate2.day()).format('yyyy-MM'));        

        System_Bill__c sbFebP2A = new System_Bill__c(Name = oppP2A.Name + ' ' + sss2.Name + ' ' + billingDate2.Month() + ' ' + billingDate2.Year(),
                                               Shared_Solar_System__c = sss2.Id,
                                               Account_Bill__c = abFebA.Id,
                                               Date__c = billingDate2,
                                               Bill_Number__c = 1,
                                               Opportunity__c = oppP2A.Id,
                                               Due_this_month__c = 375,
                                               Refund_This_Balance__c = TRUE,
                                               Amount_To_Add__c = 30,
                                               Previous_month_overdue_balance__c = 0,
                                               Total_Due__c = 375,
                                               Balance_net_late_payments__c = 375,
                                               Carry_over_balance__c = 375,
                                               Property_Account__c = propertyAcc.Id,
                                               Unique_ID__c = oppP2A.Name + ' ' + sss2.Id + ' ' + DateTime.newInstance(billingDate2.year(), billingDate2.month(), billingDate2.day()).format('yyyy-MM'));

        System_Bill__c sbFebP2B = new System_Bill__c(Name = oppP2B.Name + ' ' + sss2.Name + ' ' + billingDate2.Month() + ' ' + billingDate2.Year(),
                                                   Shared_Solar_System__c = sss2.Id,
                                                   Account_Bill__c = abFebB.Id,
                                                   Date__c = billingDate2,
                                                   Bill_Number__c = 1,
                                                   Opportunity__c = oppP2B.Id,
                                                   Due_this_month__c = 375,
                                                   Refund_This_Balance__c = TRUE,
                                                   Amount_To_Add__c = 70,
                                                   Previous_month_overdue_balance__c = 0,
                                                   Total_Due__c = 375,
                                                   Balance_net_late_payments__c = 375,
                                                   Carry_over_balance__c = 375,
                                                   Property_Account__c = propertyAcc2.Id,
                                                   Unique_ID__c = oppP2B.Name + ' ' + sss2.Id + ' ' + DateTime.newInstance(billingDate2.year(), billingDate2.month(), billingDate2.day()).format('yyyy-MM'));
        insert new List<System_Bill__c>{sbJanP1A, sbFebP1A, sbFebP2A, sbFebP2B};
        update new List<System_Bill__c>{sbJanP1A, sbFebP1A, sbFebP2A, sbFebP2B};

        Utility_Account_Bill__c uabJanA = new Utility_Account_Bill__c(Name = oppP1A.Name + ' ' + billingDate1.Month() + ' ' + billingDate1.year() + ' ' + uasP1A.Name,
                                                                      Date__c = billingDate1,
                                                                      Utility_Account_Log__c = ualA.Id,
                                                                      Bill_Number__c = 1,
                                                                      Account_Bill__c = abJanA.Id,
                                                                      Unique_ID__c = uasP1A.Utility_Account_Log__c + ' - ' + DateTime.newInstance(billingDate1.year(), billingDate1.month(), billingDate1.day()).format('yyyy-MM'));
        Utility_Account_Bill__c uabFebA = new Utility_Account_Bill__c(Name = oppP2A.Name + ' ' + billingDate1.Month() + ' ' + billingDate1.year() + ' ' + uasP1A.Name,
                                                                      Date__c = billingDate2,
                                                                      Utility_Account_Log__c = ualA.Id,
                                                                      Bill_Number__c = 2,
                                                                      Account_Bill__c = abFebA.Id,
                                                                      Unique_ID__c = uasP1A.Utility_Account_Log__c + ' - ' + DateTime.newInstance(billingDate2.year(), billingDate2.month(), billingDate2.day()).format('yyyy-MM'));        
        Utility_Account_Bill__c uabFebB = new Utility_Account_Bill__c(Name = oppP2B.Name + ' ' + billingDate2.Month() + ' ' + billingDate2.year() + ' ' + uasP2B.Name,
                                                                      Date__c = billingDate2,
                                                                      Utility_Account_Log__c = ualB.Id,
                                                                      Bill_Number__c = 1,
                                                                      Account_Bill__c = abFebB.Id,
                                                                      Unique_ID__c = uasP2B.Utility_Account_Log__c + ' - ' + DateTime.newInstance(billingDate2.year(), billingDate2.month(), billingDate2.day()).format('yyyy-MM'));

        insert new List<Utility_Account_Bill__c>{uabJanA, uabFebA, uabFebB};

        UASB__c uasbJanP1A = new UASB__c(Name = uasP1A.Name + sss1.Name,
                                       Customer_Subscription_KW_DC__c = uasP1A.Customer_Subscription_KW_DC_STATIC__c,
                                       CS_Billing_Log__c = uabJanA.Id,
                                       Date__c = billingDate1,
                                       Utility_Account_Subscription__c = uasP1A.Id,
                                       Opportunity__c = oppP1A.Id,
                                       System_Bill__c = sbJanP1A.Id,
                                       Shared_Solar_System__c = sss1.Id,
                                       Total_System_Size_kw_DC__c = sss1.Total_System_Size_kWh_DC__c,
                                       NMC_Rate__c = nmcRate.Value_of_Net_Metering_Credit__c,
                                       Unique_ID__c = oppP1A.Shared_Solar_System__c + ' - ' + uasP1A.Id + ' - ' + DateTime.newInstance(billingDate1.year(), billingDate1.month(), billingDate1.day()).format('yyyy-MM'));
        UASB__c uasbFebP1A = new UASB__c(Name = uasP1A.Name + sss1.Name,
                                       Customer_Subscription_KW_DC__c = uasP1A.Customer_Subscription_KW_DC_STATIC__c,
                                       CS_Billing_Log__c = uabFebA.Id,
                                       Date__c = billingDate2,
                                       Utility_Account_Subscription__c = uasP1A.Id,
                                       Opportunity__c = oppP1A.Id,
                                       System_Bill__c = sbFebP1A.Id,
                                       Shared_Solar_System__c = sss1.Id,
                                       Total_System_Size_kw_DC__c = sss1.Total_System_Size_kWh_DC__c,
                                       NMC_Rate__c = nmcRate.Value_of_Net_Metering_Credit__c,
                                       Unique_ID__c = oppP1A.Shared_Solar_System__c + ' - ' + uasP1A.Id + ' - ' + DateTime.newInstance(billingDate2.year(), billingDate2.month(), billingDate2.day()).format('yyyy-MM'));        
        UASB__c uasbFebP2A = new UASB__c(Name = uasP2A.Name + sss2.Name,
                                       Customer_Subscription_KW_DC__c = uasP2A.Customer_Subscription_KW_DC_STATIC__c,
                                       CS_Billing_Log__c = uabFebA.Id,
                                       Date__c = billingDate2,
                                       Utility_Account_Subscription__c = uasP2A.Id,
                                       Opportunity__c = oppP2A.Id,
                                       System_Bill__c = sbFebP2A.Id,
                                       Shared_Solar_System__c = sss2.Id,
                                       Total_System_Size_kw_DC__c = sss2.Total_System_Size_kWh_DC__c,
                                       NMC_Rate__c = nmcRate.Value_of_Net_Metering_Credit__c,
                                       Unique_ID__c = oppP2A.Shared_Solar_System__c + ' - ' + uasP2A.Id + ' - ' + DateTime.newInstance(billingDate2.year(), billingDate2.month(), billingDate2.day()).format('yyyy-MM'));      
        UASB__c uasbFebP2B = new UASB__c(Name = uasP2B.Name + sss2.Name,
                                       Customer_Subscription_KW_DC__c = uasP2B.Customer_Subscription_KW_DC_STATIC__c,
                                       CS_Billing_Log__c = uabFebB.Id,
                                       Date__c = billingDate2,
                                       Utility_Account_Subscription__c = uasP2B.Id,
                                       Opportunity__c = oppP2B.Id,
                                       System_Bill__c = sbFebP2B.Id,
                                       Shared_Solar_System__c = sss2.Id,
                                       Total_System_Size_kw_DC__c = sss2.Total_System_Size_kWh_DC__c,
                                       NMC_Rate__c = nmcRate.Value_of_Net_Metering_Credit__c,
                                       Unique_ID__c = oppP2B.Shared_Solar_System__c + ' - ' + uasP2B.Id + ' - ' + DateTime.newInstance(billingDate2.year(), billingDate2.month(), billingDate2.day()).format('yyyy-MM'));                                           
        insert new List<UASB__c>{uasbJanP1A, uasbFebP1A, uasbFebP2A, uasbFebP2B };
    
     ChargentBase__Gateway__c chGateway  = new ChargentBase__Gateway__c(Name = 'Chargent Gateway',
                                                               //Shared_Solar_System__c = sss1.Id 
                                                               ChargentBase__Merchant_ID__c = '235986',
                                                               ChargentBase__Active__c = TRUE);
      insert chGateway;  

      ChargentOrders__ChargentOrder__c chOrder  = new ChargentOrders__ChargentOrder__c(
          ChargentOrders__Account__c = propertyAcc.Id,
            ChargentOrders__Gateway__c = chGateway.Id,
            ChargentOrders__Shipping_Name__c = sss1.Id,
            ChargentOrders__Billing_First_Name__c = 'Cole',
            ChargentOrders__Billing_Last_Name__c = 'Swain',
            ChargentOrders__Billing_Address__c = '108 Ridgeland Drive',
            ChargentOrders__Billing_Zip_Postal__c = '02467',                                                                                                    
            ChargentOrders__Subtotal__c = sbJanP1A.Total_Due__c,
            ChargentOrders__Payment_Status__c = 'Recurring',
            ChargentOrders__Payment_Method__c = 'Credit Card',
            Account_Bill__c = abJanA.Id,
            System_Bill__c = sbJanP1A.Id,
            ChargentOrders__Card_Type__c = 'Visa',
            ChargentOrders__Card_Number__c = '411111111111',
            ChargentOrders__Card_Security_Code__c = '999',
            ChargentOrders__Card_Expiration_Month__c = '02',
            ChargentOrders__Card_Expiration_Year__c = '2018',
            ChargentOrders__Card_Last_4__c = '1111');  
      insert chOrder;
     
         ChargentOrders__Transaction__c chTransaction = new ChargentOrders__Transaction__c(
                                    ChargentOrders__Order__c = chOrder.id,
                                    ChargentOrders__Amount__c = 200,
                                    ChargentOrders__Response_Status__c ='Approved',
                                    ChargentOrders__Gateway_ID__c = chGateway.id,
                                    ChargentOrders__Gateway__c = chGateway.id,
                                    Distributed_Among_System_Bills__c = FALSE,
                                    ChargentOrders__Response_Message__c = 'OK',
                                    ChargentOrders__Type__c = 'Charge',
                                    ChargentOrders__Payment_Method__c = 'Credit Card',                                    
                                    Activity_Type__c = 'Payment');
        insert chTransaction;           
    }        

    @isTest static void testMethodOne() {
        Map<String, User> userMap = new Map<String, User>();
        for (User communityUser : [SELECT Id, ContactId, Parent_account_id__c, Contact.Account.Id, Username 
                              FROM User]){
          userMap.put(communityUser.Username, communityUser);
        }
        
        Map<String, Account> customerAccountMap = new Map<String, Account>();
        for (Account customerAccount : [SELECT Id, Name, Parent_Account_ID__c, Total_Outstanding_Balance__c
                                        FROM Account]){
            customerAccountMap.put(customerAccount.Name, customerAccount);
        }
        
        Map<String, Opportunity> opportunityMap = new Map<String, Opportunity>();
        for (Opportunity opp : [SELECT Id, Name, Account.Parent_Account__r.Id, Account.Parent_Account_ID__c
                                FROM Opportunity]){
            opportunityMap.put(opp.Name, opp);
        }        

        Map<String, Contact> contactMap = new Map<String, Contact>();
        for (Contact cont : [SELECT Id, Name, Email,Referral_Code__c 
                   FROM Contact]){
          contactMap.put(cont.Email, cont);
        }

        Map<String, Account_Bill__c> accountBillMap = new Map<String, Account_Bill__c>();
        for (Account_Bill__c ab : [SELECT Id, Name
                       FROM Account_Bill__c]){
          accountBillMap.put(ab.Name, ab);
        }
        Map<String, System_Bill__c> systemBillMap = new Map<String, System_Bill__c>();
        for (System_Bill__c sb : [SELECT Id, Total_Due__c, Shared_Solar_System__r.Name, Carry_Over_Balance__c, Shared_Solar_System__r.Id,  
                                        Bill_Number__c, Name, FormAssembly_Order_Helper__c, Form_ID_Helper__c
                                  FROM System_Bill__c]){
          systemBillMap.put(sb.Shared_Solar_System__r.Name, sb);
        }    

        ChargentOrders__Transaction__c chTransaction = [SELECT Id, Name 
                                                  FROM ChargentOrders__Transaction__c];                                                                            
        Test.startTest();
          System.runAs(userMap.get('communityuser@test.com')){
            //test the getMenuLabeList() method
            List<Account> menuLabelRespList = new List<Account>(MyAccountController.getMenuLabelList());
            System.assertEquals(menuLabelRespList.get(0).Id, customerAccountMap.get('Property Account').Id);

            //test the getSystemBills() method
            List <AggregateResult> systemBillPrAccRespList = new List <AggregateResult>(MyAccountController.getSystemBills(
            String.valueOf(customerAccountMap.get('Property Account').Id).subString(0,15)));
            String firstab;
            String secondab;
            String firstentity;
            String secondentity;
            for (AggregateResult ar : systemBillPrAccRespList) {
              if (ar.get('carryover') == 201) {
                  firstab = String.valueOf(ar.get('Account_Bill__c'));
                  firstentity = String.valueOf(ar.get('entity'));
                  System.assertEquals(ar.get('carryover'), 201); 
              } else {
                  secondab = String.valueOf(ar.get('Account_Bill__c'));
                  secondentity = String.valueOf(ar.get('entity'));  
                System.assertEquals(ar.get('carryover'), 30);             
              }
            }
              System.assertEquals(firstab, secondab);
              System.assertNotEquals(firstentity, secondentity);

            List <AggregateResult> systemBillallList = new List <AggregateResult> (MyAccountController.getSystemBills('all'));
            String firstab2;
            String secondab2;
            String firstentity2;
            String secondentity2;
            for (AggregateResult ar : systemBillPrAccRespList) {
              if (ar.get('carryover') == 201) {
                 firstab2 = String.valueOf(ar.get('Account_Bill__c'));
                 firstentity2 = String.valueOf(ar.get('entity'));
                 System.assertEquals(ar.get('carryover'), 201); 
              } else {
                 secondab2 = String.valueOf(ar.get('Account_Bill__c'));
                 secondentity2 = String.valueOf(ar.get('entity'));  
                System.assertEquals(ar.get('carryover'), 30);             
              }
            }
            System.assertEquals(firstab2, secondab2);
            System.assertNotEquals(firstentity2, secondentity2);

            //test the getAccountBills() method
            List<Account_Bill__c> accountBillPrAccRespList = new List<Account_Bill__c>(MyAccountController.getAccountBills(
            String.valueOf(customerAccountMap.get('Property Account').Id)));
            System.assertEquals(accountBillPrAccRespList.get(0).Id, accountBillMap.get('Property Account').Id);
            List<Account_Bill__c> accountBillAllRespList = new List<Account_Bill__c>(MyAccountController.getAccountBills('All'));
            System.assertEquals(accountBillAllRespList.get(0).Id, accountBillMap.get('Property Account').Id);

            //test the getTransactions() method
            List<ChargentOrders__Transaction__c> transactionPrAccRespList = new List<ChargentOrders__Transaction__c>(MyAccountController.getTransactions(
              String.valueOf(customerAccountMap.get('Property Account').Id)));
            System.assertEquals(transactionPrAccRespList.get(0).Id, chTransaction.Id);
            List<ChargentOrders__Transaction__c> transactionAllRespList = new List<ChargentOrders__Transaction__c>(MyAccountController.getTransactions('All'));
            System.assertEquals(transactionAllRespList.get(0).Id, chTransaction.Id);

            //test the getCode() method
            String referralCode = MyAccountController.getCode();
            System.assertEquals(referralCode, 'bluewaveFLast');

            //test the sendEmail() method
            MyAccountController.sendEmail('test@test.test');
          }
        Test.stopTest();    
    }
}