/*************************************************************************************
 + * Created By:  Jordan Pentaleri 
 + * - Controls the carry over balance, calculation of late fees from bills in a sequence
 + * - Payment Plans (6 or 12 months) and Adjustments (refunds or additions) are calculated here. 
 + * - Sets the balance that is left on a bill as payments come in, "Balance Net Late Payments" and
 + *    double counts payments - ie, sum(Total Payments This Month) = sum(Funds Applied to Balance)
 + *    these are used to see how overdue an account is. 
 + * 
 + * Tested By: TestBillCreationandPayment3
 + *************************************************************************************/

public with sharing class SystemBillAccountingLogicHandler {
    private boolean m_isExecuting = false;
    private Integer BatchSize = 0;
    
    public SystemBillAccountingLogicHandler (boolean isExecuting, Integer size) {
        m_isExecuting = isExecuting;
        BatchSize = size;
    }
    
  public void OnBeforeUpdate (System_Bill__c[] newSystemBill) {
      systemBillAccountingLogic(newSystemBill);
      }
  public void OnBeforeInsert (System_Bill__c[] newSystemBill) {
      systemBillAccountingLogic(newSystemBill);
      }    

  private void systemBillAccountingLogic (List <System_Bill__c> systemBill) {
    string stringPropertyAccount;
    decimal carryoverbalance = 0;  
    decimal pastbillamount = 0;
    decimal pastbillpayment = 0;
    decimal pastbilloverpayment = 0;
    decimal origlatefee = 0;
    decimal origcarryforward = 0;
    list<id> propertyaccountIds = new list<id>();
    list<string> propertyaccountIdsstring = new list<string>();  


    for (System_Bill__c sbill : systemBill) {
        propertyaccountIds.add(sbill.Property_Account_ID__c);
        stringPropertyAccount = string.valueOf(sbill.Property_Account_ID__c);
        propertyaccountIdsstring.add(stringPropertyAccount);
    }      

    List <System_Bill__c> listsystemBills = [SELECT Id, Property_Account_ID__c, Shared_Solar_System_ID__c, Bill_Number__c, Discounted_Bill__c,  
                                            Payments_Net_Previous_Balances__c, Waive_Late_Fees__c, Total_Payments_This_Month__c, Carry_Over_Balance__c, 
                                            Late_Payments__c, Balance_Net_Late_Payments__c, Distribute_This_Balance_12mo__c, 
                                            Late_Fee_Payments__c, Late_Fees__c, Carry_Forward_Payments__c, Early_Payments__c, Carry_Forward_Adjustments__c, Due_This_Month__c, Payment_Plan_Balance__c, Total_Due__c, Distribute_This_Balance_as_Payment_Plan__c,
                                            Payment_Plan_Balance_to_Distribute__c, Savings__c, Opportunity_ID__c
                                            FROM System_Bill__c
                                            WHERE Property_Account_ID__c IN : propertyaccountIdsstring ORDER BY Bill_Number__c DESC];

      for (System_Bill__c trigsb : systemBill) {
          string parentID = trigsb.Opportunity_ID__c;          
          decimal currentbill = trigsb.Bill_Number__c;
          decimal previousbill = currentbill-1 ; 
          decimal pastsixbills = 0;
          decimal pasttwelvebills = 0;
          
              if (currentbill > 7) {
              pastsixbills = currentbill-7;}
                    else {pastsixbills = 0;}

              if (currentbill > 13) {
              pasttwelvebills = currentbill-13;}
                    else {pasttwelvebills = 0;}
                    
          Decimal overdue = 0;
          Decimal ppbalance = 0;
          Decimal twelveppbalance = 0;
          Decimal ytdbilled = 0;
          Decimal ytdpayments = 0;
          boolean morerecentbills = FALSE;
          Decimal dueThisMonth = trigsb.Discounted_Bill__c ;  

          if (trigsb.Refund_this_Balance__c && trigsb.Date_Refunded__c == NULL) {
              trigsb.Date_Refunded__c = system.today();
          }
          
          if ( trigsb.Late_Payments__c ==NULL) {
              trigsb.Late_Payments__c=0;
          }
          
          if ( trigsb.Total_Payments_This_Month__c ==NULL) {
              trigsb.Total_Payments_This_Month__c=0;
          }
          
          if ( trigsb.Payments_Net_Previous_Balances__c ==NULL) {
              trigsb.Payments_Net_Previous_Balances__c =0 ;
          }
          
          if ( trigsb.Carry_Over_Balance__c ==NULL) {
              trigsb.Carry_Over_Balance__c = 0 ;
          }
          
          if ( trigsb.Balance_Net_Late_Payments__c ==NULL) {
              trigsb.Balance_Net_Late_Payments__c = 0 ;
          }
          
          if ( trigsb.Late_Fee_Payments__c ==NULL) {
              trigsb.Late_Fee_Payments__c=0;
          }
          
          if ( trigsb.Late_Fees__c ==NULL) {
              trigsb.Late_Fees__c=0;
          } 

          if ( trigsb.Carry_Forward_Adjustments__c ==NULL) {
              trigsb.Carry_Forward_Adjustments__c=0;
          } 

          if ( trigsb.Carry_Forward_Payments__c ==NULL) {
              trigsb.Carry_Forward_Payments__c=0;
          } 

          if ( trigsb.Early_Payments__c ==NULL) {
              trigsb.Early_Payments__c=0;
          } 
        
          if (currentbill == 1) {

            trigsb.Due_This_Month__c = dueThisMonth;
            trigsb.Total_Due__c = dueThisMonth; 
            trigsb.Previous_Month_Overdue_Balance__c = 0 ;
            trigsb.Late_Fees__c = 0; 
            trigsb.Payment_Plan_Balance__c = 0;
            trigsb.Adjustments__c = 0;                             
            trigsb.Carry_Over_Balance__c = trigsb.Total_Due__c - trigsb.Total_Payments_This_Month__c;

            for (System_Bill__c pastbills : listsystemBills) {
                if (pastbills.Opportunity_ID__c == parentID 
                   && pastbills.Bill_Number__c > currentbill) {
                         morerecentbills = TRUE;
                }
            } 

            if (trigsb.Refund_this_Balance__c && trigsb.Amount_to_Add__c > 0) {
                  trigsb.Adjustments__c = trigsb.Amount_to_Add__c;
            } else if (trigsb.Refund_this_Balance__c && trigsb.Amount_to_Deduct__c > 0) {
                  trigsb.Adjustments__c = -1 * trigsb.Amount_to_Deduct__c;
            }

            if ((trigsb.Distribute_This_Balance_as_Payment_Plan__c  
                || trigsb.Distribute_This_Balance_12mo__c ) 
                && !morerecentbills) {
                  trigsb.Payment_Plan_Balance_to_Distribute__c = trigsb.Carry_Over_Balance__c;
            }

            if (!trigsb.Refund_this_Balance__c) {
                  trigsb.Balance_Net_Late_Payments__c = dueThisMonth - trigsb.Late_Payments__c - trigsb.Payments_Net_Previous_Balances__c; 
            } else if (trigsb.Refund_this_Balance__c) {
                            trigsb.Balance_Net_Late_Payments__c = dueThisMonth + trigsb.Adjustments__c - trigsb.Late_Payments__c - trigsb.Payments_Net_Previous_Balances__c; 
                        }

          }
  
          else { 

            for (System_Bill__c newerbills : listsystemBills) {
                  if (newerbills.Opportunity_ID__c == parentID 
                      && newerbills.Bill_Number__c > currentbill ) {
                        morerecentbills = TRUE;
                  }
            }

            for (System_Bill__c sbill: listsystemBills) {
                            
                if ( sbill.Opportunity_ID__c == parentID ) {

                      if (sbill.Bill_Number__c == previousbill) {
                          pastbillamount = sbill.Total_Due__c;
                          pastbillpayment = sbill.Total_Payments_This_Month__c;
                          pastbilloverpayment = sbill.Carry_Forward_Payments__c;

                          if (sbill.Distribute_This_Balance_as_Payment_Plan__c 
                              || sbill.Distribute_This_Balance_12mo__c) {
                                  carryoverbalance = 0;
                          }
                          else {
                              carryoverbalance = sbill.Carry_Over_Balance__c;
                          }
                      }

                      if ( sbill.Bill_Number__c < currentbill 
                          && sbill.Bill_Number__c > pastsixbills
                          && sbill.Distribute_This_Balance_as_Payment_Plan__c
                          && ppbalance == 0) {
                              ppbalance = sbill.Payment_Plan_Balance_to_Distribute__c / 6 ;
                      }

                      if ( sbill.Bill_Number__c < currentbill 
                          && sbill.Bill_Number__c > pasttwelvebills
                          && sbill.Distribute_This_Balance_12mo__c
                          && ppbalance == 0) {
                              twelveppbalance = sbill.Payment_Plan_Balance_to_Distribute__c / 12 ;
                      }

                      if ( sbill.Bill_Number__c <= currentbill 
                          && sbill.Bill_Number__c >= pasttwelvebills) {
                                ytdbilled = ytdbilled + sbill.Discounted_Bill__c + sbill.Late_Fees__c ;
                                ytdpayments = ytdpayments + sbill.Total_Payments_This_Month__c;
                      }
                }      
            }
                     
            overdue = carryoverbalance;

            trigsb.Previous_Month_Overdue_Balance__c = overdue;
            trigsb.Due_This_Month__c = dueThisMonth; 
            trigsb.Past_Bill_Amount__c = pastbillamount;
            trigsb.Past_Bill_Payment__c = pastbillpayment;
            trigsb.YTD_Billed__c = ytdbilled;
            trigsb.YTD_Payments__c = ytdpayments;
            trigsb.Adjustments__c = 0;
            
            if (pastbilloverpayment < duethismonth) {
                trigsb.Early_Payments__c = pastbilloverpayment;
            } else {
                trigsb.Early_Payments__c = duethismonth;
                trigsb.Carry_Forward_Payments__c = pastbilloverpayment - duethismonth;
            }
                    
            if (ppbalance > 0) {
                trigsb.Payment_Plan_Balance__c = ppbalance;
            } else if (twelveppbalance > 0) {
                trigsb.Payment_Plan_Balance__c = twelveppbalance;
            }           

            if (!trigsb.Waive_Late_Fees__c) {
                trigsb.Late_Fees__c = 0.01*overdue;
            } else if (trigsb.Waive_Late_Fees__c) {
                trigsb.Late_Fees__c = 0;
            }

            if (trigsb.Refund_this_Balance__c && trigsb.Amount_to_Add__c > 0) {
                trigsb.Adjustments__c = trigsb.Amount_to_Add__c;
            } else if (trigsb.Refund_this_Balance__c && trigsb.Amount_to_Deduct__c > 0) {
                trigsb.Adjustments__c = -1 * trigsb.Amount_to_Deduct__c;
            }

            trigsb.Total_Due__c = dueThisMonth + trigsb.Late_Fees__c + carryoverbalance + trigsb.Payment_Plan_Balance__c + trigsb.Adjustments__c;
            decimal newbalance = trigsb.Total_Due__c - trigsb.Total_Payments_This_Month__c;
            trigsb.Carry_Over_Balance__c = newbalance;

            if (trigsb.Distribute_This_Balance_as_Payment_Plan__c
                || trigsb.Distribute_This_Balance_12mo__c 
                && !morerecentbills) {
                    trigsb.Payment_Plan_Balance_to_Distribute__c = trigsb.Carry_Over_Balance__c;
            }
            
            trigsb.Balance_Net_Late_Payments__c = dueThisMonth + trigsb.Carry_Forward_Adjustments__c - trigsb.Late_Payments__c - trigsb.Payments_Net_Previous_Balances__c - trigsb.Early_Payments__c; 

          } // end if current bill != 1     
      } // end triggered system bills
  }     

}