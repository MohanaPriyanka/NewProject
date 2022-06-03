/**
 * Created by PeterYao_6fwtfg1 on 1/24/2022.
 */

import {LightningElement, api} from 'lwc';
import {FlowNavigationNextEvent} from 'lightning/flowSupport';

export default class ReservedCapacityUpdater extends LightningElement {
    @api sssRecord;
    @api newSSSSize;
    @api capacityReservationOrders;
    currentTotal;
    newTotal;
    newTotalDifferenceFromNewSize;
    clientAcquiredAnchor;
    clientAcquiredSmallCS;
    clientAcquiredLMI;
    perchAcquiredAnchor;
    perchAcquiredSmallCS;
    perchAcquiredLMI;
    newReservedSumNotEqualToNewSize = true;
    isLMI;

    connectedCallback() {
        this.clientAcquiredSmallCS = this.sssRecord.Client_Acq_Reserved_Small_CS_Capacity__c;
        this.clientAcquiredAnchor = this.sssRecord.Client_Acq_Reserved_Anchor_Capacity__c;
        this.clientAcquiredLMI = this.sssRecord.Client_Acq_Reserved_LMI_Capacity__c;
        this.perchAcquiredSmallCS = this.sssRecord.Perch_Acq_Reserved_Small_CS_Capacity__c;
        this.perchAcquiredLMI = this.sssRecord.Perch_Acq_Reserved_LMI_Capacity__c;
        this.perchAcquiredAnchor = this.sssRecord.Reserved_Anchor_Capacity__c;
        this.isLMI = this.sssRecord.LMI__c;
        this.currentTotal =
            this.sssRecord.Client_Acq_Reserved_Anchor_Capacity__c +
            this.sssRecord.Client_Acq_Reserved_Small_CS_Capacity__c +
            this.sssRecord.Client_Acq_Reserved_LMI_Capacity__c +
            this.sssRecord.Perch_Acq_Reserved_Small_CS_Capacity__c +
            this.sssRecord.Perch_Acq_Reserved_LMI_Capacity__c +
            this.sssRecord.Reserved_Anchor_Capacity__c;
        if (!this.newSSSSize) {
            this.newSSSSize = this.sssRecord.Total_System_Size_kWh_DC__c;
        }
        this.calculateNewTotal();
    }

    genericOnChange(event) {
        this[event.target.name] = event.target.value;
        this.calculateNewTotal();
        this.setCapacityReservationOrders();
    }

    calculateNewTotal() {
        this.newTotal = this.round(
            +this.clientAcquiredAnchor +
            +this.clientAcquiredSmallCS +
            +this.clientAcquiredLMI +
            +this.perchAcquiredAnchor +
            +this.perchAcquiredLMI +
            +this.perchAcquiredSmallCS);
        this.newTotalDifferenceFromNewSize = this.round(this.newSSSSize - this.newTotal);
        this.newReservedSumNotEqualToNewSize = !!this.newTotalDifferenceFromNewSize;
    }

    get newTotalClass() {
        return this.newReservedSumNotEqualToNewSize ? 'slds-text-color_error' : '';
    }

    // https://www.skillsugar.com/round-a-number-to-2-decimal-places-in-javascript
    round(num) {
        let m = Number((Math.abs(num) * 100).toPrecision(15));
        return Math.round(m) / 100 * Math.sign(num);
    }

    setCapacityReservationOrders() {
        this.capacityReservationOrders = [];
        addCapacityReservationOrder(
            this.capacityReservationOrders,
            this.sssRecord.Client_Acq_Reserved_Small_CS_Capacity__c,
            this.clientAcquiredSmallCS,
            'Client',
            'Small CS',
            'Acquisition',
            this.sssRecord.Id
        );
        addCapacityReservationOrder (
            this.capacityReservationOrders,
            this.sssRecord.Client_Acq_Reserved_Anchor_Capacity__c,
            this.clientAcquiredAnchor,
            'Client',
            'Anchor',
            'Acquisition',
            this.sssRecord.Id
        );
        addCapacityReservationOrder (
            this.capacityReservationOrders,
            this.sssRecord.Client_Acq_Reserved_LMI_Capacity__c,
            this.clientAcquiredLMI,
            'Client',
            'LMI',
            'Acquisition',
            this.sssRecord.Id
        );
        addCapacityReservationOrder(
            this.capacityReservationOrders,
            this.sssRecord.Perch_Acq_Reserved_Small_CS_Capacity__c,
            this.perchAcquiredSmallCS,
            'Perch',
            'Small CS',
            'Acquisition',
            this.sssRecord.Id
        );
        addCapacityReservationOrder(
            this.capacityReservationOrders,
            this.sssRecord.Reserved_Anchor_Capacity__c,
            this.perchAcquiredAnchor,
            'Perch',
            'Anchor',
            'Acquisition',
            this.sssRecord.Id
        );
        addCapacityReservationOrder (
            this.capacityReservationOrders,
            this.sssRecord.Perch_Acq_Reserved_LMI_Capacity__c,
            this.perchAcquiredLMI,
            'Perch',
            'LMI',
            'Acquisition',
            this.sssRecord.Id
        );
    }

    handleNext(event) {
        const nextNavigationEvent = new FlowNavigationNextEvent();
        this.dispatchEvent(nextNavigationEvent);
    }
}

const addCapacityReservationOrder = (existingReservationOrders, previousCapacity, newCapacity, responsible, customerType, capacityType, sssId) => {
    if (+previousCapacity !== +newCapacity) {
        existingReservationOrders.push(newCapacityReservationOrder(
            previousCapacity,
            newCapacity,
            responsible,
            customerType,
            capacityType,
            sssId
        ));
    }
};

const newCapacityReservationOrder = (previousCapacity, newCapacity, responsible, customerType, capacityType, sssId) => {
    return {
        'sobjectType': 'Capacity_Reservation_Order__c',
        'Capacity_Type__c' : capacityType,
        'New_Reserved_Capacity_kW_DC__c': newCapacity,
        'Responsible_for_Capacity__c': responsible,
        'Customer_Type__c': customerType,
        'Previous_Reserved_Capacity_kW_DC__c': previousCapacity,
        'Shared_Solar_System__c': sssId
    };
};

export {addCapacityReservationOrder}