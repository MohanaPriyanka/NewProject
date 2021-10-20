/**
 * Created by rebeccanachison on 10/4/21.
 */

import {LightningElement, wire} from 'lwc';
import {ShowToastEvent} from "lightning/platformShowToastEvent";
import getUtilityAccountSubscriptions
    from '@salesforce/apex/CustomerPortalProjectUASListController.getUtilityAccountSubscriptions';

const COLUMNS = [
    {
        label: 'Shared Solar Project',
        fieldName: 'sharedSolarSystemName',
        type: 'text',
        hideDefaultActions: true
    },
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
    utilityAccountSubscriptions;
    isLoading = true;

    @wire(getUtilityAccountSubscriptions) utilityAccountSubscriptionResults(result) {
        if (result.data) {
            this.utilityAccountSubscriptions = result.data.map(row => {
                return {...row, sharedSolarSystemName: row.Shared_Solar_System__r.Name};
            });
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