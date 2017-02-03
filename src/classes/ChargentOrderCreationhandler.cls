public with sharing class ChargentOrderCreationhandler {
  private boolean m_isExecuting = false;
  private Integer BatchSize = 0;
    
  public ChargentOrderCreationhandler (boolean isExecuting, Integer size){
      m_isExecuting = isExecuting;
      BatchSize = size;
  }

  public void OnBeforeUpdate (Opportunity [] oppList, Opportunity [] oldoppList){
      ChargentOrderCreation (opplist, oldopplist);
  }
  
  private void ChargentOrderCreation (List <Opportunity> oppList, List <Opportunity> oldoppList){
  
    List <string> idlist = new list <string> ();
    List <string> accountids = new list <string> ();
    Map <Id, Opportunity> oldvaluesmap = new Map<Id, Opportunity> ();

    for(Opportunity oppold: oldopplist){
              oldvaluesmap.put(oppold.id, oppold);
              accountids.add(oppold.AccountId);
    }
    
    List <ChargentBase__Gateway__c> gatewayList  = [SELECT Name, Id, Shared_Solar_System__c 
                                                    FROM ChargentBase__Gateway__c
                                                    WHERE Name = 'Community Solar Payments - Medfield Country Way'];      
    
    List <Account> accountlist = [SELECT Name, Id, Recurring_Billing__c 
                                  FROM Account
                                  WHERE Id IN : accountids];   
    system.debug(accountlist);                 
                                                                           
    for(Opportunity opp: oppList){
      if(gatewaylist.size() > 0){
              string newACH = opp.ACH_Name_on_Account__c;
              string newvalueID = opp.Id;
              string oldACH = oldvaluesmap.get(newvalueID).ACH_Name_on_Account__c;
              string sssid;
              string subsssid;
              string gatewayid;
              system.debug(newACH);
              system.debug(oldACH);

              for(ChargentBase__Gateway__c gate : gatewayList){
                    sssid = gate.Shared_Solar_System__c;
                    subsssid = sssid.substring(0,15);
                    gatewayid = gate.Id;
                    system.debug(sssid);
                    system.debug(gatewayid);
              }

              if(newACH != null && oldACH == null){
                      system.debug('trigger');
                      ChargentOrders__ChargentOrder__c orderA  = new ChargentOrders__ChargentOrder__c(
                                                                ChargentOrders__Account__c = opp.AccountId,
                                                                ChargentOrders__Gateway__c = gatewayid,
                                                                ChargentOrders__Shipping_Name__c = subsssid,                              
                                                                ChargentOrders__Payment_Method__c = 'Check',
                                                                ChargentOrders__Bank_Name__c = opp.ACH_Bank_Name__c,
                                                                ChargentOrders__Bank_Routing_Number__c = opp.ACH_Bank_Routing_Number__c ,
                                                                ChargentOrders__Bank_Account_Type__c = opp.ACH_Account_Type__c,
                                                                ChargentOrders__Bank_Account_Number__c = opp.ACH_Account_Number__c,
                                                                ChargentOrders__Bank_Account_Name__c = opp.ACH_Name_on_Account__c);
                      insert orderA;
                      system.debug(orderA);
                      
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