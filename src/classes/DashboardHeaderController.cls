public with sharing class DashboardHeaderController {
    
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
    public static Boolean hasBill() {
      Boolean hasBill = false;
      User u = [Select Id, ContactId from User where Id = :UserInfo.getUserId()];
      if(u.ContactId != null) {
        try {
          Product_Profile__c pp = [Select Id, My_Current_Balance__c from Product_Profile__c where Contact__c = :u.ContactId and Profile_Type__c = 'Community Solar'];
          if(pp.My_Current_Balance__c != null)
            hasBill = true;
        }
        catch(Exception ex) {
          
        }
      }
      return hasBill;
    } 
    
    @AuraEnabled
    public static String getName() {
      return UserInfo.getFirstName();
    } 
}