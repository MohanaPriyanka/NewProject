/**
 * Created by PeterYao on 2/24/2020.
 */

import { LightningElement, track, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import insertLog from '@salesforce/apex/Logger.insertLog';
import getContentDocumentsById from '@salesforce/apex/SimpleSignupFormController.getContentDocumentDataById';
import getContentDocumentLinksByLead from '@salesforce/apex/SimpleSignupFormController.getContentDocumentLinksByLead'
import getContentDistributionById from '@salesforce/apex/SimpleSignupFormController.getContentDistributionById';
import {makeRequest} from 'c/httpRequestService';

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
    mostRecentDocDate;

    connectedCallback() {
        if (!this.lead && this.leadJson) {
            this.lead = JSON.parse(this.leadJson);
            if(this.lead.contentDocs && this.lead.contentDocs.length === 2) {
                this.postProcessContractDocs(this.lead.contentDocs);
            }
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

    checkForSubmit(event) {
        if (event.which === 13) {
            this.continueAgreement(event);
        }
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
        if (this.csAgreement) {
            const inputBox = this.template.querySelector('[data-id="consentEmail"]');
            if (inputBox) {
                inputBox.focus();
            }
        }
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
            this.showWarningToast('Sorry', 'Please enter the email address that you previously provided to acknowledge consents');
            return false;
        } else {
            return true;
        }
    }

    continueAgreement(event) {
        if (this.validCSAgreement() && this.validDisclosureConsent() && this.validCreditCheckReview() && this.validConsentEmail()) {
            let restLead = {
                id: this.lead.id,
                email: this.lead.email,
                customerSignedDate: new Date()
            };
            this.showSpinner = true;
            this.spinnerMessage = 'Saving your consents';
            this.consentToDocs(restLead).then(
                (resolveResult) => {
                    this.showSpinner = false;
                    const consentsCompleteEvent = new CustomEvent('consentscomplete', {
                        detail: this.lead,
                    });
                    this.dispatchEvent(consentsCompleteEvent);
                },
                (rejectResult) => {
                    this.showSpinner = false;
                    insertLog({
                        className: 'ssf',
                        methodName: 'patchLead',
                        message: JSON.stringify(rejectResult),
                        severity: 'Error'
                    });
                    this.showWarningToast('Oops', 'We ran into a technical issue, please contact customer care\n' + rejectResult);
                }
            );
        }
    }

    consentToDocs(restLead) {
        let calloutURI = '/apply/services/apexrest/v3/leads';
        let options = {
            headers: {name: 'Content-Type', value:'application/json'},
            body: JSON.stringify(restLead)
        };
        return makeRequest(calloutURI, 'PATCH', options);
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
        }, 5000);
        window.setTimeout(() => {
            this.spinnerMessage = 'This can take a minute';
        }, 1000);
        this.documentPollerId = window.setInterval(() => {
            getContentDocumentLinksByLead({leadId: this.lead.id, email: this.lead.email, mostRecentDocsStr: JSON.stringify(this.lead.contentDocs)})
            .then(result => {
                let docs = JSON.parse(result);
                if (docs.length >= 2) {
                    this.postProcessContractDocs(docs);
                }
            })
            .catch(error => {
                this.showWarningToast('Error', 'Sorry, we ran into a technical issue: ' + error.body.message);
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
        var disclosurePosition;
        for (let c in contracts) {
            if (contracts[c].title === 'Community Solar Agreement.pdf' ) {
                this.csAgreementDocumentId = contracts[c].id;
                contracts[c].title = 'Community Solar Agreement';
            }
            if (contracts[c].title === 'Solar Disclosure Form.pdf') {
                this.disclosureDocumentId = contracts[c].id;
                contracts[c].title = 'Solar Disclosure Form';
                disclosurePosition = c;
            }
        }

        if(disclosurePosition) {
            contracts = contracts.splice(0, 0, contracts.splice(disclosurePosition, 1)[0]);
        }
    }

    filePreview(event) {
        var contract;
        for(let c in this.contractDocuments) {
            if(this.contractDocuments[c].id === event.target.dataset.id) {
                contract = this.contractDocuments[c];
                break;
            }
        }

        if(contract) {
            if(this.supportsDataUri) {
                this.documentUrl = 'data:application/pdf;base64,' +  contract.body;
                // getContentDocumentsById({documentId : event.target.dataset.id, leadId: this.lead.id, email: this.lead.email})
                // .then(result => {
                //     this.showContractDocument = true;
                //     this.documentUrl = 'data:application/pdf;base64,' + result;
                // }).catch(error => {
                //     this.showWarningToast('Error', 'Sorry, we ran into a technical issue: ' + error);
                // });
            } else {
                this.documentUrl = contract.publicUrl;
                // getContentDistributionById({documentId : event.target.dataset.id, leadId: this.lead.id, email: this.lead.email})
                // .then(result => {
                //     this.showContractDocument = true;
                //     this.documentUrl = result;
                // }).catch(error => {
                //     this.showWarningToast('Error', 'Sorry, we ran into a technical issue: ' + error);
                // });
            }
            this.showContractDocument = true;
        }
        
    }

    get supportsDataUri() {
        var navua = window.navigator.userAgent.toLowerCase();
        // trident = IE
        if(navua.indexOf("trident") > -1 || navua.indexOf("edge") > -1) {
            return false;
        }
        return true;
    };

    hideContractDocument(event) {
        this.showContractDocument = false;
    }
}