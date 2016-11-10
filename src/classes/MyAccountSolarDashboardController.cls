public with sharing class MyAccountSolarDashboardController {
  
    public class DashboardResult {
      @AuraEnabled
      public Decimal myBill {get;set;}
      
      @AuraEnabled
      public Decimal mySavings {get;set;}
      
      @AuraEnabled
      public Decimal myConsumption {get;set;}
      
      @AuraEnabled
      public Decimal myProduction {get;set;}
    }
    

    @AuraEnabled
   public static Decimal getDashboardBill(string propertyAccountId) {
     system.debug(LoggingLevel.info, propertyAccountId);
     User u = [Select Id, ContactId, Parent_Account_ID__c from User where Id = :UserInfo.getUserId()];
     Map<Id, Decimal> maxBillMap = new Map<Id,Decimal>();
     decimal totalBalance = 0;   
     decimal maxBillNumberInteger;
     decimal totalDueSumInteger;     
     integer check = 0;  
      if(u.ContactId != null) {
        try {
          if(propertyAccountId == 'All' || propertyAccountId == null){
            check = 1;
            aggregateResult[] sbMax = [Select Shared_Solar_System__c, max(Bill_Number__c)maxBillNumber
                                      FROM System_Bill__c
                                      WHERE Account_Bill__r.Account_ID__c  = : u.Parent_Account_ID__c
                                      GROUP BY Shared_Solar_System__c];   
            system.debug(LoggingLevel.info, sbMax.get(0));                        
            for(AggregateResult ar : sbMax){
              maxBillMap.put((Id)ar.get('Shared_Solar_System__c'), (decimal)ar.get('maxBillNumber'));
              system.debug(LoggingLevel.info,(decimal)ar.get('maxBillNumber'));
            }
            for(System_Bill__c systemBills : [SELECT Balance_Net_Late_Payments__c, Carry_Over_Balance__c, Shared_Solar_System__r.Id,  Bill_Number__c, Name
                                              FROM System_Bill__c 
                                              WHERE Account_Bill__r.Account_ID__c = : u.Parent_Account_ID__c ]){
                                              system.debug(LoggingLevel.info,systemBills.Name);           
                                              if(maxBillMap.get(systemBills.Shared_Solar_System__r.Id) == systemBills.Bill_Number__c){
                                                  totalBalance = totalBalance + (decimal)systemBills.Carry_Over_Balance__c;
                                              }
            }
            system.debug(loggingLevel.info, totalBalance);
          }
          else{
          check = 2;
            Account propertyAccountBalance = [Select Id, Total_Outstanding_Balance__c
                                from Account 
                                where Id = : propertyAccountId];
            system.debug(logginglevel.info, propertyAccountBalance.Total_Outstanding_Balance__c);
            system.debug(logginglevel.info, propertyAccountId);   
            system.debug(logginglevel.info, propertyAccountBalance.Id);                                                   
            if(propertyAccountBalance.Total_Outstanding_Balance__c != null){
                totalBalance = propertyAccountBalance.Total_Outstanding_Balance__c;
            }
          }
        system.debug(loggingLevel.info,check);                 
        }    
        catch(Exception ex) {         
        }
      }
      system.debug(LoggingLevel.info, totalBalance);
      return totalBalance;   
   }

 
 @AuraEnabled
    public static Decimal getDashboardSavings(string propertyAccountId) {
      User u = [Select Id, ContactId, Parent_Account_ID__c from User where Id = :UserInfo.getUserId()];
      decimal totalSavings = 0;
      integer check;
      if(u.ContactId != null){
        try {
          if(propertyAccountId == 'All' || propertyAccountId == null){          
            check = 1;
            aggregateResult savingsAR = [SELECT sum(Net_Metering_Credits_Allocated__c)Savings
                                        FROM Account_Bill__c
                                        WHERE Account_ID__c = : u.Parent_Account_ID__c ];
          totalSavings = (decimal)savingsAR.get('savings') * 0.10;  
          system.debug(loggingLevel.info, totalSavings);
          }
          else{
            aggregateResult savingsARprop = [SELECT sum(Net_Metering_Credits_Allocated__c)SavingsProp
                                        FROM Account_Bill__c
                                        WHERE Parent_Account__r.Id = : propertyAccountId  ];
            totalSavings = (decimal)savingsARprop.get('SavingsProp') * 0.10;  
            system.debug(loggingLevel.info, totalSavings);
          }
        }
        catch(Exception ex){
        }
      }
      return totalSavings;                                 
    }    
                                  
 @AuraEnabled
    public static Decimal getDashboardProduction(string propertyAccountId) {
      User u = [Select Id, ContactId, Parent_Account_ID__c from User where Id = :UserInfo.getUserId()];
      decimal totalProduction;
      integer check;
      if(u.ContactId != null){
        try {
          if(propertyAccountId == 'All' || propertyAccountId == null){                
            check = 1;
            aggregateResult personalProduction = [SELECT sum(Subscription_Production_kWh__c)totalProduction
                                                  FROM UASB__c
                                                  WHERE System_Bill__r.Account_Bill__r.Account_ID__c = : u.Parent_Account_ID__c ];
          totalProduction = (decimal)personalProduction.get('totalProduction');  
          system.debug(loggingLevel.info, totalProduction);
          }
          else{
            aggregateResult personalPropertyProduction = [SELECT sum(Subscription_Production_kWh__c)totalPropertyProduction
                                        FROM UASB__c
                                        WHERE System_Bill__r.Account_Bill__r.Parent_Account__r.Id = : propertyAccountId  ];
            totalProduction = (decimal)personalPropertyProduction.get('totalPropertyProduction') ;  
            system.debug(loggingLevel.info, totalProduction);
          }          
        }
        catch(Exception ex){
        }
      }
      return totalProduction;                                 
    }    
               

 @AuraEnabled
    public static List<Account> getMenuLabelList() {
    list<Account> propertyAccountLabelList = new list<Account>();
    User u = [Select Id, ContactId, Parent_account_id__c from User where Id = :UserInfo.getUserId()];
    system.debug(LoggingLevel.info, u.Parent_account_id__c);    
    system.debug(LoggingLevel.info, u.Id);   
    for(Account propertyAccount : [SELECT Id, name, Parent_Account_ID__c FROM Account WHERE Parent_Account_ID__c = : u.Parent_Account_ID__c]){
        system.debug(LoggingLevel.info, propertyAccount.Parent_Account_ID__c);
        propertyAccountLabelList.add(propertyAccount);
    }    
    system.debug(LoggingLevel.info, propertyAccountLabelList);
    return propertyAccountLabelList;
    }     
    @AuraEnabled
   public static Decimal getMyBill(string propertyAccountId) {
     system.debug(LoggingLevel.info, propertyAccountId);
     User u = [Select Id, ContactId, Parent_Account_ID__c from User where Id = :UserInfo.getUserId()];
     decimal totalBalance;   
     decimal maxBillNumberInteger;
     decimal totalDueSumInteger;     
     integer check = 0;  
      if(u.ContactId != null) {
        try {
          if(propertyAccountId == 'All' || propertyAccountId == null){
            check = 1;
            aggregateResult sbMax = [Select max(Bill_Number__c)maxBillNumber
                                from System_Bill__c
                                where Account_Bill__r.Account_ID__c  = : u.Parent_Account_ID__c  ];   
                                   maxBillNumberInteger = (decimal)sbMax.get('maxBillNumber');
                                   system.debug(loggingLevel.info,maxBillNumberInteger);        
            aggregateResult ab = [Select sum(Carry_Over_Balance__c)totalDueSum
                                from System_Bill__c
                                where Account_Bill__r.Account_ID__c = : u.Parent_Account_ID__c 
                                and Bill_number__c = : maxBillNumberInteger];
                                   totalDueSumInteger= (decimal)ab.get('totalDueSum');
                                   system.debug(loggingLevel.info,totalDueSumInteger);                                     
            if(totalDueSumInteger != null){
              totalBalance = totalDueSumInteger;
            }
          }
          else{
          check = 2;
            Account propertyAccountBalance = [Select Total_Outstanding_Balance__c
                                from Account 
                                where Id = : propertyAccountId];            
            if(propertyAccountBalance.Total_Outstanding_Balance__c != null){
                totalBalance = propertyAccountBalance.Total_Outstanding_Balance__c;
            }
          }
        system.debug(loggingLevel.info,check);                 
        }    
        catch(Exception ex) {         
        }
      }
      system.debug(LoggingLevel.info, totalBalance);
      return totalBalance;   
   }
          

/*
    @AuraEnabled
    public static DashboardResult getDashboardInfo() {
      DashboardResult dr = new DashboardResult();
      User u = [Select Id, ContactId from User where Id = :UserInfo.getUserId()];
      if(u.ContactId != null) {
        try {
          Product_Profile__c pp = [Select Id, My_Current_Balance__c from Product_Profile__c where Contact__c = :u.ContactId and Profile_Type__c = 'Community Solar'];
          if(pp.My_Current_Balance__c != null)
            dr.myBill = pp.My_Current_Balance__c;
          try {
             Energy_Usage_Update__c euu = [Select Id, Production__c from Energy_Usage_Update__c where Product_Profile__c = :pp.Id order by Date__c desc limit 1];
             if(euu.Production__c != null)
               dr.myProduction = euu.Production__c;
          } 
          catch (Exception productionEx) {
            
          }
          try {
             Consumption_Update__c cu = [Select Id, Energy_Consumption__c from Consumption_Update__c where Product_Profile__c = :pp.Id order by Date__c desc limit 1];
             if(cu.Energy_Consumption__c != null)
               dr.myConsumption = cu.Energy_Consumption__c;
          } 
          catch (Exception consumptionEx) {
            
          }
          
          Decimal savings = 0;
          try {
            AggregateResult ar = [Select sum(My_Savings__c) sav from  Consumption_Update__c where Product_Profile__c = :pp.Id];
            savings = (Decimal) ar.get('sav');
          }
          catch(Exception savingsEx) {
            
          }
          dr.mySavings = savings;
        }
        catch(Exception ex) {
          
        }
        
      }
      return dr;
    }
    */


}