/*************************************************************************************
 + * Created By:  Jordan Pentaleri 
 + * This class moves Recurring Chargent Orders from an old Account Bill to the new AB
 + * and updates the Charge Amount field with the Total Due amount from the new bill. For 
 + * AB's with more than 1 ProjectCo (entity), updates both orders under that AB.
 + * Scheduling this class to run on the dya bills are generated will allow this to only
 + * run once, and should include any adjustments that occur on the bills that day.
 + * 
 + * Tested By: RecurringPaymentsHandlerTestClass
 + *************************************************************************************/

public without sharing class RecurringPaymentsHandler implements Database.Batchable<sObject>, Schedulable { 
    public void execute(SchedulableContext sc){
       Database.executeBatch(this);
    }

    public static ChargentOrders__ChargentOrder__c setChargentOrderToStopped (ChargentOrders__ChargentOrder__c orderToStop, String stopMessage) {
        orderToStop.ChargentOrders__Charge_Amount__c = 0;
        orderToStop.ChargentOrders__Payment_Status__c = 'Stopped';
        orderToStop.Reason_for_Recurring_Stop__c = stopMessage;
        return orderToStop;
    }

    public Database.QueryLocator start(Database.BatchableContext bc) {
        String query =  'SELECT Id, ChargentOrders__Payment_Status__c,' +
                        ' ChargentOrders__Charge_Amount__c, Account_Bill__c,' +
                        ' Account_Bill__r.Bill_Number__c, ChargentOrders__Gateway__r.Entity_ID__c,' +
                        ' Property_Account_ID__c, Reason_for_Recurring_Stop__c' +
                        ' FROM ChargentOrders__ChargentOrder__c' +
                        ' WHERE ChargentOrders__Payment_Status__c = \'' + 'Recurring' + '\'';
        return Database.getQueryLocator(query);
    }

    public void execute(Database.BatchableContext bc, List<ChargentOrders__ChargentOrder__c> scope){ 
        String uniqueId;
        Integer newBillNumber; 
        Decimal newchargeamount;
        String accBillId;
        String abMapKey;
        String entityIdString;
        String chargentOrderKey;
        List<String> accountIDList = new List<String>();
        List<Account_Bill__c> newAcctBillList = new List<Account_Bill__c>();
        Map<String, Decimal> aggregateSbMap = new Map<String,Decimal>();
        Map<String, Account_Bill__c> abMap = new Map<String,Account_Bill__c>();

        for (ChargentOrders__ChargentOrder__c recOrders : scope) {
            accountIDList.add(recOrders.Property_Account_ID__c);
        }

        for (Account_Bill__c newAcctBill : [  SELECT Id, Name, Bill_Number__c, Property_Account_ID__c
                                                FROM Account_Bill__c
                                                WHERE Property_Account_ID__c IN : accountIDList
                                                ORDER BY Bill_Number__c] ) {
            newAcctBillList.add(newAcctBill);
            abMapKey = newAcctBill.Bill_Number__c + '_' + newAcctBill.Property_Account_ID__c;
            abMap.put(abMapKey, newAcctBill);
        }                                                                                                    

        for (AggregateResult sysBills : [  SELECT Account_Bill__c, Shared_Solar_System__r.BWC_Project_Entity_Manual__c entity, SUM(Total_Due__c) totaldue
                                            FROM System_Bill__c
                                            WHERE Account_Bill__c IN : newAcctBillList
                                            GROUP BY Shared_Solar_System__r.BWC_Project_Entity_Manual__c, Account_Bill__c] ) {

            accBillId = String.valueOf(sysBills.get('Account_Bill__c'));
            entityIdString = String.valueOf(sysBills.get('entity'));
            uniqueID = accBillId + '_' + entityIdString.substring(0,15);
            aggregateSbMap.put(uniqueID , (decimal) sysBills.get('totaldue') );
        }

        for (ChargentOrders__ChargentOrder__c recurOrder : scope) {
            if (recurOrder.Account_Bill__c != null && recurOrder.Account_Bill__r.Bill_Number__c != null && recurOrder.ChargentOrders__Gateway__r.Entity_ID__c != null ) {
                newBillNumber = Integer.valueOf(recurOrder.Account_Bill__r.Bill_Number__c) + 1;
                chargentOrderKey = newBillNumber + '_' + recurOrder.Property_Account_ID__c;
                if (abMap.containsKey(chargentOrderKey)){
                    recurOrder.Account_Bill__c = abMap.get(chargentOrderKey).Id;
                    if (aggregateSbMap.containsKey(abMap.get(chargentOrderKey).Id + '_' + recurOrder.ChargentOrders__Gateway__r.Entity_ID__c)) {
                        newchargeamount = aggregateSbMap.get(abMap.get(chargentOrderKey).Id + '_' + recurOrder.ChargentOrders__Gateway__r.Entity_ID__c);
                        recurOrder.ChargentOrders__Charge_Amount__c = newchargeamount.setScale(2);
                    } else {
                        recurOrder = setChargentOrderToStopped(recurOrder, 'No System Bills found for this Account Bill: ' + abMap.get(chargentOrderKey).Id); 
                    }
                } else {
                        recurOrder = setChargentOrderToStopped(recurOrder,  'No Account Bill found for Bill Number and Property Account Id: ' + chargentOrderKey); 
                }
            } else {
                recurOrder = setChargentOrderToStopped(recurOrder, 'Order was not linked to Account Bill and/or Entity, cannot find next in series'); 
            }
        }
        update scope;
    }
    public void finish(Database.BatchableContext bc){
        AsyncApexJob job = [SELECT Id, Status, NumberOfErrors, 
                            JobItemsProcessed,
                            TotalJobItems, CreatedBy.Email
                            FROM AsyncApexJob
                            WHERE Id = :bc.getJobId()];

        String emailBody = 'Recurring Orders Have Been Updated! Job Id: '+ job.Id 
                            + '  Errors: ' + job.NumberOfErrors 
                            + '  Total Jobs Processed (groups of 10): ' + job.JobItemsProcessed;
        List<String> postJobEmailAddresses = new List<String>{'jpentaleri@bluewavesolar.com'};   
        if (!Test.isRunningTest()){
            MessagingService.createAndSendEmail(emailBody, 'customercare@bluewavesolar.com', 'CS Bill Email Send Processing Complete', postJobEmailAddresses);
        }
    }  
}   