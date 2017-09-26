public with sharing class ChargentOrderCreationhandler {

  public static void ChargentOrderCreation (List <Opportunity> oppList, List <Opportunity> oldOppList){
    List <string> idlist = new list <string> ();
    List <string> accountids = new list <string> ();
    Map <Id, Opportunity> oldvaluesmap = new Map<Id, Opportunity> ();

    for(Opportunity oppOld : oldOppList){
        oldvaluesmap.put(oppOld.id, oppOld);
        accountids.add(oppOld.AccountId);
    }
    
    List <ChargentBase__Gateway__c> gatewayList  = [SELECT Name, Id, Shared_Solar_System__c, Entity_ID__c
                                                    FROM ChargentBase__Gateway__c
                                                    WHERE Name = 'BW Community Solar Payments Account Gateway'];      
    
    List <Account> accountlist = [SELECT Name, Id, Recurring_Billing__c 
                                  FROM Account
                                  WHERE Id IN : accountids];   

    if(gatewaylist.size() > 0){
      String entityId;
      String gatewayId;

      for(ChargentBase__Gateway__c gate : gatewayList){
        entityId = gate.Entity_ID__c;
        gatewayId = gate.Id;
      }  

      for(Opportunity opp: oppList){
        String newACH = opp.ACH_Name_on_Account__c;
        String newvalueID = opp.Id;
        String oldACH = oldvaluesmap.get(newvalueID).ACH_Name_on_Account__c;
        if(newACH != null && oldACH == null){
            ChargentOrders__ChargentOrder__c orderA = new ChargentOrders__ChargentOrder__c(
                                                          ChargentOrders__Account__c = opp.AccountId,
                                                          ChargentOrders__Gateway__c = gatewayId,
                                                          ChargentOrders__Shipping_Name__c = entityId,                              
                                                          ChargentOrders__Payment_Method__c = 'Check',
                                                          ChargentOrders__Bank_Name__c = opp.ACH_Bank_Name__c,
                                                          ChargentOrders__Bank_Routing_Number__c = opp.ACH_Bank_Routing_Number__c ,
                                                          ChargentOrders__Bank_Account_Type__c = opp.ACH_Account_Type__c,
                                                          ChargentOrders__Bank_Account_Number__c = opp.ACH_Account_Number__c,
                                                          ChargentOrders__Bank_Account_Name__c = opp.ACH_Name_on_Account__c);
            insert orderA;  
            for (Account acc : accountlist){
              acc.Recurring_Billing__c = true;
            }
            opp.ACH_Bank_Name__c = 'removed';
            opp.ACH_Bank_Routing_Number__c = 'removed';
            opp.ACH_Account_Type__c = 'removed';
            opp.ACH_Account_Number__c = 'removed';
            opp.ACH_Name_on_Account__c = 'removed';      
        }
      }
    }
    update accountlist;
  }
}