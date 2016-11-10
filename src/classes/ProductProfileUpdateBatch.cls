/*
    Developed by Joey Chan (Cloud Jedi) - joey.chan@cloudjedi.com
    ProductProfileUpdateBatch is a scheduled batch script that runs at the third day of the month at 12am. 
    The script aggregates the data from Utility_Account_Bill__c and Consumption_Update__c into the Product_Profile__c of the corresponding contact

    Mappings:
    Product_Profile__c.My_Current_Balance__c  - (Utility_Account_Bill__c.Discounted_Bill__c )
    Product_Profile__c.Production_kWh__c - (Utility_Account_Bill__c.Subscription_Production__c)
    Product_Profile__c.Savings__c (Utility_Account_Bill__c. Savings__c)
    Product_Profile__c.Energy_Consumption__c - (Consumption_Update__c.Energy_Consumption__c)

*/
global class ProductProfileUpdateBatch implements Database.Batchable<sObject>, Schedulable{
    public void execute(SchedulableContext sc){
        String query = 'Select Id, AccountId, (Select Id From Product_Profiles__r) From Contact Where Active_Communities_User__c = true ';
        ProductProfileUpdateBatch batch = new ProductProfileUpdateBatch();
        batch.query = query;
        batch.runDate = Date.today();
        Database.executeBatch(batch, 200);
    }

    public String query {get; set;}
    public Date runDate {get; set;}

    global ProductProfileUpdateBatch() {}

    global Database.QueryLocator start(Database.BatchableContext BC){
        return Database.getQueryLocator(query);
    }
    global void execute(Database.BatchableContext BC, List<Contact> contactList){

        //Get the month and year of "last month"
        Integer calendarMonth = runDate.addMonths(-1).month();
        Integer calendarYear = runDate.addMonths(-1).year();
        
        //Generate a map of the Account and the Product Profile
        Map<Id, Product_Profile__c> accToProductProfileMap = new Map<Id, Product_Profile__c>();
        for(Contact con : contactList){
            if(con.Product_Profiles__r.size() > 0){
                accToProductProfileMap.put(con.AccountId, con.Product_Profiles__r[0]);
            }
        }

        //Aggregate the data from the Utility_Account_Bill__c
        for (AggregateResult ar : [Select Utility_Account_Log__r.Account__r.Parent_Account__c accountId, 
                                          SUM(Discounted_Bill__c) discountedBill, 
                                          SUM(Subscription_Production__c) subscriptionProduction, 
                                          SUM(Savings__c) savings
                                   From Utility_Account_Bill__c 
                                   Where Utility_Account_Log__r.Account__r.Parent_Account__c IN :accToProductProfileMap.keySet()
                                   AND CALENDAR_MONTH(Date__c) = :calendarMonth
                                   AND CALENDAR_YEAR(Date__c) = :calendarYear
                                   Group By Utility_Account_Log__r.Account__r.Parent_Account__c]){
            String accountId =  (String)ar.get('accountId');
            Decimal discountedBill =  (Decimal)ar.get('discountedBill');
            Decimal subscriptionProduction =  (Decimal)ar.get('subscriptionProduction');
            Decimal savings =  (Decimal)ar.get('savings');

            System.debug('Utility_Account_Bill__c '  + ar);
            if(accToProductProfileMap.containsKey(accountId)){
                Product_Profile__c pp = accToProductProfileMap.get(accountId);
                pp.My_Current_Balance__c = discountedBill;
                pp.Production_kWh__c = subscriptionProduction;
                pp.Savings__c = savings;
                pp.Month__c = String.valueOf(calendarMonth);
                pp.Year__c = String.valueOf(calendarYear);
            }
        }

        //Get the Shared Solar System lookup:
        //Contact > Parent Account > Property Account Where Opportunity Oldest 
        for(Opportunity opp : [Select Account.Parent_Account__c, Shared_Solar_System__c 
                               From Opportunity 
                               Where Account.Parent_Account__c IN :accToProductProfileMap.keySet()
                               AND Shared_Solar_System__c  != null
                               Order by CreatedDate DESC
                               Limit 1]){

            if(accToProductProfileMap.containsKey(opp.Account.Parent_Account__c)){
                Product_Profile__c pp = accToProductProfileMap.get(opp.Account.Parent_Account__c);
                pp.Shared_Solar_System__c = opp.Shared_Solar_System__c;
            }
        }

        //Aggregate the data from the Consumption_Update__c
        for (AggregateResult ar : [Select Utility_Account_Log__r.Account__r.Parent_Account__c accountId, 
                                          SUM(Energy_Consumption__c) energyConsumption
                                   From Consumption_Update__c 
                                   Where Utility_Account_Log__r.Account__r.Parent_Account__c IN :accToProductProfileMap.keySet()
                                   AND CALENDAR_MONTH(Date__c) = :calendarMonth
                                   AND CALENDAR_YEAR(Date__c) = :calendarYear
                                   Group By Utility_Account_Log__r.Account__r.Parent_Account__c]){
            System.debug('Utility_Account_Log__c '  + ar);
            String accountId =  (String)ar.get('accountId');
            Decimal energyConsumption =  (Decimal)ar.get('energyConsumption');
            if(accToProductProfileMap.containsKey(accountId)){
                Product_Profile__c pp = accToProductProfileMap.get(accountId);
                pp.Energy_Consumption__c = energyConsumption;
            }
        }

        // Debug log of the records to update
        for(Product_Profile__c pp : accToProductProfileMap.values()){
            System.debug('Updating - ' + pp);
        }
        if(accToProductProfileMap.size() > 0) update accToProductProfileMap.values();
    }
    global void finish(Database.BatchableContext bc) {
    }


}