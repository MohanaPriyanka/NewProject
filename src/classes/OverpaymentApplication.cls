/*
 * Description: applies overpayments to bills when we tell conga to generate bills and apply overpayments
 * Test: TestBillCreationandPayment {testAdjustment, testAdjustment2, testMultipleAdjustments}
 */

public without sharing class OverpaymentApplication {
    public static Map<String, List<Bill_Adjustment__c>> adjustMap;
    public static List<Adjustment_Application__c> adjustmentsToInsertList;

    public static void triggerApplication(Map<Id,APXT_BPM__Conductor__c> oldMap, List<APXT_BPM__Conductor__c> newList) {
        for (APXT_BPM__Conductor__c conductor : newList) {
            if (conductor.Apply_Overpay_Adjust__c && !oldMap.get(conductor.Id).Apply_Overpay_Adjust__c) {
                applyOverpayments();
            }
        }
    }

    public static void applyOverpayments() {
        List<String> propertyAccountIdList = new List<String>();
        List<String> opportunityIdList = new List<String>();
        Decimal adjustAmount = 0;
        adjustMap = new Map<String, List<Bill_Adjustment__c>>();
        adjustmentsToInsertList = new List<Adjustment_Application__c>();

        List<Bill_Adjustment__c> adjustments = [
            SELECT Id, Name, Account_Bill__c, Entity__r.Id, Adjustment_Amount__c, Account_Bill__r.Bill_Number__c,
                Account_Bill__r.Parent_Account__c, Outstanding__c, Opportunity_ID__c,
                Overpayment__c,UASB__c, UASB__r.Opportunity__c, Approval_Status__c
            FROM Bill_Adjustment__c
            WHERE Outstanding__c != 0
            AND(Approval_Status__c = 'Approved' OR Overpayment__c = TRUE)
            ORDER BY Adjustment_Amount__c DESC
        ];

        for(Bill_Adjustment__c adjustment : adjustments){
            String adjustKey;
            if (adjustment.Account_Bill__c != NULL) {
                propertyAccountIdList.add(adjustment.Account_Bill__r.Parent_Account__c);
                adjustKey = adjustment.Entity__r.Id;
                adjustKey = adjustKey.Substring(0,15) + '_' + adjustment.Account_Bill__r.Parent_Account__c;
            } else if (adjustment.UASB__c != NULL) {
                opportunityIdList.add(adjustment.UASB__r.Opportunity__c);
                adjustKey = adjustment.UASB__r.Opportunity__c;
            }
            adjustment.Intermediate_Outstanding__c = adjustment.Outstanding__c;
            if (adjustKey != null) {
                List<Bill_Adjustment__c> keyAdjustments;
                if (adjustMap.containsKey(adjustKey)) {
                    keyAdjustments = adjustMap.get(adjustKey);
                } else {
                    keyAdjustments = new List<Bill_Adjustment__c>();
                }
                keyAdjustments.add(adjustment);
                adjustMap.put(adjustKey, keyAdjustments);
            }
        }

        if (adjustMap.size() > 0) {
            List<System_Bill__c> systemBills = [
                SELECT Id, Name, Account_Bill__c, Due_This_Month__c, Entity_Id__c, Account_Bill__r.Bill_Number__c,
                    Account_Bill__r.Parent_Account__c, Balance_Net_Late_Payments__c, Bill_Number__c,
                    Balance_Adjustments__c, Opportunity__c, Shared_Solar_System__r.BWC_Project_Entity_Manual__c
                FROM System_Bill__c
                WHERE Account_Bill__r.Published__c = false
                AND (Account_Bill__r.Parent_Account__c IN : propertyAccountIdList
                OR Opportunity__c IN : opportunityIdList)
                ORDER BY Bill_Number__c ASC
            ];

            for (System_Bill__c sbill : systemBills ) {
                sbill.Balance_Net_Late_Payments__c = checkForAdjustments(sbill);
                checkForOverpayments(sbill);
            }
            if (adjustmentsToInsertList.size() > 0) {
                insert adjustmentsToInsertList;
            }
        }
    }

    public static Decimal checkForAdjustments (System_Bill__c sbill) {
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

    public static void checkForOverpayments (System_Bill__c sbill) {
        String sbKey = sbill.Shared_Solar_System__r.BWC_Project_Entity_Manual__c;
        sbKey = sbKey.substring(0,15) + '_' + sbill.Account_Bill__r.Parent_Account__c;

        if (adjustMap.containsKey(sbKey)) {
            List<Bill_Adjustment__c> adjustments = adjustMap.get(sbKey);
            Decimal sBillBalance = sbill.Balance_Net_Late_Payments__c;
            for (Bill_Adjustment__c adjust : adjustments) {
                Decimal originalAdjust = adjust.Adjustment_Amount__c;
                Decimal outstanding = adjust.Intermediate_Outstanding__c;
                Adjustment_Application__c adjustApp;
                if (sBillBalance > 0
                    && originalAdjust < 0
                    && outstanding < 0) {
                    Decimal amount;
                    if (Math.abs(outstanding) >= sBillBalance)  {
                        amount = -1 * sBillBalance;
                    } else {
                        amount = outstanding;
                    }
                    sBillBalance += amount;
                    adjustApp = createAdjustApp(sbill, amount, adjust, sbKey);
                    adjustmentsToInsertList.add(adjustApp);
                }
            }
        }
    }

    public static Adjustment_Application__c createAdjustApp (System_Bill__c systemBill, Decimal amount, Bill_Adjustment__c adjust, String key) {
        Adjustment_Application__c newApplication = new Adjustment_Application__c (	Name = adjust.Name,
                                                                                    Bill_Adjustment__c = adjust.Id,
                                                                                    System_Bill__c = systemBill.Id);
        if (adjust.Overpayment__c){
            newApplication.Overpayment_Amount__c = amount;
        } else {
            newApplication.Adjustment_Amount__c = amount;
        }
        List<Bill_Adjustment__c> adjustments = adjustMap.get(key);
        for (Bill_Adjustment__c adjustment : adjustments) {
            if (adjustment.Id == adjust.Id) {
                adjustment.Intermediate_Outstanding__c = adjust.Intermediate_Outstanding__c - amount;
            }
        }
        adjustMap.put(key, adjustments);
        return newApplication;
    }

}