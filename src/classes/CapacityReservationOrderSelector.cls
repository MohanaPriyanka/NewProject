/**
 * Created by PeterYao_6fwtfg1 on 1/25/2022.
 */
@SuppressWarnings('PMD.ApexCRUDViolation')
public without sharing class CapacityReservationOrderSelector {
    public MultiMap getCapacityReservationOrdersBySSSO(List<Shared_Solar_System_Order__c> sharedSolarSystemOrders) {
        List<Capacity_Reservation_Order__c> capacityReservationOrders = [
            SELECT Id, New_Reserved_Capacity_kW_DC__c, Customer_Type__c, Responsible_for_Capacity__c, Shared_Solar_System__c, Shared_Solar_System_Order__c
            FROM Capacity_Reservation_Order__c
            WHERE Shared_Solar_System_Order__c IN :sharedSolarSystemOrders
        ];
        return CollectionUtil.multiMapByField(capacityReservationOrders, Capacity_Reservation_Order__c.Shared_Solar_System_Order__c);
    }
}