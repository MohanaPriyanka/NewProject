@isTest
public class MonthlyEmailHandlerTest{  

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
                                                            Maximum_Subscription_Assemblage__c = 25);
     insert sss1;

    // FIRST ACCOUNT
    Account accountA = new Account( name = 'Account A');       
    Insert accountA; 
    Contact contacta = new Contact( FirstName = 'First',
                                    LastName = 'Last',
                                    email = 'jpentaleri@bluewave-capital.com',
                                    Account = AccountA,
                                    AccountId = AccountA.id);
    Insert contacta;
    Account accountB = new Account( name = 'Account B',
                                    Parent_Account__c = AccountA.id,
                                    Send_Bills_Contact__c = contacta.Id);       
    Insert accountB;

    Opportunity opportunityone = new Opportunity(Name = 'Jordan Jordan',
                                                   AccountId = accountB.Id,
                                                   Shared_Solar_System__c = sss1.Id,
                                                   StageName = 'Complete',
                                                   Product_Line__c = 'Community Solar',
                                                   Disable_Emails__c = False,
                                                   CloseDate = System.today());
    insert opportunityone;

    List <Account> accountlist = [SELECT Id, Name, RecordTypeId, Max_Overdue_Send_Date__c, Total_Outstanding_Balance__c, Total_Billed__c, Send_Bills_Contact__c, Days_Past_Due__c
                                  FROM Account];
    system.debug(accountlist);

    Contact cont = [ SELECT Id, FirstName, AccountId
                      FROM Contact];
    system.debug(cont);


    RecordType prop = [ SELECT Id
                      FROM RecordType
                      WHERE DeveloperName = 'Property'];
    system.debug(prop);

    RecordType par = [ SELECT Id
                      FROM RecordType
                      WHERE DeveloperName = 'Parent_Account'];
    system.debug(par);

    for (Account accts : accountlist){
       if(accts.Name == 'Account A'){
        accts.RecordTypeId = par.Id;
       }
       if(accts.Name == 'Account B'){
        accts.RecordTypeId = prop.Id;
       }
    }

    update accountlist;

    List <Account> accountlist2 = [SELECT Id, Name, RecordTypeId, Max_Overdue_Send_Date__c, Total_Outstanding_Balance__c, Total_Billed__c, Send_Bills_Contact__c, Days_Past_Due__c
                                  FROM Account];
    system.debug(accountlist2);
    
     
    Test.startTest();    

                Datetime dt = Datetime.now().addMinutes(1);
                MonthlyEmailHandler m = new MonthlyEmailHandler();
                String CRON_EXP = '0 '+ dt.minute() + ' ' + dt.hour() + ' ' + dt.day() + ' ' + dt.month() + ' ?';
                System.schedule('MonthlyEmailHandler', CRON_EXP, m );  

    Test.stopTest();

    }
 }