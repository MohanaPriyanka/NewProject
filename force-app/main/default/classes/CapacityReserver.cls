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
        String capacityType = reservationOrder.Capacity_Type__c + ' ' +
            reservationOrder.Responsible_for_Capacity__c + ' ' +
            reservationOrder.Customer_Type__c;
        switch on capacityType {
            when 'Acquisition Perch Anchor' {
                sss.Reserved_Anchor_Capacity__c = reservationOrder.New_Reserved_Capacity_kW_DC__c;
            } when 'Acquisition Perch Small CS' {
                sss.Perch_Acq_Reserved_Small_CS_Capacity__c = reservationOrder.New_Reserved_Capacity_kW_DC__c;
            } when 'Acquisition Perch LMI' {
                sss.Perch_Acq_Reserved_LMI_Capacity__c = reservationOrder.New_Reserved_Capacity_kW_DC__c;
            } when 'Acquisition Client Anchor' {
                sss.Client_Acq_Reserved_Anchor_Capacity__c = reservationOrder.New_Reserved_Capacity_kW_DC__c;
            } when 'Acquisition Client Small CS' {
                sss.Client_Acq_Reserved_Small_CS_Capacity__c = reservationOrder.New_Reserved_Capacity_kW_DC__c;
            } when 'Acquisition Client LMI' {
                sss.Client_Acq_Reserved_LMI_Capacity__c = reservationOrder.New_Reserved_Capacity_kW_DC__c;
            } when 'Management Perch Anchor' {
                sss.Perch_Mngd_Forecasted_Anchor_Capacity__c = reservationOrder.New_Reserved_Capacity_kW_DC__c;
            } when 'Management Perch Resi' {
                sss.Perch_Mngd_Forecasted_Resi_Capacity__c = reservationOrder.New_Reserved_Capacity_kW_DC__c;
            } when 'Management Perch C&I' {
                sss.Perch_Mngd_Forecasted_C_I_Capacity__c = reservationOrder.New_Reserved_Capacity_kW_DC__c;
            } when 'Management Perch Small CS' {
                sss.Perch_Mngd_Forecasted_Small_CS_Capacity__c = reservationOrder.New_Reserved_Capacity_kW_DC__c;
            } when 'Management Perch LMI' {
                sss.Perch_Mngd_Forecasted_LMI_Capacity__c = reservationOrder.New_Reserved_Capacity_kW_DC__c;
            } when 'Management Client Anchor' {
                sss.Client_Mngd_Forecasted_Anchor_Capacity__c = reservationOrder.New_Reserved_Capacity_kW_DC__c;
            } when 'Management Client Resi' {
                sss.Client_Mngd_Forecasted_Resi_Capacity__c = reservationOrder.New_Reserved_Capacity_kW_DC__c;
            } when 'Management Client C&I' {
                sss.Client_Mngd_Forecasted_C_I_Capacity__c = reservationOrder.New_Reserved_Capacity_kW_DC__c;
            } when 'Management Client Small CS' {
                sss.Client_Mngd_Forecasted_Small_CS_Capacity__c = reservationOrder.New_Reserved_Capacity_kW_DC__c;
            } when 'Management Client LMI' {
                sss.Client_Mngd_Forecasted_LMI_Capacity__c = reservationOrder.New_Reserved_Capacity_kW_DC__c;
            }
        }
    }
}