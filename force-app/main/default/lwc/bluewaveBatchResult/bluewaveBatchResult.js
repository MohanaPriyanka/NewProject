/**
 * Created by Jeff Parlin on 9/8/2020.
 * Polls database for passed-in Batch IDs for completion and reports on outcome to user graphically in Flow Screen
 */

import {LightningElement, track, api} from 'lwc';
import getBatchCompletions from '@salesforce/apex/AsyncApexJobSelector.getBatchCompletions';
import {ShowToastEvent} from 'lightning/platformShowToastEvent';
import {reduceErrors} from 'c/ldsUtils';

const columns = [
    {label: 'Batch Id', fieldName: 'Id'},
    {label: 'Status', fieldName: 'Status'},
    {label: 'Items Processed', fieldName: 'JobItemsProcessed'},
    {label: 'Completed On', fieldName: 'CompletedDate'},
    {label: 'Error', fieldName: 'ExtendedStatus'},
]

export default class BluewaveBatchResult extends LightningElement {

    @api batchIds = [];
    @api queryFrequencyInSeconds = 6;
    @api queriesSentMax = 30;
    @api successMessage = 'All batches have processed successfully. You may close this window.';
    @api errorMessage = 'An error has occurred with one or more batches. Please contact your administrator.';
    @api timeoutMessage = 'One or more batches is still in progress, or an error has occurred. ' +
                          'Please check batch logs for additional info.'

    @track showLoadingSpinner = true;
    @track batchesHandled = [];

    queriesSent = 1;
    batchesWatching = [];
    columns = columns;
    success = true;
    timeout = false;
    intervalId;

    connectedCallback() {
        // clone watched Batch IDs for later
        this.batchesWatching = [...this.batchIds].filter(entry => entry !== '');

        // run query
        this.queryBatchJobs();

        // query database for batch results on a frequency
        this.intervalId = setInterval(() => {
            this.queryBatchJobs();
            this.queriesSent++;
        }, this.queryFrequencyInSeconds * 1000);
    }

    // toggles loading spinner off and displays results
    toggleLoadingOff() {
        this.showLoadingSpinner = false;
    }

    // send query request to database on AsyncApexJob table
    queryBatchJobs() {
        getBatchCompletions({batchIds: this.batchesWatching})
            .then(result => {
                this.handleQueryResults(result)
            })
            .catch(error => {
                this.errorNotify(error);
            });
    }

    // handle incoming query data
    handleQueryResults(data) {
        let newDataArray = [...this.batchesHandled];

        // Parse through each record retrieved via SOQL
        data.forEach(record => {
            newDataArray.push(record);
            this.batchesWatching = this.batchesWatching.filter(id => id !== record.Id);
        });
        this.batchesHandled = newDataArray;

        // If new query causes state change, or timeout occurred, handle state change
        if (this.batchesWatching.length === 0) {
            clearInterval(this.intervalId);
            this.setComponentStatus();
            this.toggleLoadingOff();
            return;
        }
        if (this.queriesSent >= this.queriesSentMax) {
            clearInterval(this.intervalId);
            this.handleTimeout();
            this.toggleLoadingOff();
        }
    }

    // handle timeout scenario where polling database stops
    handleTimeout() {
        // set booleans
        this.timeout = true;

        // add incomplete rows to datatable array
        let batches = [...this.batchesHandled];
        this.batchesWatching.forEach(batch => {
            let row = {Id: batch};
            batches.push(row);
        });
        this.batchesHandled = batches;
    }

    // set component flags for conditional render of status message to user
    setComponentStatus() {
        // check for successful batches by row
        this.batchesHandled.forEach(row => {
           if (row.Status !== 'Completed') {
               this.success = false;
           }
        });
    }

    // getter for message to display to end user on status of batch operation(s)
    get message() {
        if (this.timeout) {
            return this.timeoutMessage;
        } else if (this.success) {
            return this.successMessage;
        } else if (!this.success) {
            return this.errorMessage;
        }
    }

    // getter for message text style
    get messageStyle() {
        let styleClasses = 'slds-p-around_large slds-align_absolute-center slds-text-title_bold ';
        if (this.timeout || !this.success) {
            styleClasses += 'slds-text-color_error'
        } else if (this.success) {
            styleClasses += 'slds-text-color_success';
        }
        return styleClasses;
    }

    // send error notification to User via toast
    errorNotify(error) {
        let errorMessage = reduceErrors(error).toString();
        const evt = new ShowToastEvent({
            title: 'Error retrieving data from Salesforce',
            message: 'Retrying your request... \n\n Error Encountered: ' + errorMessage,
            variant: 'error',
        });
        this.dispatchEvent(evt);
    }

}