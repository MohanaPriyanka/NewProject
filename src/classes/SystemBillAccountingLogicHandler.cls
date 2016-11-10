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
    string stringPropertyAccount;
    decimal carryoverbalance = 0;  
    decimal pastbillamount = 0;
    decimal pastbillpayment = 0;
    list<id> propertyaccountIds = new list<id>();
    list<string> propertyaccountIdsstring = new list<string>();  
    list<decimal> previousmonthlist = new list<decimal>();  


    for(j = 0; j < systemBill.size(); j++){
        propertyaccountIds.add(systemBill.get(j).Property_Account_ID__c);
        stringPropertyAccount = string.valueOf(systemBill.get(j).Property_Account_ID__c);
        propertyaccountIdsstring.add(stringPropertyAccount);
        system.debug(propertyaccountIdsstring);
    }      

// List of all associated system bills (including previous months)

    List <System_Bill__c> listsystemBills = [SELECT Id, Property_Account_ID__c, Shared_Solar_System_ID__c, Bill_Number__c, Discounted_Bill__c,  
                                            Payments_Net_Previous_Balances__c, Waive_Late_Fees__c, Total_Payments_This_Month__c, Carry_Over_Balance__c, 
                                            Late_Payments__c, Balance_Net_Late_Payments__c,
                                            Late_Fee_Payments__c, Late_Fees__c, Due_This_Month__c, Payment_Plan_Balance__c, Total_Due__c, Distribute_This_Balance_as_Payment_Plan__c,
                                            Payment_Plan_Balance_to_Distribute__c, Savings__c
                                            FROM System_Bill__c
                                            WHERE Property_Account_ID__c IN : propertyaccountIdsstring ORDER BY Bill_Number__c DESC];

