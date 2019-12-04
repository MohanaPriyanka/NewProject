/*************************************************************************************
 * Created By: peteryao on 2019-03-03  
 * Description: Methods to aid with CS Client Reporting, e.g. client owner stamping
 * Test: ClientReportingServiceTest
 *************************************************************************************/
@SuppressWarnings('PMD.ApexCRUDViolation')
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


    public static void insertClientUAS(List<Utility_Account_Subscription__c> uasList) {
        List<Client_Utility_Account_Subscription__c> clientUASList = new List<Client_Utility_Account_Subscription__c> ();

        Set<Id> parentIds = new Set<Id>();
        for (Utility_Account_Subscription__c uas : uasList) {
            parentIds.add(uas.Id);
        }

        //Have to query for parent records again because Triggers do not maintain relationships
        List<Utility_Account_Subscription__c> parentUASList = UASSelector.selectByIds(parentIds);

        for (Utility_Account_Subscription__c parent : parentUASList) {
            if (parent.Opportunity__c != null){
                Client_Utility_Account_Subscription__c child = new Client_Utility_Account_Subscription__c(
                    Name = 'C' + parent.Name,
                    Utility_Account_Subscription__c = parent.Id,
                    Shared_Solar_System__c = parent.Opportunity__r.Shared_Solar_System__r.Id
                );
                clientUASList.add(child);
            }
        }

        try {
            insert clientUASList;
        } catch (Exception e) {
            Logger.logNow('ClientReportingService', 'insertClientUAS', JSON.serialize(uasList) + '\n' + 'Unable to insert Client UASes for UASes: ' + e.getMessage() +
                '\n' + e.getStackTraceString());
        }

    }

    public static void updateClientUAS(Map<Id, Opportunity> oppMap, Map<Id, Opportunity> oldOppMap) {
        Set<Id> oppsToUpdate = new Set<Id>();
        for (Opportunity opp : oppMap.values()) {
            if (opp.Shared_Solar_System__c != oldOppMap.get(opp.Id).Shared_Solar_System__c) {
                oppsToUpdate.add(opp.Id);
            }
        }

        if (oppsToUpdate.size() > 0 ) {

            List<Client_Utility_Account_Subscription__c> clientUASList = ClientReportObjectSelector.getClientUASesByOppIds(oppsToUpdate);

            if (clientUASList.size() > 0 ){
                for (Client_Utility_Account_Subscription__c cUAS : clientUASList) {
                    cUAS.Shared_Solar_System__c = oppMap.get(cUAS.Utility_Account_Subscription__r.Opportunity__c).Shared_Solar_System__c;
                }

                update clientUASList;
            }
        }
    }


    public static void insertClientALSS(List<Schedule_Z_Subscription__c> szsList) {
        List<Client_Allocation_Schedule_Subscription__c> clientALSSList = new List<Client_Allocation_Schedule_Subscription__c>();
        Set<Id> parentIds = new Set<Id>();

        for (Schedule_Z_Subscription__c szs : szsList) {
            parentIds.add(szs.Id);
        }
        //Have to query for parent records again because Triggers do not maintain relationships
        List<Schedule_Z_Subscription__c> parentList = ScheduleZSubscriptionSelector.getScheduleZSubscriptionsList(parentIds);


        //Need to get the Child Client UAS object of the ALSS's UAS
        //Map --> key = ALSS ID, value = Client UAS
        Map<Id, Client_Utility_Account_Subscription__c> alssToClientUASMap = new Map<Id, Client_Utility_Account_Subscription__c>();
        alssToClientUASMap = getClientUtilityAccountSubscriptionsByIds(parentList);


        for (Schedule_Z_Subscription__c parent : parentList) {
            Client_Allocation_Schedule_Subscription__c child = new Client_Allocation_Schedule_Subscription__c(
                Name = 'C' + parent.Name,
                Allocation_Schedule_Subscription__c = parent.Id,
                Allocation_Schedule__c = parent.Schedule_Z__r.Id,
                Client_Utility_Account_Subscription__c = alssToClientUASMap.get(parent.Id).Id
            );
            clientALSSList.add(child);
        }
        insert clientALSSList;

    }

    public static void deleteClientUAS(List<Utility_Account_Subscription__c> uasList) {
        Set<Id> uasIds = new Set<Id>();

        for (Utility_Account_Subscription__c uas : uasList) {
            uasIds.add(uas.Id);
        }

        List<Client_Utility_Account_Subscription__c> clientUASList = ClientReportObjectSelector.getClientUASesByUASIds(uasIds);

        delete clientUASList;
    }

    public static void deleteClientALSS(List<Schedule_Z_Subscription__c> szsList) {
        Set<Id> szsIds = new Set<Id>();

        for (Schedule_Z_Subscription__c szs : szsList) {
            szsIds.add(szs.Id);
        }


        List<Client_Allocation_Schedule_Subscription__c> clientALSSList = ClientReportObjectSelector.getClientALSSBySZSIds(szsIds);

        delete clientALSSList;
    }


    private static  Map<Id, Client_Utility_Account_Subscription__c> getClientUtilityAccountSubscriptionsByIds(List<Schedule_Z_Subscription__c> parentSZSs) {
        Set<Id> uasIds = new Set<Id>();
        Map<Id, Id> uasToALSSMap = new Map<Id, Id>();
        Map<Id, Client_Utility_Account_Subscription__c> alssToClientUASMap = new Map<Id, Client_Utility_Account_Subscription__c>();


        //Map --> key: UAS Id, value: ALSS Id
        for (Schedule_Z_Subscription__c alss : parentSZSs) {
            uasIds.add(alss.Utility_Account_Subscription__c);
            uasToALSSMap.put(alss.Utility_Account_Subscription__c, alss.Id);
        }

        List<Client_Utility_Account_Subscription__c> clientUASList = ClientReportObjectSelector.getClientUASesByUASIds(uasIds);

        for (Client_Utility_Account_Subscription__c clientUAS : clientUASList) {
                // Map --> key = ALSS Id, value = client UAS
                alssToClientUASMap.put(uasToALSSMap.get(clientUAS.Utility_Account_Subscription__c), clientUAS);
        }

        return alssToClientUASMap;

    }
}