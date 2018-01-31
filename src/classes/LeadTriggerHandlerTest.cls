@isTest
private class LeadTriggerHandlerTest {
    
    @isTest static void customerSubscriptionProcessTest() {

        Utility_NMC_Tariff__c nmcRate =  (Utility_NMC_Tariff__c)TestFactory.createSObject(new Utility_NMC_Tariff__c(Value_of_Net_Metering_Credit__c = 1,
                                                                                                                    Name = 'Nation Grid WCMA Class 2 - S/F 2016',
                                                                                                                    Sizing_Rate__c = true,
                                                                                                                    Date__c = Date.today()));
        insert nmcRate;

        Shared_Solar_System__c sss1 = (Shared_Solar_System__c)TestFactory.createSObject(new Shared_Solar_System__c(Name = 'Oxford Barrett St. P1',
                                                                                                                                Service_Territories__c = 'WCMA; SEMA',
                                                                                                                                Open__c = true,
                                                                                                                                Reserved_Capacity_kW_DC__c = '0',
                                                                                                                                Capacity_Committed_kW_DC__c = 0,
                                                                                                                                Total_System_Size_kWh_DC__c = 1445.86,
                                                                                                                                Total_System_Size_kW_AC__c  = 996,
                                                                                                                                System_Utility__c = 'National Grid',
                                                                                                                                Credit_Score_Requirement__c = 200,
                                                                                                                                Assignment_order__c = '1',
                                                                                                                                Utility_NMC_Tariff__c = nmcRate.Id,
                                                                                                                                Expected_Yield_kWh_kW__c = 1300,
                                                                                                                                Assemblage_Count__c = 1,  
                                                                                                                                Maximum_Subscription_Assemblage__c = 25));

        
        sss1.Sales_Partners__c = 'Barbara Cerullo; Boston Solar'; 
        insert sss1;
        
     
        //Shared_Solar_System__c sss2 = (Shared_Solar_System__c)TestFactory.createSObject(new Shared_Solar_System__c(Name = 'Oxford Barrett St. P2',
        //                                                                                                                        Service_Territories__c = 'WCMA',
        //                                                                                                                        Open__c = true,
        //                                                                                                                        Reserved_Capacity_kW_DC__c = '100',
        //                                                                                                                        Capacity_Committed_kW_DC__c = 100,
        //                                                                                                                        Total_System_Size_kWh_DC__c = 100,
        //                                                                                                                        System_Utility__c = 'National Grid',
        //                                                                                                                        Credit_Score_Requirement__c = 200,
        //                                                                                                                        Assignment_order__c = '2'));
        //Shared_Solar_System__c sss3 = (Shared_Solar_System__c)TestFactory.createSObject(new Shared_Solar_System__c(Name = 'Oxford Barrett St. P3',
        //                                                                                                                        Service_Territories__c = 'WCMA',
        //                                                                                                                        Open__c = true,
        //                                                                                                                        Reserved_Capacity_kW_DC__c = '100',
        //                                                                                                                        Capacity_Committed_kW_DC__c = 100,
        //                                                                                                                        Total_System_Size_kWh_DC__c = 100,
        //                                                                                                                        System_Utility__c = 'National Grid',
        //                                                                                                                        Credit_Score_Requirement__c = 200,
        //                                                                                                                        Assignment_order__c = '3'));


        //Shared_Solar_System__c sss4 = (Shared_Solar_System__c)TestFactory.createSObject(new Shared_Solar_System__c(Name = 'Oxford Barrett St. P4',
        //                                                                                                                        Service_Territories__c = 'WCMA',
        //                                                                                                                        Open__c = true,
        //                                                                                                                        Reserved_Capacity_kW_DC__c = '100',
        //                                                                                                                        Capacity_Committed_kW_DC__c = 100,
        //                                                                                                                        Total_System_Size_kWh_DC__c = 100,
        //                                                                                                                        System_Utility__c = 'National Grid',
        //                                                                                                                        Credit_Score_Requirement__c = 200,
        //                                                                                                                        Assignment_order__c = '4'));
        //insert new List<Shared_Solar_System__c>{sss1, sss2, sss3, sss4};

        system.debug(sss1.Capacity_Available_to_be_Reserved__c);
        system.debug(sss1);      
        
        Partner__c Partner = new Partner__c(Name = 'Boston Solar');
        insert Partner;
        
        BSST__c newSalesTeam = new BSST__c (Name = 'Partner',
                                            Partner__c = Partner.Id,
                                            Custom_ID__c = 'partner');
                                            
        insert newSalesTeam;
        
        Lead lead = (Lead)TestFactory.createSObject(new Lead(LastName = 'Chan',
                                                             FirstName = 'Joey',
                                                             Email = 'test@email.com',
                                                             Electricity_Provider__c = 'National Grid',
                                                             Utility_1__c = 'National Grid',
                                                             Load_Zone__c = 'WCMA',
                                                             Company = 'Cloud Jedi',
                                                             Status = 'Qualified',
                                                             Product_Line__c = 'Community Solar',
                                                             Custom_ID__c = 'partner',
                                                             System_Assignment__c = 'Automatic - Assignment Order'));
        insert lead;
        
        Lead lead2 = new Lead (LastName = 'Jordan',
                                     FirstName = 'Pentaleri',
                                     Email = 'test@email.com',
                                     Electricity_Provider__c = 'National Grid',
                                     Utility_1__c = 'National Grid',
                                     Load_Zone__c = 'WCMA',
                                     Company = 'Cloud Jedi',
                                     Status = 'Qualified',
                                     Product_Line__c = 'Community Solar',
                                     System_Assignment__c = 'Automatic - Assignment Order');
        insert lead2;

        LASERCA__Personal_Credit_Report__c pcr = (LASERCA__Personal_Credit_Report__c)TestFactory.createSObject(new LASERCA__Personal_Credit_Report__c(
                                                                                        LASERCA__Lead__c = lead.Id,
                                                                                        LASERCA__Credit_Score_TransUnion__c = '700'), true);
                                                                                        
        LASERCA__Personal_Credit_Report__c pcr2 = (LASERCA__Personal_Credit_Report__c)TestFactory.createSObject(new LASERCA__Personal_Credit_Report__c(
                                                                                        LASERCA__Lead__c = lead2.Id,
                                                                                       LASERCA__Credit_Score_TransUnion__c = '700'), true);
        lead.Personal_Credit_Report__c = pcr.Id;
        lead2.Personal_Credit_Report__c = pcr2.Id;
        lead.Status = 'Qualified';
        lead2.Status = 'Qualified';
        update lead;

        System.debug([Select Id, Open__c, Capacity_Available_to_be_Reserved__c, Service_Territories__c, System_Utility__c From Shared_Solar_System__c Where Id = :sss1.Id]);


        Utility_Account_Log__c ual = (Utility_Account_Log__c)TestFactory.createSObject(new Utility_Account_Log__c(Lead__c = lead.Id,
                                                                                                                  Annual_Cost_of_Electricity__c = 10000,
                                                                                                                  Name_on_Account__c = 'Joey Chan'));
        insert ual;
        
        Utility_Account_Log__c ual2 = new Utility_Account_Log__c(Lead__c = lead2.Id,
                                                                 Annual_Cost_of_Electricity__c = 10000,
                                                                 Name_on_Account__c = 'Joey Chan');
        insert ual2;


        Test.startTest();
        System.debug('Starting LeadTriggerHandlerTest');
        System.debug('Debug SSS - ' + [Select Id, Open__c, Capacity_Available_to_be_Reserved__c, Service_Territories__c, System_Utility__c From Shared_Solar_System__c Where Id = :sss1.Id ]);
        Database.leadConvert lc = new Database.leadConvert();
        lc.setLeadId(lead.id);
        LeadStatus convertStatus = [SELECT Id, MasterLabel FROM LeadStatus WHERE IsConverted=true LIMIT 1];
        lc.setConvertedStatus(convertStatus.MasterLabel);
        lc.setDoNotCreateOpportunity(true);
        Database.LeadConvertResult lcr = Database.convertLead(lc);
        System.assert(lcr.isSuccess());
        
        Database.leadConvert ld = new Database.leadConvert();
        ld.setLeadId(lead2.id);
        LeadStatus convertStatus2 = [SELECT Id, MasterLabel FROM LeadStatus WHERE IsConverted=true LIMIT 1];
        ld.setConvertedStatus(convertStatus2.MasterLabel);
        ld.setDoNotCreateOpportunity(true);
        Database.LeadConvertResult ldr = Database.convertLead(ld);
       
        System.debug('Verifying the opportunity:');
        List<Opportunity> oppList = [Select Id, Name, AccountId, Shared_Solar_System__c, Shared_Solar_System__r.Name From Opportunity ];
        for(Opportunity opp : oppList){
            System.debug(opp);
        }
        System.assertEquals(1, oppList.size());
        Test.stopTest();
    }
}