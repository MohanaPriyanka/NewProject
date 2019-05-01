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

    public static void updateClientReports( Map<ID, Client_Health_Report__c> oldReportMap,
                                            Map<ID, Client_Health_Report__c> newReportMap) {
        for (Client_Health_Report__c newReport : newReportMap.values()) {
            if (!oldReportMap.get(newReport.Id).Recalculate_Health_Score__c && newReport.Recalculate_Health_Score__c){
                newReport.Client_Health_Score__c = Util.roundValue(calculateClientHealthScore(newReport),2,null);
            }
        }
    }

    public static Decimal calculateClientHealthScore(Client_Health_Report__c clientReport) {
        Decimal countOfVariables = 0;
        Decimal customerDSO = 0;
        Decimal clientDSO = 0;
        Decimal nps = 0;
        Decimal bluewaveRating = 0;
        Decimal openCases = 0;
        Decimal utilization = 0;

        if (Util.nullToZero(clientReport.Customer_DSO__c) > 0){
            countOfVariables += 1;
            // For every 30 days late (after 30 days), take away a point
            customerDSO = (((clientReport.Customer_DSO__c-30)/30)*-1);
        }
        if (Util.nullToZero(clientReport.Client_DSO__c) > 0){
            countOfVariables += 1;
            // For every 30 days late (after 30 days), take away a point
            clientDSO = (((clientReport.Client_DSO__c-30)/30)*-1);
        }
        if (Util.nullToZero(clientReport.NPS__c) > 0){
            countOfVariables += 1;
            // For every point below 10 take away a point
            nps = (clientReport.NPS__c-10);
        }
        if (Util.nullToZero(clientReport.BlueWave_Rating__c) > 0 || Util.nullToZero(clientReport.Open_Cases__c) > 0){
            countOfVariables += 1;
            if (Util.nullToZero(clientReport.Open_Cases__c) > 5){
                // For every 2 cases above 5 cases, take away a point
                openCases = (((clientReport.Open_Cases__c-5)/2)*-1);
            }
            if (Util.nullToZero(clientReport.BlueWave_Rating__c) > 0){
                // For every point below 10 take away a point
                bluewaveRating = (clientReport.BlueWave_Rating__c-10);
            }
        }
        if (Util.nullToZero(clientReport.Management_Projects_Utilization__c) > 0){
            countOfVariables += 1;
            //For every 1% less than 100%, take away a point
            utilization = (clientReport.Management_Projects_Utilization__c-100);
        }
        Decimal healthScore = 10 + (
            (customerDSO*(1/countOfVariables)) + (clientDSO*(1/countOfVariables)) + (nps*(1/countOfVariables)) +
            (bluewaveRating*(3/(countOfVariables*4))) + (openCases*(1/(countOfVariables*4))) +
            (utilization*(1/countOfVariables)));

        return healthScore;
    }
}