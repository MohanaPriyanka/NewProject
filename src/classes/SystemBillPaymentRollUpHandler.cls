public with sharing class SystemBillPaymentRollUpHandler {
  private boolean m_isExecuting = false;
  private Integer BatchSize = 0;
    
  public SystemBillPaymentRollUpHandler (boolean isExecuting, Integer size){
      m_isExecuting = isExecuting;
      BatchSize = size;
  }

  public void OnBeforeInsert (ChargentOrders__Transaction__c[] newlycreatedTrans){
      recurringorderfilter (newlycreatedTrans);
  }

  public void OnAfterUpdate(ChargentOrders__Transaction__c[] ChargentTransactions, ChargentOrders__Transaction__c[] oldChargentTransactions){
      rollUpChargentTransactionPaymentsToSystemBill(ChargentTransactions, oldChargentTransactions);
  }

  public static void recurringorderfilter (List <ChargentOrders__Transaction__c> newlycreatedTrans){
    List <ChargentOrders__Transaction__c> uncheckedlist = new List <ChargentOrders__Transaction__c >();
    List <ChargentOrders__Transaction__c> checkedlist = new List <ChargentOrders__Transaction__c >();

        for (ChargentOrders__Transaction__c trans: newlycreatedTrans){
            if (trans.ChargentOrders__Recurring__c){
                    trans.Distributed_Among_System_Bills__c = FALSE;
                    uncheckedlist.add(trans);
                    checkedlist.add(trans);
            }
        }

        SystemBillPaymentRollUpHandler.rollUpChargentTransactionPaymentsToSystemBill(checkedlist,uncheckedlist);
  }

  public static void rollUpChargentTransactionPaymentsToSystemBill(List<ChargentOrders__Transaction__c> chargentTransactions, List<ChargentOrders__Transaction__c> oldchargentTransactions){
        
    Map <Id, ChargentOrders__Transaction__c> oldvalues = new Map <Id, ChargentOrders__Transaction__c> ();
    List <ChargentOrders__Transaction__c> triggeredtransactions = new List <ChargentOrders__Transaction__c> ();

    for(ChargentOrders__Transaction__c oldchargentTrans: oldchargentTransactions){
              oldvalues.put(oldchargentTrans.id, oldchargentTrans);
    }

    for(ChargentOrders__Transaction__c chotran : chargentTransactions){  
        if (chotran.ChargentOrders__Recurring__c && !chotran.Distributed_Among_System_Bills__c) {
                  triggeredtransactions.add(chotran);
        } else if(!chotran.ChargentOrders__Recurring__c){
            String newvalueID = chotran.Id;
            Boolean newsb = chotran.Distributed_Among_System_Bills__c;
            Boolean oldsb = oldvalues.get(newvalueID).Distributed_Among_System_Bills__c;
                if (newsb && !oldsb) { 
                    triggeredtransactions.add(chotran);
                } 
        }
    } 

    Integer b;
    String stringPropertyAccount;
    dateTime systemBillCreatedDate; 
    List <id> chargentOrdersId = new List <id>();
    List <id> propertyaccountIds = new List <id>();
    List <string> propertyaccountIdsstring = new List <string>();

    Map <Id,System_Bill__c> systemBillMap = new Map <Id,System_Bill__c>();
    Map <Id,Account> propaccountMap = new Map <Id,Account>();
    List <System_Bill__c> groupedSystemBillsList = new List <System_Bill__c>();
    List <System_Bill__c> groupedSystemBillsToUpdate = new List <System_Bill__c>();
    
    for(ChargentOrders__Transaction__c trigtran : triggeredtransactions){
      if(trigtran.System_Bill_ID__c != NULL && trigtran.ChargentOrders__Response_Status__c == 'Approved'){    
            chargentOrdersId.add(trigtran.ChargentOrders__Order__c);
            propertyaccountIds.add(trigtran.Property_Account_ID__c);
            stringPropertyAccount = string.valueOf(trigtran.Property_Account_ID__c);
            propertyaccountIdsstring.add(stringPropertyAccount);
      }  
    }

    if(!chargentOrdersId.isEmpty()){

      List <System_Bill__c> systemBills = [ SELECT Id, Total_Payments_This_Month__c, Late_Payments__c, Payments_Net_Previous_Balances__c, 
                                                  Late_Fee_Payments__c, Balance_Net_Late_Payments__c, 
                                                  Shared_Solar_System_ID__c,
                                                  Bill_Number__c, Property_Account_ID__c, Early_Payments__c, Carry_Forward_Payments__c
                                            FROM System_Bill__c
                                            WHERE Property_Account_ID__c IN : propertyaccountIdsstring ORDER BY Bill_Number__c];

      List <Account> propertyaccounts = [ SELECT Id, Date_of_last_Payment__c
                                          FROM Account
                                          WHERE Id IN : propertyaccountIdsstring];

      for (b=0; b<propertyaccounts.size();b++){
          propaccountMap.put(propertyaccounts.get(b).Id, propertyaccounts.get(b));
      }

      for(ChargentOrders__Transaction__c chTransaction: triggeredtransactions){
        if(chTransaction.System_Bill_ID__c != NULL && chtransaction.ChargentOrders__Response_Status__c == 'Approved'){
            string parentID = chTransaction.Property_Account_ID__c;  
            string sssId = chTransaction.Shared_Solar_System_ID__c;
            decimal currentbill = chTransaction.System_Bill_Number__c;
            decimal payment = chTransaction.ChargentOrders__Amount__c;
            decimal totalpaymentsthismonth = chTransaction.ChargentOrders__Amount__c;
            decimal paymenttwo = 0;
            
            if(chTransaction.ChargentOrders__Recurring__c){
              systemBillCreatedDate = system.today();
            } else {
              systemBillCreatedDate = chTransaction.createdDate;
            }

            for(System_Bill__c sbs : systemBills){
              systemBillMap.put(sbs.Id, sbs);
                if (sbs.Property_Account_ID__c == parentID && sbs.Shared_Solar_System_ID__c == sssId){
                        groupedSystemBillsList.add(sbs);
                        groupedSystemBillsToUpdate.add(sbs);
                }
            }
            
            for(System_Bill__c bills : groupedSystemBillsList){
                if(bills.Balance_Net_Late_Payments__c > 0 && bills.Bill_Number__c < currentbill){
                      if(payment >= bills.Balance_Net_Late_Payments__c)  {
                              bills.Late_Payments__c = bills.Late_Payments__c + bills.Balance_Net_Late_Payments__c; 
                              payment = payment - bills.Balance_Net_Late_Payments__c;
                      }   else if(payment < bills.Balance_Net_Late_Payments__c) { 
                              bills.Late_Payments__c = bills.Late_Payments__c + payment; 
                              payment = 0;
                          } 
                }

                if(bills.Bill_Number__c == currentbill){
                    bills.Total_Payments_This_Month__c =  bills.Total_Payments_This_Month__c + totalpaymentsthismonth ;  
                    if(payment >= bills.Balance_Net_Late_Payments__c){
                                  bills.Payments_Net_Previous_Balances__c = bills.Payments_Net_Previous_Balances__c + bills.Balance_Net_Late_Payments__c;
                                  paymenttwo = payment - bills.Balance_Net_Late_Payments__c;
                                  bills.Late_Fee_Payments__c =  bills.Late_Fee_Payments__c + paymenttwo;
                                  system.debug(paymenttwo);
                    } else if(payment < bills.Balance_Net_Late_Payments__c){
                                    bills.Payments_Net_Previous_Balances__c = bills.Payments_Net_Previous_Balances__c + payment;
                      }
                } 
            }

          Date myDate = date.newinstance(systemBillCreatedDate.year(), systemBillCreatedDate.month(), systemBillCreatedDate.day());
          systemBillMap.get(chTransaction.System_Bill_ID__c).Date_of_Last_Payment__c = myDate; 
          propaccountMap.get(chTransaction.Property_Account_ID__c).Date_of_Last_Payment__c = myDate; 
          groupedSystemBillsList.clear();
          
          if(!chTransaction.Distributed_Among_System_Bills__c){
              chTransaction.Distributed_Among_System_Bills__c = TRUE;
          } 
        }
      } // end chargent transaction for loop

      update groupedSystemBillsToUpdate;
      update systemBillMap.values();   
      update propaccountMap.values();   

    } 
  }
}