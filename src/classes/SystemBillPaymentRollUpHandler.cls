/*************************************************************************************
 + * Created By:  Jordan Pentaleri 
 + * Description: When a Chargent Transaction is created via recurring, or is a one time payment and the 
 + * "Distributed amoung System Bills" checkbox is checked (signals that all updates from Form Assembly are complete)
 + * this class distributes the payment amount to all the related system bills. 
 + * Updates the oldest SBs first (bill number field) that have a balance
 + * Tested By: TestBillCreationandPayment3
 + *************************************************************************************/

public without sharing class   SystemBillPaymentRollUpHandler {
    public static void handleRecurringPayment (List<ChargentOrders__Transaction__c> newlycreatedTrans) {
        List<Id> recurringList = new List<Id >();
        for (ChargentOrders__Transaction__c trans: newlycreatedTrans) {
            if (trans.ChargentOrders__Recurring__c) {
                recurringList.add(trans.Id);
            } 
        }
        if (recurringList.size() > 0){
            SystemBillPaymentRollUpHandler.rollUpPayments(recurringList);
        }
    }

    public static void handleOneTimePayment(List<ChargentOrders__Transaction__c> chargentTransactions, 
                                            Map<Id, ChargentOrders__Transaction__c> oldTransMap) { 
        List<Id> triggeredtransactions = new List <Id> ();
        for (ChargentOrders__Transaction__c chotran : chargentTransactions) {  
            if ( !chotran.ChargentOrders__Recurring__c 
                && chotran.Distributed_Among_System_Bills__c
                && !oldTransMap.get(chotran.Id).Distributed_Among_System_Bills__c) {
                    triggeredtransactions.add(chotran.Id);
            }
        } 
        if (triggeredtransactions.size() > 0){
            SystemBillPaymentRollUpHandler.rollUpPayments(triggeredtransactions);
        }
    }
    
    public static void rollUpPayments(List<Id> triggeredtransactions) {
        DateTime systemBillCreatedDate;
        List<ChargentOrders__Transaction__c> queriedTransactions;
        Map<Id,Account> propaccountMap;
        List<System_Bill__c> systemBills;
        Map<Id,Account_Bill__c> accountBillMap;

        List<System_Bill__c> finalGroupedSystemBillsToUpdate = new List<System_Bill__c>();
        List<Account_Bill__c> finalAccountBillsToUpdate = new List<Account_Bill__c>();
        List<Bill_Adjustment__c> finalAdjustmentsToInsertList = new List<Bill_Adjustment__c>();

        SystemBillRepo sbRepo = new SystemBillRepo(triggeredtransactions);
        queriedTransactions = sbRepo.getTransactions();
        systemBills = sbRepo.getSystemBills();
        accountBillMap = sbRepo.getAccountBillMap();
        propaccountMap = sbRepo.getPropertyAccountMap();

        for (ChargentOrders__Transaction__c chTransaction : queriedTransactions) {
            List<System_Bill__c> groupedSystemBillsList = new List<System_Bill__c>();
            String parentID = chTransaction.ChargentOrders__Order__r.Account_Bill__r.Parent_Account__r.Id;  
            String entityId = chTransaction.ChargentOrders__Order__r.Entity__c;
            Decimal payment = chTransaction.ChargentOrders__Amount__c;
            Integer accountBillNumber = (Integer) chTransaction.ChargentOrders__Order__r.Account_Bill__r.Bill_Number__c;
            Decimal maxbillnumber = 0;

            systemBillCreatedDate = chTransaction.createdDate;
            Date dateOfLastPayment = date.newinstance(system.today().year(), system.today().month(), system.today().day());

            for (System_Bill__c sbill : systemBills) {
                if (sbill.Account_Bill__r.Parent_Account__r.Id == parentID
                    && sbill.Shared_Solar_System__r.BWC_Project_Entity_Manual__r.Id == entityId) {
                        groupedSystemBillsList.add(sbill);
                        maxbillnumber = sbill.Account_Bill_Number__c;
                }
            } 
            listObject objectList = distributePaymentToSBs( groupedSystemBillsList, 
                                                            sbRepo.getLateFees(),
                                                            accountBillMap, 
                                                            payment, 
                                                            maxbillnumber, 
                                                            dateOfLastPayment, 
                                                            chTransaction.Id);
            finalGroupedSystemBillsToUpdate.addAll(objectList.listOne);
            finalAccountBillsToUpdate.addAll(objectList.listTwo);
            finalAdjustmentsToInsertList.addAll(objectList.listThree);
            propaccountMap.get(parentID).Date_of_Last_Payment__c = dateOfLastPayment; 
        }
        if (finalGroupedSystemBillsToUpdate.size() > 0) {
            update finalGroupedSystemBillsToUpdate;
        }
        if (finalAdjustmentsToInsertList.size() > 0) {
            insert finalAdjustmentsToInsertList;
        }
        if (finalAccountBillsToUpdate.size() > 0) {
            update finalAccountBillsToUpdate;
        }
        update propaccountMap.values();
    }

    public static Decimal checkForLateFees (System_Bill__c systemBill, List<LateFee> lateFeeList) {
        Decimal newLateFeePayment = 0;
        for (LateFee lateFee : lateFeeList) {
            if (lateFee.opportunityId == systemBill.Opportunity__r.Id){
                newLateFeePayment = lateFee.totalLateFees - latefee.totalLateFeePayments;
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
                                                        List<LateFee> lateFeeList,
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
            if (balanceOnBill > 0 && bills.Account_Bill_Number__c < maxbillnumber) {
                if (payment >= balanceOnBill)  {
                    bills.Late_Payments__c = bills.Late_Payments__c + balanceOnBill; 
                    addToPaymentsMap(bills.Opportunity__r.Id, balanceOnBill, paymentsmap);
                    payment = payment - balanceOnBill;
                } else if (payment < balanceOnBill) { 
                    bills.Late_Payments__c = bills.Late_Payments__c + payment; 
                    addToPaymentsMap(bills.Opportunity__r.Id, payment, paymentsmap);
                    payment = 0;
                } 
                groupedSystemBillstoUpdate.add(bills);
            }
            // ** if there's anything left, pay off this month's bill
            if (bills.Account_Bill_Number__c == maxbillnumber) {
                if (payment >= balanceOnBill && balanceOnBill > 0) {
                    bills.Payments_Net_Previous_Balances__c = bills.Payments_Net_Previous_Balances__c + balanceOnBill;
                    addToPaymentsMap(bills.Opportunity__r.Id, balanceOnBill, paymentsmap);
                    payment = payment - balanceOnBill;
                } else if (payment < balanceOnBill) {
                    bills.Payments_Net_Previous_Balances__c = bills.Payments_Net_Previous_Balances__c + payment;
                    addToPaymentsMap(bills.Opportunity__r.Id, payment, paymentsmap);
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
                        addToPaymentsMap(maxbills.Opportunity__r.Id, lateFeesToPay, paymentsmap);
                        payment = payment - lateFeesToPay;
                    } else {
                        maxBills.Late_Fee_Payments__c = payment; 
                        addToPaymentsMap(maxbills.Opportunity__r.Id, payment, paymentsmap);
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
                                                                    Entity__c = maxSB.Shared_Solar_System__r.BWC_Project_Entity_Manual__r.Id,
                                                                    Source_ID__c = transactionId,
                                                                    Reason_For_Adjustment__c = 'Overpayment');
                adjustmentsToInsertList.add(adjust);
                accountBillMap.get(maxSB.Account_Bill__c).Overpayment_Amount__c = accountBillMap.get(maxSB.Account_Bill__c).Overpayment_Amount__c + payment;
                accountBillsToUpdate.add(accountBillMap.get(maxSB.Account_Bill__c));
                payment = 0;
            }
            if (paymentsmap.containsKey(maxSB.Opportunity__r.Id)) {
                maxSB.Total_Payments_This_Month__c =  maxSB.Total_Payments_This_Month__c + paymentsmap.get(maxSB.Opportunity__r.Id);
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

    private class SystemBillRepo {
        private List<ChargentOrders__Transaction__c> transactionList;
        private List<System_Bill__c> systemBills;
        private Map<Id, Account> propertyAccountMap;
        private Map<Id,Account_Bill__c> accountBillMap;
        private Map<Id, LateFee> lateFeeMap;

        SystemBillRepo(List<Id> transactions) {
            transactionList = [
                SELECT Id, Name, ChargentOrders__Response_Status__c, Entity_ID__c, ChargentOrders__Amount__c, CreatedDate,
                    Distributed_Among_System_Bills__c, ChargentOrders__Recurring__c,
                    ChargentOrders__Order__r.Account_Bill__r.Parent_Account__r.Id,
                    ChargentOrders__Order__r.Account_Bill__r.Parent_Account__r.Date_of_Last_Payment__c,
                    ChargentOrders__Order__r.Account_Bill__r.Bill_Number__c,
                    ChargentOrders__Order__r.Entity__c
                FROM ChargentOrders__Transaction__c
                WHERE Id IN :transactions
                AND ChargentOrders__Response_Status__c = 'Approved'];

            propertyAccountMap = new Map<Id, Account>();
            for (ChargentOrders__Transaction__c trx : transactionList) {
                Account propertyAccount = new Account(
                    Id = trx.ChargentOrders__Order__r.Account_Bill__r.Parent_Account__r.Id,
                    Date_of_Last_Payment__c = trx.ChargentOrders__Order__r.Account_Bill__r.Parent_Account__r.Date_of_Last_Payment__c
                );
                propertyAccountMap.put(propertyAccount.Id, propertyAccount);
            }

            systemBills = [
                SELECT Id, Total_Payments_This_Month__c, Late_Payments__c, Payments_Net_Previous_Balances__c,
                    Late_Fee_Payments__c, Balance_Net_Late_Payments__c, Total_Due__c, Shared_Solar_System_ID__c,
                    Entity_ID__c, Opportunity_Id__c, Account_Bill__c, Account_Bill_Number__c, Early_Payments__c,
                    Carry_Forward_Payments__c, Opportunity__r.Id, Opportunity__c, Late_Fees__c,
                    Shared_Solar_System__r.BWC_Project_Entity_Manual__r.Id,
                    Account_Bill__r.Name, Account_Bill__r.Overpayment_Amount__c,
                    Account_Bill__r.Parent_Account__r.Id, Account_Bill__r.Parent_Account__r.Date_of_Last_Payment__c
                FROM System_Bill__c
                WHERE Account_Bill__r.Parent_Account__r.Id IN :propertyAccountMap.keySet()
                ORDER BY Account_Bill_Number__c];

            accountBillMap = new Map<Id, Account_Bill__c>();
            lateFeeMap = new Map<Id, LateFee>();
            for (System_Bill__c systemBill : systemBills) {
                if (accountBillMap.get(systemBill.Account_Bill__c) == null) {
                    Account_Bill__c accountBill = new Account_Bill__c(
                        Id = systemBill.Account_Bill__c,
                        Overpayment_Amount__c = systemBill.Account_Bill__r.Overpayment_Amount__c
                    );
                    accountBillMap.put(accountBill.Id, accountBill);
                }

                if (lateFeeMap.containsKey(systemBill.Opportunity__c)) {
                    lateFeeMap.get(systemBill.Opportunity__c).totalLateFees += systemBill.Late_Fees__c;
                    lateFeeMap.get(systemBill.Opportunity__c).totalLateFeePayments += systemBill.Late_Fee_Payments__c;
                } else {
                    LateFee lateFee = new LateFee(
                        systemBill.Opportunity__c,
                        systemBill.Late_Fees__c,
                        systemBill.Late_Fee_Payments__c
                    );
                    lateFeeMap.put(systemBill.Opportunity__c, lateFee);
                }
            }
        }

        public List<ChargentOrders__Transaction__c> getTransactions() {
            return transactionList;
        }

        public List<System_Bill__c> getSystemBills() {
            return systemBills;
        }

        public Map<Id, Account_Bill__c> getAccountBillMap() {
            return accountBillMap;
        }

        public List<LateFee> getLateFees() {
            return lateFeeMap.values();
        }

        public Map<Id, Account> getPropertyAccountMap() {
            return propertyAccountMap;
        }
    }

    private class LateFee {
        Id opportunityId;
        Decimal totalLateFees;
        Decimal totalLateFeePayments;

        public LateFee(Id oppId, Decimal totalLateFees, Decimal totalLateFeePayments) {
            this.opportunityId = oppId;
            this.totalLateFees = totalLateFees;
            this.totalLateFeePayments = totalLateFeePayments;
        }
    }
}