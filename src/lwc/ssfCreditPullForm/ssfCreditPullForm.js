import {api, LightningElement, track} from 'lwc';
import {getUSStateOptionsFull} from 'c/util';
import {ShowToastEvent} from "lightning/platformShowToastEvent";
import updateLeadAndRunCreditCheck from '@salesforce/apex/SimpleSignupFormController.updateLeadAndRunCreditCheck';
import getLatestCreditReport from '@salesforce/apex/SimpleSignupFormController.getLatestCreditReport';
import insertLog from '@salesforce/apex/Logger.insertLog';

export default class SsfCreditPullForm extends LightningElement {

    @api applicantName;
    @api latestCreditReport;
    @api leadId;
    @api partnerVersion;
    @track showSpinner = false;
    @track spinnerMessage;

    activeSections = [];
    cachedInputs;
    creditBureauScoreFactor;
    creditBureauAlertMessage;
    errorState = false;
    leadLastModifiedDate;
    lead = {};
    pollerId;
    pollerTimeoutId;
    pollingTimeoutInSeconds = 60;
    retryEligible = false;
    retryPollingOnly = false;
    stateOptions;

    connectedCallback() {
        window.scrollTo(0,0);
        this.stateOptions = getUSStateOptionsFull();
        this.lead.id = this.leadId;

        // Set text to display on screen from passed-in latest credit report
        if (this.latestCreditReport) {
            this.creditBureauScoreFactor = this.latestCreditReport.scoreFactor;
            this.creditBureauAlertMessage = this.latestCreditReport.alertMessage;
        }
    }

    genericOnChange(event) {
        this.lead[event.target.name] = event.target.value;
    }

    decline() {
        this.postCompleteEvent();
    }

    async submit() {
        this.toggleSpinnerOn();

        // Verify submission has new information to send to server
        this.verifyInputs();

        // If polling previously timed out, check if we want to update the Lead again on the server before proceeding
        if (this.retryEligible) {
            this.assessRetryAttempt();
        }

        // If this is the user's first time pressing "Try Again" or they changed inputs, update Lead on the server
        if (!this.retryPollingOnly) {
            this.cachedInputs = {...this.lead};
            await this.updateLead();
        }

        // Begin polling the server for newly-generated PCR by LASERCA
        this.pollServerForNewCreditReport();

        this.clearErrorState();
    }

    verifyInputs() {
        return true;
    }

    async updateLead() {
        try {
            let response = await updateLeadAndRunCreditCheck({
                leadJSON: JSON.stringify(this.lead),
            });
            if (response === 'ERROR' || response === null) {
                this.notifyLeadUpdateError();
            } else {
                // Server response === datetime of successful lead update
                this.leadLastModifiedDate = response;
            }
        } catch (error) {
            this.notifyLeadUpdateError();
        }
    }

    assessRetryAttempt() {
        this.retryPollingOnly = this.retryEligible && !this.inputsHaveChanged();
    }

    clearErrorState() {
        this.errorState = false;
    }

    postCompleteEvent() {
        const formCompleteEvent = new CustomEvent('formcomplete');
        this.dispatchEvent(formCompleteEvent);
    }

    toggleSpinnerOn() {
        this.showSpinner = true;
        this.spinnerMessage = 'Submitting data and running credit report...';
        window.setTimeout(() => {
            this.spinnerMessage = 'This can take a minute';
        }, 4000);
    }

    notifyLeadUpdateError() {
        this.errorState = true;
        this.showSpinner = false;
        this.showErrorToast(
        'Oops!',
    `Unable to submit data. Please try again or bypass this form by pressing "No Thanks".`
        );
    }

