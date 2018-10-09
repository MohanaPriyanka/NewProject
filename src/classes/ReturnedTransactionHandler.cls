/**
 * Created by mstackhouse on 10/1/2018.
 * Description: Provides a method for reversing transactions that have been returned due to an ACH issue. Implemented as a button
 * on the transaction page and has validations to make sure there isn't another system bill published.
 * Test: TestBillCreationandPayment
 */


global without sharing class ReturnedTransactionHandler {
    webService static void unrollPayments(Id transactionId) {
        ChargentOrders__Transaction__c chTransaction;
        Map<Id,Account> propaccountMap;
        List<System_Bill__c> systemBills;
        Map<Id,Account_Bill__c> accountBillMap;
        Datetime lastSystemBillDate;

        List<System_Bill__c> finalGroupedSystemBillsToUpdate = new List<System_Bill__c>();
        List<Account_Bill__c> finalAccountBillsToUpdate = new List<Account_Bill__c>();
        List<Bill_Adjustment__c> finalAdjustmentsToInsertList = new List<Bill_Adjustment__c>();

        SystemBillPaymentRollUpHandler.SystemBillRepo sbRepo = new SystemBillPaymentRollUpHandler.SystemBillRepo(new List<Id>{transactionId});
        if (sbRepo.getTransactions().size() != 1 || sbRepo.getTransactions()[0].Id != transactionId) {
            throw new Util.BWException('Transaction cannot be marked for return.');
        }
        chTransaction = sbRepo.getTransactions()[0];
        systemBills = sbRepo.getSystemBills();
        accountBillMap = sbRepo.getAccountBillMap();
        propaccountMap = sbRepo.getPropertyAccountMap();

        List<System_Bill__c> groupedSystemBillsList = new List<System_Bill__c>();
        String parentID = chTransaction.ChargentOrders__Order__r.Account_Bill__r.Parent_Account__r.Id;
        String entityId = chTransaction.ChargentOrders__Order__r.Entity__c;
        Decimal payment = chTransaction.ChargentOrders__Amount__c;
        Decimal maxbillnumber = 0;

        Date dateOfLastPayment = Date.newInstance(System.today().year(), System.today().month(), System.today().day());

        for (System_Bill__c sbill : systemBills) {
            if (sbill.Account_Bill__r.Parent_Account__r.Id == parentID
                && sbill.Shared_Solar_System__r.BWC_Project_Entity_Manual__r.Id == entityId) {
                //add the system bills in reverse order so newest is first
                if (groupedSystemBillsList.isEmpty()) {
                    groupedSystemBillsList.add(sbill);
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
                accountBillMap,
                payment,
                maxbillnumber,
                dateOfLastPayment,
                chTransaction);
            finalGroupedSystemBillsToUpdate.addAll(objectList.systemBills);
            finalAccountBillsToUpdate.addAll(objectList.accountBills);
            finalAdjustmentsToInsertList.addAll(objectList.billAdjustments);
            propaccountMap.get(parentID).Date_of_Last_Payment__c = dateOfLastPayment;

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
        } else {
            List<Utility_Account_Subscription__c> utilAccSubs = [
                SELECT Id, Opportunity__r.Shared_Solar_System__r.BWC_Project_Entity_Manual__c
                FROM Utility_Account_Subscription__c
                WHERE Utility_Account_Log__r.Account__c = : parentID
                AND Opportunity__r.Shared_Solar_System__c = : groupedSystemBillsList[0].Shared_Solar_System__c
                AND Next_Schedule_Z_Status__c = 'Active Subscription'
            ];

            Bill_Adjustment__c adjust = new Bill_Adjustment__c( Name = 'Returned Payment: ' + groupedSystemBillsList[0].Account_Bill__r.Name + ' ' + dateOfLastPayment.format(),
                Adjustment_Amount__c = payment,
                Overpayment__c = false,
                Entity__c = utilAccSubs[0].Opportunity__r.Shared_Solar_System__r.BWC_Project_Entity_Manual__c,
                Utility_Account_Subscription__c = utilAccSubs[0].Id,
                Source_ID__c = transactionId,
                Approval_Status__c = 'Approved',
                Reason_For_Adjustment__c = 'Payment was Marked as Returned after new Bills have been Published'
            );
            insert adjust;
        }
        update chTransaction;
    }

    public static SystemBillPaymentRollUpHandler.listObject removePaymentFromSBs (  List<System_Bill__c> groupedSystemBillsList,
        Map<Id,Account_Bill__c> accountBillMap,
        Decimal payment,
        Decimal maxbillnumber,
        Date dateOfLastPayment,
        ChargentOrders__Transaction__c chTransaction) {
        String transactionId = chTransaction.Id;
        List<System_Bill__c> groupedSystemBillsToUpdate = new List <System_Bill__c>();
        Map<String, Bill_Adjustment__c> adjustmentsToInsertList = new Map<String, Bill_Adjustment__c>();
        Map<Id, Decimal> reversedPaymentsToSSSThisMonth = new Map<Id, Decimal>();
        for (System_Bill__c systemBill : groupedSystemBillsList) {
            Account_Bill__c accountBill = accountBillMap.get(systemBill.Account_Bill__c);
            if (systemBill.Account_Bill_Number__c == maxbillnumber) {
                String entityId = chTransaction.ChargentOrders__Order__r.Entity__c;
                Decimal sbEntityOverpayments = getOverpaymentAmount(entityId, accountBill.Id, adjustmentsToInsertList);
                Decimal reversedAmount = Math.min(payment, systemBill.Total_Payments_This_Month__c + sbEntityOverpayments);

                // reduce overpayments by reversed payment amount
                Decimal applicationAmount = Math.min(reversedAmount, sbEntityOverpayments);
                payment -= applicationAmount;
                accountBill.Overpayment_Amount__c -= applicationAmount;
                if (applicationAmount > 0) {
                    Bill_Adjustment__c adjust = new Bill_Adjustment__c( Name = 'Reversed Overpayment: ' + systemBill.Account_Bill__r.Name + ' ' + dateOfLastPayment.format(),
                        Adjustment_Amount__c = applicationAmount,
                        Account_Bill__c = systemBill.Account_Bill__c,
                        Overpayment__c = true,
                        Entity__c = systemBill.Shared_Solar_System__r.BWC_Project_Entity_Manual__r.Id,
                        Source_ID__c = transactionId,
                        Approval_Status__c = 'Approved',
                        Reason_For_Adjustment__c = 'Payment was Marked as Returned'
                    );
                    String key = adjust.Account_Bill__c + '_' + adjust.Entity__c;
                    adjustmentsToInsertList.put(key, adjust);
                }
                accountBillMap.put(accountBill.Id, accountBill);

                // remove late fee payments from maxBill
                Decimal lateFeePayments = systemBill.Late_Fee_Payments__c;
                applicationAmount = Math.min(reversedAmount, lateFeePayments);
                payment -= applicationAmount;
                systemBill.Late_Fee_Payments__c -= applicationAmount;
                addAmountToMap(applicationAmount, systemBill.Shared_Solar_System__c, reversedPaymentsToSSSThisMonth);

                // remove Payments Net Previous Balances from maxBill
                Decimal paymentsNetPreviousBalances = systemBill.Payments_Net_Previous_Balances__c;
                applicationAmount = Math.min(reversedAmount, paymentsNetPreviousBalances);
                payment -= applicationAmount;
                systemBill.Payments_Net_Previous_Balances__c -= applicationAmount;
                addAmountToMap(applicationAmount, systemBill.Shared_Solar_System__c, reversedPaymentsToSSSThisMonth);

                groupedSystemBillsToUpdate.add(systemBill);

            } else if (systemBill.Account_Bill_Number__c < maxbillnumber) {
                // remove Late Payments from Previous bills
                Decimal latePayments = systemBill.Late_Payments__c;
                Decimal applicationAmount = Math.min(payment, latePayments);
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
        lists.systemBills = groupedSystemBillsToUpdate;
        lists.accountBills = accountBillMap.values();
        lists.billAdjustments = adjustmentsToInsertList.values();
        return lists;
    }

    @testVisible
    private static Decimal getOverpaymentAmount(String entityId, Id accountBillId, Map<String, Bill_Adjustment__c> adjustmentsToInsertList) {
        List<Bill_Adjustment__c> overpayments = [
            SELECT Id, Overpayment__c, Entity__c, Outstanding__c
            FROM Bill_Adjustment__c
            WHERE Overpayment__c = true
            AND Entity__c = : entityId
            AND Account_Bill__c = : accountBillId
            AND Outstanding__c != 0
        ];
        Bill_Adjustment__c newAdjustment = adjustmentsToInsertList.get(accountBillId + '_'+ entityId);
        if (newAdjustment != null) {
            overpayments.add(newAdjustment);
        }
        System.debug(overpayments);
        Decimal totalOverpayments = 0;
        for (Bill_Adjustment__c overpayment : overpayments) {
            if (overpayment.Outstanding__c != null) {
                totalOverpayments += -1 * overpayment.Outstanding__c;
            } else {
                totalOverpayments += -1 * overpayment.Adjustment_Amount__c;
            }
        }
        System.debug('Overpayments');
        System.debug(totalOverpayments);
        return totalOverpayments;
    }

    private static void addAmountToMap(Decimal amount, Id idValue, Map<Id, Decimal> valueMap) {
        Decimal previousValue = valueMap.get(idValue);
        valueMap.put(idValue, Util.NullToZero(previousValue) + amount);
    }
}