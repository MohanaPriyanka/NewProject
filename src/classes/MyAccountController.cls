public without sharing class MyAccountController {
 @AuraEnabled
    public static List<Account> getMenuLabelList() {
    list<Account> propertyAccountLabelList = new list<Account>();
    User u = [SELECT Id, ContactId, Parent_account_id__c, Contact.Account.Id, Contact.AccountId  FROM User WHERE Id = :UserInfo.getUserId()];
    System.debug('The user is ' + u.Parent_account_id__c);
    String userAccountId = (string)u.Contact.Account.Id;      
    for(Account propertyAccount : [SELECT Id, Name, Parent_Account_ID__c, Total_Outstanding_Balance__c FROM Account WHERE Parent_Account__c = : u.Contact.AccountId]){
        System.debug('The returned propertyAccount is ' + propertyAccount);
        propertyAccountLabelList.add(propertyAccount);
    }    
    return propertyAccountLabelList;
    }

@AuraEnabled
  public static boolean getPaymentFormCheck () {
    List<Opportunity> nonChargentFormList = new List<Opportunity>();
    List<Opportunity> chargentFormList = new List<Opportunity>();

    User u = [SELECT Id, ContactId, Parent_Account_ID__c FROM User WHERE Id = :UserInfo.getUserId()];
   
    for (Shared_Solar_System__c sss : [SELECT Id, Name, Auto_Payment_Form__c, 
                                        (SELECT Id, Name, Account.Parent_Account__r.Id, Account.Parent_Account__c
                                        FROM Opportunities__r WHERE stageName = 'Complete' 
                                        AND Account.Parent_Account__c = : u.Parent_Account_ID__c )
                                      FROM Shared_Solar_System__c]){     
      System.debug(LoggingLevel.info, sss.Opportunities__r.size());
      for (Opportunity opp : sss.Opportunities__r){
        System.debug(Logginglevel.info, 'The Opp Account ID is ' + ' ' + String.valueOf(opp.Account.Parent_Account__r.Id).substring(0,15));
        System.debug(Logginglevel.info, 'The user account ID is ' + ' ' + u.Parent_Account_ID__c);

        //if (String.valueOf(opp.Account.Parent_Account__r.Id).substring(0,15) == u.Parent_Account_ID__c){
          if (sss.Auto_Payment_Form__c == true){
            nonChargentFormList.add(opp);
          } else {
            chargentFormList.add(opp);
          }
        //}
      }
    }      
    System.debug(Logginglevel.info, 'The nonChargentFormList size ' + ' ' + nonChargentFormList.size());
    System.debug(Logginglevel.info, 'The ChargentFormlist size ' + ' ' + chargentFormList.size());   

    if (nonChargentFormList.size() > 0 && chargentFormList.size() <= 0 ){
    System.debug(Logginglevel.info, 'true');   
        return true;
    } else {
    System.debug(Logginglevel.info, 'false ');
        return false;
    }
  }
  
//@AuraEnabled
//  public static boolean getPaymentFormCheck () {
//    List<System_Bill__c> nonChargentFormList = new List<System_Bill__c>();
//    List<System_Bill__c> chargentFormList = new List<System_Bill__c>();

//    User u = [SELECT Id, ContactId, Parent_Account_ID__c FROM User WHERE Id = :UserInfo.getUserId()];

//    for (System_Bill__c systemBill : [SELECT Id, Name, Shared_Solar_System__r.Name, Shared_Solar_System__r.Id, 
//                                             Shared_Solar_System__r.Auto_Payment_Form__c
//                                     FROM System_Bill__c 
//                                     WHERE Account_Bill__r.Account_ID__c = : u.Parent_Account_ID__c ]){
//      if (systemBill.Shared_Solar_System__r.Auto_Payment_Form__c == true){
//        nonChargentFormList.add(systemBill);
//      } else {
//        chargentFormList.add(systemBill);
//      }
//    }
//    if (nonChargentFormList.size() <= 0){
//        return false;
//    } else if (nonChargentFormList.size() > 0 && chargentFormList.size() <= 0){
//        return true;
//    } else {
//        return false;
//    }
//  } 

  //@AuraEnabled
  // public static string getMenuAccountBillItem(string menuInput) {
  //    return menuInput+ ' ' + ' has been selected';
  //} 
    @AuraEnabled
   public static string getPropertyAccountId(string propertyAccountId) {
      return propertyAccountId;
  }       
    @AuraEnabled
   public static Decimal getMyBill(string propertyAccountId) {
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
            if(propertyAccountBalance.Total_Outstanding_Balance__c != null){
                totalBalance = propertyAccountBalance.Total_Outstanding_Balance__c;
            }
          }
        }    
        catch(Exception ex) {         
        }
      }
      return totalBalance;   
   }

    @AuraEnabled
    public static List<System_Bill__c> getSystemBills(string propertyAccountId) {
      System.debug(LoggingLevel.info, propertyAccountId);
      System.debug(Logginglevel.info, 'System Bill lookup check');
      List<System_Bill__c> sbList = [SELECT ID, Account_Bill__r.Parent_Account__r.Id, Account_Bill__r.Account_ID__c 
                                     FROM System_Bill__c WHERE Opportunity__r.StageName = 'Complete'];
      List<Account> accountLIst = [SELECT Id, Name FROM Account];
      System.debug(sbList);                                     
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
        aggregateResult[] sbMax= [Select Shared_Solar_System__c, max(Bill_Number__c)maxBillNumber
                                                FROM System_Bill__c                                         
                                                WHERE Opportunity__r.StageName = 'Complete' 
                                                AND Account_Bill__r.Account_Id__c   = : u.Parent_account_id__c
                                                GROUP BY Shared_Solar_System__c];          
        for(AggregateResult ar : sbMax){
          maxBillMap.put((Id)ar.get('Shared_Solar_System__c'), (decimal)ar.get('maxBillNumber'));
          system.debug(LoggingLevel.info,(decimal)ar.get('maxBillNumber'));
        }

        for(System_Bill__c systemBills : [SELECT Id, Total_Due__c, Shared_Solar_System__r.Name, Carry_Over_Balance__c, 
                                            Shared_Solar_System__r.Id,  Bill_Number__c, Name, FormAssembly_Order_Helper__c, 
                                            Form_ID_Helper__c
                                          FROM System_Bill__c 
                                          WHERE Opportunity__r.StageName = 'Complete' 
                                          AND Account_Bill__r.Account_ID__c = : u.Parent_account_id__c]){
                                              system.debug(LoggingLevel.info,systemBills.Name);           
                                              if(maxBillMap.get(systemBills.Shared_Solar_System__r.Id) == systemBills.Bill_Number__c){
                                                  systemBillList.add(systemBills);
                                                  system.debug(LoggingLevel.info, 'System Bills are ' + systemBills.Name);
                                                  system.debug(LoggingLevel.info, 'System Billing Number is ' + systemBills.Bill_Number__c);                                                  
                                                  }
          }
        }

      else{
        aggregateResult[] sbMax = [Select Shared_Solar_System__c, max(Bill_Number__c)maxBillNumber
                                                FROM System_Bill__c
                                                WHERE Opportunity__r.StageName = 'Complete' 
                                                AND Account_Bill__r.Parent_Account__r.Id = : propertyAccountId 
                                                GROUP BY Shared_Solar_System__c];  
        for(AggregateResult ar : sbMax){
          maxBillMap.put((Id)ar.get('Shared_Solar_System__c'), (decimal)ar.get('maxBillNumber'));
          system.debug(LoggingLevel.info,(decimal)ar.get('maxBillNumber'));
        }
        for(System_Bill__c systemBills : [SELECT Id, Total_Due__c, Shared_Solar_System__r.Name, Carry_Over_Balance__c, 
                                            Shared_Solar_System__r.Id,  Bill_Number__c, Name, FormAssembly_Order_Helper__c, 
                                            Form_ID_Helper__c
                                          FROM System_Bill__c 
                                          WHERE Opportunity__r.StageName = 'Complete' 
                                          AND Account_Bill__r.Parent_Account__r.Id = : propertyAccountId]){
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

  @AuraEnabled
  public static List<Opportunity> getOpportunityIds () {
    User u = [Select Id, ContactId, Parent_Account_ID__c from User where Id = :UserInfo.getUserId()];
    List<Opportunity> oppList = new List<Opportunity>();
    integer check = 0;
      for(Opportunity opp : [SELECT Id, Name, Shared_Solar_System__r.Id
                             FROM Opportunity
                             WHERE StageName = 'Complete'
                             AND Account.Parent_Account__r.Id = : u.Parent_Account_ID__c]){
        oppList.add(opp);
      }
    System.debug(oppList);  
    return oppList;
  }

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
   
 //   @AuraEnabled
//public static String getStatement(String parentId){
//  system.debug(Logginglevel.info, 'attachment ab id ' + parentId);
//  String attachmentId;
//  User u = [Select Id, ContactId, contact.AccountId from User where Id = :UserInfo.getUserId()];
//    if(u.ContactId != null) {
//        Attachment a = [select Id, Name from Attachment 
//            where ParentId =: parentId LIMIT 1 ];
//    attachmentId = a.Id;
            
//    }
//    return attachmentId;
//}
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