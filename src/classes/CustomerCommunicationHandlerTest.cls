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
        
        for (Integer j = 1; j < 3 ; j++) {
            Shared_Solar_System__c sss1 = 
                new Shared_Solar_System__c(Name = 'SSS' + j,
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
        
            Account accountParent = new Account(Name = 'Par Account' + j);
            insert accountParent;  

            Contact contactA = new Contact( FirstName = 'Contact A', 
                                            LastName = 'Last', 
                                            Account = accountParent);
            insert contactA;     

            Account accountA = new Account( Name = 'Prop Account' + j, 
                                            Parent_Account__c = accountParent.Id,
                                            Send_Bills_Contact__c = contactA.Id);
            insert accountA;     

            Utility_Account_Log__c ualog = new Utility_Account_Log__c(
                                            Name = '0000234' + j,
                                            Account__c = accountA.Id,
                                            Annual_Cost_of_Electricity__c = 10000,
                                            Name_on_Account__c = 'jordan jordan' + j);
            insert ualog;

            Opportunity opportunityone = 
                new Opportunity(Name = 'Jordan Jordan' + j,
                                AccountId = accountA.Id,
                                Shared_Solar_System__c = sss1.Id,
                                StageName = 'Complete',
                                CS_Capacity_Allocated__c = 25,
                                CloseDate = System.today());
            insert opportunityone;
           
            Utility_Account_Subscription__c uasOne = 
                new Utility_Account_Subscription__c(Name = '0000234' + j,
                                                    Utility_Account_Log__c = ualog.Id,
                                                    Opportunity__c = opportunityone.Id,
                                                    Next_Schedule_Z_Status__c = 'Enacted: Removed',
                                                    Calculated_Annual_Cost_of_Electricity__c = 4000,
                                                    Subscribed_Annual_Cost_of_Electricity__c = 4000);
            insert uasOne;
            uasOne.Customer_Subscription_KW_DC_STATIC__c = 25;
            update uasOne;
        }

        List<Shared_Solar_System__c> sssList = [SELECT Id, Name FROM Shared_Solar_System__c];

        Energy_Usage_Update__c productionupdate = new Energy_Usage_Update__c (
                Name = 'sssA - March 2016',
                Shared_Solar_System__c = sssList[0].Id,
                Production__c = 140000,
                Total_System_NMCs__c = 34000,
                Date__c = Date.today().addDays(-26)
        );

        Energy_Usage_Update__c productionupdate2 = new Energy_Usage_Update__c (
                Name = 'sssB - March 2016',
                Shared_Solar_System__c = sssList[1].Id,
                Production__c = 140000,
                Total_System_NMCs__c = 34000,
                Date__c = Date.today().addDays(-34)
        );

        insert new List<Energy_Usage_Update__c>{productionupdate, productionupdate2};

        productionUpdate.Generate_Bills__c = True;
        productionUpdate2.Generate_Bills__c = True;
        update new List<Energy_Usage_Update__c>{productionupdate, productionupdate2};
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

        List<Account> accountlist = [SELECT Id, Name, RecordTypeId, Max_Overdue_Send_Date__c, 
                                    Total_Outstanding_Balance__c, Total_Billed__c, 
                                    Send_Bills_Contact__c, Days_Past_Due__c
                                    FROM Account
                                    WHERE Days_Past_Due__c > 0];
        System.debug(accountlist);
      //  System.AssertNotEquals(0, accountlist.size());

        CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, 
                            NextFireTime
                          FROM CronTrigger WHERE id = :jobId];

        System.AssertEquals(dt.minute(), ct.NextFireTime.minute());
        System.AssertEquals(dt.hour(), ct.NextFireTime.hour());
        System.AssertEquals(dt.day(), ct.NextFireTime.day());
        System.AssertEquals(dt.month(), ct.NextFireTime.month());
    } 
 }