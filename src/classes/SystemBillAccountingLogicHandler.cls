// Accounting Logic Class
// Turning Accounting Logic Trigger into Class
// https://cs4.salesforce.com/01pj0000004XxuM

public with sharing class SystemBillAccountingLogicHandler {
    private boolean m_isExecuting = false;
    private Integer BatchSize = 0;
    
    public SystemBillAccountingLogicHandler (boolean isExecuting, Integer size){
        m_isExecuting = isExecuting;
        BatchSize = size;
    }
    
  public void OnBeforeUpdate (System_Bill__c[] newSystemBill){
      systemBillAccountingLogic(newSystemBill);
      }
  public void OnBeforeInsert (System_Bill__c[] newSystemBill){
      systemBillAccountingLogic(newSystemBill);
      }    

  private void systemBillAccountingLogic (List <System_Bill__c> systemBill){

    integer j;
    integer i;
    integer k;
    integer l;
    integer h;
    integer g;
    string stringPropertyAccount;
    decimal carryoverbalance = 0;  
    decimal pastbillamount = 0;
    decimal pastbillpayment = 0;
    decimal pastbilloverpayment = 0;
    decimal origlatefee = 0;
    decimal origcarryforward = 0;
    list<id> propertyaccountIds = new list<id>();
    list<string> propertyaccountIdsstring = new list<string>();  


    for(j = 0; j < systemBill.size(); j++){
        propertyaccountIds.add(systemBill.get(j).Property_Account_ID__c);
        stringPropertyAccount = string.valueOf(systemBill.get(j).Property_Account_ID__c);
        propertyaccountIdsstring.add(stringPropertyAccount);
        system.debug(propertyaccountIdsstring);
    }      

    List <System_Bill__c> listsystemBills = [SELECT Id, Property_Account_ID__c, Shared_Solar_System_ID__c, Bill_Number__c, Discounted_Bill__c,  
                                            Payments_Net_Previous_Balances__c, Waive_Late_Fees__c, Total_Payments_This_Month__c, Carry_Over_Balance__c, 
                                            Late_Payments__c, Balance_Net_Late_Payments__c, Distribute_This_Balance_12mo__c, 
                                            Late_Fee_Payments__c, Late_Fees__c, Carry_Forward_Payments__c, Early_Payments__c, Carry_Forward_Adjustments__c, Due_This_Month__c, Payment_Plan_Balance__c, Total_Due__c, Distribute_This_Balance_as_Payment_Plan__c,
                                            Payment_Plan_Balance_to_Distribute__c, Savings__c
                                            FROM System_Bill__c
                                            WHERE Property_Account_ID__c IN : propertyaccountIdsstring ORDER BY Bill_Number__c DESC];

      for(j = 0; j < systemBill.size(); j++){
          string parentID = systemBill.get(j).Property_Account_ID__c;
          system.debug(parentID);

          string sssid = systemBill.get(j).Shared_Solar_System_ID__c;
          system.debug(sssid);
          
          decimal currentbill = systemBill.get(j).Bill_Number__c;
          decimal previousbill = currentbill-1 ; 
          decimal pastsixbills = 0;
          decimal pasttwelvebills = 0;
          system.debug(previousbill);
          
              if(currentbill>7) {
              pastsixbills = currentbill-7;}
                    else {pastsixbills = 0;}

              if(currentbill>13) {
              pasttwelvebills = currentbill-13;}
                    else {pasttwelvebills = 0;}
                    
          Decimal overdue = 0;
          Decimal ppbalance = 0;
          Decimal twelveppbalance = 0;
          Decimal ytdbilled = 0;
          Decimal ytdpayments = 0;
          boolean morerecentbills = FALSE;
          Decimal dueThisMonth = systemBill.get(j).Discounted_Bill__c ;  

          if (systemBill.get(j).Refund_this_Balance__c == TRUE && systemBill.get(j).Date_Refunded__c == NULL){
              systemBill.get(j).Date_Refunded__c = system.today();
          }
          
          if ( systemBill.get(j).Late_Payments__c ==NULL){
              systemBill.get(j).Late_Payments__c=0;
          }
          
          if ( systemBill.get(j).Total_Payments_This_Month__c ==NULL){
              systemBill.get(j).Total_Payments_This_Month__c=0;
          }
          
          if ( systemBill.get(j).Payments_Net_Previous_Balances__c ==NULL){
              systemBill.get(j).Payments_Net_Previous_Balances__c =0 ;
          }
          
          if ( systemBill.get(j).Carry_Over_Balance__c ==NULL){
              systemBill.get(j).Carry_Over_Balance__c = 0 ;
          }
          
          if ( systemBill.get(j).Balance_Net_Late_Payments__c ==NULL){
              systemBill.get(j).Balance_Net_Late_Payments__c = 0 ;
          }
          
          if ( systemBill.get(j).Late_Fee_Payments__c ==NULL){
              systemBill.get(j).Late_Fee_Payments__c=0;
          }
          
          if ( systemBill.get(j).Late_Fees__c ==NULL){
              systemBill.get(j).Late_Fees__c=0;
          } 

          if ( systemBill.get(j).Carry_Forward_Adjustments__c ==NULL){
              systemBill.get(j).Carry_Forward_Adjustments__c=0;
          } 

          if ( systemBill.get(j).Carry_Forward_Payments__c ==NULL){
              systemBill.get(j).Carry_Forward_Payments__c=0;
          } 
        
          if(currentbill == 1){

             systemBill.get(j).Due_This_Month__c = dueThisMonth;
             systemBill.get(j).Total_Due__c = dueThisMonth; 
             systemBill.get(j).Previous_Month_Overdue_Balance__c = 0 ;
             systemBill.get(j).Late_Fees__c = 0; 
             systemBill.get(j).Payment_Plan_Balance__c = 0;
             systemBill.get(j).Adjustments__c = 0;                             
             systemBill.get(j).Carry_Over_Balance__c = systemBill.get(j).Total_Due__c - systemBill.get(j).Total_Payments_This_Month__c;

            for(g=0; g<listsystemBills.size(); g++){
                if(listsystembills.get(g).Property_Account_ID__c == parentID 
                   && listsystembills.get(g).Bill_Number__c > currentbill 
                   && listsystembills.get(g).Shared_Solar_System_ID__c == sssid){
                         morerecentbills = TRUE;
                }
            } 

            if(systemBill.get(j).Refund_this_Balance__c == TRUE && systemBill.get(j).Amount_to_Add__c > 0){
                  systembill.get(j).Adjustments__c = -systembill.get(j).Amount_to_Add__c;
            }
                        else if(systemBill.get(j).Refund_this_Balance__c == TRUE && systemBill.get(j).Amount_to_Deduct__c > 0){
                            systembill.get(j).Adjustments__c = -1 * systembill.get(j).Amount_to_Deduct__c;
                        }

            if ((systemBill.get(j).Distribute_This_Balance_as_Payment_Plan__c == TRUE 
                || systemBill.get(j).Distribute_This_Balance_12mo__c == TRUE) 
                && morerecentbills == FALSE) {
                            systemBill.get(j).Payment_Plan_Balance_to_Distribute__c = systemBill.get(j).Carry_Over_Balance__c;
            }

            if (systemBill.get(j).Refund_this_Balance__c == FALSE){
                  systemBill.get(j).Balance_Net_Late_Payments__c = dueThisMonth - systemBill.get(j).Late_Payments__c - systemBill.get(j).Payments_Net_Previous_Balances__c; 
            }
                        else if (systemBill.get(j).Refund_this_Balance__c == TRUE){
                            systemBill.get(j).Balance_Net_Late_Payments__c = dueThisMonth + systemBill.get(j).Adjustments__c - systemBill.get(j).Late_Payments__c - systemBill.get(j).Payments_Net_Previous_Balances__c; 
                        }

          }
  
          if (currentbill != 1){

            for (h=0; h<listsystemBills.size();h++){
                  if (listsystembills.get(h).Property_Account_ID__c == parentID 
                      && listsystembills.get(h).Bill_Number__c > currentbill 
                      && listsystembills.get(h).Shared_Solar_System_ID__c == sssid){
                            morerecentbills = TRUE;
                  }
            }

            for (k=0; k<listsystemBills.size();k++){
                            
                if ( listsystembills.get(k).Property_Account_ID__c == parentID 
                    && listsystembills.get(k).Shared_Solar_System_ID__c == sssid) {

                      if (listsystembills.get(k).Bill_Number__c == previousbill){
                          pastbillamount = listsystembills.get(k).Total_Due__c;
                          pastbillpayment = listsystembills.get(k).Total_Payments_This_Month__c;
                          pastbilloverpayment = listsystembills.get(k).Carry_Forward_Payments__c;

                          if (listsystembills.get(k).Distribute_This_Balance_as_Payment_Plan__c == TRUE 
                              || listsystembills.get(k).Distribute_This_Balance_12mo__c == TRUE){
                                  carryoverbalance = 0;
                          }
                          else {
                              carryoverbalance = listsystembills.get(k).Carry_Over_Balance__c;
                          }
                      }

                      if ( listsystembills.get(k).Bill_Number__c < currentbill 
                          && listsystembills.get(k).Bill_Number__c > pastsixbills
                          && listsystembills.get(k).Distribute_This_Balance_as_Payment_Plan__c == TRUE
                          && ppbalance == 0){
                              ppbalance = listsystembills.get(k).Payment_Plan_Balance_to_Distribute__c / 6 ;
                      }

                      if ( listsystembills.get(k).Bill_Number__c < currentbill 
                          && listsystembills.get(k).Bill_Number__c > pasttwelvebills
                          && listsystembills.get(k).Distribute_This_Balance_12mo__c == TRUE
                          && ppbalance == 0){
                              twelveppbalance = listsystembills.get(k).Payment_Plan_Balance_to_Distribute__c / 12 ;
                      }

                      if ( listsystembills.get(k).Bill_Number__c <= currentbill 
                          && listsystembills.get(k).Bill_Number__c >= pasttwelvebills){
                                ytdbilled = ytdbilled + listsystembills.get(k).Discounted_Bill__c + listsystembills.get(k).Late_Fees__c ;
                                ytdpayments = ytdpayments + listsystembills.get(k).Total_Payments_This_Month__c;
                      }
                }      
            }
                     
            overdue = carryoverbalance;

            systemBill.get(j).Previous_Month_Overdue_Balance__c = overdue;
            systemBill.get(j).Due_This_Month__c = dueThisMonth; 
            systemBill.get(j).Past_Bill_Amount__c = pastbillamount;
            systemBill.get(j).Past_Bill_Payment__c = pastbillpayment;
            systemBill.get(j).YTD_Billed__c = ytdbilled;
            systemBill.get(j).YTD_Payments__c = ytdpayments;
            systemBill.get(j).Adjustments__c = 0;
            origlatefee = systemBill.get(j).Late_Fee_Payments__c;
            origcarryforward = systemBill.get(j).Carry_Forward_Payments__c ;
            
            if (pastbilloverpayment < duethismonth){
                systemBill.get(j).Early_Payments__c = pastbilloverpayment;
            } else {
                systemBill.get(j).Early_Payments__c = duethismonth;
                systemBill.get(j).Carry_Forward_Payments__c = pastbilloverpayment - duethismonth;
            }
                    
            if (ppbalance > 0){
                systemBill.get(j).Payment_Plan_Balance__c = ppbalance;
            }

            else if (twelveppbalance > 0){
                systemBill.get(j).Payment_Plan_Balance__c = twelveppbalance;
            }           

            if (systemBill.get(j).Waive_Late_Fees__c==FALSE){
                systemBill.get(j).Late_Fees__c = 0.01*overdue;
            }

            else if (systemBill.get(j).Waive_Late_Fees__c==TRUE){
                systemBill.get(j).Late_Fees__c = 0;
            }

            if (systemBill.get(j).Refund_this_Balance__c == TRUE && systemBill.get(j).Amount_to_Add__c > 0){
                systemBill.get(j).Adjustments__c = systemBill.get(j).Amount_to_Add__c;
            }

            else if (systemBill.get(j).Refund_this_Balance__c == TRUE && systemBill.get(j).Amount_to_Deduct__c > 0){
                systemBill.get(j).Adjustments__c = -1 * systemBill.get(j).Amount_to_Deduct__c;
            }

            systemBill.get(j).Total_Due__c = dueThisMonth + systemBill.get(j).Late_Fees__c + carryoverbalance + systemBill.get(j).Payment_Plan_Balance__c + systemBill.get(j).Adjustments__c;
            decimal newbalance = systemBill.get(j).Total_Due__c - systemBill.get(j).Total_Payments_This_Month__c;
            systemBill.get(j).Carry_Over_Balance__c = newbalance;

            if (systemBill.get(j).Distribute_This_Balance_as_Payment_Plan__c == TRUE 
                || systemBill.get(j).Distribute_This_Balance_12mo__c == TRUE 
                && morerecentbills == FALSE) {
                    systemBill.get(j).Payment_Plan_Balance_to_Distribute__c = systemBill.get(j).Carry_Over_Balance__c;
            }

            if (newbalance < 0 
                && newbalance != null
                && systemBill.get(j).Late_Fee_Payments__c > 0 ) {
                system.debug(newbalance);
                    if (systemBill.get(j).Late_Fee_Payments__c >= (-1 * newbalance)){
                          systemBill.get(j).Carry_Forward_Payments__c = origcarryforward + (-1*newbalance);
                          systemBill.get(j).Late_Fee_Payments__c = origlatefee + newbalance; 
                    }
            }
            
            systemBill.get(j).Balance_Net_Late_Payments__c = dueThisMonth + systemBill.get(j).Carry_Forward_Adjustments__c - systemBill.get(j).Late_Payments__c - systemBill.get(j).Payments_Net_Previous_Balances__c - systemBill.get(j).Early_Payments__c; 

          } // end if current bill != 1     
        } // end triggered system bills
  }     

}