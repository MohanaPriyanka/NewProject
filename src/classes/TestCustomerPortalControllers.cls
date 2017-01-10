@isTest
private class TestCustomerPortalControllers {

Static testMethod void TestCustomerPortalControllers(){

/*

---------------------------------------REPLACED BY COMMUNITYSOLARCUSTOMERPORTALTEST ------------------------------------------------------------------------------


Utility_NMC_Tariff__c everbillNMC = new Utility_NMC_Tariff__c (
    Name = 'Eversource SEMA Class 2', 
    Load_Zone__c = 'SEMA',
    Utility__c = 'Eversource', 
    Class__c = 'Class 2',
    Value_of_Net_Metering_Credit__c = 0.1848,
    Current_Billing_Rate__c = TRUE);
    
    Insert everbillNMC;

Utility_NMC_Tariff__c everSizeNMC = new Utility_NMC_Tariff__c (
    Name = 'Eversource SEMA Class 2',
    Load_Zone__c = 'SEMA',     
    Utility__c = 'Eversource', 
    Class__c = 'Class 2',
    Value_of_Net_Metering_Credit__c = 0.1848,
    Sizing_Rate__c = TRUE);
    
    Insert eversizeNMC;

Load_U__c everLZU = new Load_U__c ( 
    Name = '02633', 
    Load_zone__c = 'SEMA Eversource', 
    LZ__c = 'SEMA', 
    Utility__C = 'Eversource', 
    Town__c= 'Medfield');

    Insert everLZU;

Shared_Solar_System__c sss1 = new Shared_Solar_System__c(Name = 'Oxford Barrett St. FR-2',
                              Service_Territory__c = 'SEMA',
                              Open__c = true,
                              Auto_Payment_Form__c = true,
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
                              Maximum_Subscription_Assemblage__c = 25);
insert new List<Shared_Solar_System__c>{sss1};

//Energy_Usage_Update__c pu = new Energy_Usage_Update__c(Date__c = Date.today(), Production__c = 2, Shared_Solar_System__c = sss1.Id);
//insert pu; 


Id p = [select id from profile where name='Community Solar Community User'].id;

Account accountA = new Account(name = 'Account A', RecordTypeId = '012j00000010Ha3', Product_Line__c ='Community Solar'); 
insert accountA;

List <String> parentaccountIDs = new List<String>{ 
    'accountA.id'
};



Contact c = new Contact(FirstName='test', LastName ='testDashboard', Account = accountA, AccountId = accountA.Id);
insert c;

User u = new User(alias = 'testDash', email='testdash@test.test', emailencodingkey='UTF-8', lastname='testDashboard', 
                  languagelocalekey='en_US', localesidkey='en_US', profileid = p, country='United States', 
                  IsActive =true, Contact = c, ContactId = c.Id, timezonesidkey='America/New_York', username='testdashboard@test.test');
insert u;
System.runAs(u){
System.debug('USER ID IS ' + u.Contact.Account_Id__c);
Account propertyAccountA = new Account(Name = 'Property Account A', Product_Line__c = 'Community Solar', 
                                        Parent_Account__c = accountA.Id);
insert propertyAccountA;
Utility_Account_Log__c ual = new Utility_Account_Log__c(Name = '00X1ACS',
                                                        Annual_Cost_of_Electricity__c = 10000,
                                                        Name_on_Account__c = 'Joey Chan',
                                                        Account__c = propertyAccountA.Id);
insert ual; 
Date myCloseDate = Date.newInstance(2016, 1, 1);

Opportunity opp = new Opportunity(Name = 'Cole Swain',
                                    AccountId = propertyAccountA.Id, 
                                    Shared_Solar_System__c = sss1.Id, 
                                    StageName = 'Complete',
                                    CloseDate = myCloseDate,
                                    NMC_Tariff__c = everSizeNMC.Id,
                                    Customer_Group__c = 'Residential',
                                    Annual_Electricity_Cost2__c = 6000,
                                    Annual_Electricity_Cost__c = 6000,
                                    CS_Capacity_Allocated__c = 25);
insert opp;
opp.StageName = 'Complete';
update opp;                                 

Utility_Account_Subscription__c uas = new Utility_Account_Subscription__c(Name = 'Testcase', Utility_Account_Log__c = ual.Id,
                                                                                                    Annual_Cost_of_Electricity__c = 10000,
                                                                                                    Opportunity__c = opp.Id,
                                                                                                    Uas_number__c = 1,
                                                                                                    Calculated_annual_cost_of_electricity__c = 6000,
                                                                                                    Subscribed_Annual_Cost_of_Electricity__c = 6000
                                                                                                    );
insert uas;

system.debug(Logginglevel.info,'UAS Insertion ' + uas);

Date myDateJan = Date.newInstance(2016, 1, 1);

Account_Bill__c ab = new Account_Bill__c(Name = propertyAccountA.Name + ' ' + myDateJan.month() + ' ' + myDateJan.year(), 
                                        Date__c =  myDateJan,
                                        Parent_Account__c = propertyAccountA.Id,
                                        Bill_Number__c = 1);                                                         
ab.Unique_Id__c = uas.Opportunity__r.Account.Id + ' ' + DateTime.newInstance(myDateJan.year(), myDateJan.month(),myDateJan.day()).format('yyyy-MM');
insert ab;

String abStringId = string.valueOf(ab.Id);
String abSubStringId = abStringId.subString(0,15);

Blob bodyBlob = Blob.valueOf('Test Attachment');
Attachment attach = new Attachment();
attach.Name = 'Test Attachment'; 
attach.Body = bodyBlob; 
attach.ParentId = ab.Id;
Insert attach;
System.debug('Attachment debug');
System.debug(attach.Id);
System.debug(attach.ParentId);
System.debug(ab.Id);

System_Bill__c sb = new System_Bill__c(Name = opp.Name + ' ' + sss1.Name + ' ' + myDateJan.Month() + ' ' + myDateJan.Year(),                                                           
                                        Shared_Solar_System__c = sss1.Id,
                                        Account_Bill__c = ab.Id,
                                        Date__c =  myDateJan,
                                        Unique_Id__c = opp.Name + ' ' + sss1.Name + ' ' + DateTime.newInstance(myDateJan.year(), myDateJan.month(),myDateJan.day()).format('yyyy-MM'),
                                        Bill_Number__c = 1,
                                        Opportunity__c = opp.Id,
                                        Due_this_month__c = 100,
                                        Previous_month_overdue_balance__c = 0,
                                        Total_due__c = 100,
                                        Balance_net_late_payments__c = 100,
                                        Carry_over_balance__c = 100,
                                        Property_Account__c = propertyAccountA.Id);

//sb.Unique_Id__c = opp.Name + ' ' + sss1.Name + ' ' + DateTime.newInstance(myDateJan.year(), myDateJan.month(),myDateJan.day()).format('yyyy-MM');
insert sb;
System.debug('sb account id' + ' ' + ab.Account_ID__c);
System.debug('userId' + ' ' + u.Parent_Account_ID__c);

system.debug(Logginglevel.info,'System Bill Insertion ' + sb);


Utility_Account_Bill__c uab = new Utility_Account_Bill__c(Name = uas.Opportunity__r.Name + ' ' + myDateJan.month() + ' ' + myDateJan.year() + ' ' + uas.Name,
                                                            //Production_Update__c = productionUpdate.Id,
                                                            Shared_Solar_System__c = sss1.Id,
                                                            Date__c = myDateJan,
                                                            Utility_Account_Log__c = uas.Utility_Account_Log__c,
                                                            Bill_Number__c = 1,
                                                            Passcheck__c = true,
                                                            Account_Bill__c = ab.Id);
uab.Unique_Id__c = uas.Utility_Account_Log__c + ' - ' + DateTime.newInstance(myDateJan.year(), myDateJan.month(),myDateJan.day()).format('yyyy-MM');
insert uab;


system.debug(Logginglevel.info,'UAB Insertion ' + uab);

UASB__c uasb = new UASB__c( Name = uas.Name + uas.Opportunity__r.Shared_Solar_System__r.Name,
                            Customer_Subscription_KW_DC__c = uas.Customer_Subscription_KW_DC__c,
                            CS_Billing_Log__c = uab.Id, 
                            Date__c = uab.Date__c,
                            //Production_Update__c = uab.Production_Update__c44,
                            Utility_Account_Subscription__c = uas.Id,  
                            Opportunity__c = uas.Opportunity__c,
                            System_Bill__c = sb.Id,
                            Shared_Solar_System__c = uas.Opportunity__r.Shared_Solar_System__c,
                            Total_System_Size_kW_DC__c = uas.Opportunity__r.shared_solar_system__r.Total_System_Size_kWh_DC__c,
                            NMC_Rate__c = everbillNMC.Value_of_Net_Metering_Credit__c,
                            Total_System_Production_kWh__c = uab.Production_kWh_DC__c);
uasb.Unique_Id__c = uas.Opportunity__r.Shared_Solar_System__c + ' - ' + uas.Id + ' - ' + DateTime.newInstance(uab.Date__c.year(), uab.Date__c.month(),uab.Date__c.day()).format('yyyy-MM');
insert uasb;

MyAccountController.getStatement(ab.Id);

Test.startTest();
        MyAccountController.getMenuLabelList();
        MyAccountController.getPaymentFormCheck();
        MyAccountController.getPropertyAccountId(propertyAccountA.Id);
        MyAccountController.getMyParentAccountId('All');
        MyAccountController.getMyBill('All');       
        MyAccountController.getMyBill(String.valueOf(propertyAccountA.Id).substring(0, 15));
        MyAccountController.getSystemBills('All');
        MyAccountController.getSystemBills(String.valueOf(propertyAccountA.Id).substring(0, 15));                  
        MyAccountController.getAccountBills('All');
        MyAccountController.getAccountBills(String.valueOf(propertyAccountA.Id).substring(0, 15));       
        MyAccountController.getTransactions('All');
        MyAccountController.getTransactions(String.valueOf(propertyAccountA.Id).substring(0, 15));
        MyAccountSolarDashboardController.getDashboardBill('All');
        MyAccountSolarDashboardController.getDashboardBill(String.valueOf(propertyAccountA.Id).substring(0, 15));
        MyAccountSolarDashboardController.getDashboardSavings('All');
        MyAccountSolarDashboardController.getDashboardSavings(String.valueOf(propertyAccountA.Id).substring(0, 15));
        MyAccountSolarDashboardController.getDashboardProduction('All');
        MyAccountSolarDashboardController.getDashboardProduction(String.valueOf(propertyAccountA.Id).substring(0, 15)); 
        MyAccountSolarDashboardController.getMenuLabelList();
        MyAccountSolarDashboardController.getMyBill('All');        
        MyAccountSolarDashboardController.getMyBill(String.valueOf(propertyAccountA.Id).substring(0, 15));         
        UsageChartController.getTenYears();
        UsageChartController.getFiveYears();
        UsageChartController.getOneYear();
        UsageChartController.getSixMonths();
        UsageChartController.getOneMonth();
        UsageChartController.getOneDay();
        UsageChartController.getAll();                                               
        MyAccountController.getCode();                                 
        MyAccountController.sendEmail('test@test.test');                     
Test.stopTest(); 
}

sss1.Auto_Payment_Form__c = false;
update sss1;

system.runAs(u){
   MyAccountController.getPaymentFormCheck(); 
}*/
}
}