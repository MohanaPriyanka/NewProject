/*************************************************************************************
 + * Created By:  Jordan Pentaleri 
 + * - Controls the carry over balance, calculation of late fees from bills in a sequence
 + * - Payment Plans (6 or 12 months) and Adjustments (refunds or additions) are calculated here. 
 + * - Sets the balance that is left on a bill as payments come in, "Balance Net Late Payments" and
 + *    double counts payments - ie, sum(Total Payments This Month) = sum(Funds Applied to Balance)
 + *    these are used to see how overdue an account is. 
 + * 
 + * Tested By: TestBillCreationandPayment
 + *************************************************************************************/

public with sharing class SystemBillAccountingLogicHandler {
    public void accountingRefresh (List <System_Bill__c> systemBill, Map<Id, System_Bill__c> oldSBMap) {
        Decimal carryoverbalance = 0;  
        Decimal pastbillamount = 0;
        Decimal pastbillpayment = 0;
        Decimal pastbilloverpayment = 0;
        Decimal pastbilloveradjust = 0;
        List<Id> propertyaccountIds = new List<id>();
        List<System_Bill__c> unPublishedBillList = new List<System_Bill__c>();

        for (System_Bill__c sbill : systemBill) {
            if (sbill.Published__c){
                doNotAllowUpdate(sbill, oldSBMap);
            } else {
                propertyaccountIds.add(sbill.Property_Account__c);
                unPublishedBillList.add(sbill);
            }
        }

        List <System_Bill__c> listsystemBills = [SELECT Id, Property_Account_ID__c, Shared_Solar_System_ID__c, 
                                                    Bill_Number__c, Discounted_Bill__c,  
                                                    Payments_Net_Previous_Balances__c, Waive_Late_Fees__c, 
                                                    Total_Payments_This_Month__c, Carry_Over_Balance__c, 
                                                    Late_Payments__c, Balance_Net_Late_Payments__c, 
                                                    Distribute_This_Balance_12mo__c, Adjustments__c,
                                                    Late_Fee_Payments__c, Late_Fees__c, 
                                                    Carry_Forward_Payments__c, Early_Payments__c,
                                                    Carry_Forward_Adjustments__c, Due_This_Month__c, 
                                                    Payment_Plan_Balance__c, Total_Due__c, 
                                                    Distribute_This_Balance_as_Payment_Plan__c,
                                                    Payment_Plan_Balance_to_Distribute__c, 
                                                    Savings__c, Opportunity_ID__c, 
                                                    Production_kWH__c,
                                                    Entity_ID__c
                                                FROM System_Bill__c
                                                WHERE Property_Account__c
                                                IN : propertyaccountIds
                                                ORDER BY Bill_Number__c DESC];
        
        for (System_Bill__c trigsb : unPublishedBillList) {
            // Things that reset for each triggered SB
            String parentID = trigsb.Opportunity_ID__c;          
            Decimal currentbill = trigsb.Bill_Number__c;
            Decimal previousbill = currentbill-1 ; 
            Decimal pastsixbills = 0;
            Decimal pasttwelvebills = 0;
              
                if (currentbill > 7) {
                    pastsixbills = currentbill-7;
                } else {
                    pastsixbills = 0;
                }

                if (currentbill > 13) {
                    pasttwelvebills = currentbill-13;
                } else {
                    pasttwelvebills = 0;
                }
                        
            Decimal overdue = 0;
            Decimal ppbalance = 0;
            Decimal twelveppbalance = 0;
            Decimal ytdbilled = 0;
            Decimal ytdpayments = 0;
            Decimal ytdProduction = 0;
            Boolean moreRecentBills = FALSE;
            Decimal dueThisMonth = trigsb.Discounted_Bill__c ;
            
            setAllNullsToZero(trigsb);

            if ( trigsb.Monthly_Late_Fee_Interest__c == NULL) {
                trigsb.Monthly_Late_Fee_Interest__c = 1;
            }

            for (System_Bill__c newerbills : listsystemBills) {
                if (newerbills.Opportunity_ID__c == parentID 
                    && newerbills.Bill_Number__c > currentbill ) {
                        moreRecentBills = TRUE;
                }
            }
            if (currentbill == 1) {
                trigsb.Due_This_Month__c = dueThisMonth;
                trigsb.Total_Due__c = dueThisMonth + trigsb.Adjustments__c + trigsb.Previous_Overpayments__c; 
                trigsb.Previous_Month_Overdue_Balance__c = 0 ;
                trigsb.Late_Fees__c = 0; 
                trigsb.Payment_Plan_Balance__c = 0;
                trigsb.Adjustments__c = trigsb.Adjustments_UASB__c;
            } else {
                for (System_Bill__c sbill: listsystemBills) {   
                    if ( sbill.Opportunity_ID__c == parentID ) {
                        if (sbill.Bill_Number__c == previousbill) {
                            pastbillamount = sbill.Total_Due__c;
                            pastbillpayment = sbill.Total_Payments_This_Month__c;
                            pastbilloverpayment = sbill.Carry_Forward_Payments__c;
                            pastbilloveradjust = sbill.Carry_Forward_Adjustments__c;
                            if (sbill.Distribute_This_Balance_as_Payment_Plan__c
                                || sbill.Distribute_This_Balance_12mo__c) {
                                carryoverbalance = 0;
                            } else {
                                carryoverbalance = sbill.Carry_Over_Balance__c;
                            }
                        } if ( sbill.Bill_Number__c < currentbill 
                              && sbill.Bill_Number__c > pastsixbills
                              && sbill.Distribute_This_Balance_as_Payment_Plan__c
                              && ppbalance == 0) {
                                ppbalance = sbill.Payment_Plan_Balance_to_Distribute__c / 6 ;
                        } if ( sbill.Bill_Number__c < currentbill 
                              && sbill.Bill_Number__c > pasttwelvebills
                              && sbill.Distribute_This_Balance_12mo__c
                              && ppbalance == 0) {
                                twelveppbalance = sbill.Payment_Plan_Balance_to_Distribute__c / 12 ;
                        } if ( sbill.Bill_Number__c <= currentbill 
                              && sbill.Bill_Number__c >= pasttwelvebills) {
                                ytdbilled = ytdbilled + sbill.Discounted_Bill__c + sbill.Late_Fees__c + sbill.Adjustments__c;
                                ytdpayments = ytdpayments + sbill.Total_Payments_This_Month__c;
                                ytdProduction = ytdProduction + sbill.Production_kWH__c;
                        } 
                    }      
                } 
                overdue = carryoverbalance.setScale(2);
                trigsb.Due_This_Month__c = dueThisMonth;
                trigsb.Previous_Month_Overdue_Balance__c = overdue;
                trigsb.Past_Bill_Amount__c = pastbillamount;
                trigsb.Past_Bill_Payment__c = pastbillpayment;
                trigsb.YTD_Billed__c = ytdbilled;
                trigsb.YTD_Payments__c = ytdpayments;
                trigsb.YTD_kWh_Production__c = ytdProduction;
                trigsb.Adjustments__c = 0;     
                if (ppbalance > 0) {
                    trigsb.Payment_Plan_Balance__c = ppbalance.setScale(2);
                } else if (twelveppbalance > 0) {
                    trigsb.Payment_Plan_Balance__c = twelveppbalance.setScale(2);
                }           
                if (!trigsb.Waive_Late_Fees__c && overdue > 0) { 
                    trigsb.Late_Fees__c = ((trigsb.Monthly_Late_Fee_Interest__c/100)*overdue).setScale(2);
                } else if (trigsb.Waive_Late_Fees__c) {
                    trigsb.Late_Fees__c = 0;
                }
                trigsb.Adjustments__c = trigsb.Adjustments_UASB__c; 
                trigsb.Total_Due__c = dueThisMonth + trigsb.Late_Fees__c + overdue + trigsb.Payment_Plan_Balance__c + trigsb.Adjustments__c + trigsb.Previous_Overpayments__c;
            }
            balanceCalculations(trigsb, moreRecentBills);
        }
    }

    private static void setAllNullsToZero(System_Bill__c trigsb){
        trigsb.Late_Payments__c = setNullToZero(trigsb.Late_Payments__c);
        trigsb.Total_Payments_This_Month__c = setNullToZero(trigsb.Total_Payments_This_Month__c);
        trigsb.Payments_Net_Previous_Balances__c = setNullToZero(trigsb.Payments_Net_Previous_Balances__c);
        trigsb.Carry_Over_Balance__c = setNullToZero(trigsb.Carry_Over_Balance__c);
        trigsb.Balance_Net_Late_Payments__c = setNullToZero(trigsb.Balance_Net_Late_Payments__c);
        trigsb.Late_Fee_Payments__c = setNullToZero(trigsb.Late_Fee_Payments__c);
        trigsb.Late_Fees__c = setNullToZero(trigsb.Late_Fees__c);
        trigsb.Adjustments__c = setNullToZero(trigsb.Adjustments__c);
        trigsb.Carry_Forward_Adjustments__c = setNullToZero(trigsb.Carry_Forward_Adjustments__c);
        trigsb.Carry_Forward_Payments__c = setNullToZero(trigsb.Carry_Forward_Payments__c);
        trigsb.Early_Payments__c = setNullToZero(trigsb.Early_Payments__c);
    }

    private static void doNotAllowUpdate (System_Bill__c trigsb, Map<Id,System_Bill__c> oldSBMap){
        trigsb.Due_This_Month__c = setNullToZero(oldSBMap.get(trigsb.Id).Due_This_Month__c);
        trigsb.Previous_Month_Overdue_Balance__c = setNullToZero(oldSBMap.get(trigsb.Id).Previous_Month_Overdue_Balance__c);
        trigsb.Late_Fees__c = setNullToZero(oldSBMap.get(trigsb.Id).Late_Fees__c);
        trigsb.Payment_Plan_Balance__c = setNullToZero(oldSBMap.get(trigsb.Id).Payment_Plan_Balance__c);
        trigsb.Adjustments__c = setNullToZero(oldSBMap.get(trigsb.Id).Adjustments__c);
        trigsb.Total_Due__c = setNullToZero(oldSBMap.get(trigsb.Id).Total_Due__c);
        // Previous Overpayments is not Writeable because it is a rollup field. Validation rule (cannot add/remove an
        // overpayment to a published system bill)

        setAllNullsToZero(trigsb);

        if (trigsb.Payment_Plan_Balance_to_Distribute__c == null){
            balanceCalculations(trigsb, false);
        } else {
            balanceCalculations(trigsb, true);
        }
    }

    private static void balanceCalculations (System_Bill__c trigsb, Boolean moreRecentBills) {
        Decimal newbalance = trigsb.Total_Due__c - trigsb.Total_Payments_This_Month__c;
        trigsb.Carry_Over_Balance__c = newbalance;
        if (trigsb.Distribute_This_Balance_as_Payment_Plan__c
            || trigsb.Distribute_This_Balance_12mo__c
            && !morerecentbills) {
                trigsb.Payment_Plan_Balance_to_Distribute__c = trigsb.Carry_Over_Balance__c;
        }
        trigsb.Balance_Net_Late_Payments__c  = trigsb.Due_This_Month__c + trigsb.Balance_Adjustment__c + trigsb.Previous_Overpayments__c - trigsb.Late_Payments__c - trigsb.Payments_Net_Previous_Balances__c;
    }

    private static Decimal setNullToZero (Decimal systemBillField) {
        if ( systemBillField == NULL) {
          return 0;
        } else {
          return systemBillField;
        }
    }   
  
}