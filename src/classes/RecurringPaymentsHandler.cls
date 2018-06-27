/*************************************************************************************
 + * Created By:  Jordan Pentaleri
 + * This class moves Recurring Chargent Orders from an old Account Bill to the new AB
 + * and updates the Charge Amount field with the Total Due amount from the new bill. For
 + * AB's with more than 1 ProjectCo (entity), updates both orders under that AB.
 + * Scheduling this class to run on the dya bills are generated will allow this to only
 + * run once, and should include any adjustments that occur on the bills that day.
 + *
   * - If a ChargentOrder status is reoccuring, set the parent account autopay checkbox to true
   * - If a ChargentOrder status is anything else, set the partent account autopay checkbox to false
+ * Tested By: RecurringPaymentsHandlerTestClass
 + *************************************************************************************/

public without sharing class RecurringPaymentsHandler implements Database.Batchable<sObject>, Schedulable {
    public void execute(SchedulableContext sc){
       Database.executeBatch(this, 20);
    }

    public Database.QueryLocator start(Database.BatchableContext bc) {
        String query =  'SELECT Id, Name, ChargentOrders__Payment_Status__c,' +
                        ' ChargentOrders__Charge_Amount__c, Account_Bill__c,' +
                        ' Account_Bill__r.Bill_Number__c, ChargentOrders__Gateway__r.Entity_ID__c,' +
                        ' Property_Account_ID__c, Reason_for_Recurring_Stop__c,' +
                        ' Comments__c,' +
                        ' ChargentOrders__Payment_Method__c,' +
                        ' ChargentOrders__Bank_Name__c,' +
                        ' ChargentOrders__Bank_Routing_Number__c,' +
                        ' ChargentOrders__Bank_Account_Type__c,' +
                        ' ChargentOrders__Bank_Account_Number__c,' +
                        ' ChargentOrders__Bank_Account_Name__c,' +
                        ' ChargentOrders__Billing_Email__c,' +
                        ' ChargentOrders__Card_Type__c,' +
                        ' ChargentOrders__Card_Number__c,' +
                        ' ChargentOrders__Card_Security_Code__c,' +
                        ' ChargentOrders__Card_Expiration_Month__c,' +
                        ' ChargentOrders__Card_Expiration_Year__c,' +
                        ' ChargentOrders__Billing_Address__c,' +
                        ' ChargentOrders__Billing_City__c,' +
                        ' ChargentOrders__Billing_State__c,' +
                        ' ChargentOrders__Billing_Zip_Postal__c,' +
                        ' ChargentOrders__Billing_First_Name__c,' +
                        ' ChargentOrders__Billing_Last_Name__c,' +
                        ' ChargentOrders__Payment_Frequency__c,' +
                        ' ChargentOrders__Payment_Stop__c,' +
                        ' ChargentOrders__Charge_Date__c,' + 
                        ' ChargentOrders__Payment_Start_Date__c,' +
                        ' ChargentOrders__Shipping_Name__c' +
                        ' FROM ChargentOrders__ChargentOrder__c' +
                        ' WHERE ChargentOrders__Payment_Status__c = \'' + 'Recurring' + '\'' +
                        ' ORDER BY CreatedDate';
        return Database.getQueryLocator(query);
    }

    public void execute(Database.BatchableContext bc, List<ChargentOrders__ChargentOrder__c> scope){
        updateRecurringOrders(scope);
    }

    public void updateRecurringOrders(List<ChargentOrders__ChargentOrder__c> chOrders){
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
        Map<Id, ChargentOrders__ChargentOrder__c> orderMap = new Map<Id, ChargentOrders__ChargentOrder__c>();

        for (ChargentOrders__ChargentOrder__c recOrders : chOrders) {
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

        for (ChargentOrders__ChargentOrder__c recurOrder : chOrders) {
            if (recurOrder.Account_Bill__c != null && recurOrder.Account_Bill__r.Bill_Number__c != null && recurOrder.ChargentOrders__Gateway__r.Entity_ID__c != null ) {
                newBillNumber = Integer.valueOf(recurOrder.Account_Bill__r.Bill_Number__c) + 1;
                chargentOrderKey = newBillNumber + '_' + recurOrder.Property_Account_ID__c;
                if (abMap.containsKey(chargentOrderKey)){
                    recurOrder.Account_Bill__c = abMap.get(chargentOrderKey).Id;
                    if (aggregateSbMap.containsKey(abMap.get(chargentOrderKey).Id + '_' + recurOrder.ChargentOrders__Gateway__r.Entity_ID__c)) {
                        newchargeamount = aggregateSbMap.remove(abMap.get(chargentOrderKey).Id + '_' + recurOrder.ChargentOrders__Gateway__r.Entity_ID__c);
                        recurOrder.ChargentOrders__Charge_Amount__c = newchargeamount.setScale(2, roundingMode.HALF_UP);
                    } else {
                        recurOrder = setChargentOrderToStopped(recurOrder, 'No System Bills found for this Account Bill: ' + abMap.get(chargentOrderKey).Id);
                    }
                } else {
                        recurOrder = setChargentOrderToStopped(recurOrder,  'No Account Bill found for Bill Number and Property Account Id: ' + chargentOrderKey);
                }
            } else {
                recurOrder = setChargentOrderToStopped(recurOrder, 'Order was not linked to Account Bill and/or Entity, cannot find next in series');
            }
            orderMap.put(recurOrder.Account_Bill__c, recurOrder);
        }
        update chOrders;

        /* If there are any bills that are left over that don't have a Ch Order, clone one:*/
        if (aggregateSbMap.size() > 0){
            cloneOrderForNewGateway(aggregateSbMap, orderMap);
        }
    }

    public static ChargentOrders__ChargentOrder__c setChargentOrderToStopped (ChargentOrders__ChargentOrder__c orderToStop, String stopMessage) {
        orderToStop.ChargentOrders__Charge_Amount__c = 0;
        orderToStop.ChargentOrders__Payment_Status__c = 'Stopped';
        orderToStop.Reason_for_Recurring_Stop__c = stopMessage;
        return orderToStop;
    }

    public void cloneOrderForNewGateway(Map<String, Decimal> aggregateSbMap, Map<Id, ChargentOrders__ChargentOrder__c> orderMap){
        List<ChargentOrders__ChargentOrder__c> ordersToInsert = new List<ChargentOrders__ChargentOrder__c>();
        for (String sbWithoutOrder : aggregateSbMap.keySet()) {
            String acctBillid = sbWithoutOrder.substring(0,18);
            Decimal amountToCharge = aggregateSbMap.get(sbWithoutOrder).setScale(2, roundingMode.HALF_UP);
            if (orderMap.containsKey(acctBillid)){
                if (orderMap.get(acctBillid).ChargentOrders__Payment_Status__c == 'Recurring'){
                    ChargentOrders__ChargentOrder__c orderInput = orderMap.get(acctBillid);
                    ChargentOrders__ChargentOrder__c orderA = orderInput.clone(false,true,true,false);
                    orderA.ChargentOrders__Subtotal__c = amountToCharge;
                    orderA.ChargentOrders__Charge_Amount__c = amountToCharge;
                    orderA.ChargentOrders__Payment_Frequency__c = 'Monthly';
                    orderA.ChargentOrders__Payment_Status__c = 'Recurring';
                    orderA.ChargentOrders__Payment_Stop__c = 'Unending';
                    orderA.ChargentOrders__Charge_Date__c = '01';
                    orderA.Reason_for_Recurring_Stop__c = '';
                    orderA.Comments__c = 'Cloned Order';
                    orderA.ChargentOrders__Shipping_Name__c = sbWithoutOrder.substring(19,34);
                    orderA.ChargentOrders__Payment_Start_Date__c = Date.today().addDays(-1);
                    ordersToInsert.add(orderA);  
                }
            }
        } 
        insert ordersToInsert;
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
            MessagingService.createAndSendEmail(emailBody, 'customercare@bluewavesolar.com', 'CS Recurring Processing Complete', postJobEmailAddresses);
        }
    }

    public static void updateAccountAutopay(List<ChargentOrders__ChargentOrder__c> newOrders) {
        List<String> ordersIdList = new List<String>();
        for (ChargentOrders__ChargentOrder__c order : newOrders) {
            ordersIdList.add(order.Id);
        }

        List<ChargentOrders__ChargentOrder__c> orderList = [
        	SELECT Id,
               ChargentOrders__Payment_Status__c,
               Property_Account_ID__c,
               Account_Bill__r.Parent_Account__r.Recurring_Billing__c
            FROM ChargentOrders__ChargentOrder__c
            WHERE Id IN : ordersIdList
        ];

        /*
        	Since this is triggered after ChargentOrders is updated the below list should
        	exclude any 'Recurring' ChargentOrders that have been changed to 'Stopped'
        */
        List<ChargentOrders__ChargentOrder__c> ordersWithAutopay = new List<ChargentOrders__ChargentOrder__c>([
    		SELECT Property_Account_ID__c
    		FROM ChargentOrders__ChargentOrder__c
    		WHERE ChargentOrders__Payment_Status__c = 'Recurring'
            AND Id NOT IN: ordersIdList
        ]);

        Set<String> accountsWithAutopay = new Set<String>();

        for (ChargentOrders__ChargentOrder__c order : ordersWithAutopay) {
          accountsWithAutopay.add(order.Property_Account_ID__c);
        }

        Map<String, Account> accountsToUpdate = new Map<String, Account>();

        for (ChargentOrders__ChargentOrder__c order : orderList) {
            if (order.Account_Bill__r != null ) {
                if (order.ChargentOrders__Payment_Status__c == 'Recurring') {
                    order.Account_Bill__r.Parent_Account__r.Recurring_Billing__c = true;
                    accountsToUpdate.put(order.Property_Account_ID__c, order.Account_Bill__r.Parent_Account__r);
                } else if (!accountsWithAutopay.contains(order.Property_Account_ID__c)){
                    order.Account_Bill__r.Parent_Account__r.Recurring_Billing__c = false;
                    accountsToUpdate.put(order.Property_Account_ID__c, order.Account_Bill__r.Parent_Account__r);
                }

            }
        }

        update accountsToUpdate.values();
    }
}
