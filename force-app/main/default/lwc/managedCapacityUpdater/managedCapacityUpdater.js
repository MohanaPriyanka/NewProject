/**
 * Created by PeterYao_6fwtfg1 on 1/24/2022.
 */

import {LightningElement, api, track} from 'lwc';
import {FlowNavigationNextEvent} from 'lightning/flowSupport';
import {addCapacityReservationOrder} from 'c/reservedCapacityUpdater';

export default class ManagedCapacityUpdater extends LightningElement {
    @api sssRecord;
    @api newSSSSize;
    @api capacityReservationOrders;
    currentTotal;
    newTotal;
    newTotalDifferenceFromNewSize;
    clientManagedAnchor;
    clientManagedResi;
    clientManagedResiDisabled;
    clientManagedCI;
    clientManagedCIDisabled;
    clientManagedSmallCS;
    clientManagedSmallCSDisabled;
    clientManagedLMI;
    perchManagedAnchor;
    perchManagedResi;
    perchManagedResiDisabled;
    perchManagedCI;
    perchManagedCIDisabled;
    perchManagedSmallCS;
    perchManagedSmallCSDisabled;
    perchManagedLMI;
    newReservedSumNotEqualToNewSize = true;
    isLMI;

    connectedCallback() {
        this.clientManagedResi = this.sssRecord.Client_Mngd_Forecasted_Resi_Capacity__c;
        this.clientManagedCI = this.sssRecord.Client_Mngd_Forecasted_C_I_Capacity__c;
        this.clientManagedSmallCS = this.sssRecord.Client_Mngd_Forecasted_Small_CS_Capacity__c;
        this.clientManagedAnchor = this.sssRecord.Client_Mngd_Forecasted_Anchor_Capacity__c;
        this.clientManagedLMI = this.sssRecord.Client_Mngd_Forecasted_LMI_Capacity__c;
        this.perchManagedResi = this.sssRecord.Perch_Mngd_Forecasted_Resi_Capacity__c;
        this.perchManagedCI = this.sssRecord.Perch_Mngd_Forecasted_C_I_Capacity__c;
        this.perchManagedSmallCS = this.sssRecord.Perch_Mngd_Forecasted_Small_CS_Capacity__c;
        this.perchManagedLMI = this.sssRecord.Perch_Mngd_Forecasted_LMI_Capacity__c;
        this.perchManagedAnchor = this.sssRecord.Perch_Mngd_Forecasted_Anchor_Capacity__c;
        this.isLMI = this.sssRecord.LMI__c;
        this.currentTotal =
            this.sssRecord.Client_Mngd_Forecasted_Anchor_Capacity__c +
            this.sssRecord.Client_Mngd_Forecasted_Resi_Capacity__c +
            this.sssRecord.Client_Mngd_Forecasted_C_I_Capacity__c +
            this.sssRecord.Client_Mngd_Forecasted_Small_CS_Capacity__c +
            this.sssRecord.Client_Mngd_Forecasted_LMI_Capacity__c;
        this.currentTotal +=
            this.sssRecord.Perch_Mngd_Forecasted_Resi_Capacity__c +
            this.sssRecord.Perch_Mngd_Forecasted_C_I_Capacity__c +
            this.sssRecord.Perch_Mngd_Forecasted_Small_CS_Capacity__c +
            this.sssRecord.Perch_Mngd_Forecasted_LMI_Capacity__c +
            this.sssRecord.Perch_Mngd_Forecasted_Anchor_Capacity__c;
        if (!this.newSSSSize) {
            this.newSSSSize = this.sssRecord.Total_System_Size_kWh_DC__c;
        }
        this.disableFields();
        this.calculateNewTotal();
    }

    genericOnChange(event) {
        this[event.target.name] = event.target.value;
        if (event.target.dataset.capacityType) {
            this.disableFields();
        }
        this.calculateNewTotal();
        this.setCapacityReservationOrders();
    }

    disableFields() {
        if (this.perchManagedSmallCS) {
            this.perchManagedCIDisabled = true;
            this.perchManagedResiDisabled = true;
            this.perchManagedSmallCSDisabled = false;
        } else {
            this.perchManagedCIDisabled = false;
            this.perchManagedResiDisabled = false;
        }

        if (this.perchManagedCI || this.perchManagedResi) {
            this.perchManagedSmallCSDisabled = true;
            this.perchManagedCIDisabled = false;
            this.perchManagedResiDisabled = false;
        } else {
            this.perchManagedSmallCSDisabled = false;
        }

        if (this.clientManagedSmallCS) {
            this.clientManagedCIDisabled = true;
            this.clientManagedResiDisabled = true;
            this.clientManagedSmallCSDisabled = false;
        } else {
            this.clientManagedCIDisabled = false;
            this.clientManagedResiDisabled = false;
        }

        if (this.clientManagedCI || this.clientManagedResi) {
            this.clientManagedSmallCSDisabled = true;
            this.clientManagedCIDisabled = false;
            this.clientManagedResiDisabled = false;
        } else {
            this.clientManagedSmallCSDisabled = false;
        }
    }

