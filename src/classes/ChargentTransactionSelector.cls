/**
 * Created by PeterYao on 7/24/2019.
 * Tested by: ZuoraHistoricalApplicationTest
 */

public with sharing class ChargentTransactionSelector {
    public List<ChargentOrders__Transaction__c> selectForZuoraHistory(String zuoraAccountId) {
        if (!Schema.SObjectType.ChargentOrders__Transaction__c.isAccessible() ||
            !Schema.SObjectType.ChargentOrders__Transaction__c.fields.Id.isAccessible() ||
            !Schema.SObjectType.ChargentOrders__Transaction__c.fields.ChargentOrders__Type__c.isAccessible() ||
            !Schema.SObjectType.ChargentOrders__Transaction__c.fields.ChargentOrders__Amount__c.isAccessible() ||
            !Schema.SObjectType.ChargentOrders__Transaction__c.fields.ChargentOrders__Payment_Method__c.isAccessible() ||
            !Schema.SObjectType.ChargentOrders__Transaction__c.fields.ChargentOrders__Gateway_Date__c.isAccessible() ||
            !Schema.SObjectType.ChargentOrders__Transaction__c.fields.Client__c.isAccessible() ||
            !Schema.SObjectType.ChargentOrders__Transaction__c.fields.ChargentOrders__Order__c.isAccessible() ||
            !Schema.SObjectType.ChargentOrders__Transaction__c.fields.CreatedDate.isAccessible() ||
            !Schema.SObjectType.ChargentOrders__Transaction__c.fields.ChargentOrders__Response_Status__c.isAccessible() ||
            !Schema.SObjectType.ChargentOrders__Transaction__c.fields.Date_of_Transaction__c.isAccessible() ||
            !Schema.SObjectType.ChargentOrders__ChargentOrder__c.isAccessible() ||
            !Schema.SObjectType.ChargentOrders__ChargentOrder__c.fields.Entity__c.isAccessible() ||
            !Schema.SObjectType.ChargentOrders__ChargentOrder__c.fields.Account_Bill__c.isAccessible() ||
            !Schema.SObjectType.Account_Bill__c.isAccessible() ||
            !Schema.SObjectType.Account_Bill__c.fields.Parent_Account__c.isAccessible() ||
            !Schema.SObjectType.Account.isAccessible() ||
            !Schema.SObjectType.Account.fields.Zuora_Id__c.isAccessible() ||
            !Schema.SObjectType.Account.fields.Account_Number__c.isAccessible() ||
            !Schema.SObjectType.Entity__c.isAccessible() ||
            !Schema.SObjectType.Entity__c.fields.Name.isAccessible()) {
            throw new Util.FatalBWException('Insufficient permissions');
        }
        return [
            SELECT Id,
                ChargentOrders__Type__c,
                ChargentOrders__Amount__c,
                ChargentOrders__Payment_Method__c,
                ChargentOrders__Gateway_Date__c,
                Client__r.Account_Number__c,
                ChargentOrders__Order__r.Entity__c,
                ChargentOrders__Order__r.Entity__r.Name,
                CreatedDate,
                ChargentOrders__Order__r.Account_Bill__r.Parent_Account__r.Zuora_Id__c,
                ChargentOrders__Response_Status__c
            FROM ChargentOrders__Transaction__c
            WHERE ChargentOrders__Order__r.Entity__r.Name != 'BlueWave Finance Group, LLC'
            AND ChargentOrders__Response_Status__c != 'Error'
            AND ChargentOrders__Order__r.Account_Bill__r.Parent_Account__r.Zuora_Id__c =: zuoraAccountId
            AND ChargentOrders__Response_Status__c != 'Declined'
            AND ChargentOrders__Amount__c != 0
            AND ChargentOrders__Amount__c != NULL
            ORDER BY Date_of_Transaction__c
        ];
    }
}