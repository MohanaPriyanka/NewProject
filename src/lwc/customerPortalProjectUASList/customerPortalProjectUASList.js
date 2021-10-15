/**
 * Created by rebeccanachison on 10/4/21.
 */

import {LightningElement, wire} from 'lwc';
import {ShowToastEvent} from "lightning/platformShowToastEvent";
import getUtilityAccountSubscriptions
    from '@salesforce/apex/CustomerPortalProjectUASListController.getUtilityAccountSubscriptions';

const COLUMNS = [
    {
        label: 'Utility Account Number',
        fieldName: 'Utility_Account_Log_Name__c',
        type: 'text',
        hideDefaultActions: true
    },
    {
        label: 'Status',
        fieldName: 'Status__c',
        type: 'text',
        hideDefaultActions: true
    },
    {
        label: 'Service Address',
        fieldName: 'Service_Address_From_Log__c',
        type: 'text',
        hideDefaultActions: true
    }
]

export default class CustomerPortalProjectUASList extends LightningElement {

    error;
    solarSubscriptions;
    isLoading = true;

    @wire(getUtilityAccountSubscriptions) solarSubscriptionResults(result) {
        if (result.data) {
            this.solarSubscriptions = result.data;
            this.isLoading = false;
        } else if (result.error) {
            this.error = result.error;
            this.isLoading = false;
            this.handleShowError();
        }
    }

    columns = COLUMNS;

    handleShowError() {
        const event = new ShowToastEvent({
            title: 'Error',
            variant: 'error',
            message: this.error.body.message
        });
        this.dispatchEvent(event);
    }

}