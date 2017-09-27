public with sharing class ChargentOrderCreationhandler {

  public static void createChargentOrder(List<Opportunity> oppList, List<Opportunity> oldOppList){
    List <String> accountIds = new list <String> ();
    Map <Id, Opportunity> oldvaluesmap = new Map<Id, Opportunity> ();

    for(Opportunity oppOld : oldOppList){
        oldvaluesmap.put(oppOld.id, oppOld);
        accountIds.add(oppOld.AccountId);
    }
    
    ChargentBase__Gateway__c gateway  = [SELECT Name, Id, Shared_Solar_System__c, Entity_ID__c
                                          FROM ChargentBase__Gateway__c
                                          WHERE Name = 'BW Community Solar Payments Account Gateway'
                                          LIMIT 1];      

    for(Opportunity opp: oppList){
        String newACH = opp.ACH_Name_on_Account__c;
        String newvalueID = opp.Id;
        String oldACH = oldvaluesmap.get(newvalueID).ACH_Name_on_Account__c;
        if (newACH != null && oldACH == null){
            ChargentOrders__ChargentOrder__c orderA = new ChargentOrders__ChargentOrder__c(
                                                          ChargentOrders__Account__c = opp.AccountId,
                                                          ChargentOrders__Gateway__c = gateway.Id,
                                                          ChargentOrders__Shipping_Name__c = gateway.Entity_ID__c,                              
                                                          ChargentOrders__Payment_Method__c = 'Check',
                                                          ChargentOrders__Bank_Name__c = opp.ACH_Bank_Name__c,
                                                          ChargentOrders__Bank_Routing_Number__c = opp.ACH_Bank_Routing_Number__c ,
                                                          ChargentOrders__Bank_Account_Type__c = opp.ACH_Account_Type__c,
                                                          ChargentOrders__Bank_Account_Number__c = opp.ACH_Account_Number__c,
                                                          ChargentOrders__Bank_Account_Name__c = opp.ACH_Name_on_Account__c);
            Insert orderA;  
            accountids.add(opp.AccountId);
            opp.ACH_Bank_Name__c = 'removed';
            opp.ACH_Bank_Routing_Number__c = 'removed';
            opp.ACH_Account_Type__c = 'removed';
            opp.ACH_Account_Number__c = 'removed';
            opp.ACH_Name_on_Account__c = 'removed';      
      }
    }

    List<Account> accountList = [SELECT Name, Id, Recurring_Billing__c 
                                  FROM Account
                                  WHERE Id IN : accountIds];   

    if(accountList.size() > 0) {
      for(Account acc : accountList){
        acc.Recurring_Billing__c = true;
      }
    }
    update accountList;
  }
}