/**
 * Created by PeterYao_6fwtfg1 on 1/13/2022.
 */

import {LightningElement, api, wire} from 'lwc';
import {getFieldValue, getRecord} from 'lightning/uiRecordApi';
import LMI_FIELD from '@salesforce/schema/Shared_Solar_System__c.LMI__c';
import STATE_FIELD from '@salesforce/schema/Shared_Solar_System__c.State__c';

export default class SssCapacitySummary extends LightningElement {
    @api recordId;
    @wire(getRecord, { recordId: '$recordId', fields: [LMI_FIELD, STATE_FIELD] })
    sss;

    get lmi() {
        return getFieldValue(this.sss.data, LMI_FIELD);
    }

    get isNY() {
        return getFieldValue(this.sss.data, STATE_FIELD) === 'NY';
    }
}