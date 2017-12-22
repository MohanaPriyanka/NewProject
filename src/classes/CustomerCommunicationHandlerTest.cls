@isTest
public class CustomerCommunicationHandlerTest{  
    @testSetup public static void setupData() {
        Utility_NMC_Tariff__c everbillNMC = new Utility_NMC_Tariff__c (Name = 'Eversource SEMA Class 2', 
                                                                       Utility__c = 'Eversource', 
                                                                       Class__c = 'Class 2',
                                                                       Value_of_Net_Metering_Credit__c = 0.1848,
                                                                       Current_Billing_Rate__c = TRUE);

        Utility_NMC_Tariff__c eversizeNMC = new Utility_NMC_Tariff__c (Name = 'Eversource SEMA Class 2', 
                                                                       Utility__c = 'Eversource', 
                                                                       Class__c = 'Class 2',
                                                                       Value_of_Net_Metering_Credit__c = 0.1848,
                                                                       Sizing_Rate__c = TRUE);

        insert new List<Utility_NMC_Tariff__c>{everbillNMC, eversizeNMC};
        
        Load_U__c everLZU = new Load_U__c (Name = '02633', 
                                           Load_zone__c = 'SEMA Eversource', 
                                           LZ__c = 'SEMA', 
                                           Utility__C = 'Eversource', 
                                           Town__c= 'Medfield');

        insert everLZU;

        insert new BW_Address__c(Name = 'BlueWave', Address_Line_One__c = '137 Newbury Street', Address_Line_Two__c = 'Boston, MA 02114');

        Entity__c entity1 = new Entity__c (Name = 'Oxford Barrett St. P1');
        insert entity1;
        
        Shared_Solar_System__c sss1 = 
                new Shared_Solar_System__c(Name = 'SSS1',
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
                                           BWC_Project_Entity_Manual__c = entity1.Id,
                                           Maximum_Subscription_Assemblage__c = 25);
            insert sss1;

            Shared_Solar_System__c sss2 = 
                new Shared_Solar_System__c(Name = 'SSS2',
                                           Service_Territory__c = 'SEMA',
                                           Open__c = true,
                                           Reserved_Capacity_kW_DC__c = '0',
                                           Capacity_Committed_kW_DC__c = 0,
                                           Total_System_Size_kWh_DC__c = 1225.86,
                                           Total_System_Size_kW_AC__c  = 800,
                                           System_Utility__c = 'Eversource',
                                           Credit_Score_Requirement__c = 200,
                                           Assignment_order__c = '1',
                                           Utility_NMC_Tariff__c = eversizeNMC.Id,
                                           Expected_Yield_kWh_kW__c = 1300,
                                           Assemblage_Count__c = 1,
                                           Sales_Partners__c = 'All',
                                           BWC_Project_Entity_Manual__c = entity1.Id,
                                           Maximum_Subscription_Assemblage__c = 25);
            insert sss2;


            Shared_Solar_System__c sss3 = 
                new Shared_Solar_System__c(Name = 'SSS3',
                                           Service_Territory__c = 'SEMA',
                                           Open__c = true,
                                           Reserved_Capacity_kW_DC__c = '0',
                                           Capacity_Committed_kW_DC__c = 0,
                                           Total_System_Size_kWh_DC__c = 1111.86,
                                           Total_System_Size_kW_AC__c  = 940,
                                           System_Utility__c = 'Eversource',
                                           Credit_Score_Requirement__c = 200,
                                           Assignment_order__c = '1',
                                           Utility_NMC_Tariff__c = eversizeNMC.Id,
                                           Expected_Yield_kWh_kW__c = 1300,
                                           Assemblage_Count__c = 1,
                                           Sales_Partners__c = 'All',
                                           BWC_Project_Entity_Manual__c = entity1.Id,
                                           Maximum_Subscription_Assemblage__c = 25);
            insert sss3;
        
            Account accountParent1 = new Account(Name = 'Par Account 1');
            Account accountParent2 = new Account(Name = 'Par Account 2');
            Account accountParent3 = new Account(Name = 'Par Account 3');
            insert new List<Account>{accountParent1, accountParent2, accountParent3};  

            Contact contactA = new Contact( FirstName = 'Contact A', 
                                            LastName = 'Last', 
                                            Account = accountParent1);
            Contact contactB = new Contact( FirstName = 'Contact B', 
                                            LastName = 'Last', 
                                            Account = accountParent2);
            Contact contactC = new Contact( FirstName = 'Contact C', 
                                            LastName = 'Last', 
                                            Account = accountParent3);

            insert new List<Contact>{contactA, contactB, contactC};  

            Account propAcct1 = new Account( Name = 'Prop Account 1', 
                                            Parent_Account__c = accountParent1.Id,
                                            Send_Bills_Contact__c = contactA.Id);
            Account propAcct2 = new Account( Name = 'Prop Account 2', 
                                            Parent_Account__c = accountParent2.Id,
                                            Send_Bills_Contact__c = contactB.Id);
            Account propAcct3 = new Account( Name = 'Prop Account 3', 
                                            Parent_Account__c = accountParent3.Id,
                                            Send_Bills_Contact__c = contactC.Id);

            insert new List<Account>{propAcct1, propAcct2, propAcct3};  

            Utility_Account_Log__c ualog1 = new Utility_Account_Log__c(
                                            Name = '0000234',
                                            Account__c = propAcct1.Id,
                                            Annual_Cost_of_Electricity__c = 10000,
                                            Name_on_Account__c = 'Name one');

            Utility_Account_Log__c ualog2 = new Utility_Account_Log__c(
                                            Name = '0000236',
                                            Account__c = propAcct2.Id,
                                            Annual_Cost_of_Electricity__c = 10000,
                                            Name_on_Account__c = 'Name two');

            Utility_Account_Log__c ualog3 = new Utility_Account_Log__c(
                                            Name = '0000238',
                                            Account__c = propAcct3.Id,
                                            Annual_Cost_of_Electricity__c = 10000,
                                            Name_on_Account__c = 'Name three');

            insert new List<Utility_Account_Log__c>{ualog1, ualog2, ualog3};  

            Opportunity opportunityone = 
                new Opportunity(Name = 'Jordan Jordan',
                                AccountId = propAcct1.Id,
                                Shared_Solar_System__c = sss1.Id,
                                StageName = 'Complete',
                                CS_Capacity_Allocated__c = 25,
                                CloseDate = System.today());
            
            Opportunity opportunitytwo = 
                new Opportunity(Name = 'Jordan Jordan',
                                AccountId = propAcct2.Id,
                                Shared_Solar_System__c = sss2.Id,
                                StageName = 'Complete',
                                CS_Capacity_Allocated__c = 25,
                                CloseDate = System.today());

            Opportunity opportunitythree = 
                new Opportunity(Name = 'Jordan Jordan',
                                AccountId = propAcct2.Id,
                                Shared_Solar_System__c = sss3.Id,
                                StageName = 'Complete',
                                CS_Capacity_Allocated__c = 25,
                                CloseDate = System.today());
            insert new List<Opportunity>{opportunityone, opportunitytwo, opportunitythree};  
           
            Utility_Account_Subscription__c uasOne = 
                new Utility_Account_Subscription__c(Name = '0000234',
                                                    Utility_Account_Log__c = ualog1.Id,
                                                    Opportunity__c = opportunityone.Id,
                                                    Next_Schedule_Z_Status__c = 'Enacted: Removed',
                                                    Calculated_Annual_Cost_of_Electricity__c = 4000,
                                                    Subscribed_Annual_Cost_of_Electricity__c = 4000);
            Utility_Account_Subscription__c uasTwo = 
                new Utility_Account_Subscription__c(Name = '0000236',
                                                    Utility_Account_Log__c = ualog2.Id,
                                                    Opportunity__c = opportunitytwo.Id,
                                                    Next_Schedule_Z_Status__c = 'Enacted',
                                                    Calculated_Annual_Cost_of_Electricity__c = 8000,
                                                    Subscribed_Annual_Cost_of_Electricity__c = 8000);
            Utility_Account_Subscription__c uasThree = 
                new Utility_Account_Subscription__c(Name = '0000238',
                                                    Utility_Account_Log__c = ualog3.Id,
                                                    Opportunity__c = opportunitythree.Id,
                                                    Next_Schedule_Z_Status__c = 'Enacted',
                                                    Calculated_Annual_Cost_of_Electricity__c = 300,
                                                    Subscribed_Annual_Cost_of_Electricity__c = 300);

            insert new List<Utility_Account_Subscription__c>{uasOne, uasTwo, uasThree};  
            uasOne.Customer_Subscription_KW_DC_STATIC__c = 25;
            uasTwo.Customer_Subscription_KW_DC_STATIC__c = 10;
            uasTwo.Customer_Subscription_KW_DC_STATIC__c = 5;
            update new List<Utility_Account_Subscription__c>{uasOne, uasTwo, uasThree};  

            createBills(System.Today() - 110, sss1.Id); // 30 days late
            createBills(System.Today() - 50, sss2.Id); // 90 days late
            createBills(System.Today() - 17, sss3.Id); // 3 day warning

            List <Account_Bill__c> listaccountBills = [ SELECT Id, Published__c
                                                        FROM Account_Bill__c];
            
            for (Account_Bill__c acctBill : listaccountBills) {
                acctBill.Published__c = True;
            }
            update listaccountBills;
    }
    
