/**
 * Created by PeterYao on 2/24/2020.
 */

import { LightningElement, track, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import insertLog from '@salesforce/apex/Logger.insertLog';
import getContentDocumentsById from '@salesforce/apex/SimpleSignupFormController.getContentDocumentDataById';
import getContentDocumentLinksByLead from '@salesforce/apex/SimpleSignupFormController.getContentDocumentLinksByLead'

export default class SsfAgreements extends LightningElement {
    @api leadJson;
    lead;
    @track disclosures;
    @track creditCheck;
    @track csAgreement;
    @track showDisclosures = true;
    @track showCreditCheck;
    @track showCSAgreement;
    @track disclosureIcon = 'utility:record';
    @track creditCheckIcon = 'utility:routing_offline';
    @track csAgreementIcon = 'utility:routing_offline';
    @track moreCreditCheck = false;
    @track moreCSAgreement = false;
    @track consentEmail;
    @track documentUrl;
    @track contractDocuments;
    @track csAgreementDocumentId;
    @track disclosureDocumentId;
    @track showContractDocument;
    @track showSpinner;
    @track spinnerMessage;
    documentPollerId;
    documentPollerTimeoutId;

    connectedCallback() {
        if (!this.lead && this.leadJson) {
            this.lead = JSON.parse(this.leadJson);
        }
    }

    renderedCallback() {
        if (!this.contractDocuments && !this.documentPollerId) {
            this.getContractDocuments();
        }
    }

    genericOnChange(event) {
        this[event.target.name] = event.target.value;
    }

    genericOnCheckboxChange(event) {
        this[event.target.name] = event.target.checked;
    }

    disclosureChecked(event) {
        this.disclosures = event.target.checked;
        if (event.target.checked) {
            this.showCreditCheckApproval();
        }
    }

    creditCheckChecked(event) {
        this.creditCheck = event.target.checked;
        if (event.target.checked) {
            this.showCSAgreementApproval();
        }
    }

    csAgreementChecked(event) {
        this.csAgreement = event.target.checked;
    }

    validDisclosureConsent() {
        if (!this.disclosures) {
            this.showWarningToast('Sorry', 'Please check the checkbox to consent to electronic disclosures');
            return false;
        } else {
            return true;
        }
    }

    validCreditCheckReview() {
        if (!this.creditCheck) {
            this.showWarningToast('Sorry', 'Please check the checkbox to authorize credit and utility billing review');
            return false;
        } else {
            return true;
        }
    }

    validCSAgreement() {
        if (!this.csAgreement) {
            this.showWarningToast('Sorry', 'Please check the checkbox to agree to the Community Solar agreement and disclosure');
            return false;
        } else {
            return true;
        }
    }

    validConsentEmail() {
        if (this.lead.email !== this.consentEmail) {
            this.showWarningToast('Sorry', 'Please enter the email address that you previously provided (' + this.lead.email + ') to acknowledge consents');
            return false;
        } else {
            return true;
        }
    }

    continueAgreement(event) {
        if (this.validCSAgreement() && this.validDisclosureConsent() && this.validCreditCheckReview() && this.validConsentEmail()) {
            let restLead = {};
            restLead.id = this.lead.id;
            restLead.email = this.lead.email;
            restLead.applicationCompleteDate = new Date();
            this.showSpinner = true;
            this.spinnerMessage = 'Completing your application';
            this.finishApplication(restLead).then(
                (resolveResult) => {
                    this.showSpinner = false;
                    this.showWarningToast('Success', resolveResult);
                },
                (rejectResult) => {
                    this.showSpinner = false;
                    insertLog({
                        className: 'ssf',
                        methodName: 'patchLead',
                        message: JSON.stringify(rejectResult),
                        severity: 'Error'
                    });
                    this.showWarningToast('Failed', rejectResult);
                }
            );
        }
    }

    finishApplication(restLead) {
        return new Promise(function(resolve, reject) {
            let calloutURI = '/apply/services/apexrest/v3/leads';
            const xmlHttpRequest = new XMLHttpRequest();
            xmlHttpRequest.onreadystatechange = function() {
                if (this.readyState === 4) {
                    const response = JSON.parse(this.responseText);
                    if (this.status === 200 || this.status === 201) {
                        if (response.data) {
                            resolve(response.data);
                        } else {
                            reject(this.responseText);
                        }
                    } else {
                        reject(this.responseText);
                    }
                }
            };
            xmlHttpRequest.open('PATCH', calloutURI, true);
            xmlHttpRequest.setRequestHeader('Content-Type', 'application/json');
            xmlHttpRequest.send(JSON.stringify(restLead));
        });
    }

    showDisclosureApproval() {
        this.showDisclosures = true;
        this.disclosureIcon = 'utility:record';
        this.showCreditCheck = false;
        this.creditCheckIcon = 'utility:routing_offline';
        this.showCSAgreement = false;
        this.csAgreementIcon = 'utility:routing_offline';
    }

    showCreditCheckApproval() {
        if (!this.validDisclosureConsent()) {
            return;
        }
        this.showDisclosures = false;
        this.disclosureIcon = 'utility:routing_offline';
        this.showCreditCheck = true;
        this.creditCheckIcon = 'utility:record';
        this.showCSAgreement = false;
        this.csAgreementIcon = 'utility:routing_offline';
    }

    showCSAgreementApproval() {
        if (!this.validCreditCheckReview()) {
            return;
        }
        this.showDisclosures = false;
        this.disclosureIcon = 'utility:routing_offline';
        this.showCreditCheck = false;
        this.creditCheckIcon = 'utility:routing_offline';
        this.showCSAgreement = true;
        this.csAgreementIcon = 'utility:record';
    }

    showMoreCreditCheck(event) {
        this.moreCreditCheck = true;
    }
    showLessCreditCheck(event) {
        this.moreCreditCheck = false;
    }
    showMoreCSAgreement(event) {
        this.moreCSAgreement = true;
    }
    showLessCSAgreement(event) {
        this.moreCSAgreement = false;
    }

    showWarningToast(title, message) {
        const evt = new ShowToastEvent({
            title: title,
            message: message,
            variant: 'warning'
        });
        this.dispatchEvent(evt);
    }

    getContractDocuments() {
        if (this.contractDocuments) {
            return this.contractDocuments;
        }
        this.showSpinner = true;
        window.setTimeout(() => {
            this.spinnerMessage = 'Generating your documents';
        }, 4000);
        window.setTimeout(() => {
            this.spinnerMessage = 'This can take a minute';
        }, 8000);
        this.documentPollerId = window.setInterval(() => {
            getContentDocumentLinksByLead({leadId: this.lead.id, email: this.lead.email})
            .then(result => {
                if (result.length !== 0) {
                    this.postProcessContractDocs(result);
                }
            })
            .catch(error => {
                this.showWarningToast('Error', 'Sorry, we ran into a technical issue: ' + error);
                window.clearInterval(this.documentPollerId);
                window.clearTimeout(this.documentPollerTimeoutId);
                this.showSpinner = false;
            });
        }, 2000);
        this.documentPollerTimeoutId = window.setTimeout(() => {
            window.clearInterval(this.documentPollerId);
            this.showSpinner = false;
            this.showWarningToast('Error', 'Sorry, documents should not take this long to generate. Please contact customer care');
        }, 60000);
    }

    postProcessContractDocs(contracts) {
        window.clearInterval(this.documentPollerId);
        window.clearTimeout(this.documentPollerTimeoutId);
        this.showSpinner = false;
        this.contractDocuments = contracts;
        for (let c in contracts) {
            if (contracts[c].ContentDocument.LatestPublishedVersion.Title === 'Community Solar Agreement.pdf' ) {
                this.csAgreementDocumentId = contracts[c].ContentDocumentId;
                contracts[c].ContentDocument.LatestPublishedVersion.Title = 'Community Solar Agreement';
            }
            if (contracts[c].ContentDocument.LatestPublishedVersion.Title === 'Solar Disclosure Form.pdf') {
                this.disclosureDocumentId = contracts[c].ContentDocumentId;
                contracts[c].ContentDocument.LatestPublishedVersion.Title = 'Solar Disclosure Form';
            }
        }
    }

    filePreview(event) {
        getContentDocumentsById({documentId : event.target.dataset.id, leadId: this.lead.id, email: this.lead.email})
        .then(result => {
            this.showContractDocument = true;
            this.documentUrl = 'data:application/pdf;base64,' + result;
        })
        .catch(error => {
            this.showWarningToast('Error', 'Sorry, we ran into a technical issue: ' + error);
        });
    }

    hideContractDocument(event) {
        this.showContractDocument = false;
    }
}