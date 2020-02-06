/**
 * Created by mstackhouse on 1/9/2019.
 * Description: 
 * Test: CSPaymentTest
 */


global without sharing class ReturnedTransactionController {
    webService static void unrollPayments(List<Id> transactionIds) {
        List<ChargentOrders__Transaction__c> transactionsToReturn = [
            SELECT Id, ChargentOrders__Order__c, ChargentOrders__Amount__c, ChargentOrders__Response_Status__c,
                ChargentOrders__Gateway__c, Distributed_Among_System_Bills__c, ChargentOrders__Response_Message__c,
                ChargentOrders__Type__c, ChargentOrders__Payment_Method__c, Activity_Type__c,
                ChargentOrders__Order__r.Paper_Check__c
            FROM ChargentOrders__Transaction__c
            WHERE ChargentOrders__Order__r.Paper_Check__c != NUll
            AND Id IN : transactionIds
        ];

        if (!transactionsToReturn.isEmpty()) {
            throw new Util.BWException('Transactions from Paper Checks must be returned from the Paper Check record.');
        }
        
        ReturnedTransactionHandler returnedTransactionHandler = new ReturnedTransactionHandler();
        returnedTransactionHandler.unrollPayment(new Set<Id>(transactionIds));
        returnedTransactionHandler.updateRecords();
    }

    webService static void unrollPaperChecks(List<Id> paperCheckIds) {
        List<ChargentOrders__Transaction__c> transactionsToReturn = [
            SELECT Id, ChargentOrders__Order__c, ChargentOrders__Amount__c, ChargentOrders__Response_Status__c,
                ChargentOrders__Gateway__c, Distributed_Among_System_Bills__c, ChargentOrders__Response_Message__c,
                ChargentOrders__Type__c, ChargentOrders__Payment_Method__c, Activity_Type__c,
                ChargentOrders__Order__r.Paper_Check__c
            FROM ChargentOrders__Transaction__c
            WHERE ChargentOrders__Order__r.Paper_Check__c IN : paperCheckIds
        ];

        Set<Id> transactionIds = new Set<Id>();

        for (ChargentOrders__Transaction__c chOTransaction : transactionsToReturn) {
            transactionIds.add(chOTransaction.Id);
        }

        ReturnedTransactionHandler returnedTransactionHandler = new ReturnedTransactionHandler();
        returnedTransactionHandler.unrollPayment(transactionIds);
        returnedTransactionHandler.updateRecords();
    }
}