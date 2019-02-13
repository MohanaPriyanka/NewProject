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

public without sharing class SystemBillAccountingLogicHandler {
    public static void accountingRefresh (List <System_Bill__c> systemBill, Map<Id, System_Bill__c> oldSBMap) {
        Decimal carryoverbalance = 0;  
        Decimal pastbillamount = 0;
        Decimal pastbillpayment = 0;
        List<Id> propertyAccountIDs = new List<Id>();
        List<System_Bill__c> unPublishedBillList = new List<System_Bill__c>();

        for (System_Bill__c sbill : systemBill) {
            if (sbill.Published__c){
                setAllNullsToZero(sbill);
                if (sbill.Payment_Plan_Balance_to_Distribute__c == null) {
                    balanceCalculations(sbill, false);
                } else {
                    balanceCalculations(sbill, true);
                }
            } else {
                propertyAccountIDs.add(sbill.Property_Account__c);
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
                                                    Due_This_Month__c,
                                                    Payment_Plan_Balance__c, Total_Due__c, 
                                                    Distribute_This_Balance_as_Payment_Plan__c,
                                                    Payment_Plan_Balance_to_Distribute__c, 
                                                    Savings__c, Opportunity__c,
                                                    Production_kWH__c,
                                                    Entity_ID__c
                                                FROM System_Bill__c
                                                WHERE Property_Account__c
                                                IN : propertyAccountIDs
                                                ORDER BY Bill_Number__c DESC];
        for (System_Bill__c trigsb : unPublishedBillList) {
            // Things that reset for each triggered SB
            String parentID = trigsb.Opportunity__c;
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
            Decimal paymentPlanToDistribute = 0;
            Integer paymentPlanStartingBill = 0;
            Integer paymentPlanDistributions = 0;
            Decimal ytdProduction = 0;
            Boolean moreRecentBills = FALSE;
            Decimal dueThisMonth = trigsb.Discounted_Bill__c ;
            
            setAllNullsToZero(trigsb);

            if ( trigsb.Monthly_Late_Fee_Interest__c == NULL) {
                trigsb.Monthly_Late_Fee_Interest__c = 1;
            }

            for (System_Bill__c newerbills : listsystemBills) {
                if (newerbills.Opportunity__c == parentID
                    && newerbills.Bill_Number__c > currentbill ) {
                        moreRecentBills = TRUE;
                }
            }
            if (currentbill == 1) {
                trigsb.Due_This_Month__c = dueThisMonth;
                trigsb.Total_Due__c = dueThisMonth + trigsb.Adjustments__c + trigsb.Previous_Overpayment__c;
                trigsb.Previous_Month_Overdue_Balance__c = 0 ;
                trigsb.Late_Fees__c = 0; 
                trigsb.Payment_Plan_Balance__c = 0;
                trigsb.Adjustments__c = trigsb.Adjustments_UASB__c;
            } else {
                for (System_Bill__c sbill: listsystemBills) {
                    if ( sbill.Opportunity__c == parentID ) {
                        if (sbill.Bill_Number__c == previousbill) {
                            pastbillamount = sbill.Total_Due__c;
                            pastbillpayment = sbill.Total_Payments_This_Month__c;
                            if (sbill.Distribute_This_Balance_as_Payment_Plan__c
                                || sbill.Distribute_This_Balance_12mo__c) {
                                carryoverbalance = 0;
                            } else {
                                carryoverbalance = sbill.Carry_Over_Balance__c;
                            }
                        }
                        if ( sbill.Bill_Number__c < currentbill
                              && sbill.Bill_Number__c > pastsixbills
                              && sbill.Distribute_This_Balance_as_Payment_Plan__c
                              && paymentPlanToDistribute == 0) {
                            paymentPlanToDistribute = sbill.Payment_Plan_Balance_to_Distribute__c;
                            paymentPlanStartingBill = (Integer) sbill.Bill_Number__c;
                            paymentPlanDistributions = 6;
                        }
                        if ( sbill.Bill_Number__c < currentbill
                              && sbill.Bill_Number__c > pasttwelvebills
                              && sbill.Distribute_This_Balance_12mo__c
                              && paymentPlanToDistribute == 0) {
                            paymentPlanToDistribute = sbill.Payment_Plan_Balance_to_Distribute__c;
                            paymentPlanStartingBill = (Integer) sbill.Bill_Number__c;
                            paymentPlanDistributions = 12;
                        }
                        if ( sbill.Bill_Number__c <= currentbill
                              && sbill.Bill_Number__c >= pasttwelvebills) {
                                ytdProduction = ytdProduction + sbill.Production_kWH__c;
                        } 
                    }      
                } 
                overdue = carryoverbalance.setScale(2);
                trigsb.Due_This_Month__c = dueThisMonth;
                trigsb.Previous_Month_Overdue_Balance__c = overdue;
                trigsb.Past_Bill_Payment__c = pastbillpayment;
                trigsb.YTD_kWh_Production__c = ytdProduction;
                trigsb.Adjustments__c = 0;
                trigsb.Payment_Plan_Balance__c = calculatePaymentPlanBalance(
                    (Integer) currentbill - paymentPlanStartingBill,
                    paymentPlanDistributions,
                    paymentPlanToDistribute
                );
                if (!trigsb.Waive_Late_Fees__c && overdue > 0) {
                    trigsb.Late_Fees__c = ((trigsb.Monthly_Late_Fee_Interest__c/100)*overdue).setScale(2);
                } else if (trigsb.Waive_Late_Fees__c) {
                    trigsb.Late_Fees__c = 0;
                }
                trigsb.Adjustments__c = trigsb.Adjustments_UASB__c;
                trigsb.Total_Due__c = dueThisMonth + trigsb.Late_Fees__c + overdue + trigsb.Payment_Plan_Balance__c + trigsb.Adjustments__c + trigsb.Previous_Overpayment__c;
            }
            balanceCalculations(trigsb, moreRecentBills);
        }
    }

    @TestVisible
    private static Decimal calculatePaymentPlanBalance(Integer distributionNumber, Integer numberOfDistributions, Decimal amountToDistribute) {
        if (distributionNumber <= 0 ||
            distributionNumber > numberOfDistributions ||
            numberOfDistributions <= 0 ||
            amountToDistribute <= 0) {
            return 0;
        }

        Decimal defaultDistribution = ((Decimal) amountToDistribute / numberOfDistributions).setScale(2);

        if (distributionNumber == numberOfDistributions) {
            Decimal amountAlreadyDistributed = defaultDistribution * (numberOfDistributions-1);
            return amountToDistribute.setScale(2) - amountAlreadyDistributed;
        } else {
            return defaultDistribution;
        }
    }

    private static void setAllNullsToZero(System_Bill__c trigsb){
        trigsb.Late_Payments__c = Util.nullToZero(trigsb.Late_Payments__c);
        trigsb.Total_Payments_This_Month__c = Util.nullToZero(trigsb.Total_Payments_This_Month__c);
        trigsb.Payments_Net_Previous_Balances__c = Util.nullToZero(trigsb.Payments_Net_Previous_Balances__c);
        trigsb.Carry_Over_Balance__c = Util.nullToZero(trigsb.Carry_Over_Balance__c);
        trigsb.Balance_Net_Late_Payments__c = Util.nullToZero(trigsb.Balance_Net_Late_Payments__c);
        trigsb.Late_Fee_Payments__c = Util.nullToZero(trigsb.Late_Fee_Payments__c);
        trigsb.Late_Fees__c = Util.nullToZero(trigsb.Late_Fees__c);
        trigsb.Adjustments__c = Util.nullToZero(trigsb.Adjustments__c);
    }

    private static void balanceCalculations (System_Bill__c trigsb, Boolean moreRecentBills) {
        Decimal newbalance = trigsb.Total_Due__c - trigsb.Total_Payments_This_Month__c;
        trigsb.Carry_Over_Balance__c = newbalance;
        if (trigsb.Distribute_This_Balance_as_Payment_Plan__c
            || trigsb.Distribute_This_Balance_12mo__c
            && !morerecentbills) {
                trigsb.Payment_Plan_Balance_to_Distribute__c = trigsb.Carry_Over_Balance__c;
        }
        trigsb.Balance_Net_Late_Payments__c  = trigsb.Due_This_Month__c + trigsb.Balance_Adjustment__c + trigsb.Previous_Overpayment__c - trigsb.Late_Payments__c - trigsb.Payments_Net_Previous_Balances__c;
    }
}