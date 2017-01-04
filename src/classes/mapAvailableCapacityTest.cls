@isTest
private class mapAvailableCapacityTest{

Static testMethod void mapAvailableCapacity(){


Date myDate = Date.newInstance(2015, 2, 17);
        
        Utility_NMC_Tariff__c everSEMA = new Utility_NMC_Tariff__c (
                Name = 'Eversource SEMA Class 2', 
                Utility__c = 'Eversource', 
                Class__c = 'Class 2',
                Value_of_Net_Metering_Credit__c = 0.1848,
                Sizing_Rate__c = TRUE
                );

        insert everSEMA;

        Utility_NMC_Tariff__c everNEMA = new Utility_NMC_Tariff__c (
                Name = 'Eversource NEMA Class 2', 
                Utility__c = 'Eversource', 
                Class__c = 'Class 2',
                Value_of_Net_Metering_Credit__c = 0.1218,
                Sizing_Rate__c = TRUE
                );

        insert everNEMA;

        Load_U__c semaLZU = new Load_U__c ( 
                Name = '02633', 
                Load_zone__c = 'SEMA Eversource', 
                LZ__c = 'SEMA', 
                Utility__C = 'Eversource', 
                Town__c= 'Southtown');

        Load_U__c nemaLZU = new Load_U__c ( 
                Name = '01570', 
                Load_zone__c= 'NEMA Eversource', 
                LZ__c = 'NEMA', 
                Utility__C = 'Eversource', 
                Town__c= 'Westtown');

        Insert semaLZU;
        Insert nemaLZU;
        
        system.debug(semaLZU);

        Shared_Solar_System__c sss = new Shared_Solar_System__c(Name = 'No Capacity SSS',
                                                                        Service_Territory__c = 'SEMA',
                                                                        Open__c = true,
                                                                        //Reserved_Capacity_kW_DC__c = '500',
                                                                        Capacity_Committed_kW_DC__c = 500,
                                                                        Total_System_Size_kWh_DC__c = 500,
                                                                        Total_System_Size_kW_AC__c  = 500,
                                                                        System_Utility__c = 'Eversource',
                                                                        Credit_Score_Requirement__c = 200,
                                                                        Assignment_order__c = '2',
                                                                        Utility_NMC_Tariff__c = everSEMA.Id,
                                                                        Expected_Yield_kWh_kW__c = 1300,
                                                                        Assemblage_Count__c = 1,
                                                                        Sales_Partners__c = 'All',
                                                                        Maximum_Subscription_Assemblage__c = 25);

    Shared_Solar_System__c sss0 = new Shared_Solar_System__c(Name = 'Oxford NEMA',
                                                                        Service_Territory__c = 'NEMA',
                                                                        Open__c = true,
                                                                        Reserved_Capacity_kW_DC__c = '0',
                                                                        Capacity_Committed_kW_DC__c = 0,
                                                                        Total_System_Size_kWh_DC__c = 1200,
                                                                        Total_System_Size_kW_AC__c  = 996,
                                                                        System_Utility__c = 'Eversource',
                                                                        Credit_Score_Requirement__c = 200,
                                                                        Assignment_order__c = '2',
                                                                        Utility_NMC_Tariff__c = everNEMA.Id,
                                                                        Expected_Yield_kWh_kW__c = 1300,
                                                                        Assemblage_Count__c = 1,
                                                                        Sales_Partners__c = 'Boston Solar; SolWorks',
                                                                        Maximum_Subscription_Assemblage__c = 25);

    Shared_Solar_System__c sss1 = new Shared_Solar_System__c(Name = 'Oxford SEMA P1',
                                                                       Service_Territory__c = 'SEMA',
                                                                       Open__c = true,
                                                                       Reserved_Capacity_kW_DC__c = '0',
                                                                       Capacity_Committed_kW_DC__c = 0,
                                                                       Total_System_Size_kWh_DC__c = 1445,
                                                                       Total_System_Size_kW_AC__c  = 996,
                                                                       System_Utility__c = 'Eversource',
                                                                       Credit_Score_Requirement__c = 200,
                                                                       Assignment_order__c = '1',
                                                                       Utility_NMC_Tariff__c = everSEMA.Id,
                                                                       Expected_Yield_kWh_kW__c = 1300,
                                                                       Assemblage_Count__c = 1,
                                                                       Sales_Partners__c = 'All',
                                                                       Maximum_Subscription_Assemblage__c = 25);

    Shared_Solar_System__c sss2 = new Shared_Solar_System__c(Name = 'Oxford SEMA P2',
                                                                        Service_Territory__c = 'SEMA',
                                                                        Open__c = true,
                                                                        Reserved_Capacity_kW_DC__c = '0',
                                                                        Capacity_Committed_kW_DC__c = 0,
                                                                        Total_System_Size_kWh_DC__c = 1800,
                                                                        Total_System_Size_kW_AC__c  = 996,
                                                                        System_Utility__c = 'Eversource',
                                                                        Credit_Score_Requirement__c = 800,
                                                                        Assignment_order__c = '2',
                                                                        Utility_NMC_Tariff__c = everSEMA.Id,
                                                                        Expected_Yield_kWh_kW__c = 1300,
                                                                        Assemblage_Count__c = 1,
                                                                        Sales_Partners__c = 'All',
                                                                        Maximum_Subscription_Assemblage__c = 25);


    insert new List<Shared_Solar_System__c>{sss, sss0, sss1, sss2};

    Partner__c partnerA = new Partner__c(Name = 'Boston Solar');
    insert partnerA;

    BSST__c salesteam = new BSST__c (Name = 'Boston Solar',
                       Custom_ID__c = 'PA',
                       Partner__c = partnerA.Id);
    insert salesteam;
    
    Account accountA = new Account(name = 'Account A',
            RecordTypeId = '012j00000010Ha3');       

        Account accountB = new Account(name = 'Account B',
            RecordTypeId = '012j00000010Ha3');       

        Account accountC = new Account(name = 'Account C',
            RecordTypeId = '012j00000010Ha3');       

        Account accountD = new Account(name = 'Account D',
            RecordTypeId = '012j00000010Ha3');       
        
        Insert accountA;
        Insert accountB;
        Insert accountC;
        Insert accountD;   

 /* 
      Lead leadA = new Lead(LastName = 'Last',
                      FirstName = 'One',
                      Email = 'test@email.com',
                      Electricity_Provider__c = 'Eversource',
                      Utility_1__c = 'Eversource',
                      Load_Zone__c = 'NEMA',
                      Company = 'Cloud Jedi',
                      Custom_ID__c = 'PA',
                      Product_Line__c = 'Community Solar',
                      Parent_Account__c = accountA.Id,
                      System_Assignment__c = 'Automatic - Assignment Order');
      
      insert leadA;

    
                LASERCA__Personal_Credit_Report__c pcrA = (LASERCA__Personal_Credit_Report__c)TestFactory.createSObject(new LASERCA__Personal_Credit_Report__c(
                                                                                        LASERCA__Lead__c = leadA.Id,
                                                                                        LASERCA__Credit_Score_TransUnion__c = '700'), true);
                //lead.Personal_Credit_Report__c = pcrB.Id;
            update leadA;
 */       

      Lead leadB = new Lead(LastName = 'Last',
                      FirstName = 'Two',
                      Email = 'test@email.com',
                      Electricity_Provider__c = 'Eversource',
                      Utility_1__c = 'Eversource',
                      Load_Zone__c = 'NEMA',
                      Company = 'Cloud Jedi',
                      //Status = 'Qualified',
                      Product_Line__c = 'Community Solar',
                      Parent_Account__c = accountB.Id,
                      System_Assignment__c = 'Automatic - Assignment Order');
      
      insert leadB;

                  LASERCA__Personal_Credit_Report__c pcrB = (LASERCA__Personal_Credit_Report__c)TestFactory.createSObject(new LASERCA__Personal_Credit_Report__c(
                                                                                        LASERCA__Lead__c = leadB.Id,
                                                                                        LASERCA__Credit_Score_TransUnion__c = '700'), true);
                //lead.Personal_Credit_Report__c = pcrB.Id;
            update leadB;


      Lead leadC = new Lead(LastName = 'Last',
                      FirstName = 'Three',
                      Email = 'test@email.com',
                      Electricity_Provider__c = 'Eversource',
                      Utility_1__c = 'Eversource',
                      Load_Zone__c = 'SEMA',
                      Company = 'Cloud Jedi',
                      //Status = 'Qualified',
                      Product_Line__c = 'Community Solar',
                      Parent_Account__c = accountC.Id,
                      System_Assignment__c = 'Automatic - Assignment Order');
      
      insert leadC;

                  LASERCA__Personal_Credit_Report__c pcrC = (LASERCA__Personal_Credit_Report__c)TestFactory.createSObject(new LASERCA__Personal_Credit_Report__c(
                                                                                        LASERCA__Lead__c = leadC.Id,
                                                                                        LASERCA__Credit_Score_TransUnion__c = '680'), true);
                //lead.Personal_Credit_Report__c = pcrB.Id;
            update leadC;
/*
      Lead leadD = new Lead(LastName = 'Last',
                      FirstName = 'Four',
                      Email = 'test@email.com',
                      Electricity_Provider__c = 'Eversource',
                      Utility_1__c = 'Eversource',
                      Load_Zone__c = 'SEMA',
                      Company = 'Cloud Jedi',
                      //Status = 'Qualified',
                      Product_Line__c = 'Community Solar',
                      Parent_Account__c = accountD.Id,
                      System_Assignment__c = 'Automatic - Assignment Order');
      
      insert leadD;

                  LASERCA__Personal_Credit_Report__c pcrD = (LASERCA__Personal_Credit_Report__c)TestFactory.createSObject(new LASERCA__Personal_Credit_Report__c(
                                                                                        LASERCA__Lead__c = leadD.Id,
                                                                                        LASERCA__Credit_Score_TransUnion__c = '800'), true);
                //lead.Personal_Credit_Report__c = pcrB.Id;
            update leadD;
  */    
      List <Lead> updatedLeadList = [SELECT Id, FirstName, Available_Capacity__c FROM Lead];
        system.debug(updatedLeadList);


        Test.StartTest();
        for(Lead lead : updatedLeadList){

          if(lead.FirstName == 'One'){
              system.Assert(lead.Available_Capacity__c == 1200);
          }

          if(lead.FirstName == 'Two'){
              system.Assert(lead.Available_Capacity__c == 0);
          }

          if(lead.FirstName == 'Three'){
              system.Assert(lead.Available_Capacity__c == 1445);
          }

          if(lead.FirstName == 'Four'){
              system.Assert(lead.Available_Capacity__c == 3245);
          } 
        }
        Test.StopTest();
 
}
}