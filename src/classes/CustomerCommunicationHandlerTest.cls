@isTest
public class CustomerCommunicationHandlerTest{  

    public static testmethod void test1(){
    
      
    
    Utility_NMC_Tariff__c eversizeNMC = new Utility_NMC_Tariff__c (Name = 'Eversource SEMA Class 2', 
                                                                    Utility__c = 'Eversource', 
                                                                    Class__c = 'Class 2',
                                                                    Value_of_Net_Metering_Credit__c = 0.1848,
                                                                    Sizing_Rate__c = TRUE);   
    insert eversizeNMC; 

    Utility_NMC_Tariff__c everbillNMC = new Utility_NMC_Tariff__c (
                                                        Name = 'Eversource SEMA Class 2', 
                                                        Utility__c = 'Eversource', 
                                                        Class__c = 'Class 2',
                                                        Value_of_Net_Metering_Credit__c = 0.1848,
                                                        Current_Billing_Rate__c = TRUE);
    insert everbillNMC;

    Shared_Solar_System__c sss1 = new Shared_Solar_System__c(Name = 'Oxford Barrett St. P1',
                                                             Service_Territory__c = 'SEMA',
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
                                                            Maximum_Subscription_Assemblage__c = 25);
     insert sss1;

    // FIRST ACCOUNT
    Account accountA = new Account( name = 'Account A');       
    Insert accountA; 
    Contact contacta = new Contact( FirstName = 'First',
                                    LastName = 'Last',
                                    email = 'jpentaleri@bluewave-capital.com',
                                    Account = AccountA);
    Insert contacta;
    Account accountB = new Account( name = 'Account B',
                                    Parent_Account__c = AccountA.id,
                                    Send_Bills_Contact__c = contacta.Id);       
    Insert accountB;
    system.debug(accountB);
    Utility_Account_Log__c ualog = new Utility_Account_Log__c(    Name = '0000234',
                                                                Account__c = accountB.Id,
                                                                  Annual_Cost_of_Electricity__c = 10000,
                                                                Name_on_Account__c = 'jordan jordan');
    insert ualog;
    Opportunity opportunityone = new Opportunity(Name = 'Jordan Jordan',
                                                   AccountId = accountB.Id,
                                                   Shared_Solar_System__c = sss1.Id,
                                                   StageName = 'Complete',
                                                   CS_Capacity_Allocated__c = 25,
                                                   CloseDate = System.today());
    insert opportunityone;
    Utility_Account_Subscription__c uasone = new Utility_Account_Subscription__c(Name = '0000234',
                                                                                   Utility_Account_Log__c = ualog.Id,
                                                                                   Opportunity__c = opportunityone.Id,
                                                                                   Calculated_Annual_Cost_of_Electricity__c = 4000,
                                                                                    Subscribed_Annual_Cost_of_Electricity__c = 4000);
    insert uasone;
    uasone.Customer_Subscription_KW_DC_STATIC__c = 25;
    update uasone;


    // SECOND ACCOUNT
    Account accountA2 = new Account( name = 'Account A2');       
    Insert accountA2; 
    Contact contacta2 = new Contact( FirstName = 'First2',
                                    LastName = 'Last2',
                                    email = 'jpentaleri@bluewave-capital.com',
                                    Account = AccountA2);
    Insert contacta2;
    Account accountB2 = new Account( name = 'Account B2',
                                    Parent_Account__c = AccountA2.id,
                                    Send_Bills_Contact__c = contacta2.Id);       
    Insert accountB2;
    Utility_Account_Log__c ualog2 = new Utility_Account_Log__c(    Name = '00002342',
                                                                Account__c = accountB2.Id,
                                                                  Annual_Cost_of_Electricity__c = 10000,
                                                                Name_on_Account__c = 'jordan2 jordan');
    Insert ualog2;
    Opportunity opportunityone2 = new Opportunity(Name = 'Jordan2 Jordan',
                                                   AccountId = accountB2.Id,
                                                   Shared_Solar_System__c = sss1.Id,
                                                   StageName = 'Complete',
                                                   CS_Capacity_Allocated__c = 15,
                                                   CloseDate = System.today());
    insert opportunityone2;
    Utility_Account_Subscription__c uasone2 = new Utility_Account_Subscription__c(Name = '00002342',
                                                                                   Utility_Account_Log__c = ualog2.Id,
                                                                                   Opportunity__c = opportunityone2.Id,
                                                                                   Calculated_Annual_Cost_of_Electricity__c = 4000,
                                                                                    Subscribed_Annual_Cost_of_Electricity__c = 4000);
    insert uasone2;
    uasone2.Customer_Subscription_KW_DC_STATIC__c = 25;
    update uasone2;

    // THIRD ACCOUNT
    Account accountA3 = new Account( name = 'Account A3');       
    Insert accountA3; 
    Contact contacta3 = new Contact( FirstName = 'First3',
                                    LastName = 'Last3',
                                    email = 'jpentaleri@bluewave-capital.com',
                                    Account = AccountA3);
    Insert contacta3;
    Account accountB3 = new Account( name = 'Account B3',
                                    Parent_Account__c = AccountA3.id,
                                    Send_Bills_Contact__c = contacta3.Id);       
    Insert accountB3;
    Utility_Account_Log__c ualog3 = new Utility_Account_Log__c( Name = '00002343',
                                                                Account__c = accountB3.Id,
                                                                Annual_Cost_of_Electricity__c = 10000,
                                                                Name_on_Account__c = 'jordan3 jordan');
    insert ualog3;
    Opportunity opportunityone3 = new Opportunity(Name = 'Jordan3 Jordan',
                                                   AccountId = accountB3.Id,
                                                   Shared_Solar_System__c = sss1.Id,
                                                   StageName = 'Complete',
                                                   CS_Capacity_Allocated__c = 15,
                                                   CloseDate = System.today());
    insert opportunityone3;
    Utility_Account_Subscription__c uasone3 = new Utility_Account_Subscription__c(  Name = '00002342',
                                                                                    Utility_Account_Log__c = ualog3.Id,
                                                                                    Opportunity__c = opportunityone3.Id,
                                                                                    Calculated_Annual_Cost_of_Electricity__c = 1300,
                                                                                    Subscribed_Annual_Cost_of_Electricity__c = 1300);
    insert uasone3;
    uasone3.Customer_Subscription_KW_DC_STATIC__c = 20;
    update uasone3;

    // FOURTH ACCOUNT
    Account accountA4 = new Account( name = 'Account A4');       
    Insert accountA4; 
    Contact contacta4 = new Contact( FirstName = 'First4',
                                    LastName = 'Last4',
                                    email = 'jpentaleri@bluewave-capital.com',
                                    Account = AccountA4);
    Insert contacta4;
    Account accountB4 = new Account( name = 'Account B4',
                                    Parent_Account__c = AccountA4.id,
                                    Send_Bills_Contact__c = contacta4.Id);       
    Insert accountB4;
    Utility_Account_Log__c ualog4 = new Utility_Account_Log__c( Name = '00002344',
                                                                Account__c = accountB4.Id,
                                                                Annual_Cost_of_Electricity__c = 10000,
                                                                Name_on_Account__c = 'jordan4 jordan');
    insert ualog4;
    Opportunity opportunityone4 = new Opportunity(Name = 'Jordan4 Jordan',
                                                   AccountId = accountB4.Id,
                                                   Shared_Solar_System__c = sss1.Id,
                                                   StageName = 'Complete',
                                                   CS_Capacity_Allocated__c = 15,
                                                   CloseDate = System.today());
    insert opportunityone4;
    Utility_Account_Subscription__c uasone4 = new Utility_Account_Subscription__c(Name = '00002344',
                                                                                  Utility_Account_Log__c = ualog4.Id,
                                                                                  Opportunity__c = opportunityone4.Id,
                                                                                  Calculated_Annual_Cost_of_Electricity__c = 1100,
                                                                                  Subscribed_Annual_Cost_of_Electricity__c = 1100);
    insert uasone4;
    uasone4.Customer_Subscription_KW_DC_STATIC__c = 15;
    update uasone4;

     // FIFTH ACCOUNT
    Account accountA5 = new Account( name = 'Account A5');       
    Insert accountA5; 
    Contact contacta5 = new Contact( FirstName = 'First5',
                                    LastName = 'Last5',
                                    email = 'jpentaleri@bluewave-capital.com',
                                    Account = AccountA5);
    Insert contacta5;
    Account accountB5 = new Account( name = 'Account B5',
                                    Parent_Account__c = AccountA5.id,
                                    Send_Bills_Contact__c = contacta5.Id);       
    Insert accountB5;
    Utility_Account_Log__c ualog5 = new Utility_Account_Log__c( Name = '00002345',
                                                                Account__c = accountB5.Id,
                                                                Annual_Cost_of_Electricity__c = 10000,
                                                                Name_on_Account__c = 'jordan5 jordan');
    insert ualog5;
    Opportunity opportunityone5 = new Opportunity(Name = 'Jordan5 Jordan',
                                                   AccountId = accountB5.Id,
                                                   Shared_Solar_System__c = sss1.Id,
                                                   StageName = 'Complete',
                                                   CS_Capacity_Allocated__c = 15,
                                                   CloseDate = System.today());
    insert opportunityone5;
    Utility_Account_Subscription__c uasone5 = new Utility_Account_Subscription__c(Name = '00002345',
                                                                                  Utility_Account_Log__c = ualog5.Id,
                                                                                  Opportunity__c = opportunityone5.Id,
                                                                                  Calculated_Annual_Cost_of_Electricity__c = 1000,
                                                                                  Subscribed_Annual_Cost_of_Electricity__c = 1000);
    insert uasone5;
    uasone5.Customer_Subscription_KW_DC_STATIC__c = 10;
    update uasone5;




    List <Utility_Account_Subscription__c> uaslist = [SELECT Id, Customer_Subscription_KW_DC_STATIC__c, Subscribed_Annual_Cost_of_Electricity__c, Calculated_Annual_Cost_of_Electricity__c, Shared_Solar_System_Name__c FROM Utility_Account_Subscription__c];

        for(Utility_Account_Subscription__c uas : uaslist){
        system.debug(uas.Customer_Subscription_KW_DC_STATIC__c);
        system.debug(uas.Subscribed_Annual_Cost_of_Electricity__c);
        system.debug(uas.Calculated_Annual_Cost_of_Electricity__c);
        }

    Date myDateJan = Date.newInstance(2016, 1, 1);

    Energy_Usage_Update__c productionupdateA1 = new Energy_Usage_Update__c (Name = 'sssA - January 2016',
                                                                            Shared_Solar_System__c = sss1.id,
                                                                            Production__c = 90000,
                                                                            Size_off_NMCS__c = TRUE,
                                                                            Total_System_NMCs__c = 45000,
                                                                            Date__c = myDateJan);

    Insert productionupdateA1;


    List <Account_Bill__c> accountBillList = [SELECT Id, Name, Total_Due__c, Property_Account_Name__c, Bill_Number__c, Property_Account_ID__c 
                                              FROM Account_Bill__c];
    system.debug(accountBillList);
    
    
    // addDays(-49) = 30 days overdue, addDays(-79) = 60 days overdue
    for (Account_Bill__c ab : accountBillList){
      if(ab.Property_Account_Name__c == 'Account B2'){
        ab.Date_Sent__c = Date.today().addDays(-26);
      }
      else if(ab.Property_Account_Name__c == 'Account B3'){
        ab.Date_Sent__c = Date.today().addDays(-34);
      }
      else if(ab.Property_Account_Name__c == 'Account B4'){
        ab.Date_Sent__c = Date.today().addDays(-49);
      }
      else if(ab.Property_Account_Name__c == 'Account B5'){
        ab.Date_Sent__c = Date.today().addDays(-64);
      }
      else {
        ab.Date_Sent__c = Date.today().addDays(-109);
      }
    }
    
    update accountBillList;

    List <Account> accountlist = [SELECT Id, Name, RecordTypeId, Max_Overdue_Send_Date__c, Total_Outstanding_Balance__c, Total_Billed__c, Send_Bills_Contact__c, Days_Past_Due__c
                                  FROM Account];
    system.debug(accountlist);

    RecordType prop = [ SELECT Id
                      FROM RecordType
                      WHERE DeveloperName = 'Property'];
    system.debug(prop);

    RecordType par = [ SELECT Id
                      FROM RecordType
                      WHERE DeveloperName = 'Parent_Account'];
    system.debug(par);

    for (Account accts : accountlist){
       if(accts.Name == 'Account A' || accts.Name == 'Account A2' || accts.Name == 'Account A3' || accts.Name == 'Account A4' || accts.Name == 'Account A5' ){
        accts.RecordTypeId = par.Id;
       }
       if(accts.Name == 'Account B' || accts.Name == 'Account B2' || accts.Name == 'Account B3' || accts.Name == 'Account B4' || accts.Name == 'Account B5'){
        accts.RecordTypeId = prop.Id;
       }
    }

    update accountlist;
    
     
    Test.startTest();    

                Datetime dt = Datetime.now().addMinutes(1);
                CustomerCommunicationHandler m = new CustomerCommunicationHandler();
                String CRON_EXP = '0 '+ dt.minute() + ' ' + dt.hour() + ' ' + dt.day() + ' ' + dt.month() + ' ?';
                System.schedule('CustomerCommunicationHandler', CRON_EXP, m );  
                //System.schedule('CustomerCommunicationHandler', CRON_EXP, new CustomerCommunicationHandler () );   

    Test.stopTest();

    }
 }