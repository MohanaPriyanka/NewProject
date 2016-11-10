@isTest
private class TestBillCreationandPayment {

Static testMethod void TestBillCreationandPayment(){

/// https://cs4.salesforce.com/setup/build/viewApexClass.apexp?id=01pP0000000FrZQ

// Create NMC Tariffs

        Utility_NMC_Tariff__c everbillNMC = new Utility_NMC_Tariff__c (
                Name = 'Eversource SEMA Class 2', 
                Utility__c = 'Eversource', 
                Class__c = 'Class 2',
                Value_of_Net_Metering_Credit__c = 0.1848,
                Current_Billing_Rate__c = TRUE
                );
        system.debug(everbillNMC);

        Utility_NMC_Tariff__c eversizeNMC = new Utility_NMC_Tariff__c (
                Name = 'Eversource SEMA Class 2', 
                Utility__c = 'Eversource', 
                Class__c = 'Class 2',
                Value_of_Net_Metering_Credit__c = 0.1848,
                Sizing_Rate__c = TRUE
                );

        Utility_NMC_Tariff__c ngridbillNMC = new Utility_NMC_Tariff__c (
                Name = 'National Grid WCMA Class 2', 
                Utility__c = 'National Grid', 
                Class__c = 'Class 2',
                Value_of_Net_Metering_Credit__c = 0.1848,
                Current_Billing_Rate__c = TRUE
                );

        Utility_NMC_Tariff__c ngridsizeNMC = new Utility_NMC_Tariff__c (
                Name = 'National Grid WCMA Class 2', 
                Utility__c = 'National Grid', 
                Class__c = 'Class 2',
                Value_of_Net_Metering_Credit__c = 0.1848,
                Sizing_Rate__c = TRUE
                );

        Insert everbillNMC;
        Insert eversizeNMC;
        Insert ngridsizeNMC;
        Insert ngridbillNMC;
        
        system.debug(everbillNMC);


// Create Load Zones and Service Territories

        Load_U__c everLZU = new Load_U__c ( 
                Name = '02633', 
                Load_zone__c = 'SEMA Eversource', 
                LZ__c = 'SEMA', 
                Utility__C = 'Eversource', 
                Town__c= 'Medfield');

        Load_U__c ngridLZU = new Load_U__c ( 
                Name = '01570', 
                Load_zone__c= 'WCMA National Grid', 
                LZ__c = 'WCMA', 
                Utility__C = 'National Grid', 
                Town__c= 'Westtown');

        Insert everLZU;
        Insert ngridLZU;
        
        system.debug(ngridLZU);

// Create Shared Solar Systems 

        Shared_Solar_System__c sss1 = (Shared_Solar_System__c)TestFactory.createSObject(new Shared_Solar_System__c(Name = 'Oxford Barrett St. P1',
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
                                                                                                                                Maximum_Subscription_Assemblage__c = 25));

      //  insert sss1;

        Shared_Solar_System__c sss2 = (Shared_Solar_System__c)TestFactory.createSObject(new Shared_Solar_System__c(Name = 'Oxford Barrett St. P2',
                                                                                                                                Service_Territory__c = 'SEMA',
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
                                                                                                                                Maximum_Subscription_Assemblage__c = 25));
        Shared_Solar_System__c sss3 = (Shared_Solar_System__c)TestFactory.createSObject(new Shared_Solar_System__c(Name = 'Oxford Barrett St. P3',
                                                                                                                                Service_Territory__c = 'SEMA',
                                                                                                                                Open__c = true,
                                                                                                                                Reserved_Capacity_kW_DC__c = '0',
                                                                                                                                Capacity_Committed_kW_DC__c = 0,
                                                                                                                                Total_System_Size_kWh_DC__c = 1445.86,
                                                                                                                                Total_System_Size_kW_AC__c  = 996,
                                                                                                                                System_Utility__c = 'Eversource',
                                                                                                                                Credit_Score_Requirement__c = 200,
                                                                                                                                Assignment_order__c = '3',
                                                                                                                                Utility_NMC_Tariff__c = eversizeNMC.Id,
                                                                                                                                Expected_Yield_kWh_kW__c = 1300,
                                                                                                                                Assemblage_Count__c = 1,
                                                                                                                                Maximum_Subscription_Assemblage__c = 25));


        Shared_Solar_System__c sss4 = (Shared_Solar_System__c)TestFactory.createSObject(new Shared_Solar_System__c(Name = 'Oxford Barrett St. P4',
                                                                                                                                Service_Territory__c = 'WCMA',
                                                                                                                                Open__c = true,
                                                                                                                                Reserved_Capacity_kW_DC__c = '0',
                                                                                                                                Capacity_Committed_kW_DC__c = 0,
                                                                                                                                Total_System_Size_kWh_DC__c = 1445.86,
                                                                                                                                Total_System_Size_kW_AC__c  = 996,
                                                                                                                                System_Utility__c = 'National Grid',
                                                                                                                                Credit_Score_Requirement__c = 200,
                                                                                                                                Assignment_order__c = '1',
                                                                                                                                Utility_NMC_Tariff__c = ngridsizeNMC.Id,
                                                                                                                                Expected_Yield_kWh_kW__c = 1300,
                                                                                                                                Assemblage_Count__c = 1,
                                                                                                                                Maximum_Subscription_Assemblage__c = 25));
        insert new List<Shared_Solar_System__c>{sss1, sss2, sss3, sss4};

        System.debug('Verifying the SSS:');
        List <Shared_Solar_System__c> sssList = [SELECT Id,Capacity_Available_to_be_Reserved__c,Total_CS_Capacity_kW_DC_Formula__c,Anchor_CS_Capacity_Committed__c FROM Shared_Solar_System__c];
        for(Shared_Solar_System__c sss : sssList){
            System.debug(sss);
            System.debug(sss.Capacity_Available_to_be_Reserved__c);
            System.debug(sss.Total_CS_Capacity_kW_DC_Formula__c);
            System.debug(sss.Anchor_CS_Capacity_Committed__c);            
        }             

// Create Parent Accounts
         Id p = [select id from profile where name='Community Solar Community User'].id;
        Account accountA = new Account(name = 'Account A',
            RecordTypeId = '012j00000010Ha3');       
        Insert accountA;       
        system.debug(accountA);

        List <String> parentaccountIDs = new List<String>{ 
          'accountA.id'
        };
        Contact c = new Contact(FirstName='test', LastName ='testDashboard',AccountId = accountA.Id);
        insert c;  
                  
        User u = new User(alias = 'testDash', email='testdash@test.test', emailencodingkey='UTF-8', lastname='testDashboard', 
                          languagelocalekey='en_US', localesidkey='en_US', profileid = p, country='United States', 
                          IsActive =true, ContactId = c.Id, timezonesidkey='America/New_York', username='testdashboard@test.test');
        insert u;
// Create Leads
        Lead lead = (Lead)TestFactory.createSObject(new Lead(LastName = 'Chan',
                                                             FirstName = 'Joey',
                                                             Email = 'test@email.com',
                                                             Electricity_Provider__c = 'Eversource',
                                                             Utility_1__c = 'Eversource',
                                                             Load_Zone__c = 'SEMA',
                                                             Company = 'Cloud Jedi',
                                                             Status = 'Qualified',
                                                             Product_Line__c = 'Community Solar',
                                                             Parent_Account__c = accountA.Id,
                                                             System_Assignment__c = 'Automatic - Assignment Order'));
        insert lead;
        LASERCA__Personal_Credit_Report__c pcr = (LASERCA__Personal_Credit_Report__c)TestFactory.createSObject(new LASERCA__Personal_Credit_Report__c(
                                                                                        LASERCA__Lead__c = lead.Id,
                                                                                        LASERCA__Credit_Score_TransUnion__c = '700'), true);
        lead.Personal_Credit_Report__c = pcr.Id;
        lead.Status = 'Qualified';

        update lead;

        System.debug([Select Id, Open__c, Capacity_Available_to_be_Reserved__c, Service_Territory__c, System_Utility__c From Shared_Solar_System__c Where Id = :sss1.Id]);

        Utility_Account_Log__c ual = (Utility_Account_Log__c)TestFactory.createSObject(new Utility_Account_Log__c(Lead__c = lead.Id,
                                                                                                                  Annual_Cost_of_Electricity__c = 10000,
                                                                                                                  Name_on_Account__c = 'Joey Chan'));
        insert ual;

        Test.startTest();
        System.debug('Starting LeadTriggerHandlerTest');
        System.debug('Debug SSS - ' + [Select Id, Open__c, Capacity_Available_to_be_Reserved__c, Service_Territory__c, System_Utility__c From Shared_Solar_System__c Where Id = :sss1.Id ]);
        Database.leadConvert lc = new Database.leadConvert();
        lc.setLeadId(lead.id);
        System.debug(lc.getAccountId());
        LeadStatus convertStatus = [SELECT Id, MasterLabel FROM LeadStatus WHERE IsConverted=true LIMIT 1];
        lc.setConvertedStatus(convertStatus.MasterLabel);
        lc.setDoNotCreateOpportunity(true);
        Database.LeadConvertResult lcr = Database.convertLead(lc);
        System.assert(lcr.isSuccess());

 
        System.debug('Verifying the opportunity:');
        List <Opportunity> oppUpdatePendingList = new List<Opportunity>();       
        List <Opportunity> oppUpdateCompleteList = new List<Opportunity>();
        List <Opportunity> oppList = [SELECT Id, AccountId FROM Opportunity];
        for(Opportunity opp : oppList){
            opp.stageName = 'Pending BlueWave Signature';
            oppUpdatePendingList.add(opp);
            opp.stageName = 'Complete';
            oppUpdateCompleteList.add(opp);            
            System.debug(opp.AccountId);
        }
        update oppUpdatePendingList;
        update oppUpdateCompleteList;
        //System.assertEquals(1, oppList.size());
        

// Query for property accounts

      /*  List <string> listpropertyids = new list <string>();

          for(Account PR : [ SELECT Id
                             FROM Account
                             WHERE Parent_Account__c IN : parentaccountIDs]){ 

              listpropertyids.add(PR.id); 
                }

        system.debug(listpropertyids);*/

// Log Production Update - First Month

        Date myDateJan = Date.newInstance(2016, 1, 1);
        Date myDateFeb = Date.newInstance(2016, 2, 2);
        Date myDateMar = Date.newInstance(2016, 3, 3);
        Date myDateApr = Date.newInstance(2016, 4, 4);

        Energy_Usage_Update__c productionupdateA1 = new Energy_Usage_Update__c (
                Name = 'sssA - January 2016',
                Shared_Solar_System__c = sss1.id,
                Production__c = 90000,
                Date__c = myDateJan 
                );

  /*      Energy_Usage_Update__c productionupdateB1 = new Energy_Usage_Update__c (
                Name = 'sssB - January 2016',
                Shared_Solar_System__c = sss2.id,
                Production__c = 80000,
                Date__c = myDateJan 
                );

        Energy_Usage_Update__c productionupdateC1 = new Energy_Usage_Update__c (
                Name = 'sssC - January 2016',
                Shared_Solar_System__c = sss3.id,
                Production__c = 70000,
                Date__c = myDateJan 
                );*/

        Insert productionupdateA1;
      /*  Insert productionupdateB1;
        Insert productionupdateC1;*/

        system.debug(productionupdateA1);
        //system.debug(productionupdateB1);
       // system.debug(productionupdateC1);

// Insert on time payments in January Here 


                // Query for system bills that were created from the production update
                for(System_Bill__c systemBill : [SELECT Id, Name, Total_Due__c, Property_Account_ID__c FROM System_Bill__c]){
                          ChargentOrders__ChargentOrder__c orderA = new ChargentOrders__ChargentOrder__c (
                                ChargentOrders__Account__c = systemBill.Property_Account_Id__c,
                                ChargentOrders__Gateway__c = 'a1wP0000000JiZz',
                                ChargentOrders__Subtotal__c = systemBill.Total_Due__c,
                                ChargentOrders__Payment_Method__c = 'Credit Card',
                                System_Bill__c = systemBill.Id,
                                ChargentOrders__Card_Type__c = 'Visa',
                                ChargentOrders__Card_Number__c = '411111111111',
                                ChargentOrders__Card_Security_Code__c = '999',
                                ChargentOrders__Card_Expiration_Month__c = '02',
                                ChargentOrders__Card_Expiration_Year__c = '2018',
                                ChargentOrders__Card_Last_4__c = '1111'
                                );

                            ChargentOrders__Transaction__c transA = new ChargentOrders__Transaction__c(
                                    ChargentOrders__Order__c = orderA.id,
                                    ChargentOrders__Gateway__c = 'a1wP0000000JiZz',
                                    Activity_Type__c = 'Payment'
                                );

                           
                        System.debug(LoggingLevel.info, systemBill);      
                         }
                 
              

               /* List <System_Bill__c> ontimeSBs = new list <System_Bill__c>();

                for(System_Bill__c SB : [ SELECT Id, Property_Account_ID__c, Total_Due__c
                                          FROM System_Bill__c
                                          WHERE Property_Account_ID__c IN : listpropertyids AND Shared_Solar_System_ID__c = : sss1.id]){ 
                ontimeSBs.add(SB); 
                }

                system.debug('SystemBill List = ' + ontimeSBs);

                // Generate transactions on those system bills    
                integer j;
                for(j = 0; j < ontimeSBs.size(); j++){*/

 

// Production Update Month 2

        Energy_Usage_Update__c productionupdateA2 = new Energy_Usage_Update__c (
                Name = 'sssA - February 2016',
                Shared_Solar_System__c = sss1.id,
                Production__c = 90000,
                Date__c = myDateFeb
                );
                
        insert productionupdateA2;
/*
        Energy_Usage_Update__c productionupdateB2 = new Energy_Usage_Update__c (
                Name = 'sssB - February 2016',
                Shared_Solar_System__c = sss2.id,
                Production__c = 80000,
                Date__c = myDateFeb 
                );

        Energy_Usage_Update__c productionupdateC2 = new Energy_Usage_Update__c (
                Name = 'sssC - February 2016',
                Shared_Solar_System__c = sss3.id,
                Production__c = 90000,
                Date__c = myDateFeb 
                );

            Insert productionupdateA2;
            Insert productionupdateB2;
            Insert productionupdateC2;

// Insert on time payments in February Here


                // Query for system bills that were created from the production update
                List <System_Bill__c> secondmonthSBs = new list <System_Bill__c>();
                List <string> sssAandB = new list <string>{
                              'sssA.id',
                              'sssB.id' };



                for(System_Bill__c SB : [ SELECT Id, Property_Account_ID__c, Total_Due__c
                                          FROM System_Bill__c
                                          WHERE Property_Account_ID__c IN : listpropertyids AND Shared_Solar_System_ID__c IN : sssAandB]){ 

                secondmonthSBs.add(SB); 
                }

                // Generate transactions on those system bills    
                integer k;
                for(k = 0; k < secondmonthSBs.size(); k++){

                           ChargentOrders__ChargentOrder__c orderB = new ChargentOrders__ChargentOrder__c (
                                ChargentOrders__Account__c = secondmonthSBs.get(k).Property_Account_Id__c,
                                ChargentOrders__Gateway__c = 'a1wP0000000JiZz',
                                ChargentOrders__Subtotal__c = secondmonthSBs.get(k).Total_Due__c,
                                ChargentOrders__Payment_Method__c = 'Credit Card',
                                ChargentOrders__Card_Type__c = 'Visa',
                                ChargentOrders__Card_Number__c = '411111111111',
                                ChargentOrders__Card_Security_Code__c = '999',
                                ChargentOrders__Card_Expiration_Month__c = '02',
                                ChargentOrders__Card_Expiration_Year__c = '2018',
                                ChargentOrders__Card_Last_4__c = '1111'
                                );

                            ChargentOrders__Transaction__c transB = new ChargentOrders__Transaction__c(
                                    ChargentOrders__Order__c = orderB.id,
                                    ChargentOrders__Gateway__c = 'a1wP0000000JiZz',
                                    Activity_Type__c = 'Payment'
                                );
                                
                         }
// Following Months - some systems update, some do not

        Energy_Usage_Update__c productionupdateB3 = new Energy_Usage_Update__c (
                Name = 'sssC - March 2016',
                Shared_Solar_System__c = sss3.id,
                Production__c = 20000,
                Date__c = myDateMar 
                );

        Energy_Usage_Update__c productionupdateC3 = new Energy_Usage_Update__c (
                Name = 'sssC - March 2016',
                Shared_Solar_System__c = sss3.id,
                Production__c = 60000,
                Date__c = myDateMar 
                );

        Energy_Usage_Update__c productionupdateC4 = new Energy_Usage_Update__c (
                Name = 'sssC - April 2016',
                Shared_Solar_System__c = sss3.id,
                Production__c = 30000,
                Date__c = myDateApr 
                ); 


  //      Insert productionupdateB3;
  //      Insert productionupdateC3;
  //      Insert productionupdateC4;
*/


                        // Query for system bills that were created from the production update
                        /*List <System_Bill__c> allSBs = new list <System_Bill__c>();


                        for(System_Bill__c SB : [ SELECT Id, Property_Account_ID__c, Total_Due__c
                                                  FROM System_Bill__c
                                                  WHERE Property_Account_ID__c IN : listpropertyids]){ 

                        allSBs.add(SB); 
                        }

                        // Generate transactions on those system bills    
                        integer i;
                        for(i = 0; i < allSBs.size(); i++){

                                   ChargentOrders__ChargentOrder__c orderC = new ChargentOrders__ChargentOrder__c (
                                        ChargentOrders__Account__c = allSBs.get(j).Property_Account_Id__c,
                                        System_Bill__c = allSBs.get(j).Id,
                                        ChargentOrders__Gateway__c = 'a1wP0000000JiZz',
                                        ChargentOrders__Subtotal__c = 10,
                                        ChargentOrders__Payment_Method__c = 'Credit Card',
                                        ChargentOrders__Card_Type__c = 'Visa',
                                        ChargentOrders__Card_Number__c = '411111111111',
                                        ChargentOrders__Card_Security_Code__c = '999',
                                        ChargentOrders__Card_Expiration_Month__c = '02',
                                        ChargentOrders__Card_Expiration_Year__c = '2018',
                                        ChargentOrders__Card_Last_4__c = '1111'
                                        );

                                    ChargentOrders__Transaction__c transC = new ChargentOrders__Transaction__c(
                                            ChargentOrders__Order__c = orderC.id,
                                            ChargentOrders__Gateway__c = 'a1wP0000000JiZz',
                                            Activity_Type__c = 'Payment'
                                        );
                                        
                                 }*/
    


// Insert final payments






// Verify Values

/* From copied test class
test.startTest();
 
insert newLead;
 
test.stopTest();
 
lead leadQuery = [SELECT firstName, LZU__C FROM lead WHERE firstName = 'Cole'];
 
system.assertEquals('NEMA Eversource', leadQuery.LZU__C);
 
 */
 

}
}