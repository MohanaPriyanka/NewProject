// https://cs4.salesforce.com/01pP0000000FjLk


public with sharing class SystemBillPaymentRollUpHandler {
  private boolean m_isExecuting = false;
  private Integer BatchSize = 0;
    
  public SystemBillPaymentRollUpHandler (boolean isExecuting, Integer size){
      m_isExecuting = isExecuting;
      BatchSize = size;
  }

  public void OnAfterUpdate(ChargentOrders__Transaction__c[] ChargentTransactions, ChargentOrders__Transaction__c[] oldChargentTransactions){
      rollUpChargentTransactionPaymentsToSystemBill(ChargentTransactions, oldChargentTransactions);
  }

  private void rollUpChargentTransactionPaymentsToSystemBill(List<ChargentOrders__Transaction__c> chargentTransactions, List<ChargentOrders__Transaction__c> oldchargentTransactions){
   
   // Trigger only for the transactions that are fired by the process builder "Update Chargent Transaction From Order"

        system.debug(chargentTransactions);
        system.debug(oldChargentTransactions);

        integer m;
        Map<Id, ChargentOrders__Transaction__c> oldvalues = new Map<Id, ChargentOrders__Transaction__c> ();
        List<ChargentOrders__Transaction__c> triggeredtransactions = new list<ChargentOrders__Transaction__c> ();

        for(ChargentOrders__Transaction__c oldchargentTrans: oldchargentTransactions){
              oldvalues.put(oldchargentTrans.id, oldchargentTrans);
        }

        for(m = 0; m < chargenttransactions.size(); m++){  
              string newvalueID = chargenttransactions.get(m).Id;
              boolean newsb = chargenttransactions.get(m).Distributed_Among_System_Bills__c;
              boolean oldsb = oldvalues.get(newvalueID).Distributed_Among_System_Bills__c;
                  if (newsb == TRUE && oldsb == FALSE) { 
                        triggeredtransactions.add(chargentTransactions.get(m));
                  }
        } 
        system.debug(triggeredtransactions);

// Continue class with only the triggered transactions 
    //instantiate the variables
    decimal totalPayments = 0;
    decimal latePayment = 0;
    integer i; 
    integer j;
    integer l;
    integer b;
    string stringSystemBill;
    string stringPropertyAccount;
    string stringSSS;
    dateTime systemBillCreatedDate; 
    list<id> chargentOrdersId = new list<id>();
    list<id> systemBillIds = new list<id>();
    list<id> propertyaccountIds = new list<id>();
    list<id> sssIds = new list<id>();
    list<string> systemBillIdsString = new list<string>();
    list<string> propertyaccountIdsstring = new list<string>();
    list<string> sssIdsstring = new list<string>();

    map<Id,System_Bill__c> systemBillMap = new map<Id,System_Bill__c>();
    map<Id,Account> propaccountMap = new map<Id,Account>();
    list<System_Bill__c> groupedSystemBillsList = new List<System_Bill__c>();
    list<System_Bill__c> groupedSystemBillsToUpdate = new List<System_Bill__c>();
    


// FOR EACH TRANSACTION: add order id, systembill id, property account id, sss id    
    for(j = 0; j < triggeredtransactions.size(); j++){
     if(triggeredtransactions.get(j).System_Bill_ID__c != NULL && triggeredtransactions.get(j).ChargentOrders__Response_Status__c == 'Approved'){
      chargentOrdersId.add(triggeredtransactions.get(j).ChargentOrders__Order__c);
      system.debug(chargentOrdersId.size());

      systemBillIds.add(triggeredtransactions.get(j).System_Bill_ID__c);
      stringSystemBill = string.valueOf(triggeredtransactions.get(j).System_Bill_ID__c);
      systemBillIdsString.add(stringSystemBill);
      system.debug(systemBillIds.size());

      propertyaccountIds.add(triggeredtransactions.get(j).Property_Account_ID__c);
      stringPropertyAccount = string.valueOf(triggeredtransactions.get(j).Property_Account_ID__c);
      propertyaccountIdsstring.add(stringPropertyAccount);
      system.debug(propertyaccountIdsstring);

      sssIds.add(triggeredtransactions.get(j).Shared_Solar_System_ID__c);
      stringSSS = string.valueOf(triggeredtransactions.get(j).Shared_Solar_System_ID__c);
      sssIdsstring.add(stringSSS);
      system.debug(sssIdsstring);
    }  
    }
    system.debug(chargentOrdersId.size());






    if(chargentOrdersId.size() > 0){

      List <System_Bill__c> systemBills = [SELECT Id, Total_Payments_This_Month__c, Late_Payments__c, Payments_Net_Previous_Balances__c, 
                                                  Late_Fee_Payments__c, Balance_Net_Late_Payments__c, 
                                                  Shared_Solar_System_ID__c,
                                                  Bill_Number__c, Property_Account_ID__c
                                        FROM System_Bill__c
                                        WHERE Property_Account_ID__c IN : propertyaccountIdsstring ORDER BY Bill_Number__c];

     List <Account> propertyaccounts = [SELECT Id, Date_of_last_Payment__c
                                        FROM Account
                                        WHERE Id IN : propertyaccountIdsstring];

     for(b=0; b<propertyaccounts.size();b++){
          propaccountMap.put(propertyaccounts.get(b).Id, propertyaccounts.get(b));
        }


      for(ChargentOrders__Transaction__c chTransaction: triggeredtransactions){
          if(chTransaction.System_Bill_ID__c != NULL && chtransaction.ChargentOrders__Response_Status__c == 'Approved'){

        string parentID = chTransaction.Property_Account_ID__c;  
        system.debug(parentID);
        string sssId = chTransaction.Shared_Solar_System_ID__c;
        system.debug(sssId);
        decimal currentbill = chTransaction.System_Bill_Number__c;
        system.debug(currentbill);
        decimal payment = chTransaction.ChargentOrders__Amount__c;
        decimal totalpaymentsthismonth = chTransaction.ChargentOrders__Amount__c;
        decimal payment_two = 0;

        systemBillCreatedDate = chTransaction.createdDate; 


        //Load all of the related system bills into the a grouped list. Then run through this list below.
        //This finds any systemBill that has the same PR.ACC and SSS as the current iteration of chTransaction and loads them into a list.
        for(j=0; j<systemBills.size();j++){
          systemBillMap.put(systemBills.get(j).Id, systemBills.get(j));
          if(systemBills.get(j).Property_Account_ID__c == parentID && systemBills.get(j).Shared_Solar_System_ID__c == sssId){
            groupedSystemBillsList.add(systemBills.get(j));
            groupedSystemBillsToUpdate.add(systemBills.get(j));
            system.debug(groupedSystemBillsList);
          }
        }
        
        //run through the groupedSystemBillsList instead of the queried list.
        for(i=0;i<currentbill;i++){
          if(groupedSystemBillsList.get(i).Balance_Net_Late_Payments__c > 0 
            && groupedSystemBillsList.get(i).Bill_Number__c < currentbill){
            if(payment >= groupedSystemBillsList.get(i).Balance_Net_Late_Payments__c)  {
                    groupedSystemBillsList.get(i).Late_Payments__c = groupedSystemBillsList.get(i).Late_Payments__c + groupedSystemBillsList.get(i).Balance_Net_Late_Payments__c; 
                    payment = payment - groupedSystemBillsList.get(i).Balance_Net_Late_Payments__c;
                    system.debug(payment);
            }
            else if(payment < groupedSystemBillsList.get(i).Balance_Net_Late_Payments__c) { 
                    groupedSystemBillsList.get(i).Late_Payments__c = groupedSystemBillsList.get(i).Late_Payments__c + payment; payment = 0;
                    system.debug(payment);
            } 
          }   

          if(groupedSystemBillsList.get(i).Bill_Number__c == currentbill){
            groupedSystemBillsList.get(i).Total_Payments_This_Month__c =  groupedSystemBillsList.get(i).Total_Payments_This_Month__c + totalpaymentsthismonth ;
            if(payment >= groupedSystemBillsList.get(i).Balance_Net_Late_Payments__c + groupedSystemBillsList.get(i).Payments_Net_Previous_Balances__c ){
              groupedSystemBillsList.get(i).Payments_Net_Previous_Balances__c = groupedSystemBillsList.get(i).Payments_Net_Previous_Balances__c + groupedSystemBillsList.get(i).Balance_Net_Late_Payments__c;
              payment_two = payment - groupedSystemBillsList.get(i).Balance_Net_Late_Payments__c;
              groupedSystemBillsList.get(i).Late_Fee_Payments__c = payment_two;
            }
            else if(payment < groupedSystemBillsList.get(i).Balance_Net_Late_Payments__c + groupedSystemBillsList.get(i).Payments_Net_Previous_Balances__c ){
              groupedSystemBillsList.get(i).Payments_Net_Previous_Balances__c = groupedSystemBillsList.get(i).Payments_Net_Previous_Balances__c + payment;
              system.debug(payment);
            }

          }//end current bill 
          
        }//end bills to check
 

        Date myDate = date.newinstance(systemBillCreatedDate.year(), systemBillCreatedDate.month(), systemBillCreatedDate.day());
        systemBillMap.get(chTransaction.System_Bill_ID__c).Date_of_Last_Payment__c = myDate; 
        propaccountMap.get(chTransaction.Property_Account_ID__c).Date_of_Last_Payment__c = myDate;
        //clear the list to restart the loop        
        groupedSystemBillsList.clear();

      }
      } // end chargent transaction for loop




      //update the records outside of the for loop       
      update groupedSystemBillsToUpdate;
      update systemBillMap.values();   
      update propaccountMap.values();   


    } //if id size > 0


  } // end system bill update half
}// end class