    calculateNewTotal() {
        this.newTotal = this.round(
            +this.clientManagedAnchor +
            +this.clientManagedResi +
            +this.clientManagedCI +
            +this.clientManagedSmallCS +
            +this.clientManagedLMI +
            +this.perchManagedAnchor +
            +this.perchManagedLMI +
            +this.perchManagedResi +
            +this.perchManagedCI +
            +this.perchManagedSmallCS);
        this.newTotalDifferenceFromNewSize = this.round(this.newSSSSize - this.newTotal);
        this.newReservedSumNotEqualToNewSize = !!this.newTotalDifferenceFromNewSize;
    }

    get newTotalClass() {
        return this.newReservedSumNotEqualToNewSize ? 'slds-text-color_error' : '';
    }

    round(num) {
        let m = Number((Math.abs(num) * 100).toPrecision(15));
        return Math.round(m) / 100 * Math.sign(num);
    }

    setCapacityReservationOrders() {
        this.capacityReservationOrders = [];
        addCapacityReservationOrder(
            this.capacityReservationOrders,
            this.sssRecord.Client_Mngd_Forecasted_Resi_Capacity__c,
            this.clientManagedResi,
            'Client',
            'Resi',
            'Management',
            this.sssRecord.Id
        );
        addCapacityReservationOrder(
            this.capacityReservationOrders,
            this.sssRecord.Client_Mngd_Forecasted_C_I_Capacity__c,
            this.clientManagedCI,
            'Client',
            'C&I',
            'Management',
            this.sssRecord.Id
        );
        addCapacityReservationOrder(
            this.capacityReservationOrders,
            this.sssRecord.Client_Mngd_Forecasted_Small_CS_Capacity__c,
            this.clientManagedSmallCS,
            'Client',
            'Small CS',
            'Management',
            this.sssRecord.Id
        );
        addCapacityReservationOrder (
            this.capacityReservationOrders,
            this.sssRecord.Client_Mngd_Forecasted_Anchor_Capacity__c,
            this.clientManagedAnchor,
            'Client',
            'Anchor',
            'Management',
            this.sssRecord.Id
        );
        addCapacityReservationOrder (
            this.capacityReservationOrders,
            this.sssRecord.Client_Mngd_Forecasted_LMI_Capacity__c,
            this.clientManagedLMI,
            'Client',
            'LMI',
            'Management',
            this.sssRecord.Id
        );
        addCapacityReservationOrder(
            this.capacityReservationOrders,
            this.sssRecord.Perch_Mngd_Forecasted_Resi_Capacity__c,
            this.perchManagedResi,
            'Perch',
            'Resi',
            'Management',
            this.sssRecord.Id
        );
        addCapacityReservationOrder(
            this.capacityReservationOrders,
            this.sssRecord.Perch_Mngd_Forecasted_C_I_Capacity__c,
            this.perchManagedCI,
            'Perch',
            'C&I',
            'Management',
            this.sssRecord.Id
        );
        addCapacityReservationOrder(
            this.capacityReservationOrders,
            this.sssRecord.Perch_Mngd_Forecasted_Small_CS_Capacity__c,
            this.perchManagedSmallCS,
            'Perch',
            'Small CS',
            'Management',
            this.sssRecord.Id
        );
        addCapacityReservationOrder(
            this.capacityReservationOrders,
            this.sssRecord.Perch_Mngd_Forecasted_Anchor_Capacity__c,
            this.perchManagedAnchor,
            'Perch',
            'Anchor',
            'Management',
            this.sssRecord.Id
        );
        addCapacityReservationOrder (
            this.capacityReservationOrders,
            this.sssRecord.Perch_Mngd_Forecasted_LMI_Capacity__c,
            this.perchManagedLMI,
            'Perch',
            'LMI',
            'Management',
            this.sssRecord.Id
        );
    }

    handleNext(event) {
        const nextNavigationEvent = new FlowNavigationNextEvent();
        this.dispatchEvent(nextNavigationEvent);
    }
}