// For each triggered system bill,

      for(j = 0; j < systemBill.size(); j++){
          string ParentID = systemBill.get(j).Property_Account_ID__c;
          system.debug(ParentID);

          string SSSid = systemBill.get(j).Shared_Solar_System_ID__c;
          system.debug(SSSid);
          
          decimal currentbill = systemBill.get(j).Bill_Number__c;
          decimal previousbill = currentbill-1 ; 
          decimal pastsixbills = 2;
          system.debug(previousbill);
          
              if(currentbill>7) {
              pastsixbills = currentbill-5;}
                    else {pastsixbills = 0;}
              system.debug(pastsixbills);
                    
          Decimal sumLateFees = 0;
          Decimal sumLateFeePay = 0;
          Decimal overdue = 0;
          Decimal ppbalance = 0;
          Decimal dueThisMonth = systemBill.get(j).Discounted_Bill__c ;  
        
          
          IF( systemBill.get(j).Late_Payments__c ==NULL){
          systemBill.get(j).Late_Payments__c=0;}
          
          IF( systemBill.get(j).Total_Payments_This_Month__c ==NULL){
          systemBill.get(j).Total_Payments_This_Month__c=0;}
          
          IF( systemBill.get(j).Payments_Net_Previous_Balances__c ==NULL){
          systemBill.get(j).Payments_Net_Previous_Balances__c =0 ;       }
          
          IF( systemBill.get(j).Carry_Over_Balance__c ==NULL){
          systemBill.get(j).Carry_Over_Balance__c = 0 ;}
          
          IF( systemBill.get(j).Balance_Net_Late_Payments__c ==NULL){
          systemBill.get(j).Balance_Net_Late_Payments__c = 0 ;}
          
          IF( systemBill.get(j).Late_Fee_Payments__c ==NULL){
          systemBill.get(j).Late_Fee_Payments__c=0;}
          
          IF( systemBill.get(j).Late_Fees__c ==NULL){
          systemBill.get(j).Late_Fees__c=0;} 



         IF(currentbill == 1){
         
         systemBill.get(j).Due_This_Month__c = dueThisMonth;
         systemBill.get(j).Total_Due__c = dueThisMonth; 
         systemBill.get(j).Previous_Month_Overdue_Balance__c = 0 ;
         systemBill.get(j).Late_Fees__c = 0; 

         if(systemBill.get(j).Distribute_This_Balance_as_Payment_Plan__c == TRUE){
                   systemBill.get(j).Carry_Over_Balance__c  = 0;
         }

         else if (systemBill.get(j).Distribute_This_Balance_as_Payment_Plan__c == FALSE){
               systemBill.get(j).Carry_Over_Balance__c = systemBill.get(j).Total_Due__c - systemBill.get(j).Total_Payments_This_Month__c;
         }

         systemBill.get(j).Balance_Net_Late_Payments__c = dueThisMonth - systemBill.get(j).Late_Payments__c - systemBill.get(j).Payments_Net_Previous_Balances__c; 
       }  
       
      system.debug(currentbill);
      IF(currentbill != 1){
          
                for(i=0; i<listsystemBills.size();i++){
                        if(listsystembills.get(i).Property_Account_ID__c == ParentID 
                            && listsystembills.get(i).Bill_Number__c == previousbill 
                            && listsystembills.get(i).Shared_Solar_System_ID__c == SSSid){
                                    carryoverbalance = listsystembills.get(i).Carry_Over_Balance__c;
                                    pastbillamount = listsystembills.get(i).Total_Due__c;
                                    pastbillpayment = listsystembills.get(i).Total_Payments_This_Month__c;
                          }
                 }  // end for loop

                 for(k=0; k<listsystemBills.size();k++){
                        system.debug(listsystemBills.get(k).Bill_Number__c);
                        system.debug(listsystemBills.get(k).Distribute_This_Balance_as_Payment_Plan__c);

                        if(listsystembills.get(k).Property_Account_ID__c == ParentID 
                            && listsystembills.get(k).Shared_Solar_System_ID__c == SSSid
                            && listsystembills.get(k).Bill_Number__c <= currentbill 
                            && listsystembills.get(k).Bill_Number__c >= pastsixbills
                            && listsystembills.get(k).Distribute_This_Balance_as_Payment_Plan__c == TRUE
                            && ppbalance == 0){
                                    ppbalance = listsystembills.get(k).Payment_Plan_Balance_to_Distribute__c / 6 ;
                            }
                  }
                     
                  overdue = carryoverbalance;
                  system.debug(overdue);
                  system.debug(ppbalance);
                             
                   if(systemBill.get(j).Waive_Late_Fees__c==FALSE){
                            systemBill.get(j).Late_Fees__c = (0.01*overdue);
                            systemBill.get(j).Previous_Month_Overdue_Balance__c = overdue;
                            systemBill.get(j).Due_This_Month__c = dueThisMonth; 
                            systemBill.get(j).Payment_Plan_Balance__c = ppbalance;
                            systemBill.get(j).Past_Bill_Amount__c = pastbillamount;
                            systemBill.get(j).Past_Bill_Payment__c = pastbillpayment;
                            systemBill.get(j).Total_Due__c = dueThisMonth + (1.01*overdue) + ppbalance;
                            }
                            
                                    else if(systemBill.get(j).Waive_Late_Fees__c==TRUE){
                                    systemBill.get(j).Late_Fees__c = 0;
                                    systemBill.get(j).Previous_Month_Overdue_Balance__c = overdue;
                                    systemBill.get(j).Due_This_Month__c = dueThisMonth; 
                                    systemBill.get(j).Past_Bill_Amount__c = pastbillamount;
                                    systemBill.get(j).Payment_Plan_Balance__c = ppbalance;
                                    systemBill.get(j).Past_Bill_Payment__c = pastbillpayment;
                                    systemBill.get(j).Total_Due__c = dueThisMonth + overdue + ppbalance;}
                            
                            if(systemBill.get(j).Distribute_This_Balance_as_Payment_Plan__c == TRUE){
                                      systemBill.get(j).Carry_Over_Balance__c  = 0;}

                            else if (systemBill.get(j).Distribute_This_Balance_as_Payment_Plan__c == FALSE){
                                      systemBill.get(j).Carry_Over_Balance__c = systemBill.get(j).Total_Due__c - systemBill.get(j).Total_Payments_This_Month__c;
                            }

                            systemBill.get(j).Balance_Net_Late_Payments__c = dueThisMonth - systemBill.get(j).Late_Payments__c - systemBill.get(j).Payments_Net_Previous_Balances__c; 

           } // end if current bill != 1     

        }
  }     

}