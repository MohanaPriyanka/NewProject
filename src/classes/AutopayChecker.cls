/*************************************************************************************
 * Created By: peteryao on 10/17/18
 * Description:
 * Tested by: AutopayCheckerTest
 *************************************************************************************/

public with sharing class AutopayChecker implements Queueable {
    Id autopayScheduleId;
    Map<Id, ChargentBase__Gateway__c> gateways;
    List<ChargentOrders__ChargentOrder__c> recurringOrders;
    public AutopayChecker(Id autopayScheduleId) {
        this.autopayScheduleId = autopayScheduleId;
        recurringOrders = [
            SELECT Id, Account_Bill__c, Account_Bill__r.Bill_Number__c, Account_Bill__r.Parent_Account__r.Max_Account_Bill_Number__c,
                Account_Bill__r.Due_Date_SB__c, Property_Account__c, Account_Bill__r.Carry_Over_Balance__c,
                ChargentOrders__Charge_Date__c, ChargentOrders__Charge_Amount__c, ChargentOrders__Payment_Start_Date__c,
                ChargentOrders__Next_Transaction_Date__c, Entity__c, ChargentOrders__Gateway__c, ChargentOrders__Billing_Last_Name__c
            FROM ChargentOrders__ChargentOrder__c
            WHERE ChargentOrders__Payment_Status__c = 'Recurring'
        ];
        gateways = new Map<Id, ChargentBase__Gateway__c>([SELECT Id, Name FROM ChargentBase__Gateway__c]);
    }

    public void execute(QueueableContext context) {
        Autopay_Schedule__c autopaySchedule;
        List<Autopay_Schedule__c> autopaySchedules = [
            SELECT Id, Summary__c
            FROM Autopay_Schedule__c
            WHERE Id =: autopayScheduleId
            LIMIT 1
        ];
        if (autopaySchedules.size() != 1) {
            Logger.logNow('AutopayChecker', 'execute', 'No autopay schedule found with Id ' + autopayScheduleId);
            return;
        } else {
            autopaySchedule = autopaySchedules[0];
        }
        autopaySchedule.Summary__c += '\n\n';
        autopaySchedule.Summary__c += getTotalAmountByGateway().message + '\n';
        autopaySchedule.Summary__c += checkRecurringOrdersOnLastAccountBill().message + '\n';
        autopaySchedule.Summary__c += checkSingleOrderPerAccountEntity().message + '\n';
        autopaySchedule.Summary__c += checkChargeAmountEqualsCarryoverBalance().message + '\n';
        autopaySchedule.Summary__c += checkZeroDollarChargentOrdersNotToFire().message + '\n';
        autopaySchedule.Summary__c += checkChargentOrderEntitiesAndGatewaysAgainstAccountBill().message + '\n';

        update autopaySchedule;
    }

    public QCResult getTotalAmountByGateway() {
        // In case we have payments on different charge dates (not 01 or 1):
        Map<Integer, Map<Id, GatewayTotal>> gatewayTotalsByChargeDate = getGatewayTotalsByChargeDate();
        String message = 'Gateway Totals by Charge Date:\n';
        for (Integer chargeDate : gatewayTotalsByChargeDate.keySet()) {
            message += 'Charge Date: ' + chargeDate + '\n';
            List<GatewayTotal> gatewayTotals = gatewayTotalsByChargeDate.get(chargeDate).values();
            gatewayTotals.sort();
            for (GatewayTotal gatewayTotal : gatewayTotals) {
                message += gatewayTotal.gatewayName + ': $' + gatewayTotal.total.format() + '\n';
            }
        }
        return new QCResult(true, message);
    }

    private Map<Integer, Map<Id, GatewayTotal>> getGatewayTotalsByChargeDate() {
        List<AggregateResult> results = [
            SELECT ChargentOrders__Charge_Date__c, ChargentOrders__Gateway__c, SUM(ChargentOrders__Charge_Amount__c) total
            FROM ChargentOrders__ChargentOrder__c
            WHERE ChargentOrders__Payment_Status__c = 'Recurring'
            GROUP BY ChargentOrders__Charge_Date__c, ChargentOrders__Gateway__c
        ];

        Map<Integer, Map<Id, GatewayTotal>> gatewayTotalsByChargeDate = new Map<Integer, Map<Id, GatewayTotal>>();
        for (AggregateResult result : results) {
            Integer chargeDate = 0;
            if (result.get('ChargentOrders__Charge_Date__c') != null) {
                chargeDate = Integer.valueOf(result.get('ChargentOrders__Charge_Date__c'));
            }
            GatewayTotal gatewayTotal = new GatewayTotal(this, result);
            if (gatewayTotalsByChargeDate.containsKey(chargeDate)) {
                gatewayTotal.addToGatewayTotalList(gatewayTotalsByChargeDate.get(chargeDate));
            } else {
                gatewayTotalsByChargeDate.put(chargeDate, new Map<Id, GatewayTotal>{gatewayTotal.gatewayId=>gatewayTotal});
            }
        }
        return gatewayTotalsByChargeDate;
    }

    public QCResult checkRecurringOrdersOnLastAccountBill() {
        Boolean passed = true;
        List<Id> orderIds = new List<Id>();
        for (ChargentOrders__ChargentOrder__c order : recurringOrders) {
            if (order.Account_Bill__c == null ||
                order.Account_Bill__r.Bill_Number__c != order.Account_Bill__r.Parent_Account__r.Max_Account_Bill_Number__c ||
                order.Account_Bill__r.Due_Date_SB__c < Date.today()) {
                passed = false;
                orderIds.add(order.Id);
            }
        }
        String message;
        if (orderIds.isEmpty()) {
            message = 'All recurring orders are the latest account bill';
        } else {
            message = 'These orders are not on the latest account bill: (' + trimIdList(orderIds) + ')\n';
        }
        return new QCResult(passed, message);
    }

    public QCResult checkSingleOrderPerAccountEntity() {
        List<AggregateResult> results = [
            SELECT Account_Bill__r.Parent_Account__c account, Entity__c, COUNT(Id) numOrders
            FROM ChargentOrders__ChargentOrder__c
            WHERE ChargentOrders__Payment_Status__c = 'Recurring'
            AND Account_Bill__c != NULL
            GROUP BY Account_Bill__r.Parent_Account__c, Entity__c
            ORDER BY COUNT(Id) DESC
        ];

        Boolean passed = true;
        List<Id> accountIds = new List<Id>();
        for (AggregateResult result : results) {
            if ((Integer) result.get('numOrders') > 1) {
                accountIds.add((Id) result.get('account'));
                passed = false;
            } else {
                break;
            }
        }
        String message;
        if (accountIds.isEmpty()) {
            message = 'All accounts and entities combinations have a single order';
        } else {
            message = 'These accounts have multiple chargent orders for the same entity: ' +
                '(' + trimIdList(accountIds) + ')\n';
        }

        return new QCResult(passed, message);
    }

    public QCResult checkChargeAmountEqualsCarryoverBalance() {
        Map<Id, Decimal> chargeAmountByAccountBill = new Map<Id, Decimal>();
        Map<Id, Decimal> carryoverByAccountBill = new Map<Id, Decimal>();
        for (ChargentOrders__ChargentOrder__c order : recurringOrders) {
            // Orders without an Account Bill are reported by checkRecurringOrdersOnLastAccountBill
            if (order.Account_Bill__c == null) {
                continue;
            }
            if (chargeAmountByAccountBill.containsKey(order.Account_Bill__c)) {
                chargeAmountByAccountBill.put(order.Account_Bill__c,
                    chargeAmountByAccountBill.get(order.Account_Bill__c) + order.ChargentOrders__Charge_Amount__c);
            } else {
                chargeAmountByAccountBill.put(order.Account_Bill__c, order.ChargentOrders__Charge_Amount__c);
            }
            carryoverByAccountBill.put(order.Account_Bill__c, order.Account_Bill__r.Carry_Over_Balance__c);
        }
        List<Id> accountBillsWithIncorrectChargentOrders = new List<Id>();
        Boolean passed = true;
        for (Id accountBillId : carryoverByAccountBill.keySet()) {
            if (chargeAmountByAccountBill.get(accountBillId) != carryoverByAccountBill.get(accountBillId)) {
                accountBillsWithIncorrectChargentOrders.add(accountBillId);
                passed = false;
            }
        }
        String message;
        if (accountBillsWithIncorrectChargentOrders.isEmpty()) {
            message = 'All Chargent Order Charge Amounts total the Account Bill Carryover Balances';
        } else {
            message = accountBillsWithIncorrectChargentOrders.size() + ' Account Bills have Chargent Orders that don\'t add up: ' +
                '(' + trimIdList(accountBillsWithIncorrectChargentOrders) + ')\n';
        }
        return new QCResult(passed, message);
    }

    public QCResult checkZeroDollarChargentOrdersNotToFire() {
        Boolean passed = true;
        String message = 'All zero dollar Chargent Orders have been pushed to the future';
        List<Id> orderIds = new List<Id>();

        for (ChargentOrders__ChargentOrder__c order : recurringOrders) {
            Date nextAutopayDate =
                RecurringPaymentsHandler.getNextAutopayDate(Date.today(), Integer.valueOf(order.ChargentOrders__Charge_Date__c));
            if (order.Account_Bill__c != null &&
                order.ChargentOrders__Charge_Amount__c == 0 &&
                order.ChargentOrders__Payment_Start_Date__c <= nextAutopayDate) {
                orderIds.add(order.Id);
                passed = false;
            }
        }
        if (!passed) {
            message = orderIds.size() + ' Chargent Orders will be charged $0 on the Charge Date and get stopped: ' +
                '(' + trimIdList(orderIds) + ')\n';
        }

        return new QCResult(passed, message);
    }

    public QCResult checkChargentOrderEntitiesAndGatewaysAgainstAccountBill() {
        Boolean passed = true;
        String message = 'All Chargent Orders have an Entity and Gateway on their corresponding System Bill';
        List<Id> chargentOrdersWithUnexpectedEntityGateway = new List<Id>();

        Set<Id> accountBillIds = new Set<Id>();
        for (ChargentOrders__ChargentOrder__c order : recurringOrders) {
            accountBillIds.add(order.Account_Bill__c);
        }
        Map<Id, Account_Bill__c> accountBillMap = new Map<Id, Account_Bill__c>([
            SELECT Id,
            (SELECT Id, Shared_Solar_System__r.BWC_Project_Entity_Manual__c,
                Shared_Solar_System__r.BWC_Project_Entity_Manual__r.Gateway__c
            FROM System_Bills__r)
            FROM Account_Bill__c
            WHERE Id = :accountBillIds
        ]);
        for (ChargentOrders__ChargentOrder__c order : recurringOrders) {
            Boolean foundEntityAndGateway = false;
            if (order.Account_Bill__c == null) {
                // Orders without an Account Bill are reported by checkRecurringOrdersOnLastAccountBill
                continue;
            }
            for (System_Bill__c systemBill : accountBillMap.get(order.Account_Bill__c).System_Bills__r) {
                if (systemBill.Shared_Solar_System__r.BWC_Project_Entity_Manual__c == order.Entity__c &&
                    systemBill.Shared_Solar_System__r.BWC_Project_Entity_Manual__r.Gateway__c == order.ChargentOrders__Gateway__c) {
                    foundEntityAndGateway = true;
                    break;
                }
            }
            if (!foundEntityAndGateway) {
                passed = false;
                chargentOrdersWithUnexpectedEntityGateway.add(order.Id);
            }
        }
        if (chargentOrdersWithUnexpectedEntityGateway.size() > 0) {
            message = chargentOrdersWithUnexpectedEntityGateway.size() +
                ' Chargent Orders have an unexpected Entity or Gateway: ' +
                '(' + trimIdList(chargentOrdersWithUnexpectedEntityGateway) + ')\n';
        }

        return new QCResult(passed, message);
    }

    private String trimIdList(List<Id> ids) {
        String idString = String.join(ids, ',');
        if (idString.length() > 500) {
            idString = idString.left(500) + '...';
        }
        return idString;
    }

    public class QCResult {
        public Boolean passed;
        public String message;

        QCResult(Boolean passed, String message) {
            this.passed = passed;
            this.message = message;
        }
    }

    public class GatewayTotal implements Comparable {
        public AutopayChecker apc;
        public Id gatewayId;
        public String gatewayName;
        public Decimal total;

        GatewayTotal(AutopayChecker apc, AggregateResult result) {
            this.apc = apc;
            this.gatewayId = (Id) result.get('ChargentOrders__Gateway__c');
            this.gatewayName = apc.gateways.get(this.gatewayId).Name;
            this.total = (Decimal) result.get('total');
        }

        public Integer compareTo(Object compareTo) {
            GatewayTotal compareToGT = (GatewayTotal) compareTo;
            Integer returnValue = 0;
            if (this.total < compareToGT.total) {
                returnValue = 1;
            } else if (this.total > compareToGT.total) {
                returnValue = -1;
            }
            return returnValue;
        }

        public void addToGatewayTotalList(Map<Id, GatewayTotal> totals) {
            if (totals.get(this.gatewayId) == null) {
                totals.put(this.gatewayId, this);
            } else {
                totals.get(this.gatewayId).total += this.total;
            }
        }
    }
}