    pollServerForNewCreditReport() {
        // Ensure no error state prior to polling server
        if (this.errorState) {
            return;
        }
        if (!this.leadLastModifiedDate) {
            // Here indicates that lead was not updated on server and new credit pull request has NOT been initiated
            this.showErrorToast('Oops!',
                `A technical issue has been encountered. Please try again or bypass this form by pressing "No Thanks".`);
            return;
        }

        // Poll server every 3 seconds for new Credit Report generated
        this.pollerId = window.setInterval(() => {
            this.requestCreditReport();
        }, 3000);

        // Set timeout for server calls
        this.pollerTimeoutId = window.setTimeout(() => {
            window.clearInterval(this.pollerId);
            this.showSpinner = false;
            this.retryEligible = true;
            this.showErrorToast('Oops!',
                `The credit pull is taking too long to process. Please try again or proceed by pressing "No Thanks".`
            );
        }, this.pollingTimeoutInSeconds * 1000);
    }

    showErrorToast(title, message) {
        const evt = new ShowToastEvent({
            title: title,
            message: message,
            variant: 'warning'
        });
        this.dispatchEvent(evt);
    }

    showSuccessToast(title, message) {
        const evt = new ShowToastEvent({
            title: 'Success!',
            message: 'Credit Report Found',
            variant: 'success'
        });
        this.dispatchEvent(evt);
    }

    inputsHaveChanged() {
        let inputsChanged = false;
        for (const property in this.lead) {
            inputsChanged = this.cachedInputs[property] === this.lead[property] ? true : inputsChanged;
            if (inputsChanged) {
                break;
            }
        }
        return inputsChanged;
    }

    logError(promiseRejection, methodName, severity) {
        insertLog({
            className: 'ssfCreditPullForm',
            methodName: methodName,
            message: JSON.stringify(promiseRejection),
            severity: severity
        });
    }

    async requestCreditReport() {
        try {
            let creditResponse = await getLatestCreditReport({
                leadId: this.leadId,
                queryAllHistoric: false,
                queryAfter: this.leadLastModifiedDate,
            });
            this.assessCreditPull(creditResponse);
        } catch (error) {
            this.logError(error, 'requestCreditReport', 'WARN');
        }
    }

    assessCreditPull(creditResponse) {
        if (creditResponse.noMatch === null) {
            // No report found, do nothing & continue polling
        } else if (creditResponse.noMatch === true) {
            this.performFailActions(creditResponse);
        } else if (creditResponse.noMatch === false) {
            this.performSuccessActions();
        }
    }

    performFailActions(creditResponse) {
        window.clearInterval(this.pollerId);
        window.clearTimeout(this.pollerTimeoutId);
        this.creditBureauScoreFactor = creditResponse.scoreFactor;
        this.creditBureauAlertMessage = creditResponse.alertMessage;
        this.retryEligible = false;
        this.showSpinner = false;
        if (this.partnerVersion) {
            this.showErrorToast(
                'No Match Found',
                'Change inputs and try again. See technical details for more information.'
            );
        } else {
            this.showErrorToast(
                'Oops!',
                'We were unable to locate your credit file. Try again, or press "No Thanks" to proceed.',
            );
        }
    }

    performSuccessActions() {
        window.clearInterval(this.pollerId);
        window.clearTimeout(this.pollerTimeoutId);
        if (this.partnerVersion) {
            this.showSuccessToast();
        }
        this.postCompleteEvent();
    }

    get scoreFactor() {
        return !!this.creditBureauScoreFactor ? this.creditBureauScoreFactor : 'N/A';
    }

    get alertMessage() {
        return !!this.creditBureauAlertMessage ? this.creditBureauAlertMessage : 'N/A';
    }

    get headerText() {
        if (this.partnerVersion) {
            return `We were unable to locate the applicant's information with the credit reporting agency. ` +
                   `Please provide additional information to help us locate the applicant's credit file. `+
                   `This is optional, but may expedite the application process.`;
        } else {
            return `We were unable to locate your information with the credit reporting agency. `+
                   `Please provide any additional information below that might help us locate your credit file. `+
                   `This is optional, but may expedite your access to solar energy savings!`;
        }
    }
}