    public static void createBills(Date billDate, Id sssID){
        Energy_Usage_Update__c productionupdate = new Energy_Usage_Update__c (
                Name = 'sssA - March 2016',
                Shared_Solar_System__c = sssID,
                Production__c = 140000,
                Total_System_NMCs__c = 34000,
                Date__c = billDate
        );
        insert productionupdate;
        productionUpdate.Generate_Bills__c = True;
        update productionUpdate;
    }

    public static testmethod void scheduleJob(){
        Test.startTest();
        Datetime dt = Datetime.now();
        CustomerCommunicationHandler m = new CustomerCommunicationHandler();
        String CRON_EXP = '0 '+ dt.minute() + ' ' + dt.hour() + ' ' + dt.day() + ' ' + dt.month() + ' ?';
        String jobId = System.schedule('CustomerCommunicationHandler', CRON_EXP, m );  
        Test.stopTest();

        List<Account> accountlist = [SELECT Id, Name, RecordTypeId, Last_Bill_Send_Date__c, 
                                    Total_Outstanding_Balance__c, Total_Billed__c, 
                                    Send_Bills_Contact__c, Days_Past_Due__c
                                    FROM Account
                                    WHERE Days_Past_Due__c != 0];
        System.AssertNotEquals(0, accountlist.size());
        System.debug(accountlist);

        CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, 
                            NextFireTime
                          FROM CronTrigger WHERE id = :jobId];

        System.AssertEquals(dt.minute(), ct.NextFireTime.minute());
        System.AssertEquals(dt.hour(), ct.NextFireTime.hour());
        System.AssertEquals(dt.day(), ct.NextFireTime.day());
        System.AssertEquals(dt.month(), ct.NextFireTime.month());
    } 
 }