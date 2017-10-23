@isTest
private class ProductProfileUpdateBatchTest {
    
    //This code also touches the unit tests for EnergyUsageUpdateTriggerHandler and UtilityAccountBillTriggerHandler
    @isTest static void testBatchScript() {

        Date lastMonth = Date.today().addMonths(-1);
        Date myDateJan = Date.newInstance(2016, 1, 1);

        Lead lead = (Lead)TestFactory.createSObject(new Lead(LastName = 'Chan',
                                                             Email = 'test@email.com',
                                                             Electricity_Provider__c = 'Meralco',
                                                             Company = 'Cloud Jedi'));
        insert lead;
        
        insert new BW_Address__c(Name = 'BlueWave', Address_Line_One__c = '137 Newbury Street', Address_Line_Two__c = 'Boston, MA 02114');

        Utility_NMC_Tariff__c nmcRate =  (Utility_NMC_Tariff__c)TestFactory.createSObject(new Utility_NMC_Tariff__c(Value_of_Net_Metering_Credit__c = 1,
                                                                                                                    Name = 'Meralco Territory Class 2',
                                                                                                                    Sizing_Rate__c = false,
                                                                                                                    Current_Billing_Rate__c = true,
                                                                                                                    Date__c = lastMonth));
        insert nmcRate;

        Account parentAccount = (Account)TestFactory.createSObject(new Account(), 'TestFactory.AccountDefaults', true);

        Contact con = (Contact)TestFactory.createSObject(new Contact(AccountId = parentAccount.Id, Active_Communities_User__c = true), 'TestFactory.ContactDefaults', true);

        Account propertyAcc = (Account)TestFactory.createSObject(new Account(Parent_Account__c = parentAccount.Id), 'TestFactory.AccountDefaults', true);

        Shared_Solar_System__c sharedSolarSystem = (Shared_Solar_System__c)TestFactory.createSObject(new Shared_Solar_System__c(Name = 'Oxford Barrett St. P2',
                                                                                                                                Service_Territory__c = 'Territory'), true);

        Opportunity opp = (Opportunity)TestFactory.createSObject(new Opportunity(AccountId = propertyAcc.Id,
                                                                                 Shared_Solar_System__c = sharedSolarSystem.Id), 'TestFactory.OpportunityDefaults', true);


        Product_Profile__c pp = (Product_Profile__c)TestFactory.createSObject(new Product_Profile__c(Contact__c = con.Id));
        insert pp;

        Account_Bill__c ab = (Account_Bill__c)TestFactory.createSObject(new Account_Bill__c(Parent_Account__c = parentAccount.Id,
                                                                                            Product_Profile__c = pp.Id,
                                                                                            Date__c = lastMonth,
                                                                                            Unique_Id__c = 'testIdforAccountBill'));

        insert ab;

        Utility_Account_Log__c ual = (Utility_Account_Log__c)TestFactory.createSObject(new Utility_Account_Log__c(Account__c = propertyAcc.Id,
                                                                                                                  Lead__c = lead.Id));
        insert ual;
        
        Utility_Account_Bill__c uab = (Utility_Account_Bill__c)TestFactory.createSObject(new Utility_Account_Bill__c(Date__c = lastMonth,
                                                                                                            Utility_Account_Log__c = ual.Id,
                                                                                                            Account_Bill__c = ab.Id));
        insert uab;


        Utility_Account_Subscription__c uas =(Utility_Account_Subscription__c)TestFactory.createSObject(new Utility_Account_Subscription__c(
                                                                                                            Utility_Account_Log__c = ual.Id,
                                                                                                            Opportunity__c = opp.Id));
        insert uas;
        
        System_Bill__c sb = new System_Bill__c(Name = opp.Name + ' ' + sharedSolarSystem.Name + ' ' + myDateJan.Month() + ' ' + myDateJan.Year(),                                                           
                                        Shared_Solar_System__c = sharedSolarSystem .Id,
                                        Account_Bill__c = ab.Id,
                                        Date__c =  myDateJan,
                                        Bill_Number__c = 1,
                                        Due_this_month__c = 100,
                                        Previous_month_overdue_balance__c = 0,
                                        Total_due__c = 100,
                                        Balance_net_late_payments__c = 100,
                                        Carry_over_balance__c = 100,
                                        Property_Account__c = propertyAcc.Id);
        sb.Unique_Id__c = opp.Name + ' ' + sharedSolarSystem.Name + ' ' + DateTime.newInstance(myDateJan.year(), myDateJan.month(),myDateJan.day()).format('yyyy-MM');
        insert sb;        


        UASB__c uasb1 = (UASB__c)TestFactory.createSObject(new UASB__c( CS_Billing_Log__c = uab.Id,
                                                                        Date__c = lastMonth,
                                                                        system_bill__c = sb.Id,
                                                                        Customer_Subscription_KW_DC__c = 100,
                                                                        Total_System_Size_kW_DC__c = 1000,
                                                                        NMC_Rate__c = 10,
                                                                        Total_System_Production_kWh__c = 1000));

        insert uasb1;

        Consumption_Update__c cu = (Consumption_Update__c)TestFactory.createSObject(new Consumption_Update__c(Energy_Consumption__c = 5,
                                                                                                              Date__c = lastMonth,
                                                                                                              External_System_ID__c = '00001',
                                                                                                              Utility_Account_Log__c = ual.Id));
        insert cu;


        Energy_Usage_Update__c euu = (Energy_Usage_Update__c)TestFactory.createSObject(new Energy_Usage_Update__c(Date__c = lastMonth,
                                                                                                                  Shared_Solar_System__c = sharedSolarSystem.Id));
        insert euu;


        Test.startTest();
        String sch = '0 0 * * * ?';
        String jobId = System.schedule('TestProductProfileUpdateBatch', sch, new ProductProfileUpdateBatch());

        String query = 'Select Id, AccountId, (Select Id From Product_Profiles__r) From Contact';
        ProductProfileUpdateBatch batch = new ProductProfileUpdateBatch();
        batch.query = query;
        batch.runDate = Date.today();
        Database.executeBatch(batch, 200);

        Test.stopTest();
        Product_Profile__c verifyPP = [Select Id, My_Current_Balance__c, Production_kWh__c, Savings__c, Month__c, Year__c, Energy_Consumption__c 
                                       From Product_Profile__c Where Id = :pp.Id];
        System.debug(verifyPP);

        System.assertEquals(900, verifyPP.My_Current_Balance__c);
        System.assertEquals(100, verifyPP.Production_kWh__c);
        System.assertEquals(100, verifyPP.Savings__c);
        System.assertEquals(String.valueOf(lastMonth.month()), verifyPP.Month__c);
        System.assertEquals(String.valueOf(lastMonth.year()), verifyPP.Year__c);
        System.assertEquals(5, verifyPP.Energy_Consumption__c);
    }
}