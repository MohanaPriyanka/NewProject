public without sharing class MyAccountController {
 @AuraEnabled
    public static List<Account> getMenuLabelList() {
    list<Account> propertyAccountLabelList = new list<Account>();
    User u = [SELECT Id, ContactId, Parent_account_id__c, Contact.Account.Id, Contact.AccountId  FROM User WHERE Id = :UserInfo.getUserId()];
    System.debug('The user is ' + u.Parent_account_id__c);
    String userAccountId = (String)u.Contact.Account.Id;      
    for(Account propertyAccount : [SELECT Id, Name, Parent_Account_ID__c, Total_Outstanding_Balance__c FROM Account WHERE Parent_Account__c = : u.Contact.AccountId]) {
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
                                      FROM Shared_Solar_System__c]) {     
      System.debug(LoggingLevel.info, sss.Opportunities__r.size());
      for (Opportunity opp : sss.Opportunities__r) {
        System.debug(Logginglevel.info, 'The Opp Account ID is ' + ' ' + String.valueOf(opp.Account.Parent_Account__r.Id).subString(0,15));
        System.debug(Logginglevel.info, 'The user account ID is ' + ' ' + u.Parent_Account_ID__c);

        //if (String.valueOf(opp.Account.Parent_Account__r.Id).substring(0,15) == u.Parent_Account_ID__c) {
          if (sss.Auto_Payment_Form__c == true) {
            nonChargentFormList.add(opp);
          } else {
            chargentFormList.add(opp);
          }
        //}
      }
    }      
    System.debug(Logginglevel.info, 'The nonChargentFormList size ' + ' ' + nonChargentFormList.size());
    System.debug(Logginglevel.info, 'The ChargentFormlist size ' + ' ' + chargentFormList.size());   

    if (nonChargentFormList.size() > 0 && chargentFormList.size() <= 0 ) {
    System.debug(Logginglevel.info, 'true');   
        return true;
    } else {
    System.debug(Logginglevel.info, 'false ');
        return false;
    }
  }

    @AuraEnabled
   public static String getPropertyAccountId(String propertyAccountId) {
      return propertyAccountId;
  }       
    @AuraEnabled
   public static Decimal getMyBill(String propertyAccountId) {
     User u = [ SELECT Id, ContactId, Parent_Account_ID__c 
                FROM User 
                WHERE Id = :UserInfo.getUserId()];

     Decimal totalBalance = 0;   
     Decimal maxBillNumber = 0;

      if(u.ContactId != null) {
          List<Account_Bill__c> acctBillsact ;
          if(propertyAccountId == 'All' || propertyAccountId == null) {
                acctBillsact = [SELECT Id, Name, Bill_Number__c, Carry_Over_Balance__c
                                  FROM Account_Bill__c
                                  WHERE Account_ID__c = : u.Parent_Account_ID__c
                                  ORDER BY Bill_Number__c];   
          } else {
                acctBillsact = [SELECT Id, Name, Bill_Number__c, Carry_Over_Balance__c
                                  FROM Account_Bill__c
                                  WHERE Parent_Account__r.Id = : propertyAccountId 
                                  ORDER BY Bill_Number__c];
          }
          Integer j;
          List<Id> acctBillsPropertyIds = new List<id>(); 
                
          for (j = 0; j < acctBillsact.size(); j++) {
              integer maxbill = acctBillsact.size() - 1;
              maxBillNumber = acctBillsact.get(maxbill).Bill_Number__c;
          }
         for (Account_Bill__c acctbill : acctBillsact) {
            if (acctbill.Bill_Number__c == maxBillNumber) {
                totalbalance = totalbalance + acctbill.Carry_Over_Balance__c;
            }
          }
      }
      return totalBalance;   
   }

    @AuraEnabled
    public static List<AggregateResult> getSystemBills(String propertyAccountId) {
      User u = [SELECT Id, ContactId, Parent_Account_ID__c, Contact.Account.Id 
                FROM User 
                WHERE Id = :UserInfo.getUserId()]; 
      List<System_Bill__c> systemBillList = new List<System_Bill__c>();
      List<AggregateResult> aggresultlist = new List<AggregateResult>();
      Decimal maxBillNumber = 0;
      Decimal totalBalance = 0;     

      if (propertyAccountId == 'All' || propertyAccountId == null) {

            List<Account_Bill__c> acctBillsParent = [SELECT Id, Name, Bill_Number__c
                                                      FROM Account_Bill__c
                                                      WHERE Account_ID__c = : u.Parent_Account_ID__c
                                                      ORDER BY Bill_Number__c];
            Integer j;
            List<Id> acctBillsParentIDs = new List<id>(); 
            
            for (j = 0; j < acctBillsParent.size(); j++) {
              integer maxbill = acctBillsParent.size() - 1;
              maxBillNumber = acctBillsParent.get(maxbill).Bill_Number__c;
            }


            for (AggregateResult sysBillsParent : [SELECT Account_Bill__c, Shared_Solar_System__r.BWC_Project_Entity_Manual__c entity, MAX(FormAssembly_Order_Helper__c) fahelp,
                                                    SUM(Carry_Over_Balance__c) carryover
                                                  FROM System_Bill__c
                                                  WHERE Account_Bill__c IN : acctBillsParent
                                                  AND Account_Bill__r.Bill_Number__c = : maxBillNumber
                                                  AND Carry_Over_Balance__c > 0.01
                                                  GROUP BY Shared_Solar_System__r.BWC_Project_Entity_Manual__c, Account_Bill__c]) {
                aggresultlist.add(sysBillsParent);
            }

      } else {

            List<Account_Bill__c> acctBillsProperty = [SELECT Id, Name
                                              FROM Account_Bill__c
                                              WHERE Parent_Account__r.Id = : propertyAccountId 
                                              ORDER BY Bill_Number__c];
            Integer j;
            List<Id> acctBillsPropertyIds = new List<id>(); 
            
            for (j = 0; j < acctBillsProperty.size(); j++) {
              integer maxbill = acctBillsProperty.size() - 1;
              acctBillsPropertyIds.add(acctBillsProperty.get(maxbill).Id);
            }
            
            for( AggregateResult sysblisttwo : [SELECT Account_Bill__c, Shared_Solar_System__r.BWC_Project_Entity_Manual__c entity, MAX(FormAssembly_Order_Helper__c) fahelp,
                                                    SUM(Carry_Over_Balance__c) carryover
                                                FROM System_Bill__c
                                                WHERE Account_Bill__r.Id IN : acctBillsPropertyIds
                                                AND Carry_Over_Balance__c > 0.01
                                                GROUP BY Shared_Solar_System__r.BWC_Project_Entity_Manual__c, Account_Bill__c]) {
                aggresultlist.add(sysblisttwo);
            }
                                               
      }

      system.debug('JP_TESTING' + aggresultlist);
      return aggresultlist;  
    }  

  @AuraEnabled
   public static Id getMyParentAccountId(String propertyAccountId) {
    if(propertyAccountId == 'All' || propertyAccountId == null) {
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
   public static Account getMyParentAccount(String propertyAccountId) {
      Account parentAccount;
      User u = [Select Id, ContactId, contact.AccountId from User where Id = :UserInfo.getUserId()];
      if(u.ContactId != null) {
        parentAccount = [SELECT Id, Name, Recurring_Billing__c FROM Account WHERE Id = : u.Contact.AccountId];
      }
      return parentAccount;    
  }  

  @AuraEnabled
  public static List<Opportunity> getOpportunityIds () {
    User u = [Select Id, ContactId, Parent_Account_ID__c from User where Id = :UserInfo.getUserId()];
    List<Opportunity> oppList = new List<Opportunity>();
    integer check = 0;
      for(Opportunity opp : [SELECT Id, Name, Shared_Solar_System__r.Id
                             FROM Opportunity
                             WHERE StageName = 'Complete'
                             AND Account.Parent_Account__r.Id = : u.Parent_Account_ID__c]) {
        oppList.add(opp);
      }
    System.debug(oppList);  
    return oppList;
  }

  @AuraEnabled
  public static List<Account_Bill__c> getAccountBills (String propertyAccountId) {
    system.debug(loggingLevel.info, propertyAccountId);
    User u = [Select Id, ContactId, Parent_Account_ID__c from User where Id = :UserInfo.getUserId()];
    List<Account_Bill__c> accountBillList = new List<Account_Bill__c>();
    integer check = 0;
    if(propertyAccountId == 'All' || propertyAccountId == null) {
      check = 1;
      for(Account_Bill__c accountBillAll : [SELECT Parent_Account__r.Name, Date__c, Activity_Type__c, Due_this_month__c, 
                                                  Total_Due_This_Month__c, Total_Due__c, Carry_Over_Balance__c, Bill_number__c,
                                                  Balance_Net_Late_Payments__c, Date_of_Last_Payment__c, Bill_Due_Date__c, Total_due_minus_payment_plan__c
                                            FROM Account_Bill__c
                                            WHERE Account_ID__c = : u.Parent_Account_ID__c
                                            ORDER BY Bill_Number__c DESC]) {
        accountBillList.add(accountBillAll);
      }
      system.debug(accountBillList);    
    }
    else{
      check = 2;
      for(Account_Bill__c accountBillProperty : [SELECT Parent_Account__r.Name, Date__c, Activity_Type__c, Due_this_month__c, Total_Due_This_Month__c, Total_due_minus_payment_plan__c, Total_Due__c, Bill_Due_Date__c, Carry_Over_Balance__c, Bill_number__c, Balance_Net_Late_Payments__c
                                            FROM Account_Bill__c
                                            WHERE Parent_Account__r.Id = : propertyAccountId
                                            ORDER BY Bill_Number__c DESC]) {
        accountBillList.add(accountBillProperty);
      }
      system.debug(accountBillList);
    }
    system.debug(loggingLevel.info,check);
    return accountBillList;
  }

  @AuraEnabled
  public static List<ChargentOrders__Transaction__c > getTransactions (String propertyAccountId) {
    system.debug(loggingLevel.info, propertyAccountId);
    User u = [Select Id, ContactId, Parent_Account_ID__c from User where Id = :UserInfo.getUserId()];
    List<ChargentOrders__Transaction__c> chargentTransactionsList = new List<ChargentOrders__Transaction__c>();
    integer check = 0;
    if(propertyAccountId == 'All' || propertyAccountId == null) {
      check = 1;
      for(ChargentOrders__Transaction__c chargentTransactionsAll : [SELECT ChargentOrders__Type__c, Activity_Type__c, Negative_Amount__c, ChargentOrders__Order__r.Account_Bill__r.Parent_Account__r.Name, ChargentOrders__Gateway_Date__c, Date_of_transaction__c,
                                                                           ChargentOrders__Amount__c, System_Bill_Remaining_Balance__c, ChargentOrders__Order__r.ChargentOrders__Gateway__r.Entity__r.Name , ChargentOrders__Response_Status__c 
                                                                    FROM ChargentOrders__Transaction__c
                                                                    WHERE ChargentOrders__Order__r.Account_Bill__r.Account_ID__c = : u.Parent_Account_ID__c
                                                                    AND ChargentOrders__Response_Status__c = 'Approved'
                                                                    ORDER BY CreatedDate DESC]) {
        
        chargentTransactionsList.add(chargentTransactionsAll);
      }
      system.debug(chargentTransactionsList);    
    }
    else{
      check = 2;
      for(ChargentOrders__Transaction__c chargentTransactionsProperty : [SELECT ChargentOrders__Type__c, Activity_Type__c,Negative_Amount__c, ChargentOrders__Order__r.Account_Bill__r.Parent_Account__r.Name, ChargentOrders__Gateway_Date__c, Date_of_transaction__c,
                                                                           ChargentOrders__Amount__c, System_Bill_Remaining_Balance__c, ChargentOrders__Order__r.ChargentOrders__Gateway__r.Entity__r.Name, ChargentOrders__Response_Status__c 
                                                                         FROM ChargentOrders__Transaction__c
                                                                         WHERE ChargentOrders__Order__r.Account_Bill__r.Parent_Account__r.Id = : propertyAccountId
                                                                         AND ChargentOrders__Response_Status__c = 'Approved'
                                                                         ORDER BY CreatedDate DESC]) {
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
//public static String getStatement(String parentId) {
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