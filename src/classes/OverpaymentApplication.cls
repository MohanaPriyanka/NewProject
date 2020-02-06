/*
 * Description: applies overpayments to bills when we tell conga to generate bills and apply overpayments
 * Test: TestBillCreationandPayment {testAdjustment, testAdjustment2, testMultipleAdjustments}
 */

public without sharing class OverpaymentApplication {
    public static Map<String, List<Bill_Adjustment__c>> adjustMap;
    public static Map<String, List<Overpayment__c>> overpayMap;
    public static List<Adjustment_Application__c> adjustmentsToInsertList;
    public static List<Overpayment_Application__c> overpaymentAdjustmentsToInsert;

    public static void triggerApplication() {
        List<String> finalPropertyAccountIdList = new List<String>();

        List<String> propertyIdList = findAdjustments();
        if (propertyIdList.size() > 0){
            finalPropertyAccountIdList.addAll(propertyIdList);
        }
        propertyIdList = findOverpayments();
        if (propertyIdList.size() > 0){
            finalPropertyAccountIdList.addAll(propertyIdList);
        }
        findSystemBillsAndApplyAdjust(finalPropertyAccountIdList);
    }

    public static List<String> findAdjustments() {
        List<String> propIdList = new List<String>();
        adjustMap = new Map<String, List<Bill_Adjustment__c>>();

        List<Bill_Adjustment__c> adjustments = [
            SELECT Id, Name, Adjustment_Amount__c,
                Outstanding__c,
                UASB__r.Opportunity__r.AccountId,
                UASB__c, UASB__r.Opportunity__c
            FROM Bill_Adjustment__c
            WHERE Outstanding__c != 0
            AND Approval_Status__c = 'Approved'
            AND UASB__r.Opportunity__c != NULL
            ORDER BY Adjustment_Amount__c DESC
        ];
        for (Bill_Adjustment__c adjustment : adjustments){
            String adjustKey;
            propIdList.add(adjustment.UASB__r.Opportunity__r.AccountId);
            adjustKey = adjustment.UASB__r.Opportunity__c;
            adjustment.Intermediate_Outstanding__c = adjustment.Outstanding__c;
            List<Bill_Adjustment__c> keyAdjustments;
            if (adjustMap.containsKey(adjustKey)) {
                keyAdjustments = adjustMap.get(adjustKey);
            } else {
                keyAdjustments = new List<Bill_Adjustment__c>();
            }
            keyAdjustments.add(adjustment);
            adjustMap.put(adjustKey, keyAdjustments);
        }
        return propIdList;
    }

    public static List<String> findOverpayments() {
        List<String> propertyIdList = new List<String>();
        overpayMap = new Map<String, List<Overpayment__c>>();

        List<Overpayment__c> overpayments = [
            SELECT Id, Account_Bill__c, Entity__c, Outstanding__c,
                Intermediate_Outstanding__c, Overpayment_Amount__c, Total_Funds_Distributed__c,
                Transaction__c, Account_Bill__r.Parent_Account__c, Entity__r.Id
            FROM Overpayment__c
            WHERE Outstanding__c != 0
            AND Account_Bill__c != NULL
            ORDER BY Overpayment_Amount__c DESC
        ];

        for (Overpayment__c overpay : overpayments) {
            String overpayKey;
            propertyIdList.add(overpay.Account_Bill__r.Parent_Account__c);
            overpayKey = overpay.Entity__r.Id;
            overpayKey = overpayKey.Substring(0, 15) + '_' + overpay.Account_Bill__r.Parent_Account__c;
            overpay.Intermediate_Outstanding__c = overpay.Outstanding__c;
            if (overpayKey != null) {
                List<Overpayment__c> keyOverpayments;
                if (overpayMap.containsKey(overpayKey)) {
                    keyOverpayments = overpayMap.get(overpayKey);
                } else {
                    keyOverpayments = new List<Overpayment__c>();
                }
                keyOverpayments.add(overpay);
                overpayMap.put(overpayKey, keyOverpayments);
            }
        }
        return propertyIdList;
    }

    public static void findSystemBillsAndApplyAdjust(List<String> propertyAccountIdList) {
        adjustmentsToInsertList = new List<Adjustment_Application__c>();
        overpaymentAdjustmentsToInsert = new List<Overpayment_Application__c>();
        if (adjustMap.size() > 0 || overpayMap.size() > 0) {
            List<System_Bill__c> systemBills = [
                SELECT Id, Name, Account_Bill__c, Due_This_Month__c, Entity_Id__c, Account_Bill__r.Bill_Number__c,
                    Account_Bill__r.Parent_Account__c, Balance_Net_Late_Payments__c, Bill_Number__c,
                    Opportunity__c, Shared_Solar_System__r.BWC_Project_Entity_Manual__c
                FROM System_Bill__c
                WHERE Account_Bill__r.Published__c = false
                AND Account_Bill__r.Parent_Account__c IN : propertyAccountIdList
                ORDER BY Bill_Number__c ASC
            ];

            for (System_Bill__c sbill : systemBills ) {
                sbill.Balance_Net_Late_Payments__c = applyAdjustments(sbill);
                applyOverpayments(sbill);
            }
            if (adjustmentsToInsertList.size() > 0) {
                insert adjustmentsToInsertList;
            }
            if (overpaymentAdjustmentsToInsert.size() > 0) {
                insert overpaymentAdjustmentsToInsert;
            }
        }
    }

    public static Decimal applyAdjustments (System_Bill__c sbill) {
        String sbKey = sbill.Opportunity__c;

        if (adjustMap.containsKey(sbKey)) {
            List<Bill_Adjustment__c> adjustments = adjustMap.get(sbKey);
            Decimal sBillBalance = sbill.Balance_Net_Late_Payments__c;
            for (Bill_Adjustment__c adjust : adjustments) {
                Decimal adjustmentAmount = 0;
                Decimal outstanding = adjust.Intermediate_Outstanding__c;
                Decimal originalAdjust = adjust.Adjustment_Amount__c;

                if (sBillBalance > 0
                    && originalAdjust > 0
                    && outstanding > 0){
                    adjustmentAmount += outstanding;
                } else if (sBillBalance > 0
                    && originalAdjust < 0
                    && outstanding < 0){
                    if (sBillBalance > Math.abs(outstanding)) {
                        adjustmentAmount += outstanding;
                    } else {
                        adjustmentAmount += -1 * sBillBalance;
                    }
                }
                if (adjustmentAmount != 0) {
                    Adjustment_Application__c adjustApp = createAdjustApp(sbill, adjustmentAmount, adjust, sbKey);
                    adjustmentsToInsertList.add(adjustApp);
                }
                sBillBalance += adjustmentAmount;
            }
            return sBillBalance;
        } else {
            return sBill.Balance_Net_Late_Payments__c;
        }
    }

    public static void applyOverpayments (System_Bill__c sbill) {
        String sbKey = sbill.Shared_Solar_System__r.BWC_Project_Entity_Manual__c;
        sbKey = sbKey.substring(0,15) + '_' + sbill.Account_Bill__r.Parent_Account__c;

        if (overpayMap.containsKey(sbKey)) {
            List<Overpayment__c> overpayments = overpayMap.get(sbKey);
            Decimal sBillBalance = sbill.Balance_Net_Late_Payments__c;

            for (Overpayment__c overpayment : overpayments) {
                Decimal originalAdjust = overpayment.Overpayment_Amount__c;
                Decimal outstanding = overpayment.Intermediate_Outstanding__c;
                Overpayment_Application__c overApp;

                if (sBillBalance > 0
                    && originalAdjust > 0
                    && outstanding > 0) {
                    Decimal amount;
                    if (Math.abs(outstanding) >= sBillBalance)  {
                        amount = sBillBalance;
                    } else {
                        amount = outstanding;
                    }
                    sBillBalance -= amount;
                    amount = amount * -1;
                    overApp = createOverpayApp(sbill, amount, overpayment, sbKey);
                    overpaymentAdjustmentsToInsert.add(overApp);

                    overpayment.Intermediate_Outstanding__c += amount;
                }
            }
            overpayMap.put(sbkey,overpayments);
        }
    }

    public static Adjustment_Application__c createAdjustApp (System_Bill__c systemBill, Decimal amount, Bill_Adjustment__c adjust, String key) {
        Adjustment_Application__c newApplication = new Adjustment_Application__c (	Name = adjust.Name,
                                                                                    Bill_Adjustment__c = adjust.Id,
                                                                                    Adjustment_Amount__c = amount,
                                                                                    System_Bill__c = systemBill.Id);
        List<Bill_Adjustment__c> adjustments = adjustMap.get(key);
        for (Bill_Adjustment__c adjustment : adjustments) {
            if (adjustment.Id == adjust.Id) {
                adjustment.Intermediate_Outstanding__c = adjust.Intermediate_Outstanding__c - amount;
            }
        }
        adjustMap.put(key, adjustments);
        return newApplication;
    }

    public static Overpayment_Application__c createOverpayApp (System_Bill__c systemBill, Decimal amount, Overpayment__c overpay, String key) {
        Overpayment_Application__c overpayApp = new Overpayment_Application__c (    Overpayment__c = overpay.Id,
                                                                                    Overpayment_Amount__c = amount,
                                                                                    System_Bill__c = systemBill.Id);
        return overpayApp;
    }
}