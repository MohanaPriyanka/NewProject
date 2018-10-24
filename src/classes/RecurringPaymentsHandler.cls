/*************************************************************************************
 + * Created By:  Jordan Pentaleri
 + * This class moves Recurring Chargent Orders from an old Account Bill to the new AB
 + * and updates the Charge Amount field with the Total Due amount from the new bill. For
 + * AB's with more than 1 ProjectCo (entity), updates both orders under that AB.
 + * Scheduling this class to run on the dya bills are generated will allow this to only
 + * run once, and should include any adjustments that occur on the bills that day.
 + *
   * - If a ChargentOrder status is recurring, set the parent account autopay checkbox to true
   * - If a ChargentOrder status is anything else, set the parent account autopay checkbox to false
+ * Tested By: RecurringPaymentsHandlerTestClass
 + *************************************************************************************/

public without sharing class RecurringPaymentsHandler implements Database.Batchable<SObject>, Schedulable {
    public void execute(SchedulableContext sc){
       Database.executeBatch(this, 20);
    }

    public Database.QueryLocator start(Database.BatchableContext bc) {
        String query =  'SELECT Id, Name, ChargentOrders__Payment_Status__c,' +
                        ' ChargentOrders__Charge_Amount__c, Account_Bill__c, ChargentOrders__Account__r.Max_Account_Bill_Number__c,' +
                        ' Account_Bill__r.Bill_Number__c, Opportunity__r.Shared_Solar_System__r.BWC_Project_Entity_Manual__c,' +
                        ' Account_Bill__r.Due_Date_SB__c, ' +
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
                        ' ChargentOrders__Shipping_Name__c,' +
                        ' Entity__c ' +
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
        String accBillId;
        String abMapKey;
        String entityIdString;
        String chargentOrderKey;
        List<String> accountIDList = new List<String>();
        List<Account_Bill__c> newAcctBillList = new List<Account_Bill__c>();
        Map<String, Decimal> aggregateSbMap = new Map<String,Decimal>();
        Map<String, Account_Bill__c> abMap = new Map<String,Account_Bill__c>();
        Map<Id, ChargentOrders__ChargentOrder__c> orderMap = new Map<Id, ChargentOrders__ChargentOrder__c>();
        List<Account_Bill__c> uncheckedFirstAccountBills = new List<Account_Bill__c>();

        for (ChargentOrders__ChargentOrder__c recOrders : chOrders) {
            accountIDList.add(recOrders.Property_Account_ID__c);
        }

        List<Account_Bill__c> accountBills = [
            SELECT Id, Name, Bill_Number__c, Property_Account_ID__c
            FROM Account_Bill__c
            WHERE Property_Account_ID__c IN :accountIDList
            ORDER BY Bill_Number__c
        ];
        for (Account_Bill__c newAcctBill : accountBills) {
            newAcctBillList.add(newAcctBill);
            abMapKey = newAcctBill.Bill_Number__c + '_' + newAcctBill.Property_Account_ID__c;
            abMap.put(abMapKey, newAcctBill);
        }

        List<AggregateResult> aggregateResults = [
            SELECT Account_Bill__c, Shared_Solar_System__r.BWC_Project_Entity_Manual__c entity, SUM(Carry_Over_Balance__c) totaldue
            FROM System_Bill__c
            WHERE Account_Bill__c IN :newAcctBillList
            GROUP BY Shared_Solar_System__r.BWC_Project_Entity_Manual__c, Account_Bill__c
        ];
        for (AggregateResult sysBills : aggregateResults ) {
            accBillId = String.valueOf(sysBills.get('Account_Bill__c'));
            entityIdString = String.valueOf(sysBills.get('entity'));
            uniqueId = accBillId + '_' + entityIdString;
            aggregateSbMap.put(uniqueId , (Decimal) sysBills.get('totaldue'));
        }

        for (ChargentOrders__ChargentOrder__c recurOrder : chOrders) {
            Id entityId = recurOrder.Entity__c;

            if (recurOrder.Account_Bill__c != null
                && recurOrder.Account_Bill__r.Bill_Number__c != null
                && entityId != null) {
                chargentOrderKey = getChargentOrderKey(recurOrder);
                moveAndSetOrder(abMap, chargentOrderKey, recurOrder, aggregateSbMap, entityId);
            } else {
                recurOrder = setChargentOrderToStopped(recurOrder,
                    'Order was not linked to Account Bill and/or Entity, cannot find next in series');
            }
            orderMap.put(recurOrder.Account_Bill__c, recurOrder);
        }
        update uncheckedFirstAccountBills;
        update chOrders;

        /* If there are any bills that are left over that don't have a Ch Order, clone one:*/
        if (aggregateSbMap.size() > 0) {
            cloneOrderForNewGateway(aggregateSbMap, orderMap);
        }
    }

    private String getChargentOrderKey(ChargentOrders__ChargentOrder__c recurOrder) {
        Integer newBillNumber = Integer.valueOf(recurOrder.Account_Bill__r.Bill_Number__c) + 1;
        if (recurOrder.Account_Bill__r.Bill_Number__c == 1 &&
            recurOrder.ChargentOrders__Account__r.Max_Account_Bill_Number__c == 1) {
            return Integer.valueOf(recurOrder.Account_Bill__r.Bill_Number__c) + '_' + recurOrder.Property_Account_ID__c;
        } else {
            return newBillNumber + '_' + recurOrder.Property_Account_ID__c;
        }
    }
    
    private void moveAndSetOrder(Map<String, Account_Bill__c> abMap, String chargentOrderKey,
        ChargentOrders__ChargentOrder__c recurOrder, Map<String, Decimal> aggregateSbMap, Id entityId) {
        Decimal newChargeAmount;
        if (abMap.containsKey(chargentOrderKey)) {
            recurOrder.Account_Bill__c = abMap.get(chargentOrderKey).Id;
            if (aggregateSbMap.containsKey(abMap.get(chargentOrderKey).Id + '_' + entityId)) {
                newChargeAmount = aggregateSbMap.remove(abMap.get(chargentOrderKey).Id + '_' + entityId);
                recurOrder.ChargentOrders__Charge_Amount__c = newChargeAmount.setScale(2, RoundingMode.HALF_UP);
                if (recurOrder.ChargentOrders__Charge_Amount__c == 0) {
                    pushPaymentStartDate(recurOrder);
                }
            } else {
                recurOrder = setChargentOrderToStopped(recurOrder,
                    'No System Bills found for this Account Bill: ' + abMap.get(chargentOrderKey).Id);
            }
        } else {
            if (recurOrder.Account_Bill__r.Due_Date_SB__c >= Date.today()) {
                // The chargent order is on a bill that's due today or in the future - could be because someone
                // updated their autopay information which is saved on the most recent bill
                // We just need to set the new charge amount
                newChargeAmount = aggregateSbMap.remove(recurOrder.Account_Bill__c + '_' + entityId);
                recurOrder.ChargentOrders__Charge_Amount__c = newChargeAmount.setScale(2, RoundingMode.HALF_UP);
                if (recurOrder.ChargentOrders__Charge_Amount__c == 0) {
                    pushPaymentStartDate(recurOrder);
                }
            } else {
                recurOrder = setChargentOrderToStopped(recurOrder,
                    'No Account Bill found for Bill Number and Property Account Id: ' + chargentOrderKey);
            }
        }
    }

    // We don't want to charge $0 since that results in extra Chargent Transactions and Errors, so we'll push the
    // Payment Start Date out to the next cycle
    private void pushPaymentStartDate(ChargentOrders__ChargentOrder__c recurOrder) {
        if (recurOrder.ChargentOrders__Charge_Amount__c != 0) {
            return;
        }
        recurOrder.ChargentOrders__Payment_Start_Date__c = newPaymentStartDate(
            Date.today(),
            Integer.valueOf(recurOrder.ChargentOrders__Charge_Date__c),
            recurOrder.ChargentOrders__Payment_Start_Date__c
        );
    }

    @TestVisible
    private static Date newPaymentStartDate(Date today, Integer chargeDate, Date oldPaymentStartDate) {
        Date nextAutopayRun = getNextAutopayDate(today, chargeDate);
        Date nextTransactionDate = getNextTransactionDate(oldPaymentStartDate, nextAutopayRun, chargeDate);
        if (nextTransactionDate > nextAutopayRun) {
            return oldPaymentStartDate;
        } else {
            return Date.newInstance(nextTransactionDate.year(), nextTransactionDate.month() + 1, chargeDate);
        }
    }

    private static Date getNextAutopayDate(Date today, Integer chargeDate) {
        if (today.day() <= chargeDate) {
            return Date.newInstance(today.year(), today.month(), chargeDate);
        } else {
            return Date.newInstance(today.year(), today.month() + 1, chargeDate);
        }
    }

    // Chargent sets Next Transaction Date after charges, but it can be changed as well. We'll calculate it instead
    private static Date getNextTransactionDate(Date oldPaymentStartDate, Date nextAutopayRun, Integer chargeDate) {
        if (oldPaymentStartDate <= nextAutopayRun) {
            return nextAutopayRun;
        } else {
            if (oldPaymentStartDate.day() == chargeDate) {
                return Date.newInstance(oldPaymentStartDate.year(), oldPaymentStartDate.month(), chargeDate);
            } else {
                return Date.newInstance(oldPaymentStartDate.year(), oldPaymentStartDate.month() + 1, chargeDate);
            }
        }
    }


    public static ChargentOrders__ChargentOrder__c setChargentOrderToStopped(ChargentOrders__ChargentOrder__c orderToStop,
        String stopMessage) {
        orderToStop.ChargentOrders__Charge_Amount__c = 0;
        orderToStop.ChargentOrders__Payment_Status__c = 'Stopped';
        orderToStop.Reason_for_Recurring_Stop__c = stopMessage;
        return orderToStop;
    }

    public void cloneOrderForNewGateway(Map<String, Decimal> aggregateSbMap, Map<Id, ChargentOrders__ChargentOrder__c> orderMap) {
        List<ChargentOrders__ChargentOrder__c> allOrders = [
            SELECT Id, Name, ChargentOrders__Payment_Status__c, ChargentOrders__Charge_Amount__c, Account_Bill__c,
                ChargentOrders__Account__r.Max_Account_Bill_Number__c, Property_Account_ID__c, Entity__c
            FROM ChargentOrders__ChargentOrder__c
            WHERE ChargentOrders__Payment_Status__c = 'Recurring'
            ORDER BY CreatedDate
        ];
        Map<String, ChargentOrders__ChargentOrder__c> allChargentOrderMap = new Map<String, ChargentOrders__ChargentOrder__c>();
        for (ChargentOrders__ChargentOrder__c order : allOrders) {
            String entity = order.Entity__c;
            String key = order.Property_Account_ID__c + '_' + entity.substring(0,15);
            allChargentOrderMap.put(key, order);
        }
        List<ChargentOrders__ChargentOrder__c> ordersToInsert = new List<ChargentOrders__ChargentOrder__c>();
        for (String sbWithoutOrder : aggregateSbMap.keySet()) {
            String acctBillid = sbWithoutOrder.substring(0,18);
            String entityId = sbWithoutOrder.substring(19,34);
            Decimal amountToCharge = aggregateSbMap.get(sbWithoutOrder).setScale(2, RoundingMode.HALF_UP);
            ChargentOrders__ChargentOrder__c orderInput = orderMap.get(acctBillid);
            if (orderInput != null
                && orderInput.ChargentOrders__Payment_Status__c == 'Recurring'
                && !allChargentOrderMap.containsKey(orderInput.Property_Account_ID__c + '_' + entityId)
                ) {
                ChargentOrders__ChargentOrder__c orderA = orderInput.clone(false,true,true,false);
                orderA.ChargentOrders__Subtotal__c = amountToCharge;
                orderA.ChargentOrders__Charge_Amount__c = amountToCharge;
                orderA.ChargentOrders__Payment_Frequency__c = 'Monthly';
                orderA.ChargentOrders__Payment_Status__c = 'Recurring';
                orderA.ChargentOrders__Payment_Stop__c = 'Unending';
                orderA.ChargentOrders__Charge_Date__c = '01';
                orderA.Reason_for_Recurring_Stop__c = '';
                orderA.Comments__c = 'Cloned Order';
                orderA.Entity__c = entityId;
                orderA.ChargentOrders__Payment_Start_Date__c = Date.today().addDays(-1);
                ordersToInsert.add(orderA);  
            }
        } 
        insert ordersToInsert;
    }

    public void finish(Database.BatchableContext bc) {
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
            MessagingService.createAndSendEmail(emailBody,
                'customercare@bluewavesolar.com', 'CS Recurring Processing Complete', postJobEmailAddresses);
        }
    }

    public static void updateAccountAutopay(List<ChargentOrders__ChargentOrder__c> newOrders) {
        List<String> ordersIdList = new List<String>();
        for (ChargentOrders__ChargentOrder__c order : newOrders) {
            ordersIdList.add(order.Id);
        }

        List<ChargentOrders__ChargentOrder__c> orderList = [
        	SELECT Id,
                ChargentOrders__Payment_Status__c, Account_Bill__r.Parent_Account__c, ChargentOrders__Account__c,
                Account_Bill__r.Parent_Account__r.Recurring_Billing__c, ChargentOrders__Account__r.Recurring_Billing__c,
                Account_Bill__r.Parent_Account__r.RecordTypeId, ChargentOrders__Account__r.RecordTypeId
            FROM ChargentOrders__ChargentOrder__c
            WHERE Id IN : ordersIdList
        ];

        /*
        	Since this is triggered after ChargentOrders is updated the below list should
        	exclude any 'Recurring' ChargentOrders that have been changed to 'Stopped'
        */
        List<ChargentOrders__ChargentOrder__c> ordersWithAutopay = new List<ChargentOrders__ChargentOrder__c>([
    		SELECT Account_Bill__r.Parent_Account__c, ChargentOrders__Account__c
    		FROM ChargentOrders__ChargentOrder__c
    		WHERE ChargentOrders__Payment_Status__c = 'Recurring'
            AND Id NOT IN: ordersIdList
        ]);

        Set<Id> accountsWithAutopay = new Set<Id>();

        for (ChargentOrders__ChargentOrder__c order : ordersWithAutopay) {
            if (order.Account_Bill__r == null && order.ChargentOrders__Account__c != null) {
                accountsWithAutopay.add(order.ChargentOrders__Account__c);
            } else {
                accountsWithAutopay.add(order.Account_Bill__r.Parent_Account__c);
            }
        }

        Map<String, Account> accountsToUpdate = new Map<String, Account>();

        for (ChargentOrders__ChargentOrder__c order : orderList) {
            Account account = getChOrderAccount(order);
            if (account == null) break;

            if (order.ChargentOrders__Payment_Status__c == 'Recurring') {
                account.Recurring_Billing__c = true;
                accountsToUpdate.put(account.Id, account);
            } else if (!accountsWithAutopay.contains(account.Id)){
                account.Recurring_Billing__c = false;
                accountsToUpdate.put(account.Id, account);
            }
        }

        update accountsToUpdate.values();
    }

    // Called by the ChargentOrderTrigger after a new Chargent Order is inserted
    public static void closeOrdersWithDuplicateAccountAndEntity(List<ChargentOrders__ChargentOrder__c> newOrders) {

        List<Id> orderIds = new List<Id>();
        for (ChargentOrders__ChargentOrder__c order : newOrders) {
            orderIds.add(order.Id);
        }

        List<ChargentOrders__ChargentOrder__c> orders =
        [SELECT Id, ChargentOrders__Account__c, Account_Bill__r.Parent_Account__c,
            Entity_Name__c, ChargentOrders__Payment_Status__c, ChargentOrders__Charge_Date__c
        FROM ChargentOrders__ChargentOrder__c
        WHERE Id IN : orderIds
        AND ChargentOrders__Payment_Status__c = 'Recurring'];

        Map<String, ChargentOrders__ChargentOrder__c> entityToOrderMap = new Map<String, ChargentOrders__ChargentOrder__c>();

        List<String> newOrderEntites = new List<String>();
        for (ChargentOrders__ChargentOrder__c order : orders) {
            entityToOrderMap.put(order.Entity_Name__c, order);
            newOrderEntites.add(order.Entity_Name__c);
        }

        List<ChargentOrders__ChargentOrder__c> possibleDuplicates =
        [SELECT Id, ChargentOrders__Account__c, Account_Bill__r.Parent_Account__c,
            Entity_Name__c, ChargentOrders__Payment_Status__c, ChargentOrders__Charge_Date__c
        FROM ChargentOrders__ChargentOrder__c
        WHERE Entity_Name__c IN : newOrderEntites
        AND ChargentOrders__Payment_Status__c = 'Recurring'
        AND (NOT Id IN : orderIds)];

        List<ChargentOrders__ChargentOrder__c> definiteDuplicates = new List<ChargentOrders__ChargentOrder__c>();

        for (ChargentOrders__ChargentOrder__c possibleDuplicate : possibleDuplicates) {
            if (entityToOrderMap.containsKey(possibleDuplicate.Entity_Name__c)) {

                ChargentOrders__ChargentOrder__c newOrder = entityToOrderMap.get(possibleDuplicate.Entity_Name__c);

                if (newOrder.ChargentOrders__Account__c != null) {
                    if (newOrder.ChargentOrders__Account__c == possibleDuplicate.ChargentOrders__Account__c ||
                        newOrder.ChargentOrders__Account__c == possibleDuplicate.Account_Bill__r.Parent_Account__c) {
                        definiteDuplicates.add(possibleDuplicate);
                    }
                } else {
                    if (newOrder.Account_Bill__r.Parent_Account__c != null &&
                        (newOrder.Account_Bill__r.Parent_Account__c == possibleDuplicate.ChargentOrders__Account__c ||
                            newOrder.Account_Bill__r.Parent_Account__c == possibleDuplicate.Account_Bill__r.Parent_Account__c)) {
                        definiteDuplicates.add(possibleDuplicate);
                    }
                }
            }
        }

        for (ChargentOrders__ChargentOrder__c dup : definiteDuplicates) {
            dup.ChargentOrders__Payment_Status__c = 'Stopped';
            dup.Reason_for_Recurring_Stop__c = 'Another order was created with the same Account and Entity';
        }

        if (definiteDuplicates.size() > 0) {
            update definiteDuplicates;
        }
    }

    public static Account getChOrderAccount(ChargentOrders__ChargentOrder__c order) {
        Account account;
        if (order.Account_Bill__r != null) {
            account = order.Account_Bill__r.Parent_Account__r;
        } else if (order.ChargentOrders__Account__r != null) {
            account = order.ChargentOrders__Account__r;
        } else {
            return null;
        }
        return account;
    }
}