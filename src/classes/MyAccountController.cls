public with sharing class MyAccountController {
 @AuraEnabled
    public static List<Account> getMenuLabelList() {
    list<Account> propertyAccountLabelList = new list<Account>();
    User u = [Select Id, ContactId, Parent_account_id__c, Contact.Account.Id  from User where Id = :UserInfo.getUserId()];
    String userAccountId = (string)u.Contact.Account.Id;    
    system.debug(LoggingLevel.info, u.Parent_account_id__c);    
    system.debug(LoggingLevel.info, u.Id);   
    for(Account propertyAccount : [SELECT Id, name, Parent_Account_ID__c FROM Account WHERE Parent_Account_ID__c = : u.Parent_account_id__c]){
        system.debug(LoggingLevel.info, propertyAccount.Parent_Account_ID__c);
        propertyAccountLabelList.add(propertyAccount);
    }    
    system.debug(LoggingLevel.info, propertyAccountLabelList);
    return propertyAccountLabelList;
    }
    
  @AuraEnabled
   public static string getMenuAccountBillItem(string menuInput) {
      system.debug(menuInput);
      return menuInput+ ' ' + ' has been selected';
  } 
    @AuraEnabled
   public static string getPropertyAccountId(string propertyAccountId) {
      system.debug(propertyAccountId);
      return propertyAccountId;
  }       
    @AuraEnabled
   public static Decimal getMyBill(string propertyAccountId) {
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
    public static List<System_Bill__c> getSystemBills(string propertyAccountId) {
      system.debug(loggingLevel.info,propertyAccountId);
      User u = [Select Id, ContactId, Parent_Account_ID__c, Contact.Account.Id from User where Id = :UserInfo.getUserId()]; 
      String userAccountId = (string)u.Contact.Account.Id;    
      List<System_Bill__c> systemBillList = new List<System_Bill__c>();
      Map<Id, Decimal> maxBillMap = new Map<Id,Decimal>(); 
      decimal systemBillNumber;
      decimal maxBillNumberDecimal;
      decimal totalDue;
      decimal totalBalance = 0;     
      integer check = 0;      
      if(propertyAccountId == 'All' || propertyAccountId == null){
        check = 1;
        /**aggregateResult sbMax= [Select  max(Bill_Number__c)maxBillNumber
                                                FROM System_Bill__c    
                                                WHERE Account_Bill__r.Account_ID__c  = : u.Parent_Account_Id__c];   
        for(System_Bill__c systemBills : [SELECT Id, Total_Due__c, Shared_Solar_System__r.Name, Carry_Over_Balance__c, Shared_Solar_System__r.Id,  Bill_Number__c, Name
                                          FROM System_Bill__c WHERE Bill_Number__c = : maxBillNumberDecimal 
                                          AND Account_Bill__r.Account_ID__c  = : u.Parent_Account_Id__c
                                          ]){                                                    
                                                  systemBillList.add(systemBills);
                                                  system.debug(LoggingLevel.info, 'System Bills are ' + systemBills.Name);
                                                  system.debug(LoggingLevel.info, 'System Billing Number is ' + systemBills.Bill_Number__c);                                                  
          }       */
        aggregateResult[] sbMax= [Select Shared_Solar_System__c, max(Bill_Number__c)maxBillNumber
                                                FROM System_Bill__c                                         
                                                WHERE Account_Bill__r.Account_Id__c   = : u.Parent_account_id__c
                                                GROUP BY Shared_Solar_System__c];          
        for(AggregateResult ar : sbMax){
          maxBillMap.put((Id)ar.get('Shared_Solar_System__c'), (decimal)ar.get('maxBillNumber'));
          system.debug(LoggingLevel.info,(decimal)ar.get('maxBillNumber'));
        }

        for(System_Bill__c systemBills : [SELECT Id, Total_Due__c, Shared_Solar_System__r.Name, Carry_Over_Balance__c, Shared_Solar_System__r.Id,  Bill_Number__c, Name, FormAssembly_Order_Helper__c, Form_ID_Helper__c
                                          FROM System_Bill__c 
                                          WHERE Account_Bill__r.Account_ID__c = : u.Parent_account_id__c]){
                                              system.debug(LoggingLevel.info,systemBills.Name);           
                                              if(maxBillMap.get(systemBills.Shared_Solar_System__r.Id) == systemBills.Bill_Number__c){
                                                  systemBillList.add(systemBills);
                                                  system.debug(LoggingLevel.info, 'System Bills are ' + systemBills.Name);
                                                  system.debug(LoggingLevel.info, 'System Billing Number is ' + systemBills.Bill_Number__c);                                                  
                                                  }
          }
        }

      /*
      The following code will be used in an update and is necessary to show the most recent system bills on the payment form.
      if(propertyAccountId == 'All' || propertyAccountId == null){
        check = 1;
        for(System_Bill__c sb : [SELECT Id, Name, Bill_Number__c, Shared_Solar_System__r.Id, Shared_Solar_System__c FROM System_Bill__c WHERE Account_Bill__r.Account_ID__c = : u.Parent_Account_ID__c]){
            systemBills.add(sb);
            systemBillsMap.put(sb.Id, sb);
          }    
        system.debug(LoggingLevel.info, 'SystemBills List is : ' + systemBills);   
        for(Shared_Solar_System__c sssMax : [SELECT Id, Name FROM Shared_Solar_System__c]){
          for(j=0;j<systemBills.size();j++){
            if(systemBills.get(j).Shared_Solar_System__c == sssMax.Id){
              maxBillListGroupedbySSS.add(systemBills.get(j));
            }
          }
         
          for(c=0;c<maxBillListGroupedbySSS.size();c++){
            if(maxBillListGroupedbySSS.get(i).Bill_Number__c > billMaximum){
              system.debug(LoggingLevel.info, 'Begin running through the Grouped SSS list');  
              system.debug(LoggingLevel.info, 'The ' + i + '  record is' + maxBillListGroupedbySSS.get(i));                  
              system.debug(LoggingLevel.info, 'The Bill Max before is' + billMaximum);
              system.debug(LoggingLevel.info, 'The Bill Id before is' + billId);                 
              billMaximum = maxBillListGroupedbySSS.get(i).Bill_Number__c;
              system.debug(LoggingLevel.info, 'The Bill Max after is' + billMaximum); 
              system.debug(LoggingLevel.info, 'The Bill Id after is' + billId);                             
              billId = maxBillListGroupedbySSS.get(i).Id;             
            }
          }
          systemBillList.add(systemBillsMap.get(billId));
          billMaximum = 0;
          billId = null; 
          maxBillListGroupedbySSS.clear();
        }
        }*/ 



      else{
        aggregateResult[] sbMax = [Select Shared_Solar_System__c, max(Bill_Number__c)maxBillNumber
                                                FROM System_Bill__c
                                                WHERE Account_Bill__r.Parent_Account__r.Id = : propertyAccountId 
                                                GROUP BY Shared_Solar_System__c];  
        for(AggregateResult ar : sbMax){
          maxBillMap.put((Id)ar.get('Shared_Solar_System__c'), (decimal)ar.get('maxBillNumber'));
          system.debug(LoggingLevel.info,(decimal)ar.get('maxBillNumber'));
        }
        for(System_Bill__c systemBills : [SELECT Id, Total_Due__c, Shared_Solar_System__r.Name, Carry_Over_Balance__c, Shared_Solar_System__r.Id,  Bill_Number__c, Name, FormAssembly_Order_Helper__c, Form_ID_Helper__c
                                          FROM System_Bill__c 
                                          WHERE Account_Bill__r.Parent_Account__r.Id = : propertyAccountId]){
                                              system.debug(LoggingLevel.info,systemBills.Name);           
                                              if(maxBillMap.get(systemBills.Shared_Solar_System__c) == systemBills.Bill_Number__c){
                                                  systemBillList.add(systemBills);
                                                  system.debug(LoggingLevel.info, 'System Bills are ' + systemBills.Name);
                                                  system.debug(LoggingLevel.info, 'System Billing Number is ' + systemBills.Bill_Number__c);                                                    
                                                  }
        }
      }  
      return systemBillList;  
    }  


//The following method is written because the lightning component attribute systemBills will not take System_Bill__c as a type. Therefore there must be two attributes and the object can't be stored.
    /*@AuraEnabled
    public static List<Id> getSystemBillsIds (string propertyAccountId) {
      system.debug(loggingLevel.info,propertyAccountId);
      User u = [Select Id, ContactId, Parent_Account_ID__c from User where Id = :UserInfo.getUserId()];
      List<Id> systemBillIdList = new List<Id>();
      decimal systemBillNumber;
      decimal totalDue;
      integer check = 0;      
      if(propertyAccountId == 'All' || propertyAccountId == null){
        check = 1;
        aggregateResult maxSystemBillNumber = [SELECT max(Bill_number__c)maxSystemBillNumberVar FROM System_Bill__c where Account_Bill__r.Account_ID__c = : u.Parent_Account_ID__c];   
        systemBillNumber = (decimal)maxSystemBillNumber.get('maxSystemBillNumberVar');
        system.debug(LoggingLevel.info, systemBillNumber);
        for(System_bill__c systemBill : [select Id, Total_Due__c, Shared_solar_system__r.Name  
             from System_Bill__c
             where Account_Bill__r.Account_ID__c = : u.Parent_Account_ID__c
             and Bill_number__c = : systemBillNumber 
             order by Shared_solar_system__r.Name DESC]){
                 systemBillIdList.add(systemBill.Id);
                 system.debug(LoggingLevel.info, systemBillIdList);
        }
      }         
      else{
        aggregateResult maxSystemBillNumber = [SELECT max(Bill_number__c)maxSystemBillNumberVar FROM System_Bill__c where Account_Bill__r.Parent_Account__r.Id = : propertyAccountId];   
        systemBillNumber = (decimal)maxSystemBillNumber.get('maxSystemBillNumberVar');
        system.debug(LoggingLevel.info, systemBillNumber);
        for(System_bill__c systemBill : [select Id, Total_Due__c, Shared_solar_system__r.Name  
             from System_Bill__c
             where Account_Bill__r.Parent_Account__r.Id  = : propertyAccountId
             and Bill_number__c = : systemBillNumber 
             order by Shared_solar_system__r.Name DESC]){
                systemBillIdList.add(systemBill.Id);
                system.debug(LoggingLevel.info, systemBillIdList);                 
      }
    }
    return systemBillIdList;        
    } 

 @AuraEnabled
   public static Id getMyAccountBillId() {
     User u = [Select Id, ContactId from User where Id = :UserInfo.getUserId()];
     id myAccountBill;
     date currentDate = date.today();
     integer month = currentDate.month();
     integer yearInt = currentDate.year();
     string year = string.valueOf(yearInt);
      if(u.ContactId != null) {
        try {
          Account_Bill__c ab = [Select Id, Month__c
                                from Account_Bill__c 
                                where Product_Profile__r.Contact__r.Id  = : u.ContactId and Month__c = : month AND Year__c = : year];
          if(ab.Id != null)
            myAccountBill = ab.Id;           
        }
        catch(Exception ex) {         
        }
      }
      return myAccountBill;   
   }
   */
     @AuraEnabled
   public static Id getMyParentAccountId(String propertyAccountId) {
    if(propertyAccountId == 'All' || propertyAccountId == null){
      User u = [Select Id, ContactId, contact.AccountId from User where Id = :UserInfo.getUserId()];
      id myParentAccountId;
      if(u.ContactId != null) {
        try {
          Account abP = [Select Id
                                from Account
                                where Id  = : u.Contact.AccountId];
          if(abP.Id != null)
            myParentAccountId = abP.Id;           
        }
        catch(Exception ex) {
          system.debug('There was an error');
        }
      }
      return myParentAccountId;   
    }
    else{
      return propertyAccountId;
    }
  }

    
/*
     @AuraEnabled
   public static date getMyPaymentDueDate() {
     User u = [Select Id, ContactId from User where Id = :UserInfo.getUserId()];
     date paymentDueDate;
     date currentDate = date.today();
     integer month = currentDate.month();
     integer yearInt = currentDate.year();
     string year = string.valueOf(yearInt);
      if(u.ContactId != null) {
        try {
          Account_Bill__c ab1 = [Select Id, Month__c, Payment_Due_Date__c
                                from Account_Bill__c 
                                where Product_Profile__r.Contact__r.Id  = : u.ContactId and Month__c = : month AND Year__c = : year];
          if(ab1.Id != null)
            paymentDueDate = ab1.Payment_Due_Date__c;
        }
        catch(Exception ex) {         
        }
      }
      return paymentDueDate;   
   }
    @AuraEnabled
   public static decimal getMySavings() {
     User u = [Select Id, ContactId from User where Id = :UserInfo.getUserId()];
     decimal savings;
     date currentDate = date.today();
     integer month = currentDate.month();
     integer yearInt = currentDate.year();
     string year = string.valueOf(yearInt);     
      if(u.ContactId != null) {
        try {
          Account_Bill__c ab2 = [Select Id, Month__c, Savings__c
                                from Account_Bill__c 
                                where Product_Profile__r.Contact__r.Id  = : u.ContactId and Month__c = : month AND Year__c = : year];
          if(ab2.Savings__c != null)
            savings = ab2.Savings__c;
        }
        catch(Exception ex) {         
        }
      }
      return savings;   
   }*/
  @AuraEnabled
  public static List<Account_Bill__c> getAccountBills (string propertyAccountId) {
    system.debug(loggingLevel.info, propertyAccountId);
    User u = [Select Id, ContactId, Parent_Account_ID__c from User where Id = :UserInfo.getUserId()];
    List<Account_Bill__c> accountBillList = new List<Account_Bill__c>();
    integer check = 0;
    if(propertyAccountId == 'All' || propertyAccountId == null){
      check = 1;
      for(Account_Bill__c accountBillAll : [SELECT Parent_Account__r.Name, Date__c, Activity_Type__c, Due_this_month__c, 
                                                  Total_Due_This_Month__c, Total_Due__c, Carry_Over_Balance__c, Bill_number__c,
                                                  Balance_Net_Late_Payments__c, Date_of_Last_Payment__c, Bill_Due_Date__c, Total_due_minus_payment_plan__c
                                            FROM Account_Bill__c
                                            WHERE Account_ID__c = : u.Parent_Account_ID__c
                                            ORDER BY Bill_Number__c DESC]){
        accountBillList.add(accountBillAll);
      }
      system.debug(accountBillList);    
    }
    else{
      check = 2;
      for(Account_Bill__c accountBillProperty : [SELECT Parent_Account__r.Name, Date__c, Activity_Type__c, Due_this_month__c, Total_Due_This_Month__c, Total_due_minus_payment_plan__c, Total_Due__c, Bill_Due_Date__c, Carry_Over_Balance__c, Bill_number__c, Balance_Net_Late_Payments__c
                                            FROM Account_Bill__c
                                            WHERE Parent_Account__r.Id = : propertyAccountId
                                            ORDER BY Bill_Number__c DESC]){
        accountBillList.add(accountBillProperty);
      }
      system.debug(accountBillList);
    }
    system.debug(loggingLevel.info,check);
    return accountBillList;
  }

  @AuraEnabled
  public static List<ChargentOrders__Transaction__c > getTransactions (string propertyAccountId) {
    system.debug(loggingLevel.info, propertyAccountId);
    User u = [Select Id, ContactId, Parent_Account_ID__c from User where Id = :UserInfo.getUserId()];
    List<ChargentOrders__Transaction__c> chargentTransactionsList = new List<ChargentOrders__Transaction__c>();
    integer check = 0;
    if(propertyAccountId == 'All' || propertyAccountId == null){
      check = 1;
      for(ChargentOrders__Transaction__c chargentTransactionsAll : [SELECT ChargentOrders__Type__c, Activity_Type__c, Negative_Amount__c, ChargentOrders__Order__r.System_Bill__r.Account_Bill__r.Parent_Account__r.Name, ChargentOrders__Gateway_Date__c, Date_of_transaction__c,
                                                                           ChargentOrders__Amount__c, System_Bill_Remaining_Balance__c, ChargentOrders__Order__r.System_Bill__r.Shared_Solar_System__r.Name 
                                                                    FROM ChargentOrders__Transaction__c
                                                                    WHERE ChargentOrders__Order__r.System_Bill__r.Account_Bill__r.Account_ID__c = : u.Parent_Account_ID__c
                                                                    ORDER BY  ChargentOrders__Order__r.System_Bill__r.Account_Bill__r.Bill_Number__c DESC]){
        
        chargentTransactionsList.add(chargentTransactionsAll);
      }
      system.debug(chargentTransactionsList);    
    }
    else{
      check = 2;
      for(ChargentOrders__Transaction__c chargentTransactionsProperty : [SELECT ChargentOrders__Type__c, Activity_Type__c,Negative_Amount__c, ChargentOrders__Order__r.System_Bill__r.Account_Bill__r.Parent_Account__r.Name, ChargentOrders__Gateway_Date__c, Date_of_transaction__c,
                                                                           ChargentOrders__Amount__c, System_Bill_Remaining_Balance__c, ChargentOrders__Order__r.System_Bill__r.Shared_Solar_System__r.Name 
                                                                         FROM ChargentOrders__Transaction__c
                                                                         WHERE ChargentOrders__Order__r.System_Bill__r.Account_Bill__r.Parent_Account__r.Id = : propertyAccountId
                                                                         ORDER BY  ChargentOrders__Order__r.System_Bill__r.Account_Bill__r.Bill_Number__c DESC]){
        chargentTransactionsList.add(chargentTransactionsProperty);
      }
      system.debug(chargentTransactionsList);
    }
    system.debug(loggingLevel.info,check);
    return chargentTransactionsList;
  }  

   /*  @AuraEnabled
   public static decimal getMyPaymentAmount() {
     User u = [Select Id, ContactId from User where Id = :UserInfo.getUserId()];
     decimal paymentAmount;
     date currentDate = date.today();
     integer month = currentDate.month();
     integer yearInt = currentDate.year();
     string year = string.valueOf(yearInt);     
      if(u.ContactId != null) {
        try {
          Account_Bill__c ab3 = [Select Id, Month__c, Payment_Amount__c
                                from Account_Bill__c 
                                where Product_Profile__r.Contact__r.Id  = : u.ContactId and Month__c = : month AND Year__c = : year];
          if(ab3.Payment_Amount__c != null)
            paymentAmount = ab3.Payment_Amount__c;
        }
        catch(Exception ex) {         
        }
      }
      return paymentAmount;   
   }
   
     @AuraEnabled
   public static decimal getMyDueThisMonth() {
     User u = [Select Id, ContactId from User where Id = :UserInfo.getUserId()];
     decimal myDueThisMonth;
     date currentDate = date.today();
     integer month = currentDate.month();
     integer yearInt = currentDate.year();
     string year = string.valueOf(yearInt);     
      if(u.ContactId != null) {
        try {
          Account_Bill__c ab5 = [Select Id, Month__c, Total_Due_This_Month__c
                                from Account_Bill__c 
                                where Product_Profile__r.Contact__r.Id  = : u.ContactId and Month__c = : month AND Year__c = : year];
          if(ab5.Total_Due_This_Month__c != null)
            myDueThisMonth = ab5.Total_Due_This_Month__c;
        }
        catch(Exception ex) {         
        }
      }
      return myDueThisMonth;   
   }
     
     @AuraEnabled
   public static decimal getMyPreviousOverdueBalance() {
     User u = [Select Id, ContactId from User where Id = :UserInfo.getUserId()];
     decimal previousOverdueBalance;
     date currentDate = date.today();
     integer month = currentDate.month();
     integer yearInt = currentDate.year();
     string year = string.valueOf(yearInt);     
      if(u.ContactId != null) {
        try {
          Account_Bill__c ab6 = [Select Id, Month__c, Previous_Month_Overdue_Balance__c
                                from Account_Bill__c 
                                where Product_Profile__r.Contact__r.Id  = : u.ContactId and Month__c = : month AND Year__c = : year];
          if(ab6.Previous_Month_Overdue_Balance__c != null)
            previousOverdueBalance = ab6.Previous_Month_Overdue_Balance__c;
        }
        catch(Exception ex) {         
        }
      }
      return previousOverdueBalance;   
   }       
/*
     @AuraEnabled
   public static date getDateofLastPayment() {
     User u = [Select Id, ContactId from User where Id = :UserInfo.getUserId()];
     date dateOfLastPayment;
     date currentDate = date.today();
     integer month = currentDate.month();
     integer yearInt = currentDate.year();
     string year = string.valueOf(yearInt);     
      if(u.ContactId != null) {
        try {
          Account_Bill__c ab7 = [Select Id, Month__c, Date_of_Last_Payment__c
                                from Account_Bill__c 
                                where Product_Profile__r.Contact__r.Id  = : u.ContactId and Month__c = : month AND Year__c = : year];
          if(ab7.Date_of_Last_Payment__c != null)
            dateOfLastPayment = ab7.Date_of_Last_Payment__c;
        }
        catch(Exception ex) {         
        }
      }
      return dateOfLastPayment;   
   }   
   //this is the end of the code developed by Cole Swain - colemswain@gmail.com*/
   @AuraEnabled
   public static String getCode() {
     User u = [Select Id, ContactId from User where Id = :UserInfo.getUserId()];
     String code;
      if(u.ContactId != null) {
        try {
          code = [Select Id, Referral_Code__c from Contact where Id = :u.ContactId].Referral_Code__c;
        }
        catch(Exception ex) {
          
        }
      }
      return code;
   }  
  /*  @AuraEnabled
public Map<Id,Attachment> getStatementMap(){
  Map<Id, Attachment> attachmentMap = new Map<Id, Attachment>();
  User u = [Select Id, ContactId, contact.AccountId from User where Id = :UserInfo.getUserId()];
    if(u.ContactId != null) {
        for(Attachment a : [SELECT Id, Name, ParentId FROM Attachment]){
            attachmentMap.put(a.ParentId, a);
        }
    }
    return attachmentMap;
}*/
    @AuraEnabled
public static String getStatement(String parentId){
  system.debug(Logginglevel.info, parentId);
  String attachmentId;
  User u = [Select Id, ContactId, contact.AccountId from User where Id = :UserInfo.getUserId()];
    if(u.ContactId != null) {
        Attachment a = [select Id, Name from Attachment 
            where ParentId =: parentId LIMIT 1 ];
    attachmentId = a.Id;
            
    }
    return attachmentId;
}
   @AuraEnabled
   public static String sendEmail(String emailAddress) {
     try {
       EmailTemplate et = [Select Id from EmailTemplate where DeveloperName = 'Community_Referral_email'];
       User u = [Select Id, ContactId from User where Id = :UserInfo.getUserId()];
       Messaging.SingleEmailMessage sem = new Messaging.SingleEmailMessage();
       sem.setTemplateId(et.Id);
       sem.setTargetObjectId(u.ContactId);
       sem.setTreatTargetObjectAsRecipient(false);
       sem.setToAddresses(new String[] { emailAddress});
       Messaging.SendEmailResult[] results = Messaging.sendEmail(new Messaging.SingleEmailMessage[] {sem});
       if(results != null && results[0].isSuccess()) {
         return 'success';
       }
       if(results[0] != null)
         return results[0].getErrors()[0].getMessage();
       return 'There was an error sending the email.';
     }
     catch(Exception ex) {
       return ex.getMessage();
     }
   } 
}