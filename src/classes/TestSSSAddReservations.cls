@isTest
private class TestSSSAddReservations {

Static testMethod void SSSAddReservations(){

Utility_NMC_Tariff__c everbillNMC = new Utility_NMC_Tariff__c (
        Name = 'Eversource SEMA Class 2', 
        Utility__c = 'Eversource', 
        Class__c = 'Class 2',
        Value_of_Net_Metering_Credit__c = 0.1848,
        Current_Billing_Rate__c = TRUE
                );

insert everbillNMC;
system.debug(everbillNMC);

Account myAccount = new Account(name = 'Test Account');
insert myAccount;

LASERCA__Personal_Credit_Report__c pcr1 = new LASERCA__Personal_Credit_Report__c(
                                          LASERCA__Credit_Score_TransUnion__c = '700');
                                          
insert pcr1;

Date myDate = Date.newInstance(2015, 2, 17);

        Shared_Solar_System__c myProject = new Shared_Solar_System__c(Name = 'Oxford Barrett St. P1',
                                                                 Service_Territory__c = 'SEMA',
                                                                 Open__c = true,
                                                                 Reserved_Capacity_kW_DC__c = '0',
                                                                 Capacity_Committed_kW_DC__c = 0,
                                                                 Total_System_Size_kWh_DC__c = 1445.86,
                                                                 Total_System_Size_kW_AC__c  = 996,
                                                                 System_Utility__c = 'Eversource',
                                                                 Credit_Score_Requirement__c = 200,
                                                                 Assignment_order__c = '1',
                                                                 Expected_Yield_kWh_kW__c = 1300,
                                                                 Assemblage_Count__c = 1,
                                                                 Sales_Partners__c = 'All',
                                                                 Maximum_Subscription_Assemblage__c = 25);
                                                                 
       insert myProject;
                                                                 
Opportunity newOpportunity = new Opportunity(name = 'Cole', 
account = myAccount, 
project_assignment__c = 'Manual', 
type = 'New Business', 
stageName = 'Complete',
Product_line__c = 'Community Solar',
Customer_group__c = 'Residential',  
NMC_Tariff__c = everbillNMC.id,
Personal_Credit_Report2__c = pcr1.Id,
waitlist__c = FALSE, 
closeDate = myDate, 
shared_solar_system__c = myProject.id ); 

insert newOpportunity;

        Utility_Account_Log__c ual = new Utility_Account_Log__c(Account__c = myAccount.Id,
                                                                Annual_Cost_of_Electricity__c = 10000,
                                                                Name_on_Account__c = 'Joey Chan');
        insert ual;

        Utility_Account_Subscription__c uas = new Utility_Account_Subscription__c(Utility_Account_Log__c = ual.Id,
                                                                Name = '102342340',
                                                                Opportunity__c = newOpportunity.id,
                                                                Customer_Subscription_KW_DC_STATIC__c = 24,
                                                                Annual_Cost_of_Electricity__c = 1300);
        insert uas;

        system.debug(uas);

Opportunity newOpportunity3 = new Opportunity(name = 'Cole2', 
account = myAccount, 
project_assignment__c = 'Manual', 
type = 'New Business', 
stageName = 'Complete',
Product_line__c = 'Community Solar',
Customer_group__c = 'Anchor',  
Personal_Credit_Report2__c = pcr1.Id,
waitlist__c = FALSE, 
closeDate = myDate, 
CS_Capacity_Allocated__c = 22,
//CS_Capacity_Allocated__c = 100, 
shared_solar_system__c = myProject.id ); 

insert newOpportunity3;

     
/*
Opportunity newOpportunity2 = new Opportunity(name = 'Cole3', 
account = myAccount, 
project_assignment__c = 'Manual', 
type = 'New Business', 
stageName = 'Pending BlueWave Signature',
Product_line__c = 'Community Solar',
Customer_group__c = 'Residential', 
Personal_Credit_Report2__c = pcr1.Id,
waitlist__c = FALSE, 
closeDate = myDate, 
//CS_Capacity_Allocated__c = 100, 
shared_solar_system__c = myProject.id ); 

insert newOpportunity2;


        Utility_Account_Log__c ual3 = new Utility_Account_Log__c(Account__c = myAccount.Id,
                                                                Annual_Cost_of_Electricity__c = 10000,
                                                                Name_on_Account__c = 'Joey Chan');
        insert ual3;

        Utility_Account_Subscription__c uas3 = new Utility_Account_Subscription__c(Utility_Account_Log__c = ual3.Id,
                                                                Name = '012348932',
                                                                Opportunity__c = newOpportunity2.id,
                                                                Customer_Subscription_KW_DC_STATIC__c = 14,
                                                                Annual_Cost_of_Electricity__c = 1200);
        insert uas3;

        system.debug(uas3);
    */
update myProject;

List <Shared_Solar_System__c> ssslist = [SELECT Id, Capacity_Committed_kW_DC__c, Anchor_capacity_reserved__c, Reserved_capacity_kW_DC__c
                                        FROM Shared_Solar_System__c];

test.startTest();
for(Shared_Solar_System__c proj: ssslist){
        system.debug(myProject);

        system.debug(proj.Capacity_Committed_kW_DC__c);
        system.debug(proj.Reserved_capacity_kW_DC__c);
        system.debug(proj.Anchor_capacity_reserved__c);

        system.assert(proj.Capacity_Committed_kW_DC__c == 24);
        system.assert(proj.Reserved_capacity_kW_DC__c == '0');
        system.assert(proj.Anchor_capacity_reserved__c == 22);
}
test.stopTest();

 
}
}

/* OLD VERSION ****_________________
@isTest
private class TestSSSAddReservations {

Static testMethod void SSSAddReservations(){

Account myAccount = new Account(name = 'Test Account');
insert myAccount;

Date myDate = Date.newInstance(2015, 2, 17);
shared_solar_system__c myProject = new shared_solar_system__c(name = 'Tester');
insert myProject;

Opportunity newOpportunity = new Opportunity(name = 'Cole', 
account = myAccount, 
project_assignment__c = 'Manual', 
Shared_Solar_System_picklist__c = 'Tester', 
type = 'New Business', 
stageName = 'Complete',
Product_line__c = 'Community Solar',
Customer_group__c = 'Residential',  
waitlist__c = FALSE, 
closeDate = myDate, 
CS_Capacity_Allocated__c = 100, 
shared_solar_system__c = myProject.id ); 

Opportunity newOpportunity3 = new Opportunity(name = 'Cole2', 
account = myAccount, 
project_assignment__c = 'Manual', 
Shared_Solar_System_picklist__c = 'Tester', 
type = 'New Business', 
stageName = 'Complete',
Product_line__c = 'Community Solar',
Customer_group__c = 'Anchor',  
waitlist__c = FALSE, 
closeDate = myDate, 
CS_Capacity_Allocated__c = 100, 
shared_solar_system__c = myProject.id ); 

Opportunity newOpportunity2 = new Opportunity(name = 'Cole3', 
account = myAccount, 
project_assignment__c = 'Manual', 
Shared_Solar_System_picklist__c = 'Tester', 
type = 'New Business', 
stageName = 'Pending BlueWave Signature',
Product_line__c = 'Community Solar',
Customer_group__c = 'Residential', 
waitlist__c = FALSE, 
closeDate = myDate, 
CS_Capacity_Allocated__c = 100, 
shared_solar_system__c = myProject.id ); 

test.startTest();

insert newOpportunity;
insert newOpportunity2;
insert newOpportunity3;
update newOpportunity;
update newOpportunity2;
update newOpportunity3;

update myProject;


test.stopTest();

 
}
}
*/