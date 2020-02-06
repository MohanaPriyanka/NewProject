/**
 * Created by mstackhouse on 10/1/2018.
 * Description: Provides a method for reversing transactions that have been returned due to an ACH issue. Implemented as a button
 * on the transaction page and has validations to make sure there isn't another system bill published.
 * Test: CSPaymentTest
 */


public without sharing class ReturnedTransactionHandler {
    public Map<Id, System_Bill__c> finalGroupedSystemBillsToUpdate = new Map<Id, System_Bill__c>();
    public Map<Id, Overpayment__c> finalOverpaymentsToModifyList = new Map<Id, Overpayment__c>();
    public Map<Id,Account> propaccountMap;
    public List<Bill_Adjustment__c> billAdjustmentsToInsert = new List<Bill_Adjustment__c>();
    public Set<Account> propAccountsToUpdate = new Set<Account>();
    public List<ChargentOrders__Transaction__c> transactionsToUpdate = new List<ChargentOrders__Transaction__c>();
    public List<ChargentOrders__Transaction__c> reverseTransactions = new List<ChargentOrders__Transaction__c>();
    public List<Overpayment__c> overpayList;
    public List<Case> caseList = new List<Case>();

    public void unrollPayment(Set<Id> transactionIds) {
        List<ChargentOrders__Transaction__c> chTransactions;
        List<System_Bill__c> systemBills;
        Datetime lastSystemBillDate;

        SystemBillPaymentRollUpHandler.SystemBillRepo sbRepo = new SystemBillPaymentRollUpHandler.SystemBillRepo(
            new List<Id>(transactionIds)
        );

        chTransactions = sbRepo.getTransactions();
        systemBills = sbRepo.getSystemBills();
        propaccountMap = sbRepo.getPropertyAccountMap();
        getOverpayments(chTransactions);

        if (chTransactions.size() != transactionIds.size() && transactionIds.size() != 1) {
            throw new Util.BWException('One or more transactions cannot be marked for return.');
        } else if (sbRepo.getTransactions().size() != transactionIds.size()) {
            throw new Util.BWException('Transaction cannot be marked for return.');
        }

        Date dateOfLastPayment = Date.newInstance(System.today().year(), System.today().month(), System.today().day());

        for (ChargentOrders__Transaction__c chTransaction : chTransactions) {
            List<System_Bill__c> groupedSystemBillsList = new List<System_Bill__c>();
            String parentID = chTransaction.ChargentOrders__Order__r.Account_Bill__r.Parent_Account__r.Id;
            String entityId = chTransaction.ChargentOrders__Order__r.Entity__c;
            Decimal payment = chTransaction.ChargentOrders__Amount__c;
            Decimal maxbillnumber = 0;

            for (System_Bill__c sbill : systemBills) {
                // if we've previously updated the system bill, we should use that version instead
                if (finalGroupedSystemBillsToUpdate.containsKey(sbill.Id)) {
                    sbill = finalGroupedSystemBillsToUpdate.get(sbill.Id);
                }

                if (sbill.Account_Bill__r.Parent_Account__r.Id == parentID
                    && sbill.Shared_Solar_System__r.BWC_Project_Entity_Manual__r.Id == entityId) {
                    //add the system bills in reverse order so newest is first
                    if (groupedSystemBillsList.isEmpty()) {
                        groupedSystemBillsList.add(sbill);
                        maxbillnumber = sbill.Account_Bill_Number__c;
                        lastSystemBillDate = sbill.Date__c;
                    } else {
                        groupedSystemBillsList.add(0, sbill);
                        maxbillnumber = sbill.Account_Bill_Number__c;
                        lastSystemBillDate = sbill.Date__c;
                    }
                }
            }

            chTransaction.ChargentOrders__Response_Status__c = 'Returned';
            Datetime chCreatedDatetime = chTransaction.CreatedDate;
            Date chCreatedDate = Date.newInstance(chCreatedDatetime.year(), chCreatedDatetime.month(), chCreatedDatetime.day());
            if (lastSystemBillDate < chCreatedDate) {
                SystemBillPaymentRollUpHandler.listObject objectList = removePaymentFromSBs( groupedSystemBillsList,
                    payment,
                    maxbillnumber,
                    dateOfLastPayment,
                    chTransaction);
                finalGroupedSystemBillsToUpdate.putAll(objectList.systemBills);

                Account propertyAccount = propaccountMap.get(parentID);
                propertyAccount.Date_of_Last_Payment__c = dateOfLastPayment;
                propAccountsToUpdate.add(propertyAccount);
            } else {
                Bill_Adjustment__c adjust = new Bill_Adjustment__c( Name = 'Returned Payment: ' + groupedSystemBillsList[0].Account_Bill__r.Name + ' ' + dateOfLastPayment.format(),
                    Adjustment_Amount__c = payment,
                    Utility_Account_Subscription__c = groupedSystemBillsList[0].Utility_Account_Subscription_Bills__r[0].Utility_Account_Subscription__c,
                    Source_ID__c = chTransaction.Id,
                    Approval_Status__c = 'Approved',
                    Adjustment_Type__c = 'Returned Payment',
                    Reason_For_Adjustment__c = 'Payment was Marked as Returned after new Bills have been Published'
                );
                billAdjustmentsToInsert.add(adjust);
            }
            transactionsToUpdate.add(chTransaction);
            createReverseTransaction(chTransaction);
            createCaseForTransaction(chTransaction);
        }
    }

    public SystemBillPaymentRollUpHandler.listObject removePaymentFromSBs (  List<System_Bill__c> groupedSystemBillsList,
        Decimal payment,
        Decimal maxbillnumber,
        Date dateOfLastPayment,
        ChargentOrders__Transaction__c chTransaction) {

        List<System_Bill__c> groupedSystemBillsToUpdate = new List <System_Bill__c>();
        Map<Id, Decimal> reversedPaymentsToSSSThisMonth = new Map<Id, Decimal>();

        Id entityId = chTransaction.ChargentOrders__Order__r.Entity__c;
        Id accountBillId = chTransaction.ChargentOrders__Order__r.Account_Bill__c;

        // reduce overpayments by reversed payment amount
        Decimal entityOverpayments = getOverpaymentAmount(entityId, accountBillId);
        Decimal overpaymentDeductionTotal = Math.min(payment, entityOverpayments);
        payment -= overpaymentDeductionTotal;
        if (overpaymentDeductionTotal > 0) {
            for (Overpayment__c overpayToModify : overpayList){
                if (overpayToModify.Entity__c == entityId && overpayToModify.Account_Bill__c == accountBillId) {
                    Decimal overpayDeduction = Math.min(overpaymentDeductionTotal, overpayToModify.Outstanding__c);
                    overpaymentDeductionTotal -= overpayDeduction;
                    overpayToModify.Overpayment_Amount__c -= overpayDeduction;
                }
            }
        }
        Decimal applicationAmount;
        for (System_Bill__c systemBill : groupedSystemBillsList) {
            if (systemBill.Account_Bill_Number__c == maxbillnumber) {
                // remove late fee payments from maxBill
                Decimal lateFeePayments = systemBill.Late_Fee_Payments__c;
                applicationAmount = Math.min(payment, lateFeePayments);
                payment -= applicationAmount;
                systemBill.Late_Fee_Payments__c -= applicationAmount;
                addAmountToMap(applicationAmount, systemBill.Shared_Solar_System__c, reversedPaymentsToSSSThisMonth);

                // remove Payments Net Previous Balances from maxBill
                Decimal paymentsNetPreviousBalances = systemBill.Payments_Net_Previous_Balances__c;
                applicationAmount = Math.min(payment, paymentsNetPreviousBalances);
                payment -= applicationAmount;
                systemBill.Payments_Net_Previous_Balances__c -= applicationAmount;
                addAmountToMap(applicationAmount, systemBill.Shared_Solar_System__c, reversedPaymentsToSSSThisMonth);

                groupedSystemBillsToUpdate.add(systemBill);

            } else if (systemBill.Account_Bill_Number__c < maxbillnumber) {
                // remove Late Payments from Previous bills
                Decimal latePayments = systemBill.Late_Payments__c;
                applicationAmount = Math.min(payment, latePayments);
                payment -= applicationAmount;
                systemBill.Late_Payments__c -= applicationAmount;
                addAmountToMap(applicationAmount, systemBill.Shared_Solar_System__c, reversedPaymentsToSSSThisMonth);
                groupedSystemBillsToUpdate.add(systemBill);
            }
        }
        for (System_Bill__c systemBill : groupedSystemBillsToUpdate) {
            if (systemBill.Account_Bill__r.Is_Most_Recent__c
                && reversedPaymentsToSSSThisMonth.containsKey(systemBill.Shared_Solar_System__c)) {
                systemBill.Total_Payments_This_Month__c -= reversedPaymentsToSSSThisMonth.get(systemBill.Shared_Solar_System__c);
            }
        }
        SystemBillPaymentRollUpHandler.listObject lists = new SystemBillPaymentRollUpHandler.listObject();

        if (payment > 0){
            Logger.logNow('ReturnedTransactionHandler', 'removePaymentFromSBs', 'Could not reverse entire transaction: ' + chTransaction.Id + ' / Payment Amount: ' + payment);
        }

        lists.systemBills = groupedSystemBillsToUpdate;
        return lists;
    }

    public void createReverseTransaction(ChargentOrders__Transaction__c transactionToReverse) {
        ChargentOrders__Transaction__c reverseTransaction = transactionToReverse.clone(false, true, true, false);
        reverseTransaction.ChargentOrders__Amount__c *= -1;
        reverseTransaction.ChargentOrders__Response_Status__c = 'Returned';
        reverseTransactions.add(reverseTransaction);
    }

    public void createCaseForTransaction(ChargentOrders__Transaction__c transactionToReverse) {
        CaseFactory caseFactory = new CaseFactory();
        Case newCase = caseFactory.getCase('Customer_Care');

        newCase.Subject = 'Customer Transaction Marked as Returned';
        newCase.Priority = 'Medium';
        newCase.Product_Line__c = 'Community Solar';
        newCase.Category__c = 'Billing-Issue';
        newCase.Chargent_Order__c = transactionToReverse.ChargentOrders__Order__c;
        newCase.Description = 'This transaction was marked as returned. There may be followup required with the customer to resolve issues with their payment method.';
        newCase.Origin = 'Other';
        newCase.Case_Type__c = 'BlueWave';
        newCase.Disable_Followup_Email__c = true;

        caseList.add(newCase);
    }

    public void updateRecords() {
        // implement unit of work concept
        Savepoint sp = Database.setSavepoint();
        try {
            if (billAdjustmentsToInsert.size() > 0) {
                insert billAdjustmentsToInsert;
            }
            if (finalGroupedSystemBillsToUpdate.size() > 0) {
                update finalGroupedSystemBillsToUpdate.values();
            }
            if (overpayList.size() > 0) {
                update overpayList;
            }
            if (propAccountsToUpdate.size() > 0) {
                update new List<Account>(propAccountsToUpdate);
            }
            if (transactionsToUpdate.size() > 0) {
                update transactionsToUpdate;
            }
            if (reverseTransactions.size() > 0) {
                insert reverseTransactions;
            }
            if (caseList.size() > 0) {
                insert caseList;
            }
        } catch (Exception e) {
            Database.rollback(sp);
            throw e;
        }
    }

    @testVisible
    private Decimal getOverpaymentAmount(Id entityId, Id accountBillId) {
        Decimal totalOverpayments = 0;
        for (Overpayment__c overpayment : overpayList) {
            if (overpayment.Entity__c == entityId && overpayment.Account_Bill__c == accountBillId) {
                totalOverpayments += (overpayment.Overpayment_Amount__c + overpayment.Total_Funds_Distributed__c);
            }
        }
        return totalOverpayments;
    }

    private void getOverpayments(List<ChargentOrders__Transaction__c> transactions) {
        Set<Id> entityIds = new Set<Id>();
        Set<Id> accountBillIds = new Set<Id>();
        for (ChargentOrders__Transaction__c chTransaction : transactions) {
            entityIds.add(chTransaction.ChargentOrders__Order__r.Account_Bill__c);
            accountBillIds.add(chTransaction.ChargentOrders__Order__r.Entity__c);
        }

        List<Overpayment__c> overpayments = [
            SELECT Id, Entity__c, Overpayment_Amount__c, Total_Funds_Distributed__c, Outstanding__c, Account_Bill__c
            FROM Overpayment__c
            WHERE Overpayment_Amount__c != 0
        ];

        overpayList = overpayments;
    }

    private void addAmountToMap(Decimal amount, Id idValue, Map<Id, Decimal> valueMap) {
        Decimal previousValue = valueMap.get(idValue);
        valueMap.put(idValue, Util.NullToZero(previousValue) + amount);
    }
}