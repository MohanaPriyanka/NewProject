/**
 * @description Capacity Reservation Orders allow us to see the history of reserved capacity changes on SSS. They are
 * related to a Shared Solar System Order, and SSSOTrigger uses this class to makes the changes on the SSS when the SSSO
 * is approved.
 * Tested By: SubscriptionManagementServiceTest
 */
public with sharing class CapacityReserver {
    public void updateSystem(Shared_Solar_System__c sss, List<Capacity_Reservation_Order__c> reservationOrders) {
        for (Capacity_Reservation_Order__c cro : reservationOrders) {
            setSSSCapacity(sss, cro);
        }
    }

    private void setSSSCapacity(Shared_Solar_System__c sss, Capacity_Reservation_Order__c reservationOrder) {
        String capacityType = reservationOrder.Responsible_for_Capacity__c + ' ' + reservationOrder.Customer_Type__c;
        switch on capacityType {
            when 'Perch Anchor' {
                sss.Reserved_Anchor_Capacity__c = reservationOrder.New_Reserved_Capacity_kW_DC__c;
            } when 'Perch Small CS' {
                sss.Perch_Acq_Reserved_Small_CS_Capacity__c = reservationOrder.New_Reserved_Capacity_kW_DC__c;
            } when 'Client Anchor' {
                sss.Client_Acq_Reserved_Anchor_Capacity__c = reservationOrder.New_Reserved_Capacity_kW_DC__c;
            } when 'Client Small CS' {
                sss.Client_Acq_Reserved_Small_CS_Capacity__c = reservationOrder.New_Reserved_Capacity_kW_DC__c;
            }
        }
    }
}