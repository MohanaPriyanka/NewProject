/*************************************************************************************
 + * Created By:  Jordan Pentaleri 
 + * Description: When a Chargent Transaction is created via recurring, or is a one time payment and the 
 + * "Distributed amoung System Bills" checkbox is checked (signals that all updates from Form Assembly are complete)
 + * this class distributes the payment amount to all the related system bills. 
 + * Updates the oldest SBs first (bill number field) that have a balance
 + * Tested By: TestBillCreationandPayment3
 + *************************************************************************************/

public with sharing class SystemBillPaymentRollUpHandler {
    public static void handleRecurringPayment (List<ChargentOrders__Transaction__c> newlycreatedTrans) {
        List <ChargentOrders__Transaction__c> recurringList = new List <ChargentOrders__Transaction__c >();
        for (ChargentOrders__Transaction__c trans: newlycreatedTrans) {
            if (trans.ChargentOrders__Recurring__c) {
                trans.Distributed_Among_System_Bills__c = FALSE;
                recurringList.add(trans);
            } 
        }
        SystemBillPaymentRollUpHandler.rollUpPayments(recurringList);
    }

    public static void handleOneTimePayment(List<ChargentOrders__Transaction__c> chargentTransactions, 
                                            Map<Id, ChargentOrders__Transaction__c> oldTransMap) { 
        List <ChargentOrders__Transaction__c> triggeredtransactions = new List <ChargentOrders__Transaction__c> ();
        for(ChargentOrders__Transaction__c chotran : chargentTransactions) {  
            if( !chotran.ChargentOrders__Recurring__c 
                && chotran.Distributed_Among_System_Bills__c
                && !oldTransMap.get(chotran.Id).Distributed_Among_System_Bills__c) {
                    triggeredtransactions.add(chotran);
            }
        } 
        SystemBillPaymentRollUpHandler.rollUpPayments(triggeredtransactions);
    }
    
    public static void rollUpPayments(List<ChargentOrders__Transaction__c> triggeredtransactions) {
        DateTime systemBillCreatedDate; 
        List <Id> chargentOrderIdsList = new List <Id>();
        List <String> propertyaccountIdsstring = new List <String>();
        Map <Id,Account> propaccountMap = new Map <Id,Account>();
        Map <Id,Account_Bill__c> accountBillMap = new Map <Id,Account_Bill__c>();

        List<System_Bill__c> finalGroupedSystemBillsToUpdate = new List<System_Bill__c>();
        List<Account_Bill__c> finalAccountBillsToUpdate = new List<Account_Bill__c>();
        List<Bill_Adjustment__c> finalAdjustmentsToInsertList = new List<Bill_Adjustment__c>();

        for(ChargentOrders__Transaction__c trigtran : triggeredtransactions) {
            if(trigtran.Account_Bill_Id__c != NULL && trigtran.ChargentOrders__Response_Status__c == 'Approved') {    
                chargentOrderIdsList.add(trigtran.ChargentOrders__Order__c);
                propertyaccountIdsstring.add(trigtran.Property_Account_ID__c);
            }  
        }

        if(!chargentOrderIdsList.isEmpty()) {
            List<System_Bill__c> systemBills = [SELECT Id, Total_Payments_This_Month__c, Late_Payments__c, Payments_Net_Previous_Balances__c, 
                                                      Late_Fee_Payments__c, Balance_Net_Late_Payments__c, Total_Due__c, Account_Bill__r.Name,
                                                      Shared_Solar_System_ID__c, Entity_ID__c, Opportunity_Id__c, Account_Bill__c,
                                                      Bill_Number__c, Property_Account_ID__c, Early_Payments__c, Carry_Forward_Payments__c
                                                FROM System_Bill__c
                                                WHERE Property_Account_ID__c IN : propertyaccountIdsstring 
                                                ORDER BY Bill_Number__c];

            List<Account> propertyaccounts = [ SELECT Id, Date_of_last_Payment__c
                                                FROM Account
                                                WHERE Id IN : propertyaccountIdsstring];

            for ( Account_Bill__c accountBill : [   SELECT Id, Overpayment_Amount__c
                                                    FROM Account_Bill__c
                                                    WHERE Property_Account_ID__c IN : propertyaccountIdsstring] ) {
                accountBillMap.put(String.valueOf(accountBill.Id).substring(0,15), accountBill);
            }

            List<AggregateResult> lateFeeList = [   SELECT Opportunity__c oppId, SUM(Late_Fees__c) totalLateFees, SUM(Late_Fee_Payments__c) totalLateFeePayments
                                                    FROM System_Bill__c
                                                    WHERE Property_Account_ID__c IN : propertyaccountIdsstring 
                                                    GROUP BY Opportunity__c];

            for (Account prop : propertyaccounts) {
                propaccountMap.put(prop.Id, prop);
            }
            for(ChargentOrders__Transaction__c chTransaction: triggeredtransactions) {
                List<System_Bill__c> groupedSystemBillsList = new List <System_Bill__c>();
                if(chTransaction.Account_Bill_ID__c != NULL && chtransaction.ChargentOrders__Response_Status__c == 'Approved') {
                    String parentID = chTransaction.Property_Account_ID__c;  
                    String entityId = chTransaction.Entity_ID__c;
                    Decimal payment = chTransaction.ChargentOrders__Amount__c;
                    Decimal maxbillnumber = 0;

                    systemBillCreatedDate = chTransaction.createdDate;
                    Date dateOfLastPayment = date.newinstance(system.today().year(), system.today().month(), system.today().day());

                    for (System_Bill__c sbill : systemBills) {
                        if (sbill.Property_Account_ID__c == parentID && sbill.Entity_ID__c == entityId) {
                            groupedSystemBillsList.add(sbill);
                            maxbillnumber = sbill.Bill_Number__c;
                            system.debug(maxbillnumber);
                        }
                    } 
                    listObject objectList = distributePaymentToSBs(groupedSystemBillsList, lateFeeList, accountBillMap, payment, maxbillnumber, dateOfLastPayment, chTransaction.Id);
                    finalGroupedSystemBillsToUpdate.addAll(objectList.listOne);
                    finalAccountBillsToUpdate.addAll(objectList.listTwo);
                    finalAdjustmentsToInsertList.addAll(objectList.listThree);
                    if(!chTransaction.Distributed_Among_System_Bills__c) {
                        chTransaction.Distributed_Among_System_Bills__c = TRUE;
                    } 
                    propaccountMap.get(chTransaction.Property_Account_ID__c).Date_of_Last_Payment__c = dateOfLastPayment; 
                }
            } 
            if ( finalGroupedSystemBillsToUpdate.size() > 0) {
                update finalGroupedSystemBillsToUpdate;
            }
            if ( finalAdjustmentsToInsertList.size() > 0) {
                insert finalAdjustmentsToInsertList;
            }
            if ( finalAccountBillsToUpdate.size() > 0) {
                update finalAccountBillsToUpdate;
            }
            update propaccountMap.values();   
        }
    }

    public static Decimal checkForLateFees (System_Bill__c systemBill, List<AggregateResult> lateFeeList) {   
        Decimal newLateFeePayment = 0;
        for (AggregateResult lateFee : lateFeeList) {
            if (lateFee.get('oppId') == systemBill.Opportunity_Id__c){
                newLateFeePayment = (Decimal)lateFee.get('totalLateFees') - (Decimal)latefee.get('totalLateFeePayments');
                if (newLateFeePayment > 0) {
                    return newLateFeePayment;
                } else {
                    newLateFeePayment = 0;
                }
            } else {
                newLateFeePayment = 0; 
            } 
        }
        return newLateFeePayment;
    }   

    public static void addToPaymentsMap (String oppId, Decimal payment, Map<String, Decimal> paymentsMap ) {   
        if (paymentsMap.containsKey(oppId)) {
            paymentsMap.put(oppId, paymentsMap.get(oppId) + payment);
        } else {
            paymentsMap.put(oppId, payment);
        }
    }   

    public class listObject {
        public List<System_Bill__c> listOne;
        public List<Account_Bill__c> listTwo;
        public List<Bill_Adjustment__c> listThree;
    }

    public static listObject distributePaymentToSBs (  List<System_Bill__c> groupedSystemBillsList, 
                                                        List<AggregateResult> lateFeeList, 
                                                        Map<Id,Account_Bill__c> accountBillMap, 
                                                        Decimal payment, 
                                                        Decimal maxbillnumber, 
                                                        Date dateOfLastPayment, 
                                                        String transactionId) {
        List<System_Bill__c> groupedSystemBillsToUpdate = new List <System_Bill__c>();
        List<System_Bill__c> maxbillnumberlist = new List <System_Bill__c>();
        Map<String, Decimal> paymentsmap = new Map <String,Decimal>();
        List<Bill_Adjustment__c> adjustmentsToInsertList = new List<Bill_Adjustment__c>();
        List<Account_Bill__c> accountBillsToUpdate = new List<Account_Bill__c>();

        for (System_Bill__c bills : groupedSystemBillsList) {
            Decimal balanceOnBill = bills.Balance_Net_Late_Payments__c.setScale(2);
            // ** pay off late bills first
            if (balanceOnBill > 0 && bills.Bill_Number__c < maxbillnumber) {
                if (payment >= balanceOnBill)  {
                    bills.Late_Payments__c = bills.Late_Payments__c + balanceOnBill; 
                    addToPaymentsMap(bills.Opportunity_Id__c, balanceOnBill, paymentsmap);
                    payment = payment - balanceOnBill;
                } else if(payment < balanceOnBill) { 
                    bills.Late_Payments__c = bills.Late_Payments__c + payment; 
                    addToPaymentsMap(bills.Opportunity_Id__c, payment, paymentsmap);
                    payment = 0;
                } 
                groupedSystemBillstoUpdate.add(bills);
            }
            // ** if there's anything left, pay off this month's bill
            if (bills.Bill_Number__c == maxbillnumber) {
                if (payment >= balanceOnBill && balanceOnBill > 0) {
                    bills.Payments_Net_Previous_Balances__c = bills.Payments_Net_Previous_Balances__c + balanceOnBill;
                    addToPaymentsMap(bills.Opportunity_Id__c, balanceOnBill, paymentsmap);
                    payment = payment - balanceOnBill;
                } else if(payment < balanceOnBill) {
                    bills.Payments_Net_Previous_Balances__c = bills.Payments_Net_Previous_Balances__c + payment;
                    addToPaymentsMap(bills.Opportunity_Id__c, payment, paymentsmap);
                    payment = 0;
                }
                maxbillnumberlist.add(bills);
            } 
        }
        if (payment > 0){ 
            for (System_Bill__c maxbills : maxbillnumberlist) {
                Decimal lateFeesToPay = checkForLateFees(maxbills, lateFeeList);
                if (payment > 0 && lateFeesToPay > 0){ 
                    // ** if there's anything left, pay off late fees
                    if (payment > lateFeesToPay) {
                        maxBills.Late_Fee_Payments__c = maxBills.Late_Fee_Payments__c + lateFeestoPay; 
                        addToPaymentsMap(maxbills.Opportunity_Id__c, lateFeesToPay, paymentsmap);
                        payment = payment - lateFeesToPay;
                    } else {
                        maxBills.Late_Fee_Payments__c = payment; 
                        addToPaymentsMap(maxbills.Opportunity_Id__c, payment, paymentsmap);
                        payment = 0;
                    }
                }
            }
        }
        for (System_Bill__c maxSB : maxbillnumberlist) {
            if (payment > 0){ 
                // ** if there's anything left, create an Overpayment Adjustment 
                Bill_Adjustment__c adjust = new Bill_Adjustment__c( Name = 'Overpayment: ' + maxSB.Account_Bill__r.Name + ' ' + dateOfLastPayment.format(),
                                                                    Adjustment_Amount__c = -1 * payment,
                                                                    Account_Bill__c = maxSB.Account_Bill__c,
                                                                    Overpayment__c = TRUE,
                                                                    Entity__c = maxSB.Entity_ID__c,
                                                                    Source_ID__c = transactionId);
                adjustmentsToInsertList.add(adjust);
                accountBillMap.get(maxSB.Account_Bill__c).Overpayment_Amount__c = accountBillMap.get(maxSB.Account_Bill__c).Overpayment_Amount__c + payment;
                accountBillsToUpdate.add(accountBillMap.get(maxSB.Account_Bill__c));
                payment = 0;
            }
            if (paymentsmap.containsKey(maxSB.Opportunity_Id__c)) {
                maxSB.Total_Payments_This_Month__c =  maxSB.Total_Payments_This_Month__c + paymentsmap.get(maxSB.Opportunity_Id__c);
                maxSB.Date_of_Last_Payment__c = dateOfLastPayment; 
            }
            groupedSystemBillstoUpdate.add(maxSB); 
        }
        listObject lists = new listObject();
        Lists.listOne = groupedSystemBillstoUpdate;
        Lists.listTwo = accountBillsToUpdate;
        Lists.listThree = adjustmentsToInsertList;
        return lists;
    }
}