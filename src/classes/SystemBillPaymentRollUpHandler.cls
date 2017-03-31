/*************************************************************************************
 + * Created By:  Jordan Pentaleri 
 + * Description: When a Chargent Transaction is created via recurring, or is a one time payment and the 
 + * "Distributed amoung System Bills" checkbox is checked (signals that all updates from Form Assembly are complete)
 + * this class distributes the payment amount to all the related system bills. 
 + * Updates the oldest SBs first (bill number field) that have a balance
 + * Tested By: TestBillCreationandPayment3
 + *************************************************************************************/

public with sharing class SystemBillPaymentRollUpHandler {
  private boolean m_isExecuting = false;
  private Integer BatchSize = 0;
    
  public SystemBillPaymentRollUpHandler (boolean isExecuting, Integer size) {
      m_isExecuting = isExecuting;
      BatchSize = size;
  }

  public void OnBeforeInsert (ChargentOrders__Transaction__c[] newlycreatedTrans) {
      recurringorderfilter (newlycreatedTrans);
  }

  public void OnAfterUpdate(ChargentOrders__Transaction__c[] ChargentTransactions, ChargentOrders__Transaction__c[] oldChargentTransactions) {
      rollUpChargentTransactionPaymentsToSystemBill(ChargentTransactions, oldChargentTransactions);
  }

  public static void recurringorderfilter (List <ChargentOrders__Transaction__c> newlycreatedTrans) {
    List <ChargentOrders__Transaction__c> uncheckedlist = new List <ChargentOrders__Transaction__c >();
    List <ChargentOrders__Transaction__c> checkedlist = new List <ChargentOrders__Transaction__c >();

        for (ChargentOrders__Transaction__c trans: newlycreatedTrans) {
            if (trans.ChargentOrders__Recurring__c) {
                    trans.Distributed_Among_System_Bills__c = FALSE;
                    uncheckedlist.add(trans);
                    checkedlist.add(trans);
            }
        }

        SystemBillPaymentRollUpHandler.rollUpChargentTransactionPaymentsToSystemBill(checkedlist,uncheckedlist);
  }

  public static void rollUpChargentTransactionPaymentsToSystemBill(List<ChargentOrders__Transaction__c> chargentTransactions, List<ChargentOrders__Transaction__c> oldchargentTransactions) {
        
    Map <Id, ChargentOrders__Transaction__c> oldvalues = new Map <Id, ChargentOrders__Transaction__c> ();
    List <ChargentOrders__Transaction__c> triggeredtransactions = new List <ChargentOrders__Transaction__c> ();

    for(ChargentOrders__Transaction__c oldchargentTrans: oldchargentTransactions) {
          oldvalues.put(oldchargentTrans.id, oldchargentTrans);
    }

    for(ChargentOrders__Transaction__c chotran : chargentTransactions) {  
        if (chotran.ChargentOrders__Recurring__c && !chotran.Distributed_Among_System_Bills__c) {
                  triggeredtransactions.add(chotran);
        } else if(!chotran.ChargentOrders__Recurring__c) {
            String newvalueID = chotran.Id;
            Boolean newsb = chotran.Distributed_Among_System_Bills__c;
            Boolean oldsb = oldvalues.get(newvalueID).Distributed_Among_System_Bills__c;
                if (newsb && !oldsb) { 
                    triggeredtransactions.add(chotran);
                } 
        }
    } 

    Integer i;
    String stringPropertyAccount;
    dateTime systemBillCreatedDate; 
    List <id> chargentOrdersId = new List <id>();
    List <id> propertyaccountIds = new List <id>();
    List <string> propertyaccountIdsstring = new List <string>();
    Map <Id,Account> propaccountMap = new Map <Id,Account>();
    List <System_Bill__c> groupedSystemBillsList = new List <System_Bill__c>();
    List <System_Bill__c> groupedSystemBillsToUpdate = new List <System_Bill__c>();
    list <System_Bill__c> maxbillnumberlist = new List <System_Bill__c>();
    Map <String, Decimal> paymentsmap = new Map <String,Decimal>();
    
    for(ChargentOrders__Transaction__c trigtran : triggeredtransactions) {
      if(trigtran.Account_Bill_Id__c != NULL && trigtran.ChargentOrders__Response_Status__c == 'Approved') {    
            chargentOrdersId.add(trigtran.ChargentOrders__Order__c);
            propertyaccountIds.add(trigtran.Property_Account_ID__c);
            stringPropertyAccount = string.valueOf(trigtran.Property_Account_ID__c);
            propertyaccountIdsstring.add(stringPropertyAccount);
      }  
    }

    if(!chargentOrdersId.isEmpty()) {

      List <System_Bill__c> systemBills = [ SELECT Id, Total_Payments_This_Month__c, Late_Payments__c, Payments_Net_Previous_Balances__c, 
                                                  Late_Fee_Payments__c, Balance_Net_Late_Payments__c, 
                                                  Shared_Solar_System_ID__c, Entity_ID__c, Opportunity_Id__c,
                                                  Bill_Number__c, Property_Account_ID__c, Early_Payments__c, Carry_Forward_Payments__c
                                            FROM System_Bill__c
                                            WHERE Property_Account_ID__c IN : propertyaccountIdsstring ORDER BY Bill_Number__c];

      List <Account> propertyaccounts = [ SELECT Id, Date_of_last_Payment__c
                                          FROM Account
                                          WHERE Id IN : propertyaccountIdsstring];

      for (Account prop : propertyaccounts) {
          propaccountMap.put(prop.Id, prop);
      }
    
      system.debug(triggeredtransactions);

      for(ChargentOrders__Transaction__c chTransaction: triggeredtransactions) {
        if(chTransaction.Account_Bill_ID__c != NULL && chtransaction.ChargentOrders__Response_Status__c == 'Approved') {
            string parentID = chTransaction.Property_Account_ID__c;  
            string entityId = chTransaction.Entity_ID__c;
            decimal maxbillnumber = 0;
           // decimal currentbill = chTransaction.Account_Bill_Number__c;
            decimal payment = chTransaction.ChargentOrders__Amount__c;
            decimal totalpaymentsthismonth = chTransaction.ChargentOrders__Amount__c;
            decimal paymenttwo = 0;
            
            if(chTransaction.ChargentOrders__Recurring__c) {
              systemBillCreatedDate = system.today();
            } else {
              systemBillCreatedDate = chTransaction.createdDate;
            }

            Date myDate = date.newinstance(systemBillCreatedDate.year(), systemBillCreatedDate.month(), systemBillCreatedDate.day());

            for (System_Bill__c sbill : systemBills) {
                if (sbill.Property_Account_ID__c == parentID && sbill.Entity_ID__c == entityId) {
                      groupedSystemBillsList.add(sbill);
                      groupedSystemBillsToUpdate.add(sbill);
                      maxbillnumber = sbill.Bill_Number__c;
                }
            } 
            
            for(System_Bill__c bills : groupedSystemBillsList) {
                if(bills.Balance_Net_Late_Payments__c > 0 && bills.Bill_Number__c < maxbillnumber) {
                      if(payment >= bills.Balance_Net_Late_Payments__c)  {
                              bills.Late_Payments__c = bills.Late_Payments__c + bills.Balance_Net_Late_Payments__c; 
                              payment = payment - bills.Balance_Net_Late_Payments__c;
                              if (paymentsmap.containsKey(bills.Opportunity_Id__c)) {
                                  paymentsmap.put(bills.Opportunity_Id__c, paymentsmap.get(bills.Opportunity_Id__c) + bills.Balance_Net_Late_Payments__c) ;
                              } else {
                                  paymentsmap.put(bills.Opportunity_Id__c, bills.Balance_Net_Late_Payments__c);
                              }
                      }   else if(payment < bills.Balance_Net_Late_Payments__c) { 
                              bills.Late_Payments__c = bills.Late_Payments__c + payment; 
                              if (paymentsmap.containsKey(bills.Opportunity_Id__c)) {
                                  paymentsmap.put(bills.Opportunity_Id__c, paymentsmap.get(bills.Opportunity_Id__c) + payment);
                              } else {
                                  paymentsmap.put(bills.Opportunity_Id__c, payment);
                              }
                              payment = 0;
                          } 
                }

                if(bills.Bill_Number__c == maxbillnumber) {
                  maxbillnumberlist.add(bills);
                    //bills.Total_Payments_This_Month__c =  bills.Total_Payments_This_Month__c + totalpaymentsthismonth ;  
                    if(payment >= bills.Balance_Net_Late_Payments__c) {
                                  bills.Payments_Net_Previous_Balances__c = bills.Payments_Net_Previous_Balances__c + bills.Balance_Net_Late_Payments__c;
                                  if (paymentsmap.containsKey(bills.Opportunity_Id__c)) {
                                      paymentsmap.put(bills.Opportunity_Id__c, paymentsmap.get(bills.Opportunity_Id__c) + bills.Balance_Net_Late_Payments__c) ;
                                  } else {
                                      paymentsmap.put(bills.Opportunity_Id__c, bills.Balance_Net_Late_Payments__c);
                                  }
                                  payment = payment - bills.Balance_Net_Late_Payments__c;
                    } else if(payment < bills.Balance_Net_Late_Payments__c) {
                                  bills.Payments_Net_Previous_Balances__c = bills.Payments_Net_Previous_Balances__c + payment;
                                  if (paymentsmap.containsKey(bills.Opportunity_Id__c)) {
                                      paymentsmap.put(bills.Opportunity_Id__c, paymentsmap.get(bills.Opportunity_Id__c) + payment);
                                  } else {
                                      paymentsmap.put(bills.Opportunity_Id__c, payment);
                                  }
                                  payment = 0;
                      }
                } 
            }

            for (System_Bill__c maxbills : maxbillnumberlist) {
                if(paymentsmap.containsKey(maxbills.Opportunity_Id__c)) {
                    maxbills.Total_Payments_This_Month__c = maxbills.Total_Payments_This_Month__c + paymentsmap.get(maxbills.Opportunity_Id__c);
                    maxbills.Date_of_Last_Payment__c = myDate; 
                }
            }

          propaccountMap.get(chTransaction.Property_Account_ID__c).Date_of_Last_Payment__c = myDate; 
          groupedSystemBillsList.clear();
          
          if(!chTransaction.Distributed_Among_System_Bills__c) {
              chTransaction.Distributed_Among_System_Bills__c = TRUE;
          } 
        }
      } // end chargent transaction for loop

      update groupedSystemBillsToUpdate;
      update propaccountMap.values();   

    } 
  }
}