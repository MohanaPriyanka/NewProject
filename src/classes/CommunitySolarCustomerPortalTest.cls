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
        insert new List<User>{communityUser, communityUser2};         

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
                                       Schedule_Z_Filed__c = false,
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
                                       Schedule_Z_Filed__c = false,
                                       Reserved_Capacity_kW_DC__c = '100',
                                       Capacity_Committed_kW_DC__c = 100,
                                       Total_System_Size_kWh_DC__c = 1000,
                                       System_Utility__c = 'National Grid',
                                       Credit_Score_Requirement__c = 200,
                                       Assignment_order__c = '2'); 
        insert new List<Shared_Solar_System__c>{sss1, sss2};
           
        Opportunity opp1 = new Opportunity(Name = 'Opp1',
                                           StageName = 'Complete',
                                           CloseDate = System.today(),
                                           AccountId = propertyAcc.Id,
                                           Shared_Solar_System__c = sss1.Id,
                                           NMC_Tariff__c = nmcRate.id,
                                           Customer_Group__c = 'Residential',
                                           CS_Capacity_Allocated__c = 25);

        Opportunity opp1A = new Opportunity(Name = 'Opp1A',
                                           StageName = 'Complete',
                                           CloseDate = System.today(),
                                           AccountId = propertyAcc.Id,
                                           Shared_Solar_System__c = sss2.Id,
                                           NMC_Tariff__c = nmcRate.id,
                                           Customer_Group__c = 'Residential',
                                           CS_Capacity_Allocated__c = 25);

        Opportunity opp2 = new Opportunity(Name = 'Opp2',
                                           StageName = 'Complete',
                                           CloseDate = System.today(),
                                           AccountId = propertyAcc2.Id,
                                           Shared_Solar_System__c = sss2.Id,
                                           NMC_Tariff__c = nmcRate.id,
                                           Customer_Group__c = 'Residential',
                                           CS_Capacity_Allocated__c = 25); 
		insert new List<Opportunity>{opp1, opp1A, opp2};                                          
        
        Utility_Account_Log__c ual = 
            new Utility_Account_Log__c(Name = 'Cole Swain testUal',
                                       Account__c = propertyAcc.Id,
                                       Annual_Cost_of_Electricity__c = 0,
                                       Name_on_Account__c = 'Cole Swain');
        Utility_Account_Log__c ual2 = 
            new Utility_Account_Log__c(Name = 'Cole Swain testUal 2',
                                       Account__c = propertyAcc2.Id,
                                       Annual_Cost_of_Electricity__c = 0,
                                       Name_on_Account__c = 'Cole Swain 2');            
        insert new List<Utility_Account_Log__c>{ual, ual2};             
        
        Utility_Account_Subscription__c uas = new Utility_Account_Subscription__c(Name = 'Cole Swain testUas',
								                                                  Utility_Account_Log__c = ual.Id,
								                                                  Opportunity__c = opp1.Id,
								                                                  Calculated_Annual_Cost_of_Electricity__c = 4225,
								                                                  Subscribed_Annual_Cost_of_Electricity__c = 4225,
								                                                  Customer_Subscription_KW_DC_STATIC__c = 25,
								                                                  Uas_number__c = 1);    

        Utility_Account_Subscription__c uas1A = new Utility_Account_Subscription__c(Name = 'Cole Swain testUas',
                                                                  Utility_Account_Log__c = ual.Id,
                                                                  Opportunity__c = opp1A.Id,
                                                                  Calculated_Annual_Cost_of_Electricity__c = 1335,
                                                                  Subscribed_Annual_Cost_of_Electricity__c = 1335,
                                                                  Customer_Subscription_KW_DC_STATIC__c = 25,
                                                                  Uas_number__c = 2);  

        Utility_Account_Subscription__c uas2 = new Utility_Account_Subscription__c(Name = 'Cole Swain testUas 2',
								                                                  Utility_Account_Log__c = ual2.Id,
								                                                  Opportunity__c = opp2.Id,
								                                                  Calculated_Annual_Cost_of_Electricity__c = 4225,
								                                                  Subscribed_Annual_Cost_of_Electricity__c = 4225,
								                                                  Customer_Subscription_KW_DC_STATIC__c = 25,
								                                                  Uas_number__c = 1);                                                 
        insert new List<Utility_Account_Subscription__c>{uas, uas1A, uas2};

        Date billingDate1 = Date.newInstance(2016, 1, 1);

        Account_Bill__c ab = new Account_Bill__c(Name = propertyAcc.Name,
                                                 Date__c = billingDate1,
                                                 Parent_Account__c = propertyAcc.Id,
                                                 Bill_Number__c = 1,
                                                 Unique_ID__c = propertyAcc.Id + ' ' + DateTime.newInstance(billingDate1.year(), billingDate1.month(), billingDate1.day()).format('yyyy-MM'));
        Account_Bill__c ab2 = new Account_Bill__c(Name = propertyAcc2.Name,
                                                 Date__c = billingDate1,
                                                 Parent_Account__c = propertyAcc2.Id,
                                                 Bill_Number__c = 1,
                                                 Unique_ID__c = propertyAcc2.Id + ' ' + DateTime.newInstance(billingDate1.year(), billingDate1.month(), billingDate1.day()).format('yyyy-MM'));        
        insert new List<Account_Bill__c>{ab, ab2};                                                     

        //below used to the getStatement() method; however that is no longer in use due to problems with the code in communities - URL mapping of the parentID doesn't work.
        //Blob bodyBlob = Blob.valueOf('testStatement');
        //Attachment attach = new Attachment(Name = 'testStatement',
        //                                   Body = bodyBlob,
        //                                   ParentId = ab.Id);
        //insert attach;
        System_Bill__c sb = new System_Bill__c(Name = opp1.Name + ' ' + sss1.Name + ' ' + billingDate1.Month() + ' ' + billingDate1.Year(),
                                               Shared_Solar_System__c = sss1.Id,
                                               Account_Bill__c = ab.Id,
                                               Date__c = billingDate1,
                                               Bill_Number__c = 1,
                                               Opportunity__c = opp1.Id,
                                               Due_this_month__c = 375,
                                               Refund_This_Balance__c = TRUE,
                                               Amount_To_Add__c = 100,
                                               Previous_month_overdue_balance__c = 0,
                                               Total_Due__c = 375,
                                               Balance_net_late_payments__c = 375,
                                               Carry_over_balance__c = 375,
                                               Property_Account__c = propertyAcc.Id,
                                               Unique_ID__c = opp1.Name + ' ' + sss1.Id + ' ' + DateTime.newInstance(billingDate1.year(), billingDate1.month(), billingDate1.day()).format('yyyy-MM'));

        System_Bill__c sb1A = new System_Bill__c(Name = opp1A.Name + ' ' + sss2.Name + ' ' + billingDate1.Month() + ' ' + billingDate1.Year(),
                                               Shared_Solar_System__c = sss2.Id,
                                               Account_Bill__c = ab.Id,
                                               Date__c = billingDate1,
                                               Bill_Number__c = 1,
                                               Opportunity__c = opp1A.Id,
                                               Due_this_month__c = 375,
                                               Refund_This_Balance__c = TRUE,
                                               Amount_To_Add__c = 30,
                                               Previous_month_overdue_balance__c = 0,
                                               Total_Due__c = 375,
                                               Balance_net_late_payments__c = 375,
                                               Carry_over_balance__c = 375,
                                               Property_Account__c = propertyAcc.Id,
                                               Unique_ID__c = opp1A.Name + ' ' + sss2.Id + ' ' + DateTime.newInstance(billingDate1.year(), billingDate1.month(), billingDate1.day()).format('yyyy-MM'));

        System_Bill__c sb2 = new System_Bill__c(Name = opp2.Name + ' ' + sss2.Name + ' ' + billingDate1.Month() + ' ' + billingDate1.Year(),
                                               Shared_Solar_System__c = sss2.Id,
                                               Account_Bill__c = ab2.Id,
                                               Date__c = billingDate1,
                                               Bill_Number__c = 1,
                                               Opportunity__c = opp2.Id,
                                               Due_this_month__c = 375,
                                               Refund_This_Balance__c = TRUE,
                                               Amount_To_Add__c = 70,
                                               Previous_month_overdue_balance__c = 0,
                                               Total_Due__c = 375,
                                               Balance_net_late_payments__c = 375,
                                               Carry_over_balance__c = 375,
                                               Property_Account__c = propertyAcc2.Id,
                                               Unique_ID__c = opp2.Name + ' ' + sss2.Id + ' ' + DateTime.newInstance(billingDate1.year(), billingDate1.month(), billingDate1.day()).format('yyyy-MM'));
        insert new List<System_Bill__c>{sb, sb1A, sb2};
        update new List<System_Bill__c>{sb, sb1A, sb2};

        Utility_Account_Bill__c uab = new Utility_Account_Bill__c(Name = opp1.Name + ' ' + billingDate1.Month() + ' ' + billingDate1.year() + ' ' + uas.Name,
                                                                  Date__c = billingDate1,
                                                                  Utility_Account_Log__c = ual.Id,
                                                                  Bill_Number__c = 1,
                                                                  Account_Bill__c = ab.Id,
                                                                  Unique_ID__c = uas.Utility_Account_Log__c + ' - ' + DateTime.newInstance(billingDate1.year(), billingDate1.month(), billingDate1.day()).format('yyyy-MM'));
        Utility_Account_Bill__c uab2 = new Utility_Account_Bill__c(Name = opp2.Name + ' ' + billingDate1.Month() + ' ' + billingDate1.year() + ' ' + uas2.Name,
                                                                  Date__c = billingDate1,
                                                                  Utility_Account_Log__c = ual2.Id,
                                                                  Bill_Number__c = 1,
                                                                  Account_Bill__c = ab2.Id,
                                                                  Unique_ID__c = uas2.Utility_Account_Log__c + ' - ' + DateTime.newInstance(billingDate1.year(), billingDate1.month(), billingDate1.day()).format('yyyy-MM'));

        insert new List<Utility_Account_Bill__c>{uab, uab2};

        UASB__c uasb = new UASB__c(Name = uas.Name + sss1.Name,
                                   Customer_Subscription_KW_DC__c = uas.Customer_Subscription_KW_DC_STATIC__c,
                                   CS_Billing_Log__c = uab.Id,
                                   Date__c = billingDate1,
                                   Utility_Account_Subscription__c = uas.Id,
                                   Opportunity__c = Opp1.Id,
                                   System_Bill__c = sb.Id,
                                   Shared_Solar_System__c = sss1.Id,
                                   Total_System_Size_kw_DC__c = sss1.Total_System_Size_kWh_DC__c,
                                   NMC_Rate__c = nmcRate.Value_of_Net_Metering_Credit__c,
                                   Unique_ID__c = opp1.Shared_Solar_System__c + ' - ' + uas.Id + ' - ' + DateTime.newInstance(billingDate1.year(), billingDate1.month(), billingDate1.day()).format('yyyy-MM'));
        UASB__c uasb2 = new UASB__c(Name = uas2.Name + sss2.Name,
                                   Customer_Subscription_KW_DC__c = uas2.Customer_Subscription_KW_DC_STATIC__c,
                                   CS_Billing_Log__c = uab2.Id,
                                   Date__c = billingDate1,
                                   Utility_Account_Subscription__c = uas2.Id,
                                   Opportunity__c = Opp2.Id,
                                   System_Bill__c = sb2.Id,
                                   Shared_Solar_System__c = sss2.Id,
                                   Total_System_Size_kw_DC__c = sss2.Total_System_Size_kWh_DC__c,
                                   NMC_Rate__c = nmcRate.Value_of_Net_Metering_Credit__c,
                                   Unique_ID__c = opp2.Shared_Solar_System__c + ' - ' + uas2.Id + ' - ' + DateTime.newInstance(billingDate1.year(), billingDate1.month(), billingDate1.day()).format('yyyy-MM'));        
        insert new List<UASB__c>{uasb, uasb2};
    
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
	          ChargentOrders__Subtotal__c = sb.Total_Due__c,
	          ChargentOrders__Payment_Status__c = 'Recurring',
	          ChargentOrders__Payment_Method__c = 'Credit Card',
	          System_Bill__c = sb.Id,
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
        system.debug(accountBillMap);
        
        Map<String, System_Bill__c> systemBillMap = new Map<String, System_Bill__c>();
        for (System_Bill__c sb : [SELECT Id, Total_Due__c, Shared_Solar_System__r.Name, Carry_Over_Balance__c, Shared_Solar_System__r.Id,  
                                        Bill_Number__c, Name, FormAssembly_Order_Helper__c, Form_ID_Helper__c
        						              FROM System_Bill__c]){
        	systemBillMap.put(sb.Shared_Solar_System__r.Name, sb);
        }    
        system.debug(systemBillMap);

        ChargentOrders__Transaction__c chTransaction = [SELECT Id, Name 
                                      				    FROM ChargentOrders__Transaction__c];                                                                            
        Test.startTest();
          System.runAs(userMap.get('communityuser@test.com')){
            //test the getMenuLabeList() method
            List<Account> menuLabelRespList = new List<Account>(MyAccountController.getMenuLabelList());
            System.debug('The size of the menuLabelRespList is ' + menuLabelRespList.size());
            System.assertEquals(menuLabelRespList.get(0).Id, customerAccountMap.get('Property Account').Id);

            //test the getMyBill() method
            Decimal billRespPrAcc = MyAccountController.getMyBill(
            String.valueOf(customerAccountMap.get('Property Account').Id));
            System.assertEquals(billRespPrAcc, 130);
          
            Decimal billRespAll = MyAccountController.getMyBill('All');
            System.assertEquals(billRespAll, 130);

            //test the getSystemBills() method
            List <AggregateResult> systemBillPrAccRespList = new List <AggregateResult>(MyAccountController.getSystemBills(
            String.valueOf(customerAccountMap.get('Property Account').Id).substring(0,15)));
            string firstab;
            string secondab;
            string firstentity;
            string secondentity;
            for (AggregateResult ar : systemBillPrAccRespList) {
              if (ar.get('carryover') == 100) {
                  firstab = string.valueOf(ar.get('Account_Bill__c'));
                  firstentity = string.valueOf(ar.get('entity'));
              } else {
                  secondab = string.valueOf(ar.get('Account_Bill__c'));
                  secondentity = string.valueOf(ar.get('entity'));  
                System.assertEquals(ar.get('carryover'), 30);             
              }
            }
              System.assertEquals(firstab, secondab);
              System.assertnotEquals(firstentity, secondentity);

            List <AggregateResult> systemBillallList = new List <AggregateResult> (MyAccountController.getSystemBills('all'));
            string firstab2;
            string secondab2;
            string firstentity2;
            string secondentity2;
            for (AggregateResult ar : systemBillPrAccRespList) {
              if (ar.get('carryover') == 100) {
                 firstab2 = string.valueOf(ar.get('Account_Bill__c'));
                 firstentity2 = string.valueOf(ar.get('entity'));
              } else {
                 secondab2 = string.valueOf(ar.get('Account_Bill__c'));
                 secondentity2 = string.valueOf(ar.get('entity'));  
                System.assertEquals(ar.get('carryover'), 30);             
              }
            }
            System.assertEquals(firstab2, secondab2);
            System.assertnotEquals(firstentity2, secondentity2);

            //test the getMyParentAccountId() method
            Id parentAccountId = MyAccountController.getMyParentAccountId(
            String.valueOf(customerAccountMap.get('Parent Account').Id));
    				System.assertEquals(parentAccountId, String.valueOf(customerAccountMap.get('Parent Account').Id));

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

    				//test the getOpportunyIds() method
    				List <Opportunity> opportunityRespList = new List <Opportunity>(MyAccountController.getOpportunityIds());
    				System.assertEquals(opportunityRespList.get(0).Id, opportunityMap.get('Opp1A').Id);
            system.assertEquals(opportunityRespList.size(), 2);

    				//test the sendEmail() method
    				MyAccountController.sendEmail('test@test.test');

            //test the getPaymentFormCheck method for User 1
            Boolean paymentFormCheckResp = MyAccountController.getPaymentFormCheck();
            System.assertEquals(paymentFormCheckResp, false);
          }
          System.runAs(userMap.get('communityuser2@test.com')){
        	//test the getPaymentFormCheck method for User 2
            Boolean paymentFormCheckResp = MyAccountController.getPaymentFormCheck();
            System.assertEquals(paymentFormCheckResp, true);
          }
        Test.stopTest();    

    }
}