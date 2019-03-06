/*************************************************************************************
 * Created By: peteryao on 2019-03-03  
 * Description: Methods to aid with CS Client Reporting, e.g. client owner stamping
 * Test: ClientReportingServiceTest
 *************************************************************************************/

public without sharing class ClientReportingService {
    public static void beforeTransactionInsert(List<ChargentOrders__Transaction__c> transactions) {
        Set<Id> orderIds = new Set<Id>();
        for (ChargentOrders__Transaction__c trx : transactions) {
            if (trx.Client__c == null) {
                orderIds.add(trx.ChargentOrders__Order__c);
            }
        }
        Map<Id, ChargentOrders__ChargentOrder__c> chargentOrderMap = new Map<Id, ChargentOrders__ChargentOrder__c>([
            SELECT Id, Entity__r.Client_Account__c
            FROM ChargentOrders__ChargentOrder__c
            WHERE Id = :orderIds
        ]);
        for (ChargentOrders__Transaction__c trx : transactions) {
            if (trx.Client__c == null &&
                chargentOrderMap.get(trx.ChargentOrders__Order__c) != null) {
                trx.Client__c = chargentOrderMap.get(trx.ChargentOrders__Order__c).Entity__r.Client_Account__c;
            }
        }
    }

    // We need to wait until the Bill Adjustment is assigned to a UASB to know who the client owner is, so this can't
    // be done on insert
    public static void beforeAdjustmentUpdate(List<Bill_Adjustment__c> adjustments) {
        Set<Id> uasbIds = new Set<Id>();
        for (Bill_Adjustment__c billAdjustment : adjustments) {
            if (billAdjustment.Client__c == null &&
                billAdjustment.UASB__c != null) {
                uasbIds.add(billAdjustment.UASB__c);
            }
        }
        Map<Id, UASB__c> uasbsWithClientMap = new Map<Id, UASB__c>([
            SELECT Id, System_Bill__r.Shared_Solar_System__r.BWC_Project_Entity_Manual__r.Client_Account__c
            FROM UASB__c
            WHERE Id = :uasbIds
        ]);
        for (Bill_Adjustment__c billAdjustment : adjustments) {
            UASB__c uasbWithClient = uasbsWithClientMap.get(billAdjustment.UASB__c);
            if (billAdjustment.Client__c == null &&
                billAdjustment.UASB__c != null &&
                uasbWithClient != null) {
                billAdjustment.Client__c =
                    uasbWithClient.System_Bill__r.Shared_Solar_System__r.BWC_Project_Entity_Manual__r.Client_Account__c;
            }
        }
    }

    public static void beforeSystemBillInsert(List<System_Bill__c> systemBills) {
        Set<Id> sharedSolarSystemIds = new Set<Id>();
        for (System_Bill__c systemBill : systemBills) {
            if (systemBill.Client__c == null &&
                systemBill.Shared_Solar_System__c != null) {
                sharedSolarSystemIds.add(systemBill.Shared_Solar_System__c);
            }
        }
        Map<Id, Shared_Solar_System__c> sharedSolarSystemMap = new Map<Id, Shared_Solar_System__c>([
            SELECT Id, BWC_Project_Entity_Manual__r.Client_Account__c
            FROM Shared_Solar_System__c
            WHERE Id = :sharedSolarSystemIds
        ]);
        for (System_Bill__c systemBill : systemBills) {
            if (systemBill.Client__c == null &&
                sharedSolarSystemMap.get(systemBill.Shared_Solar_System__c) != null) {
                systemBill.Client__c = sharedSolarSystemMap.get(systemBill.Shared_Solar_System__c).BWC_Project_Entity_Manual__r.Client_Account__c;
            }
        }
    }
}