/**
 * Created by pyao on 12/17/2018.
 * Description: Checks System Bills after insert and update for validity (only two decimals
 * on currency fields, other checks to be added in the future)
 * Tested By: SystemBillQualityCheckerTest
 */

public with sharing class SystemBillQualityChecker {
    @Future
    public static void checkDecimalScale(Set<Id> systemBillIds) {
        List<SObject> systemBills = getSystemBillsWithCurrencyFields(new List<Id>(systemBillIds));
        List<Id> systemBillsWithTooManyDecimals = new List<Id>();
        for (SObject sObj : systemBills) {
            if (hasFractionalCentField(sObj)) {
                systemBillsWithTooManyDecimals.add(sObj.Id);
            }
        }

        if (!systemBillsWithTooManyDecimals.isEmpty()) {
            Logger.logNow('SystemBillQualityChecker', 'checkDecimalScale',
                systemBillsWithTooManyDecimals.size() + ' System Bills have fractional decimals which we might not handle: (' +
                    String.join(systemBillsWithTooManyDecimals, ', ') + ')');
        }
    }

    private static Boolean hasFractionalCentField(SObject sObj) {
        Map<String, Object> fieldMap = sObj.getPopulatedFieldsAsMap();
        for (String field : fieldMap.keySet()) {
            if (field == 'Id') {
                continue;
            } else {
                if (((Decimal) fieldMap.get(field)).scale() > 2) {
                    return true;
                }
            }
        }
        return false;
    }

    @TestVisible
    private static List<SObject> getSystemBillsWithCurrencyFields(List<Id> systemBillIds) {
        Schema.SObjectType systemBillType = Schema.getGlobalDescribe().get('System_Bill__c');
        DescribeSObjectResult soDescribe = systemBillType.getDescribe();
        List<String> currencyFields = new List<String>();
        for (SObjectField field : soDescribe.fields.getMap().values()) {
            DescribeFieldResult fieldResult = field.getDescribe();
            // Four fields aren't used in downstream calculations
            if (fieldResult.getType() == Schema.DisplayType.CURRENCY &&
                fieldResult.getName() != 'Delete_this_del__c' &&
                fieldResult.getName() != 'YTD_Payments__c' &&
                fieldResult.getName() != 'YTD_Billed__c' &&
                fieldResult.getName() != 'Past_Bill_Amount__c') {
                currencyFields.add((String) fieldResult.getName());
            }
        }

        String soql = 'SELECT ' + String.join(currencyFields, ', ') +
            ' FROM System_Bill__c ' +
            ' WHERE ID in :systemBillIds';
        return Database.query( soql);
